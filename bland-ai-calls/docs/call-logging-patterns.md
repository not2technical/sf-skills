# Call Logging Patterns for Bland.ai Integration

Best practices for storing and managing call data in Salesforce.

## Storage Options

### Option 1: Custom Call__c Object (Recommended)

**Pros**:
- ✅ Rich data model (status, duration, transcript, recording URL, cost)
- ✅ Reporting and dashboards
- ✅ Relationship to multiple objects (Lead, Contact, Account, Case)
- ✅ Full audit trail

**Cons**:
- ❌ Requires custom object deployment
- ❌ Additional storage usage

**When to Use**: Production integrations requiring full call analytics and reporting

---

### Option 2: Standard Task Object

**Pros**:
- ✅ No custom objects needed
- ✅ Native integration with Activities
- ✅ Appears in activity timelines
- ✅ Standard reporting

**Cons**:
- ❌ Limited fields for call metadata
- ❌ No external ID for Bland call_id
- ❌ Transcript truncated (Description field limited to 32KB)

**When to Use**: Simple implementations, POCs, or when custom objects aren't allowed

---

### Option 3: Hybrid Approach

**Pattern**: Use both Call__c and Task

**Implementation**:
1. **Call__c**: Store complete call data (external ID, transcript, recording URL)
2. **Task**: Create activity timeline entry linked to Call__c

**Benefits**:
- ✅ Full data storage + native activity timeline
- ✅ Sales users see calls in standard views
- ✅ Admins have rich reporting

**Example**:
```apex
// Create Call__c record
Call__c call = new Call__c(
    Bland_Call_ID__c = callId,
    Related_To__c = leadId,
    Status__c = 'Completed',
    Duration__c = 120,
    Transcript__c = transcript,
    Recording_URL__c = recordingUrl
);
insert call;

// Create linked Task
Task callTask = new Task(
    WhoId = leadId,
    Subject = 'Automated Call - Completed',
    Status = 'Completed',
    ActivityDate = Date.today(),
    CallType = 'Outbound',
    CallDurationInSeconds = 120,
    Description = 'Call ID: ' + callId + '\nRecording: ' + recordingUrl
);
insert callTask;
```

---

## Data Model Design

### Recommended Call__c Fields

| Field | Type | Purpose |
|-------|------|---------|
| `Bland_Call_ID__c` | Text (External ID) | Unique identifier from Bland.ai |
| `Related_To__c` | Lookup (polymorphic) | Link to Lead, Contact, Account, or Case |
| `Status__c` | Picklist | Current call status (Queued, In Progress, Completed, Failed) |
| `Phone_Number__c` | Phone | Called number |
| `Duration__c` | Number | Call duration in seconds |
| `Cost__c` | Currency | Call cost from Bland.ai |
| `Recording_URL__c` | URL | Link to call recording |
| `Transcript__c` | Long Text Area (131K) | Full call transcript |
| `Error_Message__c` | Long Text Area | Error details if failed |
| `Queued_At__c` | DateTime | When call was queued |
| `Started_At__c` | DateTime | When call started |
| `Answered_At__c` | DateTime | When recipient answered |
| `Completed_At__c` | DateTime | When call ended |
| `Voice__c` | Text | Voice used (maya, alex, etc.) |
| `Language__c` | Text | Language code (en, es, fr) |
| `Sentiment__c` | Picklist | Positive, Neutral, Negative |
| `Call_Type__c` | Picklist | Sales, Support, Reminder, Survey |

### Polymorphic Lookup Implementation

**Challenge**: Standard Lookups only support one object type

**Solution 1: Lookup per Object Type**
```xml
<fields>
    <fullName>Lead__c</fullName>
    <type>Lookup</type>
    <referenceTo>Lead</referenceTo>
</fields>
<fields>
    <fullName>Contact__c</fullName>
    <type>Lookup</type>
    <referenceTo>Contact</referenceTo>
</fields>
```

**Solution 2: Use Name field with Id**
```xml
<fields>
    <fullName>Related_To_ID__c</fullName>
    <type>Text</type>
    <length>18</length>
</fields>
<fields>
    <fullName>Related_To_Type__c</fullName>
    <type>Picklist</type>
    <valueSet>
        <valueSetDefinition>
            <value><fullName>Lead</fullName></value>
            <value><fullName>Contact</fullName></value>
            <value><fullName>Account</fullName></value>
        </valueSetDefinition>
    </valueSet>
</fields>
```

Then use Formula field to create link:
```
HYPERLINK("/" & Related_To_ID__c, Related_To_Type__c)
```

---

## Logging Patterns

### Pattern 1: Immediate Logging (Optimistic)

**When**: Create Call__c record BEFORE making API call

**Pros**: Call record exists even if API fails; can track queued calls

**Implementation**:
```apex
// Create call record first
Call__c call = new Call__c(
    Related_To__c = leadId,
    Status__c = 'Queued',
    Phone_Number__c = phoneNumber,
    Queued_At__c = Datetime.now()
);
insert call;

// Make API call
try {
    String callId = BlandAICalloutService.makeCall(request);
    
    // Update with Bland call ID
    call.Bland_Call_ID__c = callId;
    call.Status__c = 'In Progress';
    update call;
    
} catch (Exception e) {
    // Mark as failed
    call.Status__c = 'Failed';
    call.Error_Message__c = e.getMessage();
    update call;
}
```

**Use Case**: Tracking all call attempts including failures

---

### Pattern 2: Deferred Logging (Pessimistic)

**When**: Create Call__c record AFTER successful API call

**Pros**: Only logs successful calls; cleaner data

**Implementation**:
```apex
try {
    // Make API call
    String callId = BlandAICalloutService.makeCall(request);
    
    // Create call record only if successful
    Call__c call = new Call__c(
        Bland_Call_ID__c = callId,
        Related_To__c = leadId,
        Status__c = 'In Progress',
        Phone_Number__c = phoneNumber,
        Started_At__c = Datetime.now()
    );
    insert call;
    
} catch (Exception e) {
    // Log error elsewhere (Platform Event, custom Error__c object)
    logError(e);
}
```

**Use Case**: Production systems where failed attempts are logged separately

---

### Pattern 3: Webhook-Driven Logging

**When**: Let webhooks create/update all records

**Pros**: Single source of truth (Bland.ai); no sync issues

**Implementation**:
```apex
// Just make the call - don't create record
String callId = BlandAICalloutService.makeCall(request);

// Webhook handler creates record when call.started event received
@HttpPost
global static void handleWebhook() {
    // ...
    if (eventType == 'call.started') {
        Call__c call = new Call__c(
            Bland_Call_ID__c = callId,
            Status__c = 'In Progress'
        );
        insert call;
    }
}
```

**Use Case**: When webhook delivery is guaranteed; simplifies client code

---

## Bulk Logging for Queueable Jobs

When processing multiple calls via `BlandAICallQueueable`:

```apex
public void execute(QueueableContext context) {
    List<Call__c> callsToInsert = new List<Call__c>();
    
    for (CallQueueItem item : callQueue) {
        try {
            String callId = BlandAICalloutService.makeCall(item.request);
            
            callsToInsert.add(new Call__c(
                Bland_Call_ID__c = callId,
                Related_To__c = item.relatedToId,
                Status__c = 'Queued',
                Phone_Number__c = item.request.phone_number
            ));
            
        } catch (Exception e) {
            // Add failed record
            callsToInsert.add(new Call__c(
                Related_To__c = item.relatedToId,
                Status__c = 'Failed',
                Phone_Number__c = item.request.phone_number,
                Error_Message__c = e.getMessage()
            ));
        }
    }
    
    // Bulk insert
    Database.SaveResult[] results = Database.insert(callsToInsert, false);
    
    // Handle partial failures
    for (Integer i = 0; i < results.size(); i++) {
        if (!results[i].isSuccess()) {
            System.debug('Failed to insert call: ' + results[i].getErrors());
        }
    }
}
```

---

## Transcript Storage

### Challenge: Transcript Size

Transcripts can be large. Salesforce limits:
- Long Text Area: 131,072 characters
- Rich Text Area: 131,072 characters

### Solution 1: Store in Long Text Area

```apex
call.Transcript__c = transcript; // Up to 131K chars
```

**Pros**: Simple, searchable
**Cons**: 131K character limit

### Solution 2: Store as Attachment/File

```apex
ContentVersion cv = new ContentVersion(
    Title = 'Call Transcript - ' + callId,
    PathOnClient = 'transcript.txt',
    VersionData = Blob.valueOf(transcript),
    FirstPublishLocationId = call.Id
);
insert cv;
```

**Pros**: No size limit
**Cons**: Not searchable, requires additional query

### Solution 3: External Storage (S3, Salesforce Files)

Store URL only:
```apex
call.Transcript_URL__c = 'https://storage.bland.ai/transcripts/abc123.json';
```

**Pros**: No storage limits, cheaper
**Cons**: Requires external system integration

---

## Reporting and Analytics

### Key Metrics Dashboard

**Reports to Build**:
1. **Call Volume by Date**: Count of calls per day
2. **Answer Rate**: % of calls answered vs. no answer
3. **Average Duration**: Mean duration by call type
4. **Cost Analysis**: Total cost by campaign/user
5. **Transcript Sentiment**: Positive vs. negative calls

### Sample Report Type

**Primary Object**: Call__c
**Fields**:
- Status
- Duration
- Cost
- Answered (formula: `Status__c = 'Completed'`)
- Date fields (Queued At, Started At, Completed At)

**Grouping**: By Status, Date, Related To (Lead/Contact)

---

## Data Retention Policies

**Considerations**:
- Call recordings may have privacy/compliance requirements (GDPR, CCPA)
- Transcripts contain PII
- Storage costs increase over time

**Recommended Policy**:
```apex
// Scheduled job to delete old call records
global class BlandCallDataRetention implements Schedulable {
    global void execute(SchedulableContext sc) {
        Date cutoffDate = Date.today().addMonths(-12); // 12-month retention
        
        List<Call__c> oldCalls = [
            SELECT Id 
            FROM Call__c 
            WHERE Completed_At__c < :cutoffDate 
            AND Status__c IN ('Completed', 'Failed')
            LIMIT 10000
        ];
        
        delete oldCalls;
    }
}
```

**Schedule**: Run monthly
```apex
System.schedule('Bland Call Retention', '0 0 0 1 * ?', new BlandCallDataRetention());
```

---

## See Also

- [Webhook Events Guide](webhook-events-guide.md)
- [Flow Integration Guide](flow-integration-guide.md)
- [Bland.ai API Documentation](https://docs.bland.ai/)
