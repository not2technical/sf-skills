---
name: sf-flow-builder
description: Creates and validates Salesforce flows using best practices and metadata standards
version: 1.4.0
author: Jag Valaiyapathy
license: MIT
tags:
  - salesforce
  - flow
  - automation
  - builder
  - metadata
  - sfdx
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - AskUserQuestion
  - TodoWrite
  - Skill
  - WebFetch
dependencies:
  - name: sf-deployment
    version: ">=2.0.0"
    required: true
metadata:
  format_version: "2.0.0"
  created: "2024-11-28"
  updated: "2025-11-30"
  api_version: "62.0"
  license_file: "LICENSE"
  features:
    - transform-element
    - bulk-validation
    - strict-mode
    - simulation-mode
    - platform-events
    - before-save-triggers
    - before-delete-triggers
---

# sf-flow-builder: Salesforce Flow Creation and Validation

Expert Salesforce Flow Builder with deep knowledge of best practices, bulkification, and Winter '26 (API 62.0) metadata. Create production-ready, performant, secure, and maintainable flows.

## Core Responsibilities

1. **Flow Generation**: Create well-structured Flow metadata XML from requirements
2. **Strict Validation**: Enforce best practices with comprehensive checks and scoring
3. **Safe Deployment**: Integrate with sf-deployment skill for two-step validation and deployment
4. **Testing Guidance**: Provide type-specific testing checklists and verification steps

## Workflow Design (5-Phase Pattern)

### Phase 1: Requirements Gathering & Analysis

1. **Use AskUserQuestion to gather:**
   - Flow type (Screen, Record-Triggered After/Before Save/Delete, Platform Event, Autolaunched, Scheduled)
   - Primary purpose (one sentence)
   - Trigger object/conditions (if record-triggered)
   - Target org alias

2. **Check existing flows:** `Glob: pattern="**/*.flow-meta.xml"`

3. **Offer Reusable Subflows:**
   - Ask: "Use standard subflows?" Options: Sub_LogError (logging), Sub_SendEmailAlert (notifications), Sub_ValidateRecord (validation), Sub_UpdateRelatedRecords (bulk ops), Sub_QueryRecordsWithRetry (fault handling), None/Custom
   - See: [docs/subflow-library.md](docs/subflow-library.md)

4. **Assess Security & Governance:**
   - If sensitive data/complex automation: Ask "Architecture review completed?" (Yes/No-non-critical/Need-guidance)
   - If needed: Reference [docs/governance-checklist.md](docs/governance-checklist.md)

5. **Create TodoWrite tasks:** Gather requirements ✓, Select template, Generate XML, Validate, Deploy (two-step), Test

### Phase 2: Flow Design & Template Selection

1. **Select template:**
   - Screen → `templates/screen-flow-template.xml`
   - Record-Triggered (After/Before Save/Delete) → `templates/record-triggered-*.xml`
   - Platform Event → `templates/platform-event-flow-template.xml`
   - Autolaunched → `templates/autolaunched-flow-template.xml`
   - Scheduled → `templates/scheduled-flow-template.xml`

2. **Load template:** `Read: ~/.claude/skills/sf-flow-builder/templates/[template].xml`

3. **Generate naming:**
   - API Name: PascalCase_With_Underscores (e.g., `Account_Creation_Screen_Flow`)
   - Label: Human-readable (e.g., "Account Creation Screen Flow")

4. **Design structure:** Variables (var/col prefixes), Elements, Flow paths, Error handling (fault paths)

5. **Suggest Orchestration Pattern (if complex):**
   - Detect: Multiple objects/steps, cross-object updates, conditional logic
   - Suggest: Parent-Child (independent), Sequential (dependent), Conditional (scenarios)
   - Ask: "Create parent flow + subflows?"
   - See: [docs/orchestration-guide.md](docs/orchestration-guide.md)

### Phase 3: Flow Generation & Validation

1. **Create flow file:**
```bash
Bash: mkdir -p force-app/main/default/flows
Write: force-app/main/default/flows/[FlowName].flow-meta.xml
```

2. **Populate template:**
   - Replace {{FLOW_LABEL}}, {{FLOW_DESCRIPTION}}, {{OBJECT_NAME}}
   - API version: 62.0
   - **CRITICAL:** Alphabetical XML element ordering at root level
   - **CRITICAL:** NO deprecated `<bulkSupport>` (removed API 60.0+)
   - **CRITICAL:** Auto-Layout (all locationX/Y = 0) - cleaner git diffs, easier reviews
   - Add fault paths to all DML operations

3. **Run Enhanced Validation Suite:**
```bash
# 6-category scoring validator
python3 ~/.claude/skills/sf-flow-builder/validators/enhanced_validator.py \
  force-app/main/default/flows/[FlowName].flow-meta.xml

# Security & governance
python3 ~/.claude/skills/sf-flow-builder/validators/security_validator.py \
  force-app/main/default/flows/[FlowName].flow-meta.xml

# Naming conventions
python3 ~/.claude/skills/sf-flow-builder/validators/naming_validator.py \
  force-app/main/default/flows/[FlowName].flow-meta.xml
```

4. **Inline Validation (STRICT MODE - ALL must pass):**

**CRITICAL ERRORS (Block immediately):**
- ❌ XML malformed
- ❌ Missing: apiVersion, label, processType, status
- ❌ API version < 62.0
- ❌ Broken element references
- ❌ **DML operations inside loops** (causes bulk failures)

**WARNINGS (Block in strict mode):**
- ⚠️ Incorrect XML element ordering (must be alphabetical)
- ⚠️ Deprecated elements
- ⚠️ Non-zero location coordinates
- ⚠️ DML missing fault paths
- ⚠️ Unused variables/orphaned elements
- ⚠️ Loops with field mapping (use Transform for 30-50% gain)
- ⚠️ Naming conventions violated

**BEST PRACTICES:**
- ✓ Has description, proper naming, Transform usage, Auto-Layout

5. **Run Simulation (REQUIRED for record-triggered/scheduled):**
```bash
python3 ~/.claude/skills/sf-flow-builder/validators/flow_simulator.py \
  force-app/main/default/flows/[FlowName].flow-meta.xml --test-records 200
```
- Tests bulk execution (200+ records), governor limits (SOQL:100, DML:150, rows:10k, CPU:10s)
- **If simulation fails: STOP and fix before proceeding**

6. **Validation Report Format (6-Category Scoring 0-110):**
```
Score: 92/110 ⭐⭐⭐⭐ Very Good
├─ Design & Naming: 18/20 (90%)
├─ Logic & Structure: 20/20 (100%)
├─ Architecture & Orchestration: 12/15 (80%)
├─ Performance & Bulk Safety: 20/20 (100%)
├─ Error Handling & Observability: 15/20 (75%)
└─ Security & Governance: 15/15 (100%)

Recommendations:
1. Add Sub_LogError for structured logging
2. Consider parent+subflows for complex logic
3. Expand flow description
```

7. **Strict Mode Enforcement:** If ANY errors/warnings: Block with options: (1) Apply auto-fixes, (2) Show manual fixes, (3) Generate corrected version. **DO NOT PROCEED** to Phase 4 until 100% clean.

### Phase 4: Deployment & Integration

1. **Step 1: Validation Deployment (Check-Only)**
```
Skill(skill="sf-deployment")
Request: "Deploy flow at force-app/main/default/flows/[FlowName].flow-meta.xml
to [target-org] with dry-run validation (--dry-run flag). Do NOT deploy yet."
```

2. **Review validation:** Check for field access, permissions, conflicts. Common failures: Field missing, insufficient permissions, duplicate API name, required field missing.

3. **Step 2: Actual Deployment (only if validation succeeds)**
```
Skill(skill="sf-deployment")
Request: "Proceed with actual deployment of flow to [target-org]."
```

4. **Step 3: Activation Prompt**
```
AskUserQuestion: "Activate '[FlowName]' now or keep Draft?"
Options: Activate Now (⚠️ caution in prod), Keep Draft (✓ recommended)
```
If activate: Edit status to `<status>Active</status>`, re-deploy, verify.

5. **Generate Flow Documentation:**
```bash
python3 ~/.claude/skills/sf-flow-builder/generators/doc_generator.py \
  force-app/main/default/flows/[FlowName].flow-meta.xml \
  docs/flows/[FlowName]_documentation.md
```
Includes: Overview, entry/exit criteria, logic, orchestration pattern, performance, error handling, security, testing, dependencies, troubleshooting.
See: [templates/flow-documentation-template.md](templates/flow-documentation-template.md)

6. **Governance Checklist (if required):**
For sensitive/complex flows: Reference [docs/governance-checklist.md](docs/governance-checklist.md)
Required checkpoints: Business justification, architecture review, security assessment, testing plan, rollback strategy, authorization.
Minimum score: **140/200 points** for production.

### Phase 5: Testing & Documentation

1. **Type-Specific Testing:**

**Screen Flows:** Setup → Flows → Run, test all paths/profiles
URL: `https://[org].lightning.force.com/lightning/setup/Flows/page?address=%2F[FlowId]`

**Record-Triggered:** Create test record, verify Debug Logs, **CRITICAL:** bulk test (200+ records via Data Loader)
Query: `sf data query --query "SELECT Id, Status FROM FlowInterview WHERE FlowDefinitionName='[FlowName]' ORDER BY CreatedDate DESC LIMIT 10" --target-org [org]`

**Autolaunched:** Apex test class, edge cases (nulls, max values), bulkification (200+ records)
Sample: `Flow.Interview.[FlowName] flowInstance = new Flow.Interview.[FlowName](); flowInstance.start();`

**Scheduled:** Verify schedule config, manual Run test first, monitor Debug Logs, check Scheduled Jobs

**Examples:** See `examples/` directory for detailed testing patterns

2. **Security & Profile Testing (User mode):**
Test with multiple profiles (Standard User, Custom, Permission Sets) to verify FLS/CRUD respected.
```bash
sf org login user --username standard.user@company.com --target-org [org]
```
**System mode:** ⚠️ Security review required - bypasses FLS/CRUD. Must document justification.

3. **Documentation:** Review auto-generated `docs/flows/[FlowName]_documentation.md`, fill business context, test results, troubleshooting notes.

4. **Completion Summary:**
```
✓ Flow Creation Complete: [FlowName]
  Type: [type] | API: 62.0 | Status: [Draft/Active]
  Location: force-app/main/default/flows/[FlowName].flow-meta.xml
  Validation: PASSED (Score: XX/110)
  Deployment: Org=[target-org], Job=[job-id]

Next Steps:
1. Complete testing (unit, bulk, security, integration)
2. Review docs/flows/[FlowName]_documentation.md
3. Activate after testing (if Draft)
4. Monitor Debug Logs
5. Complete governance checklist (if required)

Resources: examples/, docs/subflow-library.md, docs/orchestration-guide.md,
docs/governance-checklist.md, https://help.salesforce.com/s/articleView?id=sf.flow.htm
```

## Salesforce Flow Best Practices (Built-In Enforcement)

### Critical Requirements
- **API 62.0:** Latest features (Transform, enhanced error connectors)
- **No DML in Loops:** CRITICAL ERROR - causes bulk failures. Pattern: Collect in loop → DML after loop
- **Bulkify Record-Triggered:** MUST handle collections
- **Fault Paths:** All DML must have fault connectors
- **Auto-Layout:** All locationX/Y = 0 (cleaner git, easier reviews, standard in API 64.0+)

### XML Element Ordering (CRITICAL)
Salesforce Metadata API requires strict alphabetical ordering. Required order:
1. `<apiVersion>` 2. `<assignments>` 3. `<decisions>` 4. `<description>` 5. `<label>` 6. `<loops>` 7. `<processType>` 8. `<recordCreates>` 9. `<recordUpdates>` 10. `<start>` 11. `<status>` 12. `<variables>`
**Note:** API 60.0+ does NOT use `<bulkSupport>` - bulk processing is automatic.

### Performance
- **Transform Element:** 30-50% faster than loops for field mapping
- **Minimize DML:** Batch operations
- **Get Records with Filters:** Instead of loops + decisions

### Design
- **Meaningful Names:** Variables (camelCase), Elements (PascalCase_With_Underscores)
- **Descriptions:** Add for complex logic
- **Subflows:** Reusable logic

### Security
- **System vs User Mode:** Understand implications
- **Field-Level Security:** Validate permissions for sensitive fields
- **No Hardcoded Data:** Use variables/custom settings

## Tool Usage

**Key Patterns:**
- **Bash:** SF CLI (`sf org list`, `sf project deploy`), validation scripts
- **Read/Write/Edit:** Flow XML manipulation, templates
- **Glob:** Find flows (`**/*.flow-meta.xml`), locate metadata
- **Grep:** Search flows for objects/fields/elements
- **AskUserQuestion:** Gather requirements, confirm activation
- **TodoWrite:** Track 5-phase workflow progress
- **Skill:** Invoke `sf-deployment` for two-step deployment
- **WebFetch:** Fetch SF docs, API reference

## Common Error Patterns

**DML in Loop (CRITICAL):** Collect records in collection variable inside loop → Single DML after loop exits
**Missing Fault Path:** Add fault connector from DML → error handling element → log/display error
**Field Not Found:** Verify field exists in target org, deploy field first if missing
**Insufficient Permissions:** Check profile permissions, consider System mode, verify FLS

## Edge Cases & Troubleshooting

**Large Data (>200 records):** Warn about governor limits, suggest scheduled flow for batching, recommend Transform over loops
**Complex Branching (>5 paths):** Suggest subflows for modularity, document criteria, consider formula fields
**Cross-Object Updates:** Check for circular dependencies, existing flows on related objects, test for recursion
**Production Deployments:** Keep Draft initially, require explicit activation, provide rollback instructions

**Common Issues:**
- Flow not visible after deployment → Check `sf project deploy report`, verify permissions, refresh Setup → Flows
- Validation passes but testing fails → Check Debug Logs, verify test data, test bulk (200+ records)
- Performance issues → Check for DML in loops, use Transform, use Get Records with filters
- Sandbox works, production fails → Check FLS differences, verify dependent metadata deployed, review validation rules, test with production data volumes

## Notes

- **Strict Mode:** All warnings block deployment
- **API 62.0 Required:** Latest Salesforce features
- **Two-Step Deployment:** Validate before deploying
- **Testing Required:** Never deploy to production untested
- **Dependencies:** Requires sf-deployment ≥2.0.0
- **Python Validators:** Optional but recommended

---

## License

MIT License. See [LICENSE](LICENSE) file.
Copyright (c) 2024-2025 Jag Valaiyapathy
