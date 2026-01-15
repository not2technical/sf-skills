/**
 * @description Queueable Apex class for processing Bland.ai calls asynchronously.
 *              Handles bulk call requests with rate limit awareness and retry logic.
 * 
 * @author Your Name
 * @date 2026-01-12
 * 
 * @example
 * List<BlandAICallQueueable.CallQueueItem> queue = new List<BlandAICallQueueable.CallQueueItem>();
 * 
 * for (Lead lead : qualifiedLeads) {
 *     BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
 *     request.phone_number = lead.Phone;
 *     request.task = 'Introduce our product and schedule a demo';
 *     
 *     queue.add(new BlandAICallQueueable.CallQueueItem(request, lead.Id));
 * }
 * 
 * System.enqueueJob(new BlandAICallQueueable(queue));
 */
public with sharing class BlandAICallQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<CallQueueItem> callQueue;
    private Integer currentIndex;
    private Integer batchSize;
    private Integer maxRetries;
    
    /**
     * @description Constructor for single call
     */
    public BlandAICallQueueable(BlandAICalloutService.CallRequest request, Id relatedToId) {
        this(new List<CallQueueItem>{ new CallQueueItem(request, relatedToId) });
    }
    
    /**
     * @description Constructor for bulk calls
     */
    public BlandAICallQueueable(List<CallQueueItem> queue) {
        this(queue, 0, 10, 3);
    }
    
    /**
     * @description Full constructor with configuration
     */
    public BlandAICallQueueable(List<CallQueueItem> queue, Integer startIndex, Integer batchSize, Integer maxRetries) {
        this.callQueue = queue;
        this.currentIndex = startIndex;
        this.batchSize = batchSize;
        this.maxRetries = maxRetries;
    }
    
    /**
     * @description Execute the queued calls
     */
    public void execute(QueueableContext context) {
        if (callQueue == null || callQueue.isEmpty()) {
            return;
        }
        
        List<Call__c> callsToInsert = new List<Call__c>();
        List<CallQueueItem> failedCalls = new List<CallQueueItem>();
        
        Integer endIndex = Math.min(currentIndex + batchSize, callQueue.size());
        
        for (Integer i = currentIndex; i < endIndex; i++) {
            CallQueueItem item = callQueue[i];
            
            try {
                // Make the API call
                String callId = BlandAICalloutService.makeCall(item.request);
                
                // Create Call__c record
                Call__c call = new Call__c(
                    Bland_Call_ID__c = callId,
                    Related_To__c = item.relatedToId,
                    Status__c = 'Queued',
                    Phone_Number__c = item.request.phone_number,
                    Queued_At__c = Datetime.now()
                );
                
                callsToInsert.add(call);
                
                // Small delay to respect rate limits (if needed)
                // Note: Can't use Thread.sleep() in Queueable, handle via chaining
                
            } catch (Exception e) {
                // Log error and retry if under max retries
                System.debug(LoggingLevel.ERROR, 'Failed to initiate call: ' + e.getMessage());
                
                item.retryCount++;
                if (item.retryCount < maxRetries) {
                    failedCalls.add(item);
                } else {
                    // Create failed call record
                    Call__c failedCall = new Call__c(
                        Related_To__c = item.relatedToId,
                        Status__c = 'Failed',
                        Phone_Number__c = item.request.phone_number,
                        Error_Message__c = e.getMessage(),
                        Queued_At__c = Datetime.now()
                    );
                    callsToInsert.add(failedCall);
                }
            }
        }
        
        // Insert call records
        if (!callsToInsert.isEmpty() && Schema.sObjectType.Call__c.isCreateable()) {
            Database.SaveResult[] results = Database.insert(callsToInsert, false);
            
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Call__c insert error: ' + err.getMessage());
                    }
                }
            }
        }
        
        // Chain next batch if more calls remain
        if (endIndex < callQueue.size()) {
            System.enqueueJob(new BlandAICallQueueable(callQueue, endIndex, batchSize, maxRetries));
        }
        
        // Retry failed calls with exponential backoff
        if (!failedCalls.isEmpty()) {
            // Wait before retry by enqueueing with delay (future enhancement: use Platform Events)
            System.enqueueJob(new BlandAICallQueueable(failedCalls, 0, batchSize, maxRetries));
        }
    }
    
    /**
     * @description Wrapper class for queued call items
     */
    public class CallQueueItem {
        public BlandAICalloutService.CallRequest request { get; set; }
        public Id relatedToId { get; set; }
        public Integer retryCount { get; set; }
        
        public CallQueueItem(BlandAICalloutService.CallRequest request, Id relatedToId) {
            this.request = request;
            this.relatedToId = relatedToId;
            this.retryCount = 0;
        }
    }
}
