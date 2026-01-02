#!/usr/bin/env python3
"""
Cross-Skill Suggestion Hook for sf-skills (v3.0)

Enhanced skill suggestion system that:
- Reads from unified skills-registry.json
- Accepts optional skill name as CLI argument
- Adds confidence levels (REQUIRED/RECOMMENDED/OPTIONAL)
- Detects orchestration chains
- Persists context for inter-skill communication

Usage:
  python3 suggest-related-skills.py [skill-name]

Called automatically via PostToolUse hook on Write|Edit operations.
"""

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional

# Configuration
MAX_SUGGESTIONS = 3
SCRIPT_DIR = Path(__file__).parent
REGISTRY_FILE = SCRIPT_DIR / "skills-registry.json"
CONTEXT_FILE = Path("/tmp/sf-skills-context.json")

# Cache for registry config
_registry_cache: Optional[dict] = None


def load_registry() -> dict:
    """Load the unified skills registry configuration."""
    global _registry_cache
    if _registry_cache is not None:
        return _registry_cache

    try:
        with open(REGISTRY_FILE, 'r') as f:
            _registry_cache = json.load(f)
            return _registry_cache
    except (FileNotFoundError, json.JSONDecodeError) as e:
        # Fallback to empty config
        return {"skills": {}, "chains": {}, "confidence_levels": {}}


def load_context() -> dict:
    """Load previous skill context for chain awareness."""
    try:
        if CONTEXT_FILE.exists():
            with open(CONTEXT_FILE, 'r') as f:
                return json.load(f)
    except (json.JSONDecodeError, IOError):
        pass
    return {}


def save_context(skill: str, file_path: str, triggers: list[str], suggestions: list[dict]):
    """Save current context for next skill invocation."""
    context = {
        "timestamp": datetime.now().isoformat(),
        "last_skill": skill,
        "last_file": file_path,
        "detected_triggers": triggers,
        "suggested_next": [s["skill"] for s in suggestions if s["type"] == "after"][:2]
    }
    try:
        with open(CONTEXT_FILE, 'w') as f:
            json.dump(context, f, indent=2)
    except IOError:
        pass  # Context saving is optional


def detect_skill_from_file(file_path: str, registry: dict) -> Optional[str]:
    """Detect which skill owns this file based on filePatterns."""
    skills = registry.get("skills", {})

    for skill_name, skill_config in skills.items():
        patterns = skill_config.get("filePatterns", [])
        for pattern in patterns:
            if re.search(pattern, file_path, re.IGNORECASE):
                return skill_name

    return None


def detect_content_triggers(content: str, skill_config: dict) -> list[str]:
    """Detect trigger patterns in file content using skill's contentTriggers."""
    triggers = []

    # Check skill-specific content triggers
    content_triggers = skill_config.get("contentTriggers", {})
    for pattern, _ in content_triggers.items():
        if re.search(pattern, content, re.IGNORECASE):
            triggers.append(pattern)

    # Also detect common patterns (for backwards compatibility)
    common_patterns = [
        (r"@InvocableMethod", "@InvocableMethod"),
        (r"@AuraEnabled", "@AuraEnabled"),
        (r"@IsTest|testMethod", "@IsTest"),
        (r"implements\s+Queueable", "Queueable"),
        (r"implements\s+Batchable", "Batchable"),
        (r"implements\s+Schedulable", "Schedulable"),
        (r"HttpRequest|HttpResponse", "callout"),
        (r"import.*@salesforce/apex", "apex_import"),
        (r"lightning__FlowScreen", "FlowScreen"),
        (r"FlowAttributeChangeEvent", "FlowAttributeChangeEvent"),
        (r"@salesforce/messageChannel", "message_channel"),
        (r"actionType.*apex|actionCalls", "apex_action"),
        (r"ComponentInstance|extensionName", "ComponentInstance"),
        (r"processType.*AutoLaunchedFlow", "AutoLaunchedFlow"),
        (r"RecordAfterSave|RecordBeforeSave", "record_triggered"),
        (r"CustomObject|CustomField", "custom_object"),
        (r"flow://", "flow_target"),
        (r"failure|failed|FAIL", "failure"),
        (r"Assert\.|System\.assert", "Assert"),
        (r"bulk|200\+|251", "bulk"),
    ]

    for pattern, trigger_name in common_patterns:
        if re.search(pattern, content, re.IGNORECASE):
            if trigger_name not in triggers:
                triggers.append(trigger_name)

    return triggers


def detect_chain(context: dict, current_skill: str, registry: dict) -> Optional[dict]:
    """Detect if we're in an orchestration chain."""
    chains = registry.get("chains", {})
    last_skill = context.get("last_skill")

    if not last_skill:
        return None

    for chain_name, chain_config in chains.items():
        order = chain_config.get("order", [])
        if last_skill in order and current_skill in order:
            last_idx = order.index(last_skill)
            current_idx = order.index(current_skill)

            # Check if we're progressing in the chain
            if current_idx == last_idx + 1 or current_idx > last_idx:
                return {
                    "name": chain_name,
                    "description": chain_config.get("description", ""),
                    "order": order,
                    "current_step": current_idx + 1,
                    "total_steps": len(order),
                    "next_skills": order[current_idx + 1:current_idx + 3]
                }

    return None


def get_suggestions(skill: str, triggers: list[str], registry: dict) -> list[dict]:
    """Get skill suggestions based on detected skill and triggers."""
    suggestions = []
    skill_config = registry.get("skills", {}).get(skill, {})
    orchestration = skill_config.get("orchestration", {})

    # Prerequisites (before_this)
    prerequisites = orchestration.get("prerequisites", [])
    for prereq in prerequisites:
        condition = prereq.get("condition", "always")
        if condition == "always" or any(
            re.search(condition, t, re.IGNORECASE) for t in triggers
        ):
            suggestions.append({
                "type": "before",
                "skill": prereq["skill"],
                "message": prereq["message"],
                "confidence": prereq.get("confidence", 2),
                "priority": 0  # Prerequisites come first
            })

    # Next steps (after_creating)
    next_steps = orchestration.get("next_steps", [])
    for step in next_steps:
        condition = step.get("condition", "always")
        if condition == "always" or any(
            re.search(condition, t, re.IGNORECASE) for t in triggers
        ):
            suggestions.append({
                "type": "after",
                "skill": step["skill"],
                "message": step["message"],
                "confidence": step.get("confidence", 2),
                "priority": step.get("confidence", 2)
            })

    # Commonly used with (based on triggers)
    commonly_with = orchestration.get("commonly_with", [])
    for related in commonly_with:
        trigger_pattern = related.get("trigger", "always")
        if trigger_pattern == "always" or any(
            re.search(trigger_pattern, t, re.IGNORECASE) for t in triggers
        ):
            # Don't duplicate suggestions
            if related["skill"] not in [s["skill"] for s in suggestions]:
                suggestions.append({
                    "type": "with",
                    "skill": related["skill"],
                    "message": related["message"],
                    "confidence": related.get("confidence", 1),
                    "priority": 10 + related.get("confidence", 1)
                })

    # Sort by priority (lower = higher priority) and deduplicate
    seen_skills = set()
    unique_suggestions = []
    for s in sorted(suggestions, key=lambda x: x["priority"]):
        if s["skill"] not in seen_skills:
            seen_skills.add(s["skill"])
            unique_suggestions.append(s)

    return unique_suggestions[:MAX_SUGGESTIONS]


def format_suggestions(suggestions: list[dict], current_skill: str, chain: Optional[dict], registry: dict) -> str:
    """Format suggestions as readable text with confidence levels."""
    if not suggestions and not chain:
        return ""

    confidence_levels = registry.get("confidence_levels", {
        "3": {"icon": "***", "label": "REQUIRED"},
        "2": {"icon": "**", "label": "RECOMMENDED"},
        "1": {"icon": "*", "label": "OPTIONAL"}
    })

    lines = [f"\n{'═' * 54}"]
    lines.append(f"🔗 SKILL SUGGESTIONS (working with {current_skill})")
    lines.append(f"{'═' * 54}")

    # Show chain progress if detected
    if chain:
        step = chain["current_step"]
        total = chain["total_steps"]
        chain_name = chain["name"]
        lines.append(f"\n📋 DETECTED WORKFLOW: {chain_name}")
        lines.append(f"   Step {step} of {total}: {current_skill}")
        if chain["next_skills"]:
            next_str = " → ".join(chain["next_skills"])
            lines.append(f"   Next: {next_str}")
        lines.append("")

    type_labels = {
        "before": ("⚠️", "PREREQUISITE"),
        "after": ("➡️", "NEXT STEP"),
        "with": ("🔄", "RELATED")
    }

    for s in suggestions:
        icon, type_label = type_labels.get(s["type"], ("💡", "SUGGESTION"))
        conf = s.get("confidence", 2)
        conf_info = confidence_levels.get(str(conf), {"icon": "**", "label": "RECOMMENDED"})
        conf_stars = conf_info["icon"]
        conf_label = conf_info["label"]

        lines.append(f"{icon} {type_label}: /{s['skill']} {conf_stars} {conf_label}")
        lines.append(f"   └─ {s['message']}")

    lines.append(f"{'─' * 54}")
    lines.append("💡 Invoke with /skill-name or ask Claude to use it")
    lines.append(f"{'═' * 54}\n")

    return "\n".join(lines)


def main():
    """Main entry point for the hook."""
    # Check for skill name passed as argument
    cli_skill = sys.argv[1] if len(sys.argv) > 1 else None

    try:
        # Read hook input from stdin
        input_data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        # If no stdin, exit silently
        sys.exit(0)

    # Get file path from tool input
    tool_input = input_data.get("tool_input", {})
    file_path = tool_input.get("file_path", "")
    content = tool_input.get("content", "")

    # For Edit operations, content might be in different fields
    if not content:
        content = tool_input.get("new_string", "")

    if not file_path:
        sys.exit(0)

    # Load registry and context
    registry = load_registry()
    context = load_context()

    # Detect the skill from file pattern (or use CLI argument)
    current_skill = cli_skill or detect_skill_from_file(file_path, registry)
    if not current_skill:
        sys.exit(0)

    # Get skill config
    skill_config = registry.get("skills", {}).get(current_skill, {})
    if not skill_config:
        sys.exit(0)

    # Read full file content if we only have partial content
    if not content or len(content) < 100:
        try:
            with open(file_path, 'r') as f:
                content = f.read()
        except (FileNotFoundError, IOError):
            pass

    # Detect content triggers
    triggers = detect_content_triggers(content, skill_config)

    # Detect if we're in a chain
    chain = detect_chain(context, current_skill, registry)

    # Get suggestions
    suggestions = get_suggestions(current_skill, triggers, registry)

    # Save context for next skill
    save_context(current_skill, file_path, triggers, suggestions)

    if not suggestions and not chain:
        sys.exit(0)

    # Format output
    formatted = format_suggestions(suggestions, current_skill, chain, registry)

    # Output as JSON for Claude
    output = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": formatted
        }
    }

    print(json.dumps(output))
    sys.exit(0)


if __name__ == "__main__":
    main()
