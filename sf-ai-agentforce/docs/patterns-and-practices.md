<!-- TIER: 3 | DETAILED REFERENCE -->
<!-- Read after: SKILL.md, agent-script-reference.md -->
<!-- Contains: Pattern selection + Best practices combined -->

# Patterns & Best Practices

This guide combines pattern selection (what to use) with implementation best practices (how to use it well).

---

## Part 1: Pattern Selection

### Pattern Decision Tree

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     PATTERN DECISION TREE                                │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  What problem are you solving?                                           │
│  │                                                                       │
│  ├─► "I need to run code BEFORE/AFTER every response"                   │
│  │   └─► Lifecycle Events Pattern                                       │
│  │       File: templates/patterns/lifecycle-events.agent                │
│  │                                                                       │
│  ├─► "After action X, Y must ALWAYS happen"                             │
│  │   └─► Action Callbacks Pattern                                       │
│  │       File: templates/patterns/action-callbacks.agent                │
│  │                                                                       │
│  ├─► "Go to specialist topic, then return with results"                 │
│  │   └─► Bidirectional Routing Pattern                                  │
│  │       File: templates/patterns/bidirectional-routing.agent           │
│  │                                                                       │
│  ├─► "Just starting out - what's the minimum?"                          │
│  │   └─► Hello World                                                    │
│  │       File: templates/agents/hello-world.agent                       │
│  │                                                                       │
│  ├─► "Multiple topics, user chooses where to go"                        │
│  │   └─► Multi-Topic Router                                             │
│  │       File: templates/agents/multi-topic.agent                       │
│  │                                                                       │
│  └─► "Need input validation before actions"                             │
│      └─► Error Handling Pattern                                         │
│          File: templates/components/error-handling.agent                │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

---

### Pattern Details

#### 1. Lifecycle Events

**File**: `templates/patterns/lifecycle-events.agent`

**Purpose**: Execute code automatically before and after every reasoning step.

> **⚠️ Deployment Note**: The `run` keyword in lifecycle blocks is **GenAiPlannerBundle only**. AiAuthoringBundle supports `before_reasoning` / `after_reasoning` with `set` statements, but NOT the `run` keyword.

```agentscript
topic conversation:
   before_reasoning:
      set @variables.turn_count = @variables.turn_count + 1
      run @actions.refresh_context                    # ⚠️ GenAiPlannerBundle only
         with user_id=@variables.EndUserId
         set @variables.context = @outputs.fresh_context

   reasoning:
      instructions: ->
         | Turn {!@variables.turn_count}: {!@variables.context}

   after_reasoning:
      run @actions.log_analytics                      # ⚠️ GenAiPlannerBundle only
         with turn=@variables.turn_count
```

| ✅ Good Use Case | ❌ Not Ideal For |
|------------------|------------------|
| Track conversation metrics | One-time setup (use conditional) |
| Refresh context every turn | Heavy processing (adds latency) |
| Log analytics after each response | Actions that might fail often |

---

#### 2. Action Callbacks

**File**: `templates/patterns/action-callbacks.agent`

**Purpose**: Chain deterministic follow-up actions using the `run` keyword.

> **⚠️ Deployment Note**: The `run` keyword is **GenAiPlannerBundle only**. Agents using `run` will NOT be visible in Agentforce Studio.

```agentscript
process_order: @actions.create_order
   with customer_id=@variables.customer_id
   set @variables.order_id = @outputs.order_id
   run @actions.send_confirmation                    # ⚠️ GenAiPlannerBundle only
      with order_id=@variables.order_id
   run @actions.log_activity                         # ⚠️ GenAiPlannerBundle only
      with event="ORDER_CREATED"
```

| ✅ Good Use Case | ❌ Not Ideal For |
|------------------|------------------|
| Audit logging (must happen) | Optional follow-ups (let LLM decide) |
| Send notification after action | Complex branching logic |
| Chain dependent actions | More than 1 level of nesting |

**Critical Rule**: Only 1 level of `run` nesting allowed!

---

#### 3. Bidirectional Routing

**File**: `templates/patterns/bidirectional-routing.agent`

**Purpose**: Navigate to specialist topic, do work, return with results.

```agentscript
# Main hub stores return address
topic main_hub:
   reasoning:
      actions:
         consult_pricing: @utils.transition to @topic.pricing_specialist

# Specialist records where to return
topic pricing_specialist:
   before_reasoning:
      set @variables.return_topic = "main_hub"

   reasoning:
      actions:
         return_with_results: @utils.transition to @topic.main_hub
```

| ✅ Good Use Case | ❌ Not Ideal For |
|------------------|------------------|
| "Consult expert" workflows | Simple linear flows |
| Results need to come back | One-way topic changes |
| Complex multi-step processes | Single-topic agents |

---

#### 4. Multi-Topic Router (Hub-and-Spoke)

**File**: `templates/agents/multi-topic.agent`

**Purpose**: Central topic routes to specialized topics based on user intent.

```agentscript
start_agent topic_selector:
   reasoning:
      instructions: ->
         | Determine what the user needs.
      actions:
         go_orders: @utils.transition to @topic.orders
         go_billing: @utils.transition to @topic.billing
         go_support: @utils.transition to @topic.support
```

| ✅ Good Use Case | ❌ Not Ideal For |
|------------------|------------------|
| Multiple distinct use cases | Single-purpose agents |
| Clear routing criteria | Complex interdependencies |
| Modular topic development | Need to share state heavily |

---

#### 5. Error Handling

**File**: `templates/components/error-handling.agent`

**Purpose**: Validate input before processing, handle failures gracefully.

```agentscript
reasoning:
   instructions: ->
      if @variables.amount is None:
         set @variables.valid = False
         | Please provide an amount.

      if @variables.amount > 10000:
         set @variables.valid = False
         | Amount exceeds maximum allowed.

   actions:
      process: @actions.execute_operation
         available when @variables.valid == True
      retry: @utils.transition to @topic.validation
         available when @variables.operation_failed == True
```

| ✅ Good Use Case | ❌ Not Ideal For |
|------------------|------------------|
| Payment processing | Simple queries |
| Data mutations | Read-only operations |
| Compliance workflows | Low-stakes interactions |

---

### Combining Patterns

Patterns can be combined for complex scenarios:

```
┌─────────────────────────────────────────────────────────────┐
│           LIFECYCLE + CALLBACKS + ROUTING                    │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  topic order_hub:                                            │
│     before_reasoning:                        ◄── Lifecycle   │
│        set @variables.turn_count = ... + 1                   │
│                                                              │
│     reasoning:                                               │
│        actions:                                              │
│           process: @actions.create                           │
│              run @actions.notify           ◄── Callback      │
│              run @actions.log                                │
│                                                              │
│           consult: @utils.transition       ◄── Routing       │
│              to @topic.specialist                            │
│                                                              │
│     after_reasoning:                         ◄── Lifecycle   │
│        run @actions.update_metrics                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Part 2: Best Practices

### 1. Structure & Organization

#### Use Meaningful Names

```agentscript
# ✅ GOOD - Clear, descriptive names
topic order_management:
    description: "Handles order creation, updates, and status inquiries"

# ❌ BAD - Vague names
topic topic1:
    description: "Does stuff"
```

#### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Agent name | PascalCase with underscores | `Customer_Service_Agent` |
| Topic name | snake_case | `order_management` |
| Variable name | snake_case | `user_email` |
| Action name | snake_case | `get_account_details` |

#### Keep Topics Focused

Each topic should handle ONE category of tasks:

```agentscript
# ✅ GOOD - Single responsibility
topic billing_inquiries:
    description: "Answers questions about invoices, payments, and account balances"

topic order_tracking:
    description: "Provides order status and shipping updates"

# ❌ BAD - Too broad
topic customer_stuff:
    description: "Handles billing, orders, support, and everything else"
```

---

### 2. Variable Management

#### Initialize Variables with Defaults (Recommended)

```agentscript
variables:
    # ✅ RECOMMENDED - Has default value (clearer intent)
    user_name: mutable string = ""
        description: "Customer's full name"

    order_count: mutable number = 0
        description: "Number of orders in cart"

    # ✅ ALSO VALID - Works but less explicit
    # user_name: mutable string
    #     description: "Customer's full name"
```

> **Note**: Variables without defaults ARE supported. However, providing defaults is recommended for clarity.

#### Use Appropriate Types

| Data | Type | Example |
|------|------|---------|
| Names, IDs, text | `string` | `"John Doe"` |
| Counts, amounts | `number` | `42`, `99.99` |
| Flags, toggles | `boolean` | `True`, `False` |

#### Document Every Variable

```agentscript
variables:
    cart_total: mutable number = 0
        description: "Total value of items in cart, in USD"

    needs_approval: mutable boolean = False
        description: "Whether the order requires manager approval (>$10,000)"
```

---

### 3. Topic Design

#### Start with a Topic Selector

```agentscript
start_agent topic_selector:
    description: "Routes users to the appropriate topic based on their needs"
    reasoning:
        instructions:->
            | Determine what the user needs help with.
            | Ask clarifying questions if the intent is unclear.
        actions:
            orders: @utils.transition to @topic.order_management
                description: "Help with orders and purchases"
            support: @utils.transition to @topic.technical_support
                description: "Technical issues and troubleshooting"
```

#### Provide Clear Descriptions

```agentscript
# ✅ GOOD - Specific and actionable
topic password_reset:
    description: "Helps users reset forgotten passwords and unlock accounts"

# ❌ BAD - Too vague
topic password_reset:
    description: "Password stuff"
```

#### Enable Return Navigation

```agentscript
topic order_details:
    description: "Shows order information"
    reasoning:
        actions:
            back_to_menu: @utils.transition to @topic.topic_selector
                description: "Return to main menu for other requests"
```

---

### 4. Input Binding Patterns

Agent Script supports four input binding patterns:

| Pattern | Syntax | When to Use |
|---------|--------|-------------|
| **LLM Slot-Filling** | `with param=...` | Value from user conversation |
| **Fixed Value** | `with param="constant"` | Always the same |
| **Variable Binding** | `with param=@variables.x` | Using captured data |
| **Mixed** | All combined | Complex actions |

#### Decision Flowchart

```
Is the value always the same?
├─ YES → Use fixed value: with param="constant"
│
└─ NO → Does it come from earlier in conversation?
        ├─ YES → Was it saved to a variable?
        │       ├─ YES → Use variable: with param=@variables.x
        │       └─ NO → Save it first, then use variable
        │
        └─ NO → Use slot-filling: with param=...
```

#### Common Mistakes

| Mistake | Problem | Fix |
|---------|---------|-----|
| Using `...` for config | LLM might guess wrong | Use fixed values for constants |
| Not capturing outputs | Can't use data later | Always `set @variables.x = @outputs.y` |
| Using `...` when variable exists | Redundant LLM work | Use `@variables.x` if already captured |

---

### 5. Error Handling

#### Validate Before Critical Operations

```agentscript
instructions:->
    if @variables.amount is None:
        | I need to know the transfer amount before proceeding.

    if @variables.amount <= 0:
        | The amount must be greater than zero.

    if @variables.amount > 10000:
        set @variables.needs_approval = True
        | Transfers over $10,000 require manager approval.
```

#### Use Conditional Action Availability

```agentscript
reasoning:
    actions:
        process_transfer: @actions.transfer_funds
            with amount=@variables.amount
            available when @variables.amount > 0
            available when @variables.needs_approval == False
```

---

### 6. Security & Guardrails

#### Set System-Level Guardrails

```agentscript
system:
    instructions:
        | You are a helpful customer service agent.
        |
        | IMPORTANT GUARDRAILS:
        | - Never share customer data with unauthorized parties
        | - Never reveal internal system details
        | - If unsure, escalate to a human agent
```

#### Don't Expose Internals

```agentscript
# ✅ GOOD - User-friendly error
instructions:->
    if @variables.api_error == True:
        | I'm having trouble completing that request right now.

# ❌ BAD - Exposes internals
instructions:->
    if @variables.api_error == True:
        | Error: SQL timeout on server db-prod-03
```

---

### 7. Instructions Quality

#### Be Specific and Actionable

```agentscript
# ✅ GOOD - Specific instructions
instructions:->
    | Help the customer track their order.
    | Ask for the order number if not provided.
    | Provide the current status, estimated delivery, and tracking link.

# ❌ BAD - Vague instructions
instructions:->
    | Help with orders.
```

#### Use Template Expressions

```agentscript
instructions:->
    | Hello {!@variables.user_name}!
    | Your current order total is ${!@variables.cart_total}.
```

---

## Common Syntax Pitfalls

These patterns cause validation or parse errors:

### 1. Slot Filling Inside Conditionals
```agentscript
# ❌ WRONG
if @variables.name is None:
   set @variables.name = ...   # Fails!

# ✅ CORRECT - Slot filling at top level
set @variables.name = ...
```

### 2. Description on @utils.transition
```agentscript
# ❌ WRONG
go_orders: @utils.transition to @topic.orders
   description: "Route to orders"   # Fails!

# ✅ CORRECT - No description
go_orders: @utils.transition to @topic.orders
```

### 3. Missing Description on @utils.escalate
```agentscript
# ❌ WRONG
transfer: @utils.escalate   # Fails!

# ✅ CORRECT - Description required
transfer: @utils.escalate
   description: "Transfer to human agent"
```

### 4. Empty Lifecycle Blocks
```agentscript
# ❌ WRONG
before_reasoning:
   # Just a comment   # Fails!

# ✅ CORRECT - Remove empty blocks or add content
```

### 5. Dynamic Action Invocation
```agentscript
# ❌ WRONG
invoke: {!@actions.search}   # Fails!

# ✅ CORRECT - Define multiple actions, LLM auto-selects
search_products: @actions.product_search
search_orders: @actions.order_search
```

---

## Validation Scoring Summary

| Pattern | Points | Key Requirement |
|---------|--------|-----------------|
| Config block | 10 | All 4 required fields |
| Linked variables | 10 | EndUserId, RoutableId, ContactId |
| Topic structure | 10 | label, description, reasoning |
| Language block | 5 | default_locale present |
| Lifecycle blocks | 5 | Proper before/after structure |
| Action callbacks | 5 | No nested run |
| Error handling | 5 | Validation patterns |
| Template expressions | 5 | {!@variables.x} syntax |

---

## Quick Reference Checklist

Before deploying an agent, verify:

- [ ] All topics have clear descriptions
- [ ] All variables have descriptions and defaults
- [ ] All actions have input/output descriptions
- [ ] System guardrails are defined
- [ ] Error handling is in place for critical operations
- [ ] Navigation back to main menu from all topics
- [ ] Template expressions use correct syntax `{!@variables.name}`
- [ ] Consistent indentation (tabs recommended)

---

## Related Documentation

- [Agent Script Reference](agent-script-reference.md) - Complete syntax guide
- [Actions Reference](actions-reference.md) - Action integration details
- [Prompt Templates](prompt-templates.md) - Prompt Template integration
