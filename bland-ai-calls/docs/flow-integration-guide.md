# Flow Integration Guide for Bland.ai

Complete guide to integrating Bland.ai phone calls with Salesforce Flow.

## Overview

Connect Bland.ai with declarative automation using:
- **@InvocableMethod** - Call Apex from Flow
- **Record-Triggered Flows** - Automatic call triggering
- **Screen Flows** - User-initiated calls
- **Scheduled Flows** - Batch reminder calls

## Architecture Pattern

```
Flow (Declarative)
    ↓
Invocable Apex Action
    ↓
BlandAICalloutService (Callout)
    ↓
Bland.ai API
```

## Creating an Invocable Apex Action

### Step 1: Create Invocable Method Class

```apex
public with sharing class BlandAIFlowActions {
    
    @InvocableMethod(
        label='Make Bland.ai Call'
        description='Initiates an outbound call via Bland.ai'
        category='Phone Calls'
    )
    public static List<Response> makeCall(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            
            try {
                // Build CallRequest
                BlandAICalloutService.CallRequest callReq = new BlandAICalloutService.CallRequest();
                callReq.phone_number = req.phoneNumber;
                callReq.task = req.prompt;
                callReq.voice = req.voice ?? 'maya';
                callReq.language = req.language ?? 'en';
                
                // Make the call
                String callId = BlandAICalloutService.makeCall(callReq);
                
                // Create Call record
                Call__c call = new Call__c(
                    Bland_Call_ID__c = callId,
                    Related_To__c = req.relatedRecordId,
                    Status__c = 'Queued',
                    Phone_Number__c = req.phoneNumber,
                    Queued_At__c = Datetime.now()
                );
                insert call;
                
                res.isSuccess = true;
                res.callId = callId;
                res.callRecordId = call.Id;
                res.message = 'Call initiated successfully';
                
            } catch (Exception e) {
                res.isSuccess = false;
                res.message = 'Error: ' + e.getMessage();
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    public class Request {
        @InvocableVariable(label='Phone Number' description='E.164 format: +15555551234' required=true)
        public String phoneNumber;
        
        @InvocableVariable(label='AI Prompt/Task' description='Instructions for the AI agent' required=true)
        public String prompt;
        
        @InvocableVariable(label='Related Record ID' description='Lead, Contact, Account, or Case ID' required=false)
        public Id relatedRecordId;
        
        @InvocableVariable(label='Voice' description='Voice ID (maya, alex, etc.)' required=false)
        public String voice;
        
        @InvocableVariable(label='Language' description='Language code (en, es, fr)' required=false)
        public String language;
    }
    
    public class Response {
        @InvocableVariable(label='Success')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Call ID')
        public String callId;
        
        @InvocableVariable(label='Call Record ID')
        public Id callRecordId;
        
        @InvocableVariable(label='Message')
        public String message;
    }
}
```

### Step 2: Deploy Invocable Class

```bash
sf project deploy start --source-dir force-app/main/default/classes/BlandAIFlowActions.cls --target-org your-org
```

---

## Flow Patterns

### Pattern 1: Record-Triggered Flow (Auto-Call Qualified Leads)

**Trigger**: When Lead Status changes to "Qualified"

**Flow Configuration**:
1. **Trigger**: Object = Lead, When = Updated, Condition = Status EQUALS Qualified
2. **Action**: Apex Action "Make Bland.ai Call"
   - Phone Number: `{!$Record.Phone}`
   - AI Prompt: `You are a sales representative. Introduce our product and ask if they'd like to schedule a demo. The lead name is {!$Record.FirstName} {!$Record.LastName}.`
   - Related Record ID: `{!$Record.Id}`
   - Voice: `maya`
   - Language: `en`
3. **Decision**: Check if Success = True
4. **Update Lead**: Add note "Automated call initiated"

**Example Prompt Template**:
```
You are calling {!$Record.FirstName} {!$Record.LastName} from {!$Record.Company}.
They recently expressed interest in our product.

Your goal:
1. Introduce yourself and our company
2. Confirm their interest
3. Offer to schedule a product demo
4. If interested, tell them someone will follow up within 24 hours

Be conversational and friendly. If they're not interested, thank them and end the call.
```

---

### Pattern 2: Screen Flow (User-Initiated Call)

**Use Case**: Sales rep clicks button to initiate call

**Flow Configuration**:
1. **Screen 1**: Show Lead/Contact details, confirm phone number
2. **Screen 2**: Text area for custom message/prompt
3. **Action**: Make Bland.ai Call
4. **Screen 3**: Success/failure message with Call Record link

**Lightning Component**:
```html
<!-- leadCallButton.html -->
<template>
    <lightning-button 
        label="Make AI Call" 
        onclick={handleCallClick}
        variant="brand"
        icon-name="utility:call">
    </lightning-button>
</template>
```

```javascript
// leadCallButton.js
import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class LeadCallButton extends LightningElement {
    @api recordId;
    @api availableActions = [];
    
    handleCallClick() {
        if (this.availableActions.find(action => action === 'NEXT')) {
            const navigateNextEvent = new FlowNavigationNextEvent();
            this.dispatchEvent(navigateNextEvent);
        }
    }
}
```

---

### Pattern 3: Scheduled Flow (Daily Appointment Reminders)

**Trigger**: Scheduled (Daily at 9 AM)

**Flow Configuration**:
1. **Get Records**: Query Events where `ActivityDate = TODAY` AND `Phone__c != null`
2. **Loop**: Iterate through events
3. **Action**: Make Bland.ai Call for each event
   - Phone Number: `{!Event.Phone__c}`
   - AI Prompt: `You are calling to remind about an appointment today at {!Event.StartDateTime}. Location: {!Event.Location}. If they can't make it, ask if they'd like to reschedule.`
   - Related Record ID: `{!Event.WhoId}`

**Schedule**: Daily at 9 AM
```
0 0 9 * * ?
```

---

### Pattern 4: Post-Case Closure Survey

**Trigger**: When Case Status changes to "Closed"

**Flow Configuration**:
1. **Trigger**: Object = Case, When = Updated, Condition = Status EQUALS Closed
2. **Decision**: Check if `Case.Contact.Phone != null`
3. **Action**: Make Bland.ai Call
   - Phone Number: `{!$Record.Contact.Phone}`
   - AI Prompt: `You are conducting a quick satisfaction survey about case #{!$Record.CaseNumber}. Ask the customer to rate their experience from 1-5 and if they have any feedback.`
   - Related Record ID: `{!$Record.ContactId}`
4. **Wait**: 5 minutes (for webhook to update Call record)
5. **Get Records**: Retrieve Call__c by Bland_Call_ID__c
6. **Decision**: If sentiment is negative, create follow-up task

---

## Advanced Patterns

### Pattern 5: Conditional Voice Selection

Choose voice based on language:

```apex
String voice;
if (req.language == 'es') {
    voice = 'miguel'; // Spanish voice
} else if (req.language == 'fr') {
    voice = 'marie'; // French voice
} else {
    voice = 'maya'; // Default English voice
}
```

**In Flow**:
Use Formula resource:
```
IF(Contact.Language__c = "Spanish", "miguel", 
   IF(Contact.Language__c = "French", "marie", "maya"))
```

---

### Pattern 6: Bulk Call Processing (Avoid Flow Limits)

**Challenge**: Flow has 2000 element limit per interview

**Solution**: Use Platform Event to queue calls

**Flow Configuration**:
1. **Get Records**: Query up to 200 Leads
2. **Loop**: For each Lead
3. **Create Record**: Bland_Call_Queue__e Platform Event
   - Phone: `{!Lead.Phone}`
   - Record_Id: `{!Lead.Id}`
   - Prompt: `{!$GlobalConstant.SalesCallPrompt}`

**Platform Event Trigger**:
```apex
trigger BlandCallQueueTrigger on Bland_Call_Queue__e (after insert) {
    List<BlandAICallQueueable.CallQueueItem> queue = new List<BlandAICallQueueable.CallQueueItem>();
    
    for (Bland_Call_Queue__e evt : Trigger.new) {
        BlandAICalloutService.CallRequest req = new BlandAICalloutService.CallRequest();
        req.phone_number = evt.Phone__c;
        req.task = evt.Prompt__c;
        
        queue.add(new BlandAICallQueueable.CallQueueItem(req, evt.Record_Id__c));
    }
    
    if (!queue.isEmpty()) {
        System.enqueueJob(new BlandAICallQueueable(queue));
    }
}
```

---

## Testing Flows with Bland.ai Integration

### Test Class for Invocable Method

```apex
@IsTest
private class BlandAIFlowActionsTest {
    
    @IsTest
    static void testMakeCallSuccess() {
        // Setup mock
        Test.setMock(HttpCalloutMock.class, new BlandAIMockSuccess());
        
        // Create request
        BlandAIFlowActions.Request req = new BlandAIFlowActions.Request();
        req.phoneNumber = '+15555551234';
        req.prompt = 'Test call';
        req.voice = 'maya';
        
        Test.startTest();
        List<BlandAIFlowActions.Response> responses = BlandAIFlowActions.makeCall(
            new List<BlandAIFlowActions.Request>{ req }
        );
        Test.stopTest();
        
        Assert.areEqual(1, responses.size());
        Assert.isTrue(responses[0].isSuccess);
        Assert.isNotNull(responses[0].callId);
    }
    
    @IsTest
    static void testMakeCallFailure() {
        // Setup mock
        Test.setMock(HttpCalloutMock.class, new BlandAIMockFailure());
        
        BlandAIFlowActions.Request req = new BlandAIFlowActions.Request();
        req.phoneNumber = '+15555551234';
        req.prompt = 'Test call';
        
        Test.startTest();
        List<BlandAIFlowActions.Response> responses = BlandAIFlowActions.makeCall(
            new List<BlandAIFlowActions.Request>{ req }
        );
        Test.stopTest();
        
        Assert.areEqual(1, responses.size());
        Assert.isFalse(responses[0].isSuccess);
        Assert.isTrue(responses[0].message.contains('Error'));
    }
}

// Mock classes
private class BlandAIMockSuccess implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody('{"call_id": "test-call-123"}');
        return res;
    }
}

private class BlandAIMockFailure implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(400);
        res.setBody('{"error": "Invalid phone number"}');
        return res;
    }
}
```

---

## Flow Best Practices

### 1. Error Handling

Always check `isSuccess` after Apex action:

```
[Decision: Is Success?]
├─ TRUE → Update record, show success message
└─ FALSE → Log error, show error message to user
```

### 2. Governor Limits

- **Max Apex Actions per Flow**: 2000 elements total
- **For Bulk**: Use Platform Events + Queueable instead of looping in Flow

### 3. Phone Number Validation

Add validation before calling:

**Formula Resource**: `IsValidPhone`
```
REGEX(Lead.Phone, "^\\+[1-9]\\d{1,14}$")
```

**Decision**: Only proceed if `IsValidPhone = TRUE`

### 4. Prompt Templates

Store prompts in Custom Metadata or Custom Labels for easy updates:

```apex
String prompt = System.Label.Bland_Sales_Call_Prompt
    .replace('{FirstName}', lead.FirstName)
    .replace('{Company}', lead.Company);
```

---

## See Also

- [Webhook Events Guide](webhook-events-guide.md)
- [Call Logging Patterns](call-logging-patterns.md)
- [Bland.ai API Documentation](https://docs.bland.ai/)
- [Salesforce Flow Best Practices](https://help.salesforce.com/articleView?id=flow_concepts_bestpractices.htm)
