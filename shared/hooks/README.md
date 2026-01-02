# Shared Hooks Architecture

This directory contains the centralized hook system for sf-skills, providing intelligent skill discovery and orchestration across all 16 Salesforce skills.

## Overview

```
shared/hooks/
├── skills-registry.json         # Single source of truth for all skill metadata
├── skill-activation-prompt.py   # UserPromptSubmit hook (pre-prompt suggestions)
├── suggest-related-skills.py    # PostToolUse hook (post-action suggestions)
└── README.md                    # This file
```

## Architecture

### Enhanced Advisory System

The hooks follow an **advisory, not automatic** philosophy:

```
User Prompt → Pre-Prompt Hook → Claude sees suggestions → Claude decides
                 ↓
           skill-activation-prompt.py
                 ↓
           skills-registry.json
                 ↓
           "⭐⭐⭐ REQUIRED: /sf-apex"

─────────────────────────────────────────────────────────────────────

User Edits File → Post-Tool Hook → Claude sees suggestions → Claude decides
                     ↓
              suggest-related-skills.py
                     ↓
              skills-registry.json
                     ↓
              "➡️ NEXT STEP: /sf-testing"
```

### Key Features

1. **Unified Registry** - Single `skills-registry.json` contains:
   - Keywords and intent patterns for discovery
   - File patterns for skill detection
   - Content triggers (decorators → related skills)
   - Orchestration (prerequisites, next_steps, commonly_with)
   - Named workflow chains

2. **Confidence Levels**:
   - `⭐⭐⭐ REQUIRED` (confidence: 3) - Must use this skill
   - `⭐⭐ RECOMMENDED` (confidence: 2) - Strongly suggested
   - `⭐ OPTIONAL` (confidence: 1) - Consider if applicable

3. **Chain Detection** - Recognizes workflow patterns:
   - `full_feature`: sf-metadata → sf-apex → sf-flow → sf-lwc → sf-deploy → sf-testing
   - `agentforce`: sf-metadata → sf-apex → sf-flow → sf-deploy → sf-ai-agentforce
   - `integration`: sf-connected-apps → sf-integration → sf-flow → sf-deploy
   - `troubleshooting`: sf-testing → sf-debug → sf-apex → sf-deploy → sf-testing

4. **Context Persistence** - Saves context to `/tmp/sf-skills-context.json`:
   - Last skill used
   - Files modified
   - Detected patterns
   - Enables chain awareness across skill invocations

## Usage

### Pre-Prompt Hook (skill-activation-prompt.py)

Wired globally in `.claude/hooks.json`:

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "type": "command",
      "command": "python3 ./shared/hooks/skill-activation-prompt.py",
      "timeout": 5000
    }]
  }
}
```

**Example Output:**
```
══════════════════════════════════════════════════════
💡 SKILL SUGGESTIONS (based on your request)
══════════════════════════════════════════════════════

📋 DETECTED WORKFLOW: agentforce
   Agentforce agent development - prerequisites to testing
   Order: sf-metadata → sf-apex → sf-flow → sf-deploy → sf-ai-agentforce
   ⭐ START WITH: /sf-metadata

⭐⭐⭐ /sf-apex - REQUIRED
   └─ Apex code development with validation and best practices
⭐⭐ /sf-flow - RECOMMENDED
   └─ Flow Builder automation with validation
──────────────────────────────────────────────────────
💡 Invoke with /skill-name or ask Claude to use it
══════════════════════════════════════════════════════
```

### Post-Tool Hook (suggest-related-skills.py)

Wired in each skill's `hooks/hooks.json`:

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write",
      "hooks": [{
        "type": "command",
        "command": "python3 ${CLAUDE_PLUGIN_ROOT}/../../shared/hooks/suggest-related-skills.py sf-apex",
        "timeout": 5000
      }]
    }]
  }
}
```

**Example Output:**
```
══════════════════════════════════════════════════════
🔗 SKILL SUGGESTIONS (working with sf-apex)
══════════════════════════════════════════════════════

📋 DETECTED WORKFLOW: full_feature
   Step 2 of 7: sf-apex
   Next: sf-flow → sf-lwc

➡️ NEXT STEP: /sf-testing *** REQUIRED
   └─ Run tests to validate Apex code
➡️ NEXT STEP: /sf-deploy ** RECOMMENDED
   └─ Deploy Apex to org with validation
🔄 RELATED: /sf-flow ** RECOMMENDED
   └─ Create Flow to call this @InvocableMethod
──────────────────────────────────────────────────────
💡 Invoke with /skill-name or ask Claude to use it
══════════════════════════════════════════════════════
```

## Skills Registry Schema

```json
{
  "version": "3.0.0",
  "skills": {
    "sf-apex": {
      "keywords": ["apex", "trigger", "batch", ...],
      "intentPatterns": ["create.*apex", "write.*trigger", ...],
      "filePatterns": ["\\.cls$", "\\.trigger$"],
      "contentTriggers": {
        "@InvocableMethod": { "suggests": "sf-flow", "message": "..." }
      },
      "priority": "high",
      "description": "Apex code development...",
      "orchestration": {
        "prerequisites": [{ "skill": "...", "confidence": 2, "message": "..." }],
        "next_steps": [{ "skill": "...", "confidence": 3, "message": "..." }],
        "commonly_with": [{ "skill": "...", "trigger": "...", "message": "..." }]
      }
    }
  },
  "chains": {
    "full_feature": {
      "description": "Complete feature development...",
      "trigger_phrases": ["build feature", "complete feature"],
      "order": ["sf-metadata", "sf-apex", "sf-flow", ...]
    }
  },
  "confidence_levels": {
    "3": { "label": "REQUIRED", "icon": "***" },
    "2": { "label": "RECOMMENDED", "icon": "**" },
    "1": { "label": "OPTIONAL", "icon": "*" }
  }
}
```

## Adding a New Skill

1. Add entry to `skills-registry.json`:
   ```json
   "sf-newskill": {
     "keywords": [...],
     "intentPatterns": [...],
     "filePatterns": [...],
     "priority": "medium",
     "description": "...",
     "orchestration": { ... }
   }
   ```

2. Update any existing skill's orchestration to reference the new skill if relevant

3. Add to appropriate chains in the `chains` section if applicable

4. In new skill's `hooks/hooks.json`, reference the shared script:
   ```json
   "command": "python3 ${CLAUDE_PLUGIN_ROOT}/../../shared/hooks/suggest-related-skills.py sf-newskill"
   ```

## Design Rationale

### Why Advisory, Not Automatic?

1. **User Agency** - Users stay in control of skill invocations
2. **Transparency** - Claude explains why it's suggesting skills
3. **Flexibility** - Users can override suggestions based on context
4. **Claude is Smart** - The model follows well-structured suggestions

### Why Single Registry?

1. **DRY** - No duplicate configuration across 16+ skills
2. **Consistency** - All skills use the same schema
3. **Maintainability** - One place to update skill metadata
4. **Discoverability** - Easy to see all skill relationships

### Why Context Persistence?

1. **Chain Awareness** - Detect multi-skill workflows
2. **Smarter Suggestions** - Know what was done previously
3. **Progress Tracking** - Show "Step 2 of 5" in chains
