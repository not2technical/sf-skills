---
name: sf-apex
description: >
  Generates and reviews Salesforce Apex code with 2025 best practices and 150-point
  scoring. Use when writing Apex classes, triggers, test classes, batch jobs, or
  reviewing existing Apex code for bulkification, security, and SOLID principles.
license: MIT
metadata:
  version: "1.0.0"
  author: "Jag Valaiyapathy"
  scoring: "150 points across 8 categories"
---

# sf-apex: Salesforce Apex Code Generation and Review

Expert Apex developer specializing in clean code, SOLID principles, and 2025 best practices. Generate production-ready, secure, performant, and maintainable Apex code.

## Core Responsibilities

1. **Code Generation**: Create Apex classes, triggers (TAF), tests, async jobs from requirements
2. **Code Review**: Analyze existing Apex for best practices violations with actionable fixes
3. **Validation & Scoring**: Score code against 8 categories (0-150 points)
4. **Deployment Integration**: Validate and deploy via sf-deploy skill

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

Use **AskUserQuestion** to gather:
- Class type (Trigger, Service, Selector, Batch, Queueable, Test, Controller)
- Primary purpose (one sentence)
- Target object(s)
- Test requirements

**Then**:
1. Check existing code: `Glob: **/*.cls`, `Glob: **/*.trigger`
2. Check for existing Trigger Actions Framework setup: `Glob: **/*TriggerAction*.cls`
3. Create TodoWrite tasks

### Phase 2: Design & Template Selection

**Select template**:
| Class Type | Template |
|------------|----------|
| Trigger | `templates/trigger.trigger` |
| Trigger Action | `templates/trigger-action.cls` |
| Service | `templates/service.cls` |
| Selector | `templates/selector.cls` |
| Batch | `templates/batch.cls` |
| Queueable | `templates/queueable.cls` |
| Test | `templates/test-class.cls` |
| Test Data Factory | `templates/test-data-factory.cls` |
| Standard Class | `templates/apex-class.cls` |

**Template Path Resolution** (try in order):
1. **Marketplace folder**: `~/.claude/plugins/marketplaces/sf-skills/sf-apex/templates/[template]`
2. **Project folder**: `[project-root]/sf-apex/templates/[template]`

**Example**: `Read: ~/.claude/plugins/marketplaces/sf-skills/sf-apex/templates/apex-class.cls`

### Phase 3: Code Generation/Review

**For Generation**:
1. Create class file in `force-app/main/default/classes/`
2. Apply naming conventions (see [docs/naming-conventions.md](docs/naming-conventions.md))
3. Include ApexDoc comments
4. Create corresponding test class

**For Review**:
1. Read existing code
2. Run validation against best practices
3. Generate improvement report with specific fixes

**Run Validation**:
```
Score: XX/150 ⭐⭐⭐⭐ Rating
├─ Bulkification: XX/25
├─ Security: XX/25
├─ Testing: XX/25
├─ Architecture: XX/20
├─ Clean Code: XX/20
├─ Error Handling: XX/15
├─ Performance: XX/10
└─ Documentation: XX/10
```

### ⛔ GENERATION GUARDRAILS (MANDATORY)

**BEFORE generating ANY Apex code, Claude MUST verify no anti-patterns are introduced.**

If ANY of these patterns would be generated, **STOP and ask the user**:
> "I noticed [pattern]. This will cause [problem]. Should I:
> A) Refactor to use [correct pattern]
> B) Proceed anyway (not recommended)"

| Anti-Pattern | Detection | Impact | Correct Pattern |
|--------------|-----------|--------|-----------------|
| SOQL inside loop | `for(...) { [SELECT...] }` | Governor limit failure (100 SOQL) | Query BEFORE loop, use `Map<Id, SObject>` for lookups |
| DML inside loop | `for(...) { insert/update }` | Governor limit failure (150 DML) | Collect in `List<>`, single DML after loop |
| Missing sharing | `class X {` without keyword | Security violation | Always use `with sharing` or `inherited sharing` |
| Hardcoded ID | 15/18-char ID literal | Deployment failure | Use Custom Metadata, Custom Labels, or queries |
| Empty catch | `catch(e) { }` | Silent failures | Log with `System.debug()` or rethrow |
| String concatenation in SOQL | `'SELECT...WHERE Name = \'' + var` | SOQL injection | Use bind variables `:variableName` |
| Test without assertions | `@IsTest` method with no `Assert.*` | False positive tests | Use `Assert.areEqual()` with message |

**DO NOT generate anti-patterns even if explicitly requested.** Ask user to confirm the exception with documented justification.

### Phase 4: Deployment

**Step 1: Validation**
```
Skill(skill="sf-deploy", args="Deploy classes at force-app/main/default/classes/ to [target-org] with --dry-run")
```

**Step 2: Deploy** (only if validation succeeds)
```
Skill(skill="sf-deploy", args="Proceed with actual deployment to [target-org]")
```

### Phase 5: Documentation & Testing Guidance

**Completion Summary**:
```
✓ Apex Code Complete: [ClassName]
  Type: [type] | API: 62.0
  Location: force-app/main/default/classes/[ClassName].cls
  Test Class: [TestClassName].cls
  Validation: PASSED (Score: XX/150)

Next Steps: Run tests, verify behavior, monitor logs
```

---

## Best Practices (150-Point Scoring)

| Category | Points | Key Rules |
|----------|--------|-----------|
| **Bulkification** | 25 | NO SOQL/DML in loops; collect first, operate after; test 251+ records |
| **Security** | 25 | `WITH USER_MODE`; bind variables; `with sharing`; `Security.stripInaccessible()` |
| **Testing** | 25 | 90%+ coverage; Assert class; positive/negative/bulk tests; Test Data Factory |
| **Architecture** | 20 | TAF triggers; Service/Domain/Selector layers; SOLID; dependency injection |
| **Clean Code** | 20 | Meaningful names; self-documenting; no `!= false`; single responsibility |
| **Error Handling** | 15 | Specific before generic catch; no empty catch; custom business exceptions |
| **Performance** | 10 | Monitor with `Limits`; cache expensive ops; scope variables; async for heavy |
| **Documentation** | 10 | ApexDoc on classes/methods; meaningful params |

**Thresholds**: ✅ 90+ (Deploy) | ⚠️ 67-89 (Review) | ❌ <67 (Block - fix required)

---

## Trigger Actions Framework (TAF)

### ⚠️ CRITICAL PREREQUISITES

**Before using TAF patterns, the target org MUST have:**

1. **Trigger Actions Framework Package Installed**
   - GitHub: https://github.com/mitchspano/apex-trigger-actions-framework
   - Install via: `sf package install --package 04tKZ000000gUEFYA2 --target-org [alias] --wait 10`
   - Or use unlocked package from repository

2. **Custom Metadata Type Records Created**
   - TAF triggers do NOTHING without `Trigger_Action__mdt` records!
   - Each trigger action class needs a corresponding CMT record

**If TAF is NOT installed, use the Standard Trigger Pattern instead (see below).**

---

### TAF Pattern (Requires Package)

All triggers MUST use the Trigger Actions Framework pattern:

**Trigger** (one per object):
```apex
trigger AccountTrigger on Account (
    before insert, after insert,
    before update, after update,
    before delete, after delete, after undelete
) {
    new MetadataTriggerHandler().run();
}
```

**Action Class** (one per behavior):
```apex
public class TA_Account_SetDefaults implements TriggerAction.BeforeInsert {
    public void beforeInsert(List<Account> newList) {
        for (Account acc : newList) {
            if (acc.Industry == null) {
                acc.Industry = 'Other';
            }
        }
    }
}
```

**Multi-Interface Action Class** (BeforeInsert + BeforeUpdate):
```apex
public class TA_Lead_CalculateScore implements TriggerAction.BeforeInsert, TriggerAction.BeforeUpdate {

    // Called on new record creation
    public void beforeInsert(List<Lead> newList) {
        calculateScores(newList);
    }

    // Called on record updates
    public void beforeUpdate(List<Lead> newList, List<Lead> oldList) {
        // Only recalculate if scoring fields changed
        List<Lead> leadsToScore = new List<Lead>();
        Map<Id, Lead> oldMap = new Map<Id, Lead>(oldList);

        for (Lead newLead : newList) {
            Lead oldLead = oldMap.get(newLead.Id);
            if (scoringFieldsChanged(newLead, oldLead)) {
                leadsToScore.add(newLead);
            }
        }

        if (!leadsToScore.isEmpty()) {
            calculateScores(leadsToScore);
        }
    }

    private void calculateScores(List<Lead> leads) {
        // Scoring logic here
    }

    private Boolean scoringFieldsChanged(Lead newLead, Lead oldLead) {
        return newLead.Industry != oldLead.Industry ||
               newLead.NumberOfEmployees != oldLead.NumberOfEmployees;
    }
}
```

### ⚠️ REQUIRED: Custom Metadata Type Records

**TAF triggers will NOT execute without `Trigger_Action__mdt` records!**

For each trigger action class, create a Custom Metadata record:

| Field | Value | Description |
|-------|-------|-------------|
| Label | TA Lead Calculate Score | Human-readable name |
| Trigger_Action_Name__c | TA_Lead_CalculateScore | Apex class name |
| Object__c | Lead | sObject API name |
| Context__c | Before Insert | Trigger context |
| Order__c | 1 | Execution order (lower = first) |
| Active__c | true | Enable/disable without deploy |

**Example Custom Metadata XML** (`Trigger_Action.TA_Lead_CalculateScore_BI.md-meta.xml`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>TA Lead Calculate Score - Before Insert</label>
    <protected>false</protected>
    <values>
        <field>Apex_Class_Name__c</field>
        <value xsi:type="xsd:string">TA_Lead_CalculateScore</value>
    </values>
    <values>
        <field>Object__c</field>
        <value xsi:type="xsd:string">Lead</value>
    </values>
    <values>
        <field>Order__c</field>
        <value xsi:type="xsd:double">1.0</value>
    </values>
    <values>
        <field>Bypass_Execution__c</field>
        <value xsi:type="xsd:boolean">false</value>
    </values>
</CustomMetadata>
```

**NOTE**: Create separate CMT records for each context (Before Insert, Before Update, etc.)

---

### Standard Trigger Pattern (No Package Required)

**Use this when TAF package is NOT installed in the target org:**

```apex
trigger LeadTrigger on Lead (before insert, before update) {

    LeadScoringService scoringService = new LeadScoringService();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            scoringService.calculateScores(Trigger.new);
        }
        else if (Trigger.isUpdate) {
            scoringService.recalculateIfChanged(Trigger.new, Trigger.oldMap);
        }
    }
}
```

**Pros**: No external dependencies, works in any org
**Cons**: Less maintainable for complex triggers, no declarative control

See `docs/trigger-actions-framework.md` (in sf-apex folder) for full patterns.

---

## Async Decision Matrix

| Scenario | Use |
|----------|-----|
| Simple callout, fire-and-forget | `@future(callout=true)` |
| Complex logic, needs chaining | `Queueable` |
| Process millions of records | `Batch Apex` |
| Scheduled/recurring job | `Schedulable` |
| Post-queueable cleanup | `Queueable Finalizer` |

---

## Code Review Red Flags

| Anti-Pattern | Fix |
|--------------|-----|
| SOQL/DML in loop | Collect in loop, operate after |
| `without sharing` everywhere | Use `with sharing` by default |
| No trigger bypass flag | Add Boolean Custom Setting |
| Multiple triggers on object | Single trigger + TAF |
| SOQL without WHERE/LIMIT | Always filter and limit |
| `System.debug()` everywhere | Control via Custom Metadata |
| `isEmpty()` before DML | Remove - empty list = 0 DMLs |
| Generic Exception only | Catch specific types first |
| Hard-coded Record IDs | Query dynamically |
| No Test Data Factory | Implement Factory pattern |

---

## Modern Apex Features (API 62.0)

- **Null coalescing**: `value ?? defaultValue`
- **Safe navigation**: `record?.Field__c`
- **User mode**: `WITH USER_MODE` in SOQL
- **Assert class**: `Assert.areEqual()`, `Assert.isTrue()`

**Breaking Change (API 62.0)**: Cannot modify Set while iterating - throws `System.FinalException`

---

## Reference

**Docs**: `docs/` folder (in sf-apex):
| Document | Description |
|----------|-------------|
| `best-practices.md` | Bulkification, collections, null safety, guard clauses, DML performance |
| `code-smells-guide.md` | Code smells detection and refactoring patterns (**NEW**) |
| `design-patterns.md` | 12 patterns including Domain Class, Abstraction Levels (**NEW patterns**) |
| `trigger-actions-framework.md` | TAF setup and patterns |
| `security-guide.md` | CRUD/FLS, sharing, SOQL injection prevention |
| `testing-guide.md` | Test patterns, mocking, bulk testing |
| `naming-conventions.md` | Variable, method, class naming rules |
| `solid-principles.md` | SOLID principles for Apex |
| `code-review-checklist.md` | 150-point scoring criteria |

- **Path**: `~/.claude/plugins/marketplaces/sf-skills/sf-apex/docs/`

> 💡 New content from *"Clean Apex Code"* (Pablo Gonzalez) integrated into best-practices.md, design-patterns.md, and the new code-smells-guide.md.

---

## Flow Integration (@InvocableMethod)

Apex classes can be called from Flow using `@InvocableMethod`. This pattern enables complex business logic, DML, callouts, and integrations from declarative automation.

### Quick Reference

| Annotation | Purpose |
|------------|---------|
| `@InvocableMethod` | Makes method callable from Flow |
| `@InvocableVariable` | Exposes properties in Request/Response wrappers |

### Template

Use `templates/invocable-method.cls` for the complete pattern with Request/Response wrappers.

### Example

```apex
public with sharing class RecordProcessor {

    @InvocableMethod(label='Process Record' category='Custom')
    public static List<Response> execute(List<Request> requests) {
        List<Response> responses = new List<Response>();
        for (Request req : requests) {
            Response res = new Response();
            res.isSuccess = true;
            res.processedId = req.recordId;
            responses.add(res);
        }
        return responses;
    }

    public class Request {
        @InvocableVariable(label='Record ID' required=true)
        public Id recordId;
    }

    public class Response {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
        @InvocableVariable(label='Processed ID')
        public Id processedId;
    }
}
```

**See Also**:
- [docs/flow-integration.md](docs/flow-integration.md) - Complete @InvocableMethod guide
- [docs/triangle-pattern.md](docs/triangle-pattern.md) - Flow-LWC-Apex triangle (Apex perspective)

---

## Cross-Skill Integration

| Skill | When to Use | Example |
|-------|-------------|---------|
| sf-metadata | Discover object/fields before coding | `Skill(skill="sf-metadata")` → "Describe Invoice__c" |
| sf-data | Generate 251+ test records after deploy | `Skill(skill="sf-data")` → "Create 251 Accounts for bulk testing" |
| sf-deploy | Deploy to org - see Phase 4 | `Skill(skill="sf-deploy", args="Deploy to [org]")` |
| sf-flow | Create Flow that calls your Apex | See @InvocableMethod section above |
| sf-lwc | Create LWC that calls your Apex | `@AuraEnabled` controller patterns |

## Dependencies

**All optional**: sf-deploy, sf-metadata, sf-data. Install: `/plugin install github:Jaganpro/sf-skills/[skill-name]`

## Common Exception Types Reference

When writing test classes, use these specific exception types:

| Exception Type | When to Use | Example |
|----------------|-------------|---------|
| `DmlException` | Insert/update/delete failures | `Assert.isTrue(e.getMessage().contains('FIELD_CUSTOM_VALIDATION'))` |
| `QueryException` | SOQL query failures | Malformed query, no rows for assignment |
| `NullPointerException` | Null reference access | Accessing field on null object |
| `ListException` | List operation failures | Index out of bounds |
| `MathException` | Mathematical errors | Division by zero |
| `TypeException` | Type conversion failures | Invalid type casting |
| `LimitException` | Governor limit exceeded | Too many SOQL queries, DML statements |
| `CalloutException` | HTTP callout failures | Timeout, invalid endpoint |
| `JSONException` | JSON parsing failures | Malformed JSON |
| `InvalidParameterValueException` | Invalid method parameters | Bad input values |

**Test Example:**
```apex
@IsTest
static void testShouldThrowExceptionForMissingRequiredField() {
    try {
        // Code that should throw
        insert new Account(); // Missing Name
        Assert.fail('Expected DmlException was not thrown');
    } catch (DmlException e) {
        Assert.isTrue(e.getMessage().contains('REQUIRED_FIELD_MISSING'),
            'Expected REQUIRED_FIELD_MISSING but got: ' + e.getMessage());
    }
}
```

---

## Cross-Skill Dependency Checklist

**Before deploying Apex code, verify these prerequisites:**

| Prerequisite | Check Command | Required For |
|--------------|---------------|--------------|
| TAF Package | `sf package installed list --target-org alias` | TAF trigger pattern |
| Custom Fields | `sf sobject describe --sobject Lead --target-org alias` | Field references in code |
| Permission Sets | `sf org list metadata --metadata-type PermissionSet` | FLS for custom fields |
| Trigger_Action__mdt | Check Setup → Custom Metadata Types | TAF trigger execution |

**Common Deployment Order:**
```
1. sf-metadata: Create custom fields
2. sf-metadata: Create Permission Sets
3. sf-deployment: Deploy fields + Permission Sets
4. sf-apex: Deploy Apex classes/triggers
5. sf-data: Create test data
```

---

## LSP-Based Validation (Auto-Fix Loop)

The sf-apex skill includes Language Server Protocol (LSP) integration for real-time syntax validation. This enables Claude to automatically detect and fix Apex syntax errors during code authoring.

### How It Works

1. **PostToolUse Hook**: After every Write/Edit operation on `.cls` or `.trigger` files, the LSP hook validates syntax
2. **Apex Language Server**: Uses Salesforce's official `apex-jorje-lsp.jar` (from VS Code extension)
3. **Auto-Fix Loop**: If errors are found, Claude receives diagnostics and auto-fixes them (max 3 attempts)
4. **Two-Layer Validation**:
   - **LSP Validation**: Fast syntax checking (~500ms)
   - **150-Point Validation**: Semantic analysis for best practices

### Prerequisites

For LSP validation to work, users must have:

| Requirement | How to Install |
|-------------|----------------|
| **VS Code Salesforce Extension Pack** | VS Code → Extensions → "Salesforce Extension Pack" |
| **Java 11+ (Adoptium recommended)** | https://adoptium.net/temurin/releases/ |

### Validation Flow

```
User writes Apex code → Write/Edit tool executes
                              ↓
                    ┌─────────────────────────┐
                    │   LSP Validation (fast) │
                    │   Syntax errors only    │
                    └─────────────────────────┘
                              ↓
                    ┌─────────────────────────┐
                    │  150-Point Validation   │
                    │  Semantic best practices│
                    └─────────────────────────┘
                              ↓
                    Claude sees any errors and auto-fixes
```

### Sample LSP Error Output

```
============================================================
🔍 APEX LSP VALIDATION RESULTS
   File: force-app/main/default/classes/MyClass.cls
   Attempt: 1/3
============================================================

Found 1 error(s), 0 warning(s)

ISSUES TO FIX:
----------------------------------------
❌ [ERROR] line 4: Missing ';' at 'System.debug' (source: apex)

ACTION REQUIRED:
Please fix the Apex syntax errors above and try again.
(Attempt 1/3)
============================================================
```

### Graceful Degradation

If LSP is unavailable (no VS Code extension or Java), validation silently skips - the skill continues to work with only 150-point semantic validation.

---

## Notes

- **API Version**: 62.0 required
- **TAF Optional**: Prefer TAF when package is installed, use standard trigger pattern as fallback
- **Scoring**: Block deployment if score < 67
- **LSP**: Optional but recommended for real-time syntax validation

---

## License

MIT License. See [LICENSE](LICENSE) file.
Copyright (c) 2024-2025 Jag Valaiyapathy
