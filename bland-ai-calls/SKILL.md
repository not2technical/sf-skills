---
name: bland-ai-calls
description: >
  Integrates Bland.ai phone call API with Salesforce for automated calls, call logging,
  webhook handling, and voice AI interactions. Use when making outbound calls, handling
  inbound call webhooks, or building voice-enabled workflows.
license: MIT
metadata:
  version: "1.0.0"
  author: "Your Name"
  scoring: "100 points across 5 categories"
---

# bland-ai-calls: Bland.ai Phone Call Integration Expert

Expert integration architect specializing in Bland.ai phone call API integration with Salesforce for voice AI, automated calling, and call logging.

## Core Responsibilities

1. **Named Credential Setup**: Create Named Credentials for Bland.ai API authentication
2. **Callout Patterns**: Generate Apex classes for making outbound calls, retrieving call status, and managing call campaigns
3. **Webhook Handling**: Create REST endpoints to receive Bland.ai webhooks (call started, completed, transcripts)
4. **Call Logging**: Automatically log call data to Salesforce objects (Tasks, custom Call__c objects)
5. **Voice Workflows**: Build integration between Salesforce Flow and Bland.ai for voice-enabled automation
6. **Validation & Scoring**: Score integrations against 5 categories (0-100 points)

## Key Insights

| Insight | Details | Action |
|---------|---------|--------|
| **API Authentication** | Bland.ai uses API key authentication | Store in Named Credential, never hardcode |
| **Async Callouts** | Phone calls are async - use webhooks for status | Always implement webhook handler |
| **Call Data Storage** | Track call recordings, transcripts, and metadata | Create custom Call__c object |
| **Rate Limits** | Bland.ai has rate limits based on plan | Implement retry logic and queueing |

---

## ⚠️ CRITICAL: Bland.ai API Basics

### API Authentication

**Authentication Method**: API Key in Authorization header
```
Authorization: {YOUR_API_KEY}
```

**Base URL**: `https://api.bland.ai/v1`

### Key Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/calls` | POST | Initiate outbound call |
| `/calls/{call_id}` | GET | Get call status and details |
| `/calls/{call_id}/recording` | GET | Get call recording URL |
| `/calls/{call_id}/transcript` | GET | Get call transcript |
| `/calls` | GET | List all calls |

### Webhook Events

Bland.ai sends webhooks for:
- `call.started` - Call initiated
- `call.answered` - Call answered by recipient
- `call.completed` - Call ended
- `transcript.ready` - Call transcript available

---

## Workflow (5-Phase Pattern)

### Phase 1: Requirements Gathering

Use `AskUserQuestion` to gather:

1. **Use Case**: Outbound sales calls, appointment reminders, support callbacks, survey calls
2. **Call Configuration**: Voice selection, language, custom prompts/scripts
3. **Data Requirements**: Which Salesforce objects to log calls against (Lead, Contact, Account, Custom)
4. **Webhook Requirements**: Which call events to track (started, completed, transcript)
5. **Volume**: Expected call volume for rate limit planning

### Phase 2: Salesforce Setup

**Step 1: Create Custom Objects** (optional - can use Tasks)
```
Call__c object with fields:
- Bland_Call_ID__c (External ID)
- Related_To__c (Lookup to Lead/Contact/Account)
- Status__c (Queued, In Progress, Completed, Failed)
- Duration__c (Number - seconds)
- Recording_URL__c (URL)
- Transcript__c (Long Text Area)
- Cost__c (Currency)
- Called_At__c (DateTime)
```

**Step 2: Create Named Credential**
Template: `templates/bland-api-credential.namedCredential-meta.xml`

### Phase 3: Apex Implementation

| Component | Template | Purpose |
|-----------|----------|---------|
| **Callout Service** | `BlandAICalloutService.cls` | Make API calls to Bland.ai |
| **Webhook Handler** | `BlandAIWebhookHandler.cls` | Receive and process webhooks |
| **Call Logger** | `BlandAICallLogger.cls` | Log call data to Salesforce |
| **Queueable Job** | `BlandAICallQueueable.cls` | Queue calls for async processing |

### Phase 4: Integration Patterns

**Pattern 1: Flow-Triggered Outbound Call**
```
Record-Triggered Flow on Lead (Status = "Qualified")
→ Apex Action: BlandAICalloutService.makeCall()
→ Create Call__c record
→ Webhook updates Call__c with status/transcript
```

**Pattern 2: Scheduled Appointment Reminders**
```
Scheduled Flow (Daily at 9 AM)
→ Get today's appointments
→ Bulk Queueable: BlandAICallQueueable
→ Make reminder calls
```

**Pattern 3: Webhook-Driven Call Logging**
```
Bland.ai calls webhook endpoint
→ BlandAIWebhookHandler processes event
→ Update Call__c record
→ Create Task linked to Lead/Contact
```

### Phase 5: Testing & Deployment

**Test Scenarios**:
1. **Positive Test**: Make test call, verify webhook received
2. **Negative Test**: Invalid phone number, API error handling
3. **Bulk Test**: Queue 50+ calls, verify rate limit handling

**Deployment Order**:
1. Custom objects (Call__c)
2. Named Credential
3. Apex classes
4. REST API endpoint (Site/Guest User setup)
5. Flows

---

## Templates

### Named Credential

**Template**: `templates/bland-api-credential.namedCredential-meta.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<NamedCredential xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Bland AI API</label>
    <endpoint>https://api.bland.ai/v1</endpoint>
    <principalType>NamedUser</principalType>
    <protocol>Password</protocol>
    <username>api</username>
    <password>{!$Credential.Password}</password>
</NamedCredential>
```

### Apex Callout Service

**Template**: `templates/BlandAICalloutService.cls`

Quick example:
```apex
public with sharing class BlandAICalloutService {
    
    public class CallRequest {
        public String phone_number;
        public String task;
        public String voice;
        public String language;
        public Map<String, Object> request_data;
    }
    
    public static String makeCall(CallRequest request) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Bland_AI_API/calls');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(request));
        req.setTimeout(120000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return (String)result.get('call_id');
        } else {
            throw new CalloutException('Bland.ai API error: ' + res.getBody());
        }
    }
}
```

---

## Webhook Handler Pattern

**REST Endpoint Setup**:
1. Create Site for public access OR use Platform Events internally
2. Expose Apex REST class for webhook endpoint
3. Configure webhook URL in Bland.ai dashboard

**Template**: `templates/BlandAIWebhookHandler.cls`

```apex
@RestResource(urlMapping='/bland/webhook/*')
global with sharing class BlandAIWebhookHandler {
    
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        String body = req.requestBody.toString();
        
        Map<String, Object> webhook = (Map<String, Object>)JSON.deserializeUntyped(body);
        String eventType = (String)webhook.get('event');
        String callId = (String)webhook.get('call_id');
        
        switch on eventType {
            when 'call.started' {
                handleCallStarted(callId, webhook);
            }
            when 'call.completed' {
                handleCallCompleted(callId, webhook);
            }
            when 'transcript.ready' {
                handleTranscriptReady(callId, webhook);
            }
        }
    }
    
    private static void handleCallCompleted(String callId, Map<String, Object> data) {
        List<Call__c> calls = [SELECT Id FROM Call__c WHERE Bland_Call_ID__c = :callId LIMIT 1];
        if (!calls.isEmpty()) {
            Call__c call = calls[0];
            call.Status__c = 'Completed';
            call.Duration__c = (Decimal)data.get('duration');
            call.Recording_URL__c = (String)data.get('recording_url');
            update call;
        }
    }
}
```

---

## Scoring System (100 Points)

### Category Breakdown

| Category | Points | Evaluation Criteria |
|----------|--------|---------------------|
| **Security** | 25 | Named Credentials used, no hardcoded API keys, webhook signature verification |
| **Error Handling** | 25 | Retry logic, timeout handling, invalid phone number validation, logging |
| **Data Management** | 20 | Call records properly linked, transcript storage, recording URLs tracked |
| **Architecture** | 20 | Async patterns, proper service layer, webhook decoupling |
| **Best Practices** | 10 | Rate limit awareness, bulk processing, proper HTTP methods |

### Scoring Thresholds

```
Score: XX/100 Rating
├─ ⭐⭐⭐⭐⭐ Excellent (90-100): Production-ready
├─ ⭐⭐⭐⭐ Very Good (80-89): Minor improvements suggested
├─ ⭐⭐⭐ Good (70-79): Acceptable with noted improvements
├─ ⭐⭐ Needs Work (60-69): Address issues before deployment
└─ ⭐ Block (<60): CRITICAL issues, do not deploy
```

---

## Common Use Cases

### 1. Outbound Sales Calls
```apex
// Trigger call when Lead is qualified
BlandAICalloutService.CallRequest req = new BlandAICalloutService.CallRequest();
req.phone_number = lead.Phone;
req.task = 'You are a sales representative. Introduce our product and schedule a demo.';
req.voice = 'maya'; // Female voice
req.language = 'en';

String callId = BlandAICalloutService.makeCall(req);

// Create Call record
Call__c call = new Call__c(
    Bland_Call_ID__c = callId,
    Related_To__c = lead.Id,
    Status__c = 'In Progress'
);
insert call;
```

### 2. Appointment Reminders
```apex
// Daily scheduled flow
List<Event> todayEvents = [SELECT Id, WhoId, ActivityDateTime, Location 
                           FROM Event 
                           WHERE ActivityDate = TODAY 
                           AND Phone__c != null];

for (Event evt : todayEvents) {
    BlandAICalloutService.CallRequest req = new BlandAICalloutService.CallRequest();
    req.phone_number = evt.Phone__c;
    req.task = 'Remind customer about appointment at ' + evt.ActivityDateTime.format('h:mm a');
    
    // Queue the call (async)
    System.enqueueJob(new BlandAICallQueueable(req, evt.WhoId));
}
```

### 3. Post-Call Survey
```apex
// After support case is closed
BlandAICalloutService.CallRequest req = new BlandAICalloutService.CallRequest();
req.phone_number = contact.Phone;
req.task = 'Conduct a brief satisfaction survey about case #' + caseNumber;
req.request_data = new Map<String, Object>{
    'case_number' => caseNumber,
    'agent_name' => agentName
};

String callId = BlandAICalloutService.makeCall(req);
```

---

## Anti-Patterns

| Anti-Pattern | Problem | Correct Pattern |
|--------------|---------|-----------------|
| Hardcoded API key | Security vulnerability | Use Named Credential |
| Sync callout in trigger | Uncommitted work error | Use Queueable/Platform Event |
| No webhook handler | Can't track call completion | Always implement webhook endpoint |
| No rate limit handling | API errors at scale | Queue calls with exponential backoff |
| Missing error logs | Can't debug failed calls | Log all errors to custom object |

---

## Cross-Skill Integration

| To Skill | When to Use |
|----------|-------------|
| sf-integration | Named Credential setup, general callout patterns |
| sf-apex | Custom call routing logic, complex data models |
| sf-flow | Voice-enabled automation workflows |
| sf-metadata | Create custom Call objects and fields |
| sf-deploy | Deploy integration to org |

---

## Additional Resources

📚 **Documentation**:
- [Bland.ai API Reference](https://docs.bland.ai/)
- [Webhook Events Guide](docs/webhook-events-guide.md)
- [Call Logging Patterns](docs/call-logging-patterns.md)

📁 **Templates**:
- `templates/BlandAICalloutService.cls` - API callout wrapper
- `templates/BlandAIWebhookHandler.cls` - Webhook receiver
- `templates/BlandAICallLogger.cls` - Call data logging
- `templates/BlandAICallQueueable.cls` - Async call queueing

---

## Notes & Dependencies

- **API Version**: 62.0+ recommended
- **Required Permissions**: API Enabled, External Services access
- **Optional Skills**: sf-integration (Named Credential), sf-apex (Apex code), sf-deploy (deployment)
- **Bland.ai Account**: Required - get API key from https://app.bland.ai/
- **Webhook URL**: Public endpoint required (Salesforce Site or Platform Events)

---

## License

MIT License - See LICENSE file for details.
