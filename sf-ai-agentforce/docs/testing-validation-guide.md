# Testing & Validation Guide

This guide documents tested Agent Script patterns and common deployment issues based on systematic validation testing (December 2025).

## Deployment Methods

There are **two ways** to deploy Agentforce agents:

### 1. Metadata API (GenAiPlannerBundle)

Uses standard `sf project deploy start` with `genAiPlannerBundles/` directory:

```
force-app/main/default/genAiPlannerBundles/
└── My_Agent/
    ├── My_Agent.genAiPlannerBundle           # XML manifest
    └── agentScript/
        └── My_Agent_definition.agent         # Agent Script file
```

**Requirements:**
- `sourceApiVersion: "65.0"` in sfdx-project.json (v65+ required!)
- XML bundle file + Agent Script file in `agentScript/` subfolder

### 2. Agent Builder DX (authoring-bundle)

Uses `sf agent publish authoring-bundle` with `aiAuthoringBundles/` directory:

```
force-app/main/default/aiAuthoringBundles/
└── My_Agent/
    ├── My_Agent.bundle-meta.xml
    └── My_Agent.agent
```

---

## Test Matrix

| Level | Complexity | Features Tested | Status |
|-------|------------|-----------------|--------|
| 1 | Basic | system, config, single topic | ✅ Verified |
| 2 | Variables | mutable, linked, language block | ✅ Verified |
| 3 | Actions | flow:// targets, inputs/outputs | ✅ Verified |
| 4 | Multi-topic | topic routing, conditional transitions | ✅ Verified |
| 5 | External | Flow wrappers for Apex, callbacks | ✅ Verified |
| 6 | Complex | All features combined | ✅ Verified |

---

## Validated Working Syntax

### Minimal Working Agent (Level 1)

```agentscript
system:
    instructions: "You are a helpful assistant."
    messages:
        welcome: "Hello!"
        error: "Sorry, something went wrong."

config:
    developer_name: "Minimal_Agent"
    default_agent_user: "user@example.com"
    agent_label: "Minimal Agent"
    description: "A minimal working agent"

variables:
    EndUserId: linked string
        source: @MessagingSession.MessagingEndUserId
        description: "Messaging End User ID"
    RoutableId: linked string
        source: @MessagingSession.Id
        description: "Messaging Session ID"
    ContactId: linked string
        source: @MessagingEndUser.ContactId
        description: "Contact ID"

language:
    default_locale: "en_US"
    additional_locales: ""
    all_additional_locales: False

start_agent topic_selector:
    label: "Topic Selector"
    description: "Routes to topics"
    reasoning:
        instructions: ->
            | Determine what the user needs.
        actions:
            go_to_help: @utils.transition to @topic.help

topic help:
    label: "Help"
    description: "Provides help"
    reasoning:
        instructions: ->
            | Answer user questions.
```

### Agent with Variables (Level 2)

```agentscript
variables:
    # Linked variables (Salesforce context)
    EndUserId: linked string
        source: @MessagingSession.MessagingEndUserId
        description: "Messaging End User ID"
    RoutableId: linked string
        source: @MessagingSession.Id
        description: "Messaging Session ID"
    ContactId: linked string
        source: @MessagingEndUser.ContactId
        description: "Contact ID"

    # Mutable variables (agent state)
    user_name: mutable string
        description: "User's name"
    preference_count: mutable number
        description: "Number of preferences"
    has_preferences: mutable boolean
        description: "Whether user has preferences"
```

### Agent with Flow Action (Level 3+)

```agentscript
topic account_lookup:
    label: "Account Lookup"
    description: "Looks up account information"

    actions:
        get_account:
            description: "Retrieves account information"
            inputs:
                inp_AccountId: string
                    description: "Salesforce Account ID"
            outputs:
                out_AccountName: string
                    description: "Account name"
                out_IsFound: boolean
                    description: "Whether account was found"
            target: "flow://Get_Account_Info"

    reasoning:
        instructions: ->
            | Ask for the Account ID.
            | Look up the account information.
        actions:
            lookup: @actions.get_account
                with inp_AccountId=...
                set @variables.account_name = @outputs.out_AccountName
```

---

## Common Deployment Errors & Solutions

### Error: "Internal Error, try again later"

**Causes:**
1. Invalid `default_agent_user` - user doesn't exist in org
2. User lacks Agentforce permissions
3. Flow referenced by `flow://` not deployed to org
4. Transient server issue

**Solutions:**
```bash
# Verify user exists
sf data query --query "SELECT Id, Username FROM User WHERE Username = 'user@example.com'" --target-org [alias]

# Deploy flows first
sf project deploy start --metadata Flow --target-org [alias]

# Then publish agent
sf agent publish authoring-bundle --api-name [AgentName] --target-org [alias]
```

### Error: "SyntaxError: Invalid system instructions"

**Cause:** Using pipe `|` syntax in `system.instructions`

**Wrong:**
```agentscript
system:
    instructions:
        | You are helpful.
```

**Correct:**
```agentscript
system:
    instructions: "You are helpful."
```

### Error: "Unexpected 'actions'"

**Cause:** Defining actions at top level instead of inside topics

**Wrong:**
```agentscript
actions:
    my_action:
        target: "flow://MyFlow"

topic my_topic:
    ...
```

**Correct:**
```agentscript
topic my_topic:
    actions:
        my_action:
            target: "flow://MyFlow"
    ...
```

### Error: "ValidationError: default agent user is required"

**Cause:** Missing `default_agent_user` field in config

**Solution:** Add the field:
```agentscript
config:
    developer_name: "My_Agent"
    default_agent_user: "user@example.com"  # Required!
    agent_label: "My Agent"
    description: "Description"
```

### Error: Reserved word conflict

**Cause:** Using reserved words as input/output parameter names

**Reserved Words:**
- `description`
- `inputs`
- `outputs`
- `target`
- `label`
- `source`

**Solution:** Use prefixed alternatives:
```agentscript
# Wrong
inputs:
    description: string

# Correct
inputs:
    case_description: string
```

---

## Deployment Checklist

Before running `sf agent publish authoring-bundle`:

### Files (Metadata API - GenAiPlannerBundle)
- [ ] `.genAiPlannerBundle` XML file exists
- [ ] `.agent` file in `agentScript/` subfolder
- [ ] Both in `force-app/main/default/genAiPlannerBundles/[AgentName]/`
- [ ] `sourceApiVersion: "65.0"` or higher in sfdx-project.json

### Files (Agent Builder DX - authoring-bundle)
- [ ] `.bundle-meta.xml` file exists alongside `.agent`
- [ ] Both in `force-app/main/default/aiAuthoringBundles/[AgentName]/`

### Syntax
- [ ] 4-space indentation (not tabs, not 3 spaces)
- [ ] `developer_name` in config (not `agent_name`)
- [ ] `default_agent_user` set to valid org user
- [ ] `system.instructions` is single quoted string
- [ ] All topics have `label:` and `description:`
- [ ] `instructions: ->` has space before arrow
- [ ] No reserved words as input/output names

### Dependencies
- [ ] Target org has API v64.0+ (v65.0+ for GenAiPlannerBundle deploy)
- [ ] All Flows referenced by `flow://` are deployed
- [ ] All Apex classes referenced by Flows are deployed
- [ ] `default_agent_user` exists in org with Agentforce permissions

### Blocks Present
- [ ] `system:` block (first)
- [ ] `config:` block
- [ ] `variables:` block with linked variables
- [ ] `language:` block
- [ ] `start_agent topic_selector:` entry point
- [ ] At least one additional `topic:`

---

## CLI Commands Quick Reference

### Metadata API Deployment (GenAiPlannerBundle)

```bash
# Deploy agent using standard metadata deploy
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/[AgentName] --target-org [alias]

# Deploy all agent bundles
sf project deploy start --metadata GenAiPlannerBundle --target-org [alias]

# Retrieve agent from org
sf project retrieve start --metadata "GenAiPlannerBundle:[AgentName]" --target-org [alias]
```

### Agent Builder DX (authoring-bundle)

```bash
# Validate before publish (optional)
sf agent validate authoring-bundle --api-name [AgentName] --target-org [alias]

# Publish agent
sf agent publish authoring-bundle --api-name [AgentName] --target-org [alias]

# Open in Agentforce Studio
sf org open agent --api-name [AgentName] --target-org [alias]

# Activate agent
sf agent activate --api-name [AgentName] --target-org [alias]
```

### Common Commands

```bash
# Deploy dependencies first
sf project deploy start --metadata Flow --target-org [alias]
sf project deploy start --metadata ApexClass --target-org [alias]

# List agents in org
sf org list metadata --metadata-type GenAiPlannerBundle --target-org [alias]
```

---

## Testing Best Practices

1. **Start Simple**: Begin with Level 1 (no actions) to verify basic syntax
2. **Deploy Dependencies First**: Flows and Apex must exist in org before agent publish
3. **Validate Incrementally**: Test each feature addition before combining
4. **Check User Permissions**: Ensure `default_agent_user` has Agentforce permissions
5. **Use Explicit Errors**: If publish fails with "Internal Error", check dependencies first

---

*Last Updated: December 2025*
*Based on systematic testing with SF CLI v2.115.15 and API v65.0*
