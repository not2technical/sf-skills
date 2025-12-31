---
name: sf-lwc
description: >
  Lightning Web Components development skill with PICKLES architecture methodology,
  component scaffolding, wire service patterns, event handling, Apex integration,
  GraphQL support, and Jest test generation. Build modern Salesforce UIs with
  proper reactivity, accessibility, dark mode compatibility, and performance patterns.
license: MIT
metadata:
  version: "2.0.0"
  author: "Jag Valaiyapathy"
  scoring: "165 points across 8 categories (SLDS 2 + Dark Mode compliant)"
---

# sf-lwc: Lightning Web Components Development

Expert frontend engineer specializing in Lightning Web Components for Salesforce. Generate production-ready LWC components using the **PICKLES Framework** for architecture, with proper data binding, Apex/GraphQL integration, event handling, SLDS 2 styling, and comprehensive Jest tests.

## Core Responsibilities

1. **Component Scaffolding**: Generate complete LWC bundles (JS, HTML, CSS, meta.xml)
2. **PICKLES Architecture**: Apply structured design methodology for robust components
3. **Wire Service Patterns**: Implement @wire decorators for data fetching (Apex & GraphQL)
4. **Apex/GraphQL Integration**: Connect LWC to backend with @AuraEnabled and GraphQL
5. **Event Handling**: Component communication (CustomEvent, LMS, pubsub)
6. **Lifecycle Management**: Proper use of connectedCallback, renderedCallback, etc.
7. **Jest Testing**: Generate comprehensive unit tests with advanced patterns
8. **Accessibility**: WCAG compliance with ARIA attributes, focus management
9. **Dark Mode**: SLDS 2 compliant styling with global styling hooks
10. **Performance**: Lazy loading, virtual scrolling, debouncing, efficient rendering

---

## PICKLES Framework (Architecture Methodology)

The **PICKLES Framework** provides a structured approach to designing robust Lightning Web Components. Apply each principle during component design and implementation.

```
┌─────────────────────────────────────────────────────────────────────┐
│                     🥒 PICKLES FRAMEWORK                            │
├─────────────────────────────────────────────────────────────────────┤
│  P → Prototype    │  Validate ideas with wireframes & mock data    │
│  I → Integrate    │  Choose data source (LDS, Apex, GraphQL, API)  │
│  C → Composition  │  Structure component hierarchy & communication │
│  K → Kinetics     │  Handle user interactions & event flow         │
│  L → Libraries    │  Leverage platform APIs & base components      │
│  E → Execution    │  Optimize performance & lifecycle hooks        │
│  S → Security     │  Enforce permissions, FLS, and data protection │
└─────────────────────────────────────────────────────────────────────┘
```

### P - Prototype

**Purpose**: Validate ideas early before full implementation.

| Action | Description |
|--------|-------------|
| Wireframe | Create high-level component sketches |
| Mock Data | Use sample data to test functionality |
| Stakeholder Review | Gather feedback before development |
| Separation of Concerns | Break into smaller functional pieces |

```javascript
// Mock data pattern for prototyping
const MOCK_ACCOUNTS = [
    { Id: '001MOCK001', Name: 'Acme Corp', Industry: 'Technology' },
    { Id: '001MOCK002', Name: 'Global Inc', Industry: 'Finance' }
];

export default class AccountPrototype extends LightningElement {
    accounts = MOCK_ACCOUNTS; // Replace with wire/Apex later
}
```

### I - Integrate

**Purpose**: Determine how components interact with data systems.

**Data Source Decision Tree**:

| Scenario | Recommended Approach |
|----------|---------------------|
| Single record by ID | Lightning Data Service (`getRecord`) |
| Simple record CRUD | `lightning-record-form` / `lightning-record-edit-form` |
| Complex queries | Apex with `@AuraEnabled(cacheable=true)` |
| Related records | GraphQL wire adapter |
| Real-time updates | Platform Events / Streaming API |
| External data | Named Credentials + Apex callout |

**Integration Checklist**:
- [ ] Implement error handling with clear user notifications
- [ ] Add loading spinners to prevent duplicate requests
- [ ] Use LDS for single-object operations (minimizes DML)
- [ ] Respect FLS and CRUD in Apex implementations
- [ ] Store `wiredResult` for `refreshApex()` support

### C - Composition

**Purpose**: Structure how LWCs nest and communicate.

**Communication Patterns**:

| Pattern | Direction | Use Case |
|---------|-----------|----------|
| `@api` properties | Parent → Child | Pass data down |
| Custom Events | Child → Parent | Bubble actions up |
| Lightning Message Service | Any → Any | Cross-DOM communication |
| Pub/Sub | Sibling → Sibling | Same page, no hierarchy |

**Best Practices**:
- Maintain shallow component hierarchies (max 3-4 levels)
- Single responsibility per component
- Clean up subscriptions in `disconnectedCallback()`
- Use custom events purposefully, not for every interaction

```javascript
// Parent-managed composition pattern
// parent.js
handleChildEvent(event) {
    this.selectedId = event.detail.id;
    // Update child via @api
    this.template.querySelector('c-child').selectedId = this.selectedId;
}
```

### K - Kinetics

**Purpose**: Manage user interaction and event responsiveness.

**Key Patterns**:

| Pattern | Implementation |
|---------|----------------|
| Debounce | 300ms delay for search inputs |
| Disable during submit | Prevent duplicate clicks |
| Keyboard navigation | Enter/Space triggers actions |
| Event bubbling | Control with `bubbles` and `composed` |

```javascript
// Debounce pattern for search
delayTimeout;

handleSearchChange(event) {
    const searchTerm = event.target.value;
    clearTimeout(this.delayTimeout);
    this.delayTimeout = setTimeout(() => {
        this.dispatchEvent(new CustomEvent('search', {
            detail: { searchTerm }
        }));
    }, 300);
}
```

### L - Libraries

**Purpose**: Leverage Salesforce-provided and platform tools.

**Recommended Platform Features**:

| API/Module | Use Case |
|------------|----------|
| `lightning/navigation` | Page/record navigation |
| `lightning/uiRecordApi` | LDS operations (getRecord, updateRecord) |
| `lightning/platformShowToastEvent` | User notifications |
| `lightning/modal` | Native modal dialogs |
| Base Components | Pre-built UI (button, input, datatable) |
| `lightning/refresh` | Dispatch refresh events |

**Avoid reinventing** what base components already provide!

### E - Execution

**Purpose**: Optimize performance and resource efficiency.

**Lifecycle Hook Guidance**:

| Hook | When to Use | Avoid |
|------|-------------|-------|
| `constructor()` | Initialize properties | DOM access (not ready) |
| `connectedCallback()` | Subscribe to events, fetch data | Heavy processing |
| `renderedCallback()` | DOM-dependent logic | Infinite loops, property changes |
| `disconnectedCallback()` | Cleanup subscriptions/listeners | Async operations |

**Performance Checklist**:
- [ ] Lazy load with `if:true` / `lwc:if`
- [ ] Use `key` directive in iterations
- [ ] Cache computed values in getters
- [ ] Avoid property updates that trigger re-renders
- [ ] Use browser DevTools Performance tab

### S - Security

**Purpose**: Enforce access control and data protection.

**Security Checklist**:

| Requirement | Implementation |
|-------------|----------------|
| Field-Level Security | Use `WITH SECURITY_ENFORCED` in SOQL |
| CRUD Permissions | Check before DML operations |
| Custom Permissions | Conditionally render features |
| Input Validation | Sanitize before processing |
| Sensitive Data | Never expose in client-side code |

```apex
// Secure Apex pattern
@AuraEnabled(cacheable=true)
public static List<Account> getAccounts(String searchTerm) {
    String searchKey = '%' + String.escapeSingleQuotes(searchTerm) + '%';
    return [
        SELECT Id, Name, Industry
        FROM Account
        WHERE Name LIKE :searchKey
        WITH SECURITY_ENFORCED
        LIMIT 50
    ];
}
```

---

## Component Patterns

### 1. Basic Data Display (Wire Service)

```javascript
// accountCard.js
import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import INDUSTRY_FIELD from '@salesforce/schema/Account.Industry';

const FIELDS = [NAME_FIELD, INDUSTRY_FIELD];

export default class AccountCard extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    account;

    get name() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    get industry() {
        return getFieldValue(this.account.data, INDUSTRY_FIELD);
    }

    get isLoading() {
        return !this.account.data && !this.account.error;
    }
}
```

### 2. Wire Service with Apex

```javascript
// contactList.js
import { LightningElement, api, wire } from 'lwc';
import getContacts from '@salesforce/apex/ContactController.getContacts';
import { refreshApex } from '@salesforce/apex';

export default class ContactList extends LightningElement {
    @api recordId;
    wiredContactsResult;

    @wire(getContacts, { accountId: '$recordId' })
    wiredContacts(result) {
        this.wiredContactsResult = result; // Store for refreshApex
        const { error, data } = result;
        if (data) {
            this.contacts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }

    async handleRefresh() {
        await refreshApex(this.wiredContactsResult);
    }
}
```

### 3. GraphQL Patterns (Queries & Mutations)

> **Module Note**: `lightning/graphql` supersedes `lightning/uiGraphQLApi` and provides newer features like mutations, optional fields, and dynamic query construction.

#### 3a. GraphQL Query (Wire Adapter)

```javascript
// graphqlContacts.js
import { LightningElement, wire } from 'lwc';
import { gql, graphql } from 'lightning/graphql';

const CONTACTS_QUERY = gql`
    query ContactsQuery($first: Int, $after: String) {
        uiapi {
            query {
                Contact(first: $first, after: $after) {
                    edges {
                        node {
                            Id
                            Name { value }
                            Email { value }
                            Account {
                                Name { value }
                            }
                        }
                        cursor
                    }
                    pageInfo {
                        hasNextPage
                        endCursor
                    }
                }
            }
        }
    }
`;

export default class GraphqlContacts extends LightningElement {
    contacts;
    pageInfo;
    error;

    @wire(graphql, {
        query: CONTACTS_QUERY,
        variables: '$queryVariables'
    })
    wiredContacts({ data, error }) {
        if (data) {
            const result = data.uiapi.query.Contact;
            this.contacts = result.edges.map(edge => ({
                id: edge.node.Id,
                name: edge.node.Name.value,
                email: edge.node.Email?.value,
                accountName: edge.node.Account?.Name?.value
            }));
            this.pageInfo = result.pageInfo;
        } else if (error) {
            this.error = error;
        }
    }

    get queryVariables() {
        return { first: 10, after: this._cursor };
    }

    loadMore() {
        if (this.pageInfo?.hasNextPage) {
            this._cursor = this.pageInfo.endCursor;
        }
    }
}
```

#### 3b. GraphQL Mutations (Spring '26 - GA in API 66.0)

Mutations allow create, update, and delete operations via GraphQL. Use `executeMutation` for imperative operations.

```javascript
// graphqlAccountMutation.js
import { LightningElement, track } from 'lwc';
import { gql, executeMutation } from 'lightning/graphql';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Create mutation
const CREATE_ACCOUNT = gql`
    mutation CreateAccount($name: String!, $industry: String) {
        uiapi {
            AccountCreate(input: {
                Account: {
                    Name: $name
                    Industry: $industry
                }
            }) {
                Record {
                    Id
                    Name { value }
                    Industry { value }
                }
            }
        }
    }
`;

// Update mutation
const UPDATE_ACCOUNT = gql`
    mutation UpdateAccount($id: ID!, $name: String!) {
        uiapi {
            AccountUpdate(input: {
                Account: {
                    Id: $id
                    Name: $name
                }
            }) {
                Record {
                    Id
                    Name { value }
                }
            }
        }
    }
`;

// Delete mutation
const DELETE_ACCOUNT = gql`
    mutation DeleteAccount($id: ID!) {
        uiapi {
            AccountDelete(input: { Account: { Id: $id } }) {
                Id
            }
        }
    }
`;

export default class GraphqlAccountMutation extends LightningElement {
    @track accountName = '';
    @track industry = '';
    isLoading = false;

    handleNameChange(event) {
        this.accountName = event.target.value;
    }

    handleIndustryChange(event) {
        this.industry = event.target.value;
    }

    async handleCreate() {
        if (!this.accountName) return;

        this.isLoading = true;
        try {
            const result = await executeMutation(CREATE_ACCOUNT, {
                variables: {
                    name: this.accountName,
                    industry: this.industry || null
                }
            });

            const newRecord = result.data.uiapi.AccountCreate.Record;
            this.showToast('Success', `Account "${newRecord.Name.value}" created`, 'success');
            this.resetForm();
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }

    async handleUpdate(accountId, newName) {
        try {
            const result = await executeMutation(UPDATE_ACCOUNT, {
                variables: { id: accountId, name: newName }
            });
            this.showToast('Success', 'Account updated', 'success');
            return result.data.uiapi.AccountUpdate.Record;
        } catch (error) {
            this.handleError(error);
        }
    }

    async handleDelete(accountId) {
        try {
            await executeMutation(DELETE_ACCOUNT, {
                variables: { id: accountId }
            });
            this.showToast('Success', 'Account deleted', 'success');
        } catch (error) {
            this.handleError(error);
        }
    }

    handleError(error) {
        const message = error.graphQLErrors
            ? error.graphQLErrors.map(e => e.message).join(', ')
            : error.message || 'Unknown error';
        this.showToast('Error', message, 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    resetForm() {
        this.accountName = '';
        this.industry = '';
    }
}
```

#### GraphQL Mutation Operations

| Operation | Mutation Type | Notes |
|-----------|---------------|-------|
| **Create** | `{Object}Create` | Can request fields from newly created record |
| **Update** | `{Object}Update` | Cannot query fields in same request |
| **Delete** | `{Object}Delete` | Cannot query fields in same request |

#### allOrNone Parameter

Control transaction behavior with `allOrNone` (default: `true`):

```javascript
const BATCH_CREATE = gql`
    mutation BatchCreate($allOrNone: Boolean = true) {
        uiapi(allOrNone: $allOrNone) {
            acc1: AccountCreate(input: { Account: { Name: "Account 1" } }) {
                Record { Id }
            }
            acc2: AccountCreate(input: { Account: { Name: "Account 2" } }) {
                Record { Id }
            }
        }
    }
`;

// If allOrNone=true: All rollback if any fails
// If allOrNone=false: Only failed operations rollback
```

### 4. Modal Component Pattern (Composable)

Based on [James Simone's composable modal pattern](https://www.jamessimone.net/blog/joys-of-apex/lwc-composable-modal/).

```javascript
// composableModal.js
import { LightningElement, api } from 'lwc';

const OUTER_MODAL_CLASS = 'outerModalContent';

export default class ComposableModal extends LightningElement {
    @api modalHeader;
    @api modalTagline;
    @api modalSaveHandler;

    _isOpen = false;
    _focusableElements = [];

    @api
    toggleModal() {
        this._isOpen = !this._isOpen;
        if (this._isOpen) {
            this._focusableElements = [...this.querySelectorAll('.focusable')];
            this._focusFirstElement();
            window.addEventListener('keyup', this._handleKeyUp);
        } else {
            window.removeEventListener('keyup', this._handleKeyUp);
        }
    }

    get modalAriaHidden() {
        return !this._isOpen;
    }

    get modalClass() {
        return this._isOpen
            ? 'slds-modal slds-visible slds-fade-in-open'
            : 'slds-modal slds-hidden';
    }

    get backdropClass() {
        return this._isOpen ? 'slds-backdrop slds-backdrop_open' : 'slds-backdrop';
    }

    _handleKeyUp = (event) => {
        if (event.code === 'Escape') {
            this.toggleModal();
        } else if (event.code === 'Tab') {
            this._handleTabNavigation(event);
        }
    }

    _handleTabNavigation(event) {
        // Focus trap logic - keep focus within modal
        const activeEl = this.template.activeElement;
        const lastIndex = this._focusableElements.length - 1;
        const currentIndex = this._focusableElements.indexOf(activeEl);

        if (event.shiftKey && currentIndex === 0) {
            this._focusableElements[lastIndex]?.focus();
        } else if (!event.shiftKey && currentIndex === lastIndex) {
            this._focusFirstElement();
        }
    }

    _focusFirstElement() {
        if (this._focusableElements.length > 0) {
            this._focusableElements[0].focus();
        }
    }

    handleBackdropClick(event) {
        if (event.target.classList.contains(OUTER_MODAL_CLASS)) {
            this.toggleModal();
        }
    }

    handleSave() {
        if (this.modalSaveHandler) {
            this.modalSaveHandler();
        }
        this.toggleModal();
    }

    disconnectedCallback() {
        window.removeEventListener('keyup', this._handleKeyUp);
    }
}
```

```html
<!-- composableModal.html -->
<template>
    <!-- Backdrop -->
    <div class={backdropClass}></div>

    <!-- Modal -->
    <div class={modalClass}
         role="dialog"
         aria-modal="true"
         aria-hidden={modalAriaHidden}
         aria-labelledby="modal-heading">

        <div class="slds-modal__container outerModalContent"
             onclick={handleBackdropClick}>

            <div class="slds-modal__content slds-p-around_medium">
                <!-- Header -->
                <template lwc:if={modalHeader}>
                    <h2 id="modal-heading" class="slds-text-heading_medium">
                        {modalHeader}
                    </h2>
                </template>
                <template lwc:if={modalTagline}>
                    <p class="slds-m-top_x-small slds-text-color_weak">
                        {modalTagline}
                    </p>
                </template>

                <!-- Slotted Content -->
                <div class="slds-m-top_medium">
                    <slot name="modalContent"></slot>
                </div>

                <!-- Footer -->
                <div class="slds-m-top_medium slds-text-align_right">
                    <lightning-button
                        label="Cancel"
                        onclick={toggleModal}
                        class="slds-m-right_x-small focusable">
                    </lightning-button>
                    <lightning-button
                        variant="brand"
                        label="Save"
                        onclick={handleSave}
                        class="focusable">
                    </lightning-button>
                </div>
            </div>
        </div>
    </div>

    <!-- Hidden background content -->
    <div aria-hidden={_isOpen}>
        <slot name="body"></slot>
    </div>
</template>
```

### 5. Record Picker Pattern (NEW)

```javascript
// recordPicker.js
import { LightningElement, api } from 'lwc';

export default class RecordPicker extends LightningElement {
    @api label = 'Select Record';
    @api objectApiName = 'Account';
    @api placeholder = 'Search...';
    @api required = false;
    @api multiSelect = false;

    _selectedIds = [];

    @api
    get value() {
        return this.multiSelect ? this._selectedIds : this._selectedIds[0];
    }

    set value(val) {
        this._selectedIds = Array.isArray(val) ? val : val ? [val] : [];
    }

    handleChange(event) {
        const recordId = event.detail.recordId;
        if (this.multiSelect) {
            if (!this._selectedIds.includes(recordId)) {
                this._selectedIds = [...this._selectedIds, recordId];
            }
        } else {
            this._selectedIds = recordId ? [recordId] : [];
        }

        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                recordId: this.value,
                recordIds: this._selectedIds
            }
        }));
    }

    handleRemove(event) {
        const idToRemove = event.target.dataset.id;
        this._selectedIds = this._selectedIds.filter(id => id !== idToRemove);
        this.dispatchEvent(new CustomEvent('select', {
            detail: { recordIds: this._selectedIds }
        }));
    }
}
```

```html
<!-- recordPicker.html -->
<template>
    <lightning-record-picker
        label={label}
        placeholder={placeholder}
        object-api-name={objectApiName}
        onchange={handleChange}
        required={required}>
    </lightning-record-picker>

    <template lwc:if={multiSelect}>
        <div class="slds-m-top_x-small">
            <template for:each={_selectedIds} for:item="id">
                <lightning-pill
                    key={id}
                    label={id}
                    data-id={id}
                    onremove={handleRemove}>
                </lightning-pill>
            </template>
        </div>
    </template>
</template>
```

### 6. Workspace API Pattern (Console Apps)

```javascript
// workspaceTabManager.js
import { LightningElement, wire } from 'lwc';
import { IsConsoleNavigation, getFocusedTabInfo, openTab, closeTab,
         setTabLabel, setTabIcon, refreshTab } from 'lightning/platformWorkspaceApi';

export default class WorkspaceTabManager extends LightningElement {
    @wire(IsConsoleNavigation) isConsole;

    async openRecordTab(recordId, objectApiName) {
        if (!this.isConsole) return;

        await openTab({
            recordId,
            focus: true,
            icon: `standard:${objectApiName.toLowerCase()}`,
            label: 'Loading...'
        });
    }

    async openSubtab(parentTabId, recordId) {
        if (!this.isConsole) return;

        await openTab({
            parentTabId,
            recordId,
            focus: true
        });
    }

    async getCurrentTabInfo() {
        if (!this.isConsole) return null;
        return await getFocusedTabInfo();
    }

    async updateTabLabel(tabId, label) {
        if (!this.isConsole) return;
        await setTabLabel(tabId, label);
    }

    async updateTabIcon(tabId, iconName) {
        if (!this.isConsole) return;
        await setTabIcon(tabId, iconName);
    }

    async refreshCurrentTab() {
        if (!this.isConsole) return;
        const tabInfo = await getFocusedTabInfo();
        await refreshTab(tabInfo.tabId);
    }

    async closeCurrentTab() {
        if (!this.isConsole) return;
        const tabInfo = await getFocusedTabInfo();
        await closeTab(tabInfo.tabId);
    }
}
```

### 7. Parent-Child Communication

```javascript
// parent.js
import { LightningElement } from 'lwc';

export default class Parent extends LightningElement {
    selectedAccountId;

    handleAccountSelected(event) {
        this.selectedAccountId = event.detail.accountId;
    }
}
```

```html
<!-- parent.html -->
<template>
    <c-account-list onaccountselected={handleAccountSelected}></c-account-list>
    <template lwc:if={selectedAccountId}>
        <c-account-detail account-id={selectedAccountId}></c-account-detail>
    </template>
</template>
```

### 8. Lightning Message Service (Cross-DOM)

```javascript
// publisher.js
import { LightningElement, wire } from 'lwc';
import { publish, MessageContext } from 'lightning/messageService';
import ACCOUNT_SELECTED_CHANNEL from '@salesforce/messageChannel/AccountSelected__c';

export default class Publisher extends LightningElement {
    @wire(MessageContext) messageContext;

    handleSelect(event) {
        const payload = { accountId: event.target.dataset.id };
        publish(this.messageContext, ACCOUNT_SELECTED_CHANNEL, payload);
    }
}
```

```javascript
// subscriber.js
import { LightningElement, wire } from 'lwc';
import { subscribe, unsubscribe, MessageContext,
         APPLICATION_SCOPE } from 'lightning/messageService';
import ACCOUNT_SELECTED_CHANNEL from '@salesforce/messageChannel/AccountSelected__c';

export default class Subscriber extends LightningElement {
    subscription = null;
    accountId;

    @wire(MessageContext) messageContext;

    connectedCallback() {
        this.subscribeToChannel();
    }

    disconnectedCallback() {
        this.unsubscribeFromChannel();
    }

    subscribeToChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                ACCOUNT_SELECTED_CHANNEL,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeFromChannel() {
        unsubscribe(this.subscription);
        this.subscription = null;
    }

    handleMessage(message) {
        this.accountId = message.accountId;
    }
}
```

### 9. Navigation

```javascript
// navigator.js
import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class Navigator extends NavigationMixin(LightningElement) {

    navigateToRecord(recordId, objectApiName = 'Account') {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName: 'view'
            }
        });
    }

    navigateToList(objectApiName, filterName = 'Recent') {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName,
                actionName: 'list'
            },
            state: { filterName }
        });
    }

    navigateToNewRecord(objectApiName, defaultValues = {}) {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: Object.entries(defaultValues)
                    .map(([k, v]) => `${k}=${encodeURIComponent(v)}`)
                    .join(',')
            }
        });
    }
}
```

---

## SLDS 2 Validation (165-Point Scoring)

The sf-lwc skill includes automated SLDS 2 validation that ensures dark mode compatibility, accessibility, and modern styling.

| Category | Points | Key Checks |
|----------|--------|------------|
| **SLDS Class Usage** | 25 | Valid class names, proper `slds-*` utilities |
| **Accessibility** | 25 | ARIA labels, roles, alt-text, keyboard navigation |
| **Dark Mode Readiness** | 25 | No hardcoded colors, CSS variables only **(NEW)** |
| **SLDS Migration** | 20 | No deprecated SLDS 1 patterns/tokens |
| **Styling Hooks** | 20 | Proper `--slds-g-*` variable usage |
| **Component Structure** | 15 | Uses `lightning-*` base components |
| **Performance** | 10 | Efficient selectors, no `!important` |
| **PICKLES Compliance** | 25 | Architecture methodology adherence (optional) |

**Scoring Thresholds**:
```
⭐⭐⭐⭐⭐ 150-165 pts → Production-ready, full SLDS 2 + Dark Mode
⭐⭐⭐⭐   125-149 pts → Good component, minor styling issues
⭐⭐⭐     100-124 pts → Functional, needs SLDS cleanup
⭐⭐       75-99 pts  → Basic functionality, SLDS issues
⭐         <75 pts   → Needs significant work
```

---

## Dark Mode Readiness (NEW)

Dark mode is exclusive to SLDS 2 themes. Components must use global styling hooks to support light/dark theme switching.

### Dark Mode Checklist

- [ ] **No hardcoded hex colors** (`#FFFFFF`, `#333333`)
- [ ] **No hardcoded RGB/RGBA values**
- [ ] **All colors use CSS variables** (`var(--slds-g-color-*)`)
- [ ] **Fallback values provided** for SLDS 1 compatibility
- [ ] **No inline color styles** in HTML templates
- [ ] **Icons use SLDS utility icons** (auto-adjust for dark mode)

### SLDS 1 → SLDS 2 Migration

**Before (SLDS 1 - Deprecated)**:
```css
.my-card {
    background-color: #ffffff;
    color: #333333;
    border: 1px solid #dddddd;
    border-radius: 4px;
}
```

**After (SLDS 2 - Dark Mode Ready)**:
```css
.my-card {
    background-color: var(--slds-g-color-surface-container-1, #ffffff);
    color: var(--slds-g-color-on-surface, #181818);
    border: 1px solid var(--slds-g-color-border-1, #c9c9c9);
    border-radius: var(--slds-g-radius-border-2, 0.25rem);
}
```

### Global Styling Hooks Reference

| Category | SLDS 2 Variable | Purpose |
|----------|-----------------|---------|
| **Surface** | `--slds-g-color-surface-1` to `-4` | Background colors |
| **Container** | `--slds-g-color-surface-container-1` to `-3` | Card/section backgrounds |
| **Text** | `--slds-g-color-on-surface` | Primary text |
| **Text Secondary** | `--slds-g-color-on-surface-1`, `-2` | Muted text |
| **Border** | `--slds-g-color-border-1`, `-2` | Borders |
| **Brand** | `--slds-g-color-brand-1`, `-2` | Brand accent |
| **Error** | `--slds-g-color-error-1` | Error states |
| **Success** | `--slds-g-color-success-1` | Success states |
| **Warning** | `--slds-g-color-warning-1` | Warning states |
| **Spacing** | `--slds-g-spacing-0` to `-12` | Margins/padding |
| **Font Size** | `--slds-g-font-size-1` to `-10` | Typography |
| **Radius** | `--slds-g-radius-border-1` to `-4` | Border radius |

**Important**: Component-level hooks (`--slds-c-*`) are NOT supported in SLDS 2 yet. Use only global hooks (`--slds-g-*`).

### SLDS Validator/Linter Commands

```bash
# Install SLDS Linter
npm install -g @salesforce-ux/slds-linter

# Run validation
slds-linter lint force-app/main/default/lwc/myComponent

# Auto-fix issues
slds-linter lint --fix force-app/main/default/lwc/myComponent
```

---

## Advanced Jest Testing Patterns

Based on [James Simone's advanced testing patterns](https://www.jamessimone.net/blog/joys-of-apex/advanced-lwc-jest-testing/).

### Render Cycle Helper

```javascript
// testUtils.js
export const runRenderingLifecycle = async (reasons = ['render']) => {
    while (reasons.length > 0) {
        await Promise.resolve(reasons.pop());
    }
};

// Usage in tests
it('updates after property change', async () => {
    const element = createElement('c-example', { is: Example });
    document.body.appendChild(element);

    element.greeting = 'new value';
    await runRenderingLifecycle(['property change', 'render']);

    expect(element.shadowRoot.querySelector('div').textContent).toBe('new value');
});
```

### Proxy Unboxing (LWS Compatibility)

```javascript
// Lightning Web Security proxifies objects - unbox them for assertions
const unboxedData = JSON.parse(JSON.stringify(component.data));
expect(unboxedData).toEqual(expectedData);
```

### DOM Cleanup Pattern

```javascript
describe('c-my-component', () => {
    afterEach(() => {
        // Clean up DOM to prevent state bleed
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });
});
```

### ResizeObserver Polyfill

```javascript
// jest.setup.js
if (!window.ResizeObserver) {
    window.ResizeObserver = class ResizeObserver {
        constructor(callback) {
            this.callback = callback;
        }
        observe() {}
        unobserve() {}
        disconnect() {}
    };
}
```

### Complete Test Template

```javascript
import { createElement } from 'lwc';
import MyComponent from 'c/myComponent';
import getData from '@salesforce/apex/MyController.getData';

jest.mock('@salesforce/apex/MyController.getData', () => ({
    default: jest.fn()
}), { virtual: true });

const MOCK_DATA = [
    { Id: '001xx000001', Name: 'Test 1' },
    { Id: '001xx000002', Name: 'Test 2' }
];

const runRenderingLifecycle = async (reasons = ['render']) => {
    while (reasons.length > 0) {
        await Promise.resolve(reasons.pop());
    }
};

describe('c-my-component', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('displays data when loaded successfully', async () => {
        getData.mockResolvedValue(MOCK_DATA);

        const element = createElement('c-my-component', { is: MyComponent });
        document.body.appendChild(element);

        await runRenderingLifecycle(['wire data fetch', 'render']);

        const items = element.shadowRoot.querySelectorAll('.item');
        expect(items.length).toBe(2);
    });

    it('displays error when fetch fails', async () => {
        getData.mockRejectedValue(new Error('Failed'));

        const element = createElement('c-my-component', { is: MyComponent });
        document.body.appendChild(element);

        await runRenderingLifecycle(['wire error', 'render']);

        const error = element.shadowRoot.querySelector('.error');
        expect(error).not.toBeNull();
    });

    it('fires event when item clicked', async () => {
        getData.mockResolvedValue(MOCK_DATA);
        const handler = jest.fn();

        const element = createElement('c-my-component', { is: MyComponent });
        element.addEventListener('itemselected', handler);
        document.body.appendChild(element);

        await runRenderingLifecycle();

        const item = element.shadowRoot.querySelector('.item');
        item.click();

        expect(handler).toHaveBeenCalled();
        expect(handler.mock.calls[0][0].detail.id).toBe('001xx000001');
    });
});
```

---

## Apex Controller Patterns

### Cacheable Methods (for @wire)

```apex
public with sharing class LwcController {

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccounts(String searchTerm) {
        String searchKey = '%' + String.escapeSingleQuotes(searchTerm) + '%';
        return [
            SELECT Id, Name, Industry, AnnualRevenue
            FROM Account
            WHERE Name LIKE :searchKey
            WITH SECURITY_ENFORCED
            ORDER BY Name
            LIMIT 50
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<PicklistOption> getIndustryOptions() {
        List<PicklistOption> options = new List<PicklistOption>();
        Schema.DescribeFieldResult fieldResult =
            Account.Industry.getDescribe();
        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                options.add(new PicklistOption(entry.getLabel(), entry.getValue()));
            }
        }
        return options;
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;

        public PicklistOption(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}
```

### Non-Cacheable Methods (for DML)

```apex
@AuraEnabled
public static Account createAccount(String accountJson) {
    Account acc = (Account) JSON.deserialize(accountJson, Account.class);

    // FLS check
    SObjectAccessDecision decision = Security.stripInaccessible(
        AccessType.CREATABLE,
        new List<Account>{ acc }
    );

    insert decision.getRecords();
    return (Account) decision.getRecords()[0];
}

@AuraEnabled
public static void deleteAccounts(List<Id> accountIds) {
    if (accountIds == null || accountIds.isEmpty()) {
        throw new AuraHandledException('No accounts to delete');
    }

    List<Account> toDelete = [
        SELECT Id FROM Account
        WHERE Id IN :accountIds
        WITH SECURITY_ENFORCED
    ];

    delete toDelete;
}
```

---

## Metadata Configuration

### meta.xml Targets

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Account Dashboard</masterLabel>
    <description>SLDS 2 compliant account dashboard with dark mode support</description>
    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
        <target>lightning__HomePage</target>
        <target>lightning__FlowScreen</target>
        <target>lightningCommunity__Page</target>
    </targets>
    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
            </objects>
            <property name="title" type="String" default="Dashboard"/>
            <property name="maxRecords" type="Integer" default="10"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

---

## CLI Commands

| Command | Purpose |
|---------|---------|
| `sf lightning generate component --type lwc` | Create new LWC |
| `sf lightning lwc test run` | Run Jest tests |
| `sf lightning lwc test run --watch` | Watch mode |
| `sf project deploy start -m LightningComponentBundle` | Deploy LWC |

### Generate New Component

```bash
sf lightning generate component \
  --name accountDashboard \
  --type lwc \
  --output-dir force-app/main/default/lwc
```

### Run Tests

```bash
# All tests
sf lightning lwc test run

# Specific component
sf lightning lwc test run --spec force-app/main/default/lwc/accountList/__tests__

# With coverage
sf lightning lwc test run -- --coverage
```

---

## Accessibility Checklist

| Requirement | Implementation |
|-------------|----------------|
| **Labels** | `label` on inputs, `aria-label` on icons |
| **Keyboard** | Enter/Space triggers, Tab navigation |
| **Focus** | Visible indicator, logical order |
| **Live Regions** | `aria-live="polite"` for dynamic content |
| **Contrast** | 4.5:1 minimum for text |

```html
<!-- Accessible dynamic content -->
<div aria-live="polite" class="slds-assistive-text">
    {statusMessage}
</div>
```

---

## Flow Screen Integration

LWC components can be embedded in Flow Screens for custom UI experiences within guided processes.

### Key Concepts

| Mechanism | Direction | Purpose |
|-----------|-----------|---------|
| `@api` with `role="inputOnly"` | Flow → LWC | Pass context data |
| `FlowAttributeChangeEvent` | LWC → Flow | Return user selections |
| `FlowNavigationFinishEvent` | LWC → Flow | Programmatic Next/Back/Finish |
| `availableActions` | Flow → LWC | Check available navigation |

### Quick Example

```javascript
import { FlowAttributeChangeEvent, FlowNavigationFinishEvent } from 'lightning/flowSupport';

@api recordId;           // Input from Flow
@api selectedRecordId;   // Output to Flow
@api availableActions = [];

handleSelect(event) {
    this.selectedRecordId = event.detail.id;
    // CRITICAL: Notify Flow of the change
    this.dispatchEvent(new FlowAttributeChangeEvent(
        'selectedRecordId',
        this.selectedRecordId
    ));
}

handleNext() {
    if (this.availableActions.includes('NEXT')) {
        this.dispatchEvent(new FlowNavigationFinishEvent('NEXT'));
    }
}
```

### Template & Documentation

| Resource | Location |
|----------|----------|
| Flow Screen Component Template | `templates/flow-screen-component/` |
| Flow Integration Guide | [docs/flow-integration-guide.md](docs/flow-integration-guide.md) |
| Triangle Architecture | [docs/triangle-pattern.md](docs/triangle-pattern.md) |

---

## TypeScript Support (Spring '26 - GA in API 66.0)

Lightning Web Components now support TypeScript with the `@salesforce/lightning-types` package. TypeScript provides type safety, better IDE support, and compile-time error detection.

### Setup

```bash
# Install TypeScript dependencies
npm install @salesforce/lightning-types @salesforce/i18n lwc typescript

# TypeScript version requirement: 5.4.5+
```

### tsconfig.json Configuration

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "types": ["@salesforce/lightning-types"],
    "lib": ["ES2022", "DOM"],
    "experimentalDecorators": true,
    "useDefineForClassFields": false
  },
  "include": ["force-app/**/*.ts"],
  "exclude": ["node_modules", "**/__tests__/**"]
}
```

### TypeScript Component Pattern

```typescript
// accountList.ts
import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';

// Define interfaces for type safety
interface AccountRecord {
    Id: string;
    Name: string;
    Industry?: string;
    AnnualRevenue?: number;
}

interface WireResult<T> {
    data?: T;
    error?: Error;
}

export default class AccountList extends LightningElement {
    // Typed @api properties
    @api recordId: string | undefined;

    @api
    get maxRecords(): number {
        return this._maxRecords;
    }
    set maxRecords(value: number) {
        this._maxRecords = value;
    }

    // Typed @track properties
    @track private _accounts: AccountRecord[] = [];
    @track private _error: string | null = null;

    private _maxRecords: number = 10;
    private _wiredResult: WireResult<AccountRecord[]> | undefined;

    // Typed wire service
    @wire(getAccounts, { maxRecords: '$maxRecords' })
    wiredAccounts(result: WireResult<AccountRecord[]>): void {
        this._wiredResult = result;
        const { data, error } = result;

        if (data) {
            this._accounts = data;
            this._error = null;
        } else if (error) {
            this._error = this.reduceErrors(error);
            this._accounts = [];
        }
    }

    // Typed getters
    get accounts(): AccountRecord[] {
        return this._accounts;
    }

    get hasAccounts(): boolean {
        return this._accounts.length > 0;
    }

    // Typed event handlers
    handleSelect(event: CustomEvent<{ accountId: string }>): void {
        const { accountId } = event.detail;
        this.dispatchEvent(new CustomEvent('accountselected', {
            detail: { accountId },
            bubbles: true,
            composed: true
        }));
    }

    // Typed utility methods
    private reduceErrors(error: Error | Error[]): string {
        const errors = Array.isArray(error) ? error : [error];
        return errors
            .filter((e): e is Error => e !== null)
            .map(e => e.message || 'Unknown error')
            .join('; ');
    }
}
```

### TypeScript Jest Test Pattern

```typescript
// accountList.test.ts
import { createElement, LightningElement } from 'lwc';
import AccountList from 'c/accountList';
import getAccounts from '@salesforce/apex/AccountController.getAccounts';

// Type definitions for tests
interface AccountRecord {
    Id: string;
    Name: string;
    Industry?: string;
}

// Mock Apex
jest.mock(
    '@salesforce/apex/AccountController.getAccounts',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const MOCK_ACCOUNTS: AccountRecord[] = [
    { Id: '001xx000003DGQ', Name: 'Acme Corp', Industry: 'Technology' }
];

describe('c-account-list', () => {
    let element: LightningElement & { maxRecords?: number };

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('displays accounts after data loads', async () => {
        (getAccounts as jest.Mock).mockResolvedValue(MOCK_ACCOUNTS);

        element = createElement('c-account-list', { is: AccountList });
        document.body.appendChild(element);

        await Promise.resolve();

        const items = element.shadowRoot?.querySelectorAll('.slds-item');
        expect(items?.length).toBe(MOCK_ACCOUNTS.length);
    });
});
```

### Key TypeScript Features

| Feature | LWC Support | Notes |
|---------|-------------|-------|
| **Interface definitions** | ✅ | Define shapes for records, events, props |
| **Typed @api properties** | ✅ | Getter/setter patterns with types |
| **Typed @wire results** | ✅ | Generic `WireResult<T>` pattern |
| **Typed event handlers** | ✅ | `CustomEvent<T>` for event detail typing |
| **Private class fields** | ✅ | Use `private` keyword |
| **Strict null checking** | ✅ | Optional chaining `?.` and nullish coalescing `??` |

### Template

| Resource | Location |
|----------|----------|
| TypeScript Component Template | `templates/typescript-component/` |

> **Note**: TypeScript files must be compiled to JavaScript before deployment. The Salesforce platform does not store TypeScript source files.

---

## LWC in Dashboards (Beta - Spring '26)

> **⚠️ Beta Feature**: This feature requires enablement via Salesforce Customer Support and may change before GA.

Lightning Web Components can now be embedded as custom dashboard widgets, enabling rich, interactive visualizations in Lightning Dashboards.

### Enabling LWC in Dashboards

1. Contact Salesforce Customer Support to enable "LWC in Dashboards" for your org
2. Configure component for `lightning__Dashboard` target
3. Define widget properties for dashboard configuration

### Dashboard Component Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Pipeline Dashboard Widget</masterLabel>
    <description>Custom pipeline visualization for dashboards</description>

    <targets>
        <target>lightning__Dashboard</target>
        <target>lightning__AppPage</target>
    </targets>

    <targetConfigs>
        <targetConfig targets="lightning__Dashboard">
            <property
                name="metricType"
                type="String"
                label="Metric Type"
                datasource="apex://DashboardMetricProvider"
                description="Select the metric to display"/>
            <property
                name="refreshInterval"
                type="Integer"
                label="Refresh Interval (seconds)"
                default="30"
                min="10"
                max="300"/>
            <property
                name="chartColor"
                type="Color"
                label="Chart Color"
                default="#0176D3"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Dashboard Widget Best Practices

| Guideline | Implementation |
|-----------|----------------|
| **Responsive sizing** | Use relative units, handle container resize |
| **Loading states** | Show spinners during data fetch |
| **Error handling** | Display user-friendly error messages |
| **Performance** | Cache data, minimize re-renders |
| **Refresh support** | Implement `@api refresh()` method |

---

## Agentforce Discoverability (Spring '26 - GA in API 66.0)

Make your Lightning Web Components discoverable by Agentforce agents by adding the `lightning__agentforce` capability to your component metadata.

### Agentforce-Enabled Component Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<LightningComponentBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>66.0</apiVersion>
    <isExposed>true</isExposed>
    <masterLabel>Account Dashboard</masterLabel>
    <description>Displays account metrics and KPIs for sales analysis</description>

    <!-- Agentforce Discoverability -->
    <capabilities>
        <capability>lightning__agentforce</capability>
    </capabilities>

    <targets>
        <target>lightning__RecordPage</target>
        <target>lightning__AppPage</target>
    </targets>

    <targetConfigs>
        <targetConfig targets="lightning__RecordPage">
            <objects>
                <object>Account</object>
            </objects>
            <!-- Descriptive properties help agents understand usage -->
            <property
                name="recordId"
                type="String"
                label="Record ID"
                description="The ID of the Account record to display metrics for"/>
            <property
                name="timeRange"
                type="String"
                label="Time Range"
                datasource="Last 7 Days,Last 30 Days,Last Quarter,Last Year"
                default="Last 30 Days"
                description="The time period for calculating metrics"/>
        </targetConfig>
    </targetConfigs>
</LightningComponentBundle>
```

### Agentforce Discoverability Checklist

| Requirement | Implementation |
|-------------|----------------|
| **Capability declaration** | Add `<capability>lightning__agentforce</capability>` |
| **Clear masterLabel** | Human-readable component name |
| **Detailed description** | Explain what the component does |
| **Property descriptions** | Describe each property's purpose |
| **Semantic naming** | Use descriptive property names |

---

## Cross-Skill Integration

| Skill | Use Case |
|-------|----------|
| sf-apex | Generate Apex controllers (`@AuraEnabled`, `@InvocableMethod`) |
| sf-flow | Embed components in Flow Screens, pass data to/from Flow |
| sf-testing | Generate Jest tests |
| sf-deploy | Deploy components |
| sf-metadata | Create message channels |

---

## Dependencies

**Required**:
- Target org with LWC support (API 45.0+)
- `sf` CLI authenticated

**For Testing**:
- Node.js 18+
- Jest (`@salesforce/sfdx-lwc-jest`)

**For SLDS Validation**:
- `@salesforce-ux/slds-linter` (optional)

Install: `/plugin install github:Jaganpro/sf-skills/sf-lwc`

---

## References

- [PICKLES Framework (Salesforce Ben)](https://www.salesforceben.com/the-ideal-framework-for-architecting-salesforce-lightning-web-components/)
- [LWC Recipes (GitHub)](https://github.com/trailheadapps/lwc-recipes)
- [SLDS 2 Transition Guide](https://www.lightningdesignsystem.com/2e1ef8501/p/8184ad-transition-to-slds-2)
- [SLDS Styling Hooks](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-css-custom-properties.html)
- [James Simone - Composable Modal](https://www.jamessimone.net/blog/joys-of-apex/lwc-composable-modal/)
- [James Simone - Advanced Jest Testing](https://www.jamessimone.net/blog/joys-of-apex/advanced-lwc-jest-testing/)

---

## License

MIT License. See [LICENSE](LICENSE) file.
Copyright (c) 2024-2025 Jag Valaiyapathy
