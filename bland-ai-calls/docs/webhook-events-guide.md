# Bland.ai Webhook Events Guide

Complete reference for handling Bland.ai webhook events in Salesforce.

## Overview

Bland.ai sends webhook notifications for various call lifecycle events. Configure webhook URLs either:
- **Per-call**: Include `webhook` parameter in CallRequest
- **Global**: Configure in Bland.ai dashboard (Settings → Webhooks)

## Webhook Endpoint Setup

### Option 1: Salesforce Site (Public Endpoint)

**Steps:**
1. Create a Salesforce Site (Setup → Sites)
2. Enable public access for `BlandAIWebhookHandler` class
3. Get site URL: `https://your-domain.my.salesforce-sites.com`
4. Full endpoint: `https://your-domain.my.salesforce-sites.com/services/apexrest/bland/webhook`

**Security Considerations:**
- Enable webhook signature verification (coming in v1.1)
- Use IP allowlisting in Site settings
- Monitor for suspicious activity

### Option 2: Platform Events (Internal Processing)

For internal processing without public endpoints:
1. Use a third-party webhook relay service (e.g., Zapier, Make)
2. Relay forwards webhook to Platform Event
3. Salesforce processes via Platform Event trigger

## Event Types

### 1. call.started

**Triggered**: When Bland.ai initiates the call

**Payload Example**:
```json
{
  "event": "call.started",
  "call_id": "c-abc123xyz",
  "phone_number": "+15555551234",
  "timestamp": "2026-01-12T10:30:00Z"
}
```

**Salesforce Action**:
- Update Call__c record: `Status__c = 'In Progress'`
- Set `Started_At__c = NOW()`

**Use Case**: Track when calls begin, update dashboards in real-time

---

### 2. call.answered

**Triggered**: When recipient answers the call

**Payload Example**:
```json
{
  "event": "call.answered",
  "call_id": "c-abc123xyz",
  "phone_number": "+15555551234",
  "answered_at": "2026-01-12T10:30:15Z"
}
```

**Salesforce Action**:
- Update Call__c record: `Status__c = 'Answered'`
- Set `Answered_At__c`

**Use Case**: Distinguish between answered vs. no-answer calls for reporting

---

### 3. call.completed

**Triggered**: When call ends (answered or not)

**Payload Example**:
```json
{
  "event": "call.completed",
  "call_id": "c-abc123xyz",
  "phone_number": "+15555551234",
  "duration": 125,
  "cost": 0.15,
  "answered": true,
  "recording_url": "https://storage.bland.ai/recordings/abc123.mp3",
  "ended_at": "2026-01-12T10:32:20Z"
}
```

**Salesforce Action**:
- Update Call__c record:
  - `Status__c = 'Completed'` or `'No Answer'`
  - `Duration__c = 125`
  - `Cost__c = 0.15`
  - `Recording_URL__c`
  - `Completed_At__c`
- Create Task record linked to Lead/Contact
- Trigger follow-up workflows (if answered)

**Use Case**: Main event for call completion, triggers most business logic

---

### 4. transcript.ready

**Triggered**: When call transcript is processed (usually 30-60 seconds after call ends)

**Payload Example**:
```json
{
  "event": "transcript.ready",
  "call_id": "c-abc123xyz",
  "transcript": "Agent: Hello, this is a call from...\nCustomer: Yes, I'm interested...",
  "transcript_url": "https://storage.bland.ai/transcripts/abc123.json",
  "words": 245,
  "sentiment": "positive"
}
```

**Alternative Format** (JSON array):
```json
{
  "event": "transcript.ready",
  "call_id": "c-abc123xyz",
  "transcript": [
    {
      "speaker": "agent",
      "text": "Hello, this is a call from...",
      "timestamp": 0.5
    },
    {
      "speaker": "customer",
      "text": "Yes, I'm interested...",
      "timestamp": 3.2
    }
  ]
}
```

**Salesforce Action**:
- Update Call__c record: `Transcript__c` (long text area)
- Extract keywords/sentiment for analytics
- Trigger AI analysis (Einstein GPT, external NLP)

**Use Case**: Enable searchable call transcripts, sentiment analysis, compliance monitoring

---

## Webhook Handler Implementation

### Basic Pattern

```apex
@RestResource(urlMapping='/bland/webhook/*')
global with sharing class BlandAIWebhookHandler {
    
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String body = req.requestBody.toString();
            Map<String, Object> webhook = (Map<String, Object>)JSON.deserializeUntyped(body);
            
            String eventType = (String)webhook.get('event');
            String callId = (String)webhook.get('call_id');
            
            switch on eventType {
                when 'call.started' { handleCallStarted(callId, webhook); }
                when 'call.answered' { handleCallAnswered(callId, webhook); }
                when 'call.completed' { handleCallCompleted(callId, webhook); }
                when 'transcript.ready' { handleTranscriptReady(callId, webhook); }
            }
            
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'success'
            }));
            
        } catch (Exception e) {
            res.statusCode = 500;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'error',
                'message' => e.getMessage()
            }));
        }
    }
}
```

### Error Handling Best Practices

1. **Always Return 200 OK**: Bland.ai will retry if non-2xx response
2. **Idempotency**: Handle duplicate webhook deliveries gracefully
3. **Async Processing**: For heavy operations, enqueue Platform Event or Queueable
4. **Logging**: Log all webhook payloads for debugging
5. **Validation**: Verify `call_id` exists before processing

### Testing Webhooks

**Local Testing**:
1. Use tools like [webhook.site](https://webhook.site) to inspect payloads
2. Copy payload structure
3. Write Apex test with mock data

**Test Class Example**:
```apex
@IsTest
private class BlandAIWebhookHandlerTest {
    
    @IsTest
    static void testCallCompletedWebhook() {
        // Create test Call__c record
        Call__c call = new Call__c(
            Bland_Call_ID__c = 'test-call-123',
            Status__c = 'In Progress'
        );
        insert call;
        
        // Prepare webhook payload
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/bland/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
            'event' => 'call.completed',
            'call_id' => 'test-call-123',
            'duration' => 120,
            'answered' => true
        }));
        
        RestContext.request = req;
        RestContext.response = new RestResponse();
        
        // Call webhook handler
        Test.startTest();
        BlandAIWebhookHandler.handleWebhook();
        Test.stopTest();
        
        // Verify call was updated
        Call__c updatedCall = [SELECT Status__c, Duration__c FROM Call__c WHERE Id = :call.Id];
        Assert.areEqual('Completed', updatedCall.Status__c);
        Assert.areEqual(120, updatedCall.Duration__c);
    }
}
```

## Webhook Retry Logic

**Bland.ai Behavior**:
- Retries webhooks up to **3 times** with exponential backoff
- Retry intervals: 1 minute, 5 minutes, 30 minutes
- Marks webhook as failed after 3 failures

**Salesforce Best Practices**:
- Always return 200 OK quickly (< 10 seconds)
- For long-running operations, use Queueable
- Implement idempotency checks (prevent duplicate processing)

## Security: Webhook Signature Verification

**Coming in v1.1**: Bland.ai includes `X-Bland-Signature` header for verification.

**Implementation**:
```apex
private static Boolean verifySignature(String payload, String signature, String secret) {
    Blob hmac = Crypto.generateMac('hmacSHA256', Blob.valueOf(payload), Blob.valueOf(secret));
    String calculatedSignature = EncodingUtil.base64Encode(hmac);
    return calculatedSignature == signature;
}
```

## Common Webhook Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Webhooks not received | Site not public | Enable public access for REST class |
| Duplicate processing | Retries without idempotency | Check if call already processed |
| 500 errors | Uncaught exceptions | Add try-catch, always return 200 |
| Missing transcript | Called too soon | Wait for `transcript.ready` event |
| Call not found | Webhook before callout returns | Create call optimistically or handle gracefully |

## Advanced Patterns

### Pattern 1: Async Processing with Platform Events

```apex
// Webhook handler publishes Platform Event
@HttpPost
global static void handleWebhook() {
    String body = RestContext.request.requestBody.toString();
    
    Bland_Webhook_Event__e event = new Bland_Webhook_Event__e(
        Payload__c = body,
        Received_At__c = Datetime.now()
    );
    
    EventBus.publish(event);
    
    RestContext.response.statusCode = 200;
}

// Platform Event trigger processes asynchronously
trigger BlandWebhookEventTrigger on Bland_Webhook_Event__e (after insert) {
    for (Bland_Webhook_Event__e evt : Trigger.new) {
        BlandWebhookProcessor.process(evt.Payload__c);
    }
}
```

### Pattern 2: Chained Processing

```apex
// call.completed triggers follow-up action
private static void handleCallCompleted(String callId, Map<String, Object> data) {
    // Update call record
    // ...
    
    // If call was answered, schedule follow-up
    if ((Boolean)data.get('answered')) {
        scheduleFollowUpCall(callId, 7); // 7 days later
    }
}
```

## See Also

- [Call Logging Patterns](call-logging-patterns.md)
- [Flow Integration Guide](flow-integration-guide.md)
- [Bland.ai API Documentation](https://docs.bland.ai/webhooks)
