# Rate Limit Handling for Bland.ai Integration

Best practices for managing API rate limits and scaling call operations.

## Bland.ai Rate Limits

Rate limits vary by plan:

| Plan | Concurrent Calls | Calls per Hour | Calls per Day |
|------|------------------|----------------|---------------|
| **Free** | 1 | 50 | 100 |
| **Starter** | 5 | 500 | 2,000 |
| **Pro** | 20 | 2,000 | 10,000 |
| **Enterprise** | Custom | Custom | Custom |

**Important**: These limits are approximate. Check your Bland.ai dashboard for current limits.

## Salesforce Governor Limits

In addition to Bland.ai limits, consider Salesforce limits:

| Limit | Synchronous | Asynchronous |
|-------|-------------|--------------|
| **Callout Limit** | 100 per transaction | 100 per transaction |
| **Timeout** | 120 seconds max | 120 seconds max |
| **CPU Time** | 10,000ms | 60,000ms |
| **Heap Size** | 6MB | 12MB |

## Handling Rate Limits

### Pattern 1: Queueable with Batching

**Strategy**: Process calls in small batches with chaining

```apex
public with sharing class BlandAICallQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<CallQueueItem> callQueue;
    private Integer currentIndex;
    private static final Integer BATCH_SIZE = 10; // Process 10 at a time
    
    public BlandAICallQueueable(List<CallQueueItem> queue) {
        this(queue, 0);
    }
    
    private BlandAICallQueueable(List<CallQueueItem> queue, Integer startIndex) {
        this.callQueue = queue;
        this.currentIndex = startIndex;
    }
    
    public void execute(QueueableContext context) {
        Integer endIndex = Math.min(currentIndex + BATCH_SIZE, callQueue.size());
        
        for (Integer i = currentIndex; i < endIndex; i++) {
            CallQueueItem item = callQueue[i];
            
            try {
                String callId = BlandAICalloutService.makeCall(item.request);
                // Log success
                
            } catch (BlandAICalloutService.CalloutException e) {
                if (isRateLimitError(e)) {
                    // Handle rate limit - will retry
                    System.debug('Rate limit hit, will retry');
                } else {
                    // Other error - log and continue
                    logError(item, e);
                }
            }
        }
        
        // Chain next batch if more calls remain
        if (endIndex < callQueue.size()) {
            System.enqueueJob(new BlandAICallQueueable(callQueue, endIndex));
        }
    }
    
    private Boolean isRateLimitError(Exception e) {
        return e.getMessage().contains('429') || 
               e.getMessage().contains('rate limit') ||
               e.getMessage().contains('too many requests');
    }
}
```

**Pros**:
- ✅ Respects Salesforce callout limits (100 per transaction)
- ✅ Automatic chaining for large queues
- ✅ Can process thousands of calls

**Cons**:
- ❌ May still hit Bland.ai rate limits
- ❌ No built-in delay between calls

---

### Pattern 2: Exponential Backoff with Retry

**Strategy**: Retry failed calls with increasing delays

```apex
public class BlandAICallQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<CallQueueItem> callQueue;
    private Integer retryDelayMinutes;
    private static final Integer MAX_RETRY_DELAY = 60; // Max 1 hour delay
    
    public void execute(QueueableContext context) {
        List<CallQueueItem> retryQueue = new List<CallQueueItem>();
        
        for (CallQueueItem item : callQueue) {
            try {
                String callId = BlandAICalloutService.makeCall(item.request);
                // Success
                
            } catch (Exception e) {
                if (isRateLimitError(e) && item.retryCount < 5) {
                    // Add to retry queue
                    item.retryCount++;
                    retryQueue.add(item);
                } else {
                    // Max retries reached or other error
                    logFailedCall(item, e);
                }
            }
        }
        
        // Schedule retry with exponential backoff
        if (!retryQueue.isEmpty()) {
            Integer delayMinutes = Math.min(
                (Integer)Math.pow(2, retryQueue[0].retryCount), 
                MAX_RETRY_DELAY
            );
            scheduleRetry(retryQueue, delayMinutes);
        }
    }
    
    private void scheduleRetry(List<CallQueueItem> queue, Integer delayMinutes) {
        // Use Platform Event to trigger retry after delay
        Bland_Call_Retry__e retryEvent = new Bland_Call_Retry__e(
            Queue_Data__c = JSON.serialize(queue),
            Retry_At__c = Datetime.now().addMinutes(delayMinutes)
        );
        EventBus.publish(retryEvent);
    }
}
```

**Retry Schedule**:
- Attempt 1: Immediate
- Attempt 2: 2 minutes later
- Attempt 3: 4 minutes later
- Attempt 4: 8 minutes later
- Attempt 5: 16 minutes later

---

### Pattern 3: Throttling with Platform Events

**Strategy**: Use Platform Events as a queue with controlled processing rate

**Step 1: Create Platform Event**
```xml
<!-- Bland_Call_Queue__e.object-meta.xml -->
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Bland Call Queue</label>
    <pluralLabel>Bland Call Queue</pluralLabel>
    <eventType>HighVolume</eventType>
    
    <fields>
        <fullName>Phone_Number__c</fullName>
        <type>Text</type>
        <length>20</length>
    </fields>
    
    <fields>
        <fullName>Prompt__c</fullName>
        <type>LongTextArea</type>
        <length>32768</length>
    </fields>
    
    <fields>
        <fullName>Related_Record_Id__c</fullName>
        <type>Text</type>
        <length>18</length>
    </fields>
</CustomObject>
```

**Step 2: Publish Events**
```apex
// Flow or Apex publishes events
List<Bland_Call_Queue__e> events = new List<Bland_Call_Queue__e>();

for (Lead lead : qualifiedLeads) {
    events.add(new Bland_Call_Queue__e(
        Phone_Number__c = lead.Phone,
        Prompt__c = 'Sales call script...',
        Related_Record_Id__c = lead.Id
    ));
}

EventBus.publish(events);
```

**Step 3: Process with Controlled Rate**
```apex
trigger BlandCallQueueTrigger on Bland_Call_Queue__e (after insert) {
    // Process in small batches
    List<BlandAICallQueueable.CallQueueItem> batch = new List<BlandAICallQueueable.CallQueueItem>();
    
    Integer count = 0;
    for (Bland_Call_Queue__e evt : Trigger.new) {
        BlandAICalloutService.CallRequest req = new BlandAICalloutService.CallRequest();
        req.phone_number = evt.Phone_Number__c;
        req.task = evt.Prompt__c;
        
        batch.add(new BlandAICallQueueable.CallQueueItem(req, evt.Related_Record_Id__c));
        
        count++;
        if (count >= 10) { // Process 10 at a time
            System.enqueueJob(new BlandAICallQueueable(batch));
            batch = new List<BlandAICallQueueable.CallQueueItem>();
            count = 0;
        }
    }
    
    // Process remaining
    if (!batch.isEmpty()) {
        System.enqueueJob(new BlandAICallQueueable(batch));
    }
}
```

**Pros**:
- ✅ Decouples publishing from processing
- ✅ Natural throttling via trigger batching
- ✅ High Volume events support millions of messages

**Cons**:
- ❌ Requires Platform Event setup
- ❌ 24-hour retention for High Volume events

---

### Pattern 4: Scheduled Batch Job

**Strategy**: Process queued calls via scheduled Batch Apex

**Step 1: Create Call Queue Object**
```xml
<!-- Call_Queue__c.object-meta.xml -->
<CustomObject>
    <fields>
        <fullName>Status__c</fullName>
        <type>Picklist</type>
        <valueSet>
            <value><fullName>Pending</fullName></value>
            <value><fullName>Processing</fullName></value>
            <value><fullName>Completed</fullName></value>
            <value><fullName>Failed</fullName></value>
        </valueSet>
    </fields>
    <!-- Other fields: Phone_Number__c, Prompt__c, etc. -->
</CustomObject>
```

**Step 2: Batch Apex**
```apex
global class BlandCallBatchProcessor implements Database.Batchable<sObject>, Database.AllowsCallouts {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Phone_Number__c, Prompt__c, Related_Record_Id__c
            FROM Call_Queue__c
            WHERE Status__c = 'Pending'
            ORDER BY CreatedDate ASC
            LIMIT 1000
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<Call_Queue__c> scope) {
        List<Call__c> callsToInsert = new List<Call__c>();
        List<Call_Queue__c> queueToUpdate = new List<Call_Queue__c>();
        
        for (Call_Queue__c queueItem : scope) {
            try {
                BlandAICalloutService.CallRequest req = new BlandAICalloutService.CallRequest();
                req.phone_number = queueItem.Phone_Number__c;
                req.task = queueItem.Prompt__c;
                
                String callId = BlandAICalloutService.makeCall(req);
                
                // Create Call record
                callsToInsert.add(new Call__c(
                    Bland_Call_ID__c = callId,
                    Related_To__c = queueItem.Related_Record_Id__c,
                    Status__c = 'Queued'
                ));
                
                // Mark queue item as completed
                queueItem.Status__c = 'Completed';
                
            } catch (Exception e) {
                queueItem.Status__c = 'Failed';
                queueItem.Error_Message__c = e.getMessage();
            }
            
            queueToUpdate.add(queueItem);
        }
        
        insert callsToInsert;
        update queueToUpdate;
    }
    
    global void finish(Database.BatchableContext bc) {
        // Send summary email
    }
}
```

**Step 3: Schedule**
```apex
// Run every 15 minutes
System.schedule('Bland Call Processor', '0 0,15,30,45 * * * ?', new BlandCallScheduler());

public class BlandCallScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new BlandCallBatchProcessor(), 10); // Batch size 10
    }
}
```

**Pros**:
- ✅ Controlled processing rate (batch size + schedule)
- ✅ Easy to monitor and manage
- ✅ Can pause/resume by descheduling

**Cons**:
- ❌ Less real-time (15-minute intervals)
- ❌ Requires custom queue object

---

## Monitoring and Alerting

### Track Rate Limit Hits

```apex
// Custom object: API_Error_Log__c
private static void logRateLimitHit(String endpoint, String message) {
    API_Error_Log__c log = new API_Error_Log__c(
        Endpoint__c = endpoint,
        Error_Type__c = 'Rate Limit',
        Error_Message__c = message,
        Timestamp__c = Datetime.now()
    );
    insert log;
    
    // Send alert if > 10 rate limit errors in last hour
    Integer recentErrors = [
        SELECT COUNT()
        FROM API_Error_Log__c
        WHERE Error_Type__c = 'Rate Limit'
        AND Timestamp__c >= :Datetime.now().addHours(-1)
    ];
    
    if (recentErrors > 10) {
        sendRateLimitAlert();
    }
}
```

### Dashboard Metrics

Create reports to track:
- **API Call Volume**: Calls per hour/day
- **Rate Limit Hits**: Count of 429 errors
- **Retry Rate**: % of calls requiring retry
- **Average Processing Time**: Time from queue to completion

---

## Best Practices

1. **Start Small**: Begin with batch size of 10, increase as needed
2. **Monitor Closely**: Track rate limit hits in first week
3. **Use Off-Peak Hours**: Schedule bulk calls during low-traffic times
4. **Prioritize Calls**: Process high-priority calls first
5. **Set Expectations**: Inform stakeholders about processing times
6. **Plan for Scale**: Design for 2x expected volume

---

## See Also

- [Bland.ai Rate Limits Documentation](https://docs.bland.ai/rate-limits)
- [Salesforce Governor Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm)
- [Platform Events Guide](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/)
