/**
 * @description REST API endpoint to receive webhooks from Bland.ai for call events.
 *              Handles call.started, call.completed, and transcript.ready events.
 * 
 * @author Your Name
 * @date 2026-01-12
 * 
 * Endpoint URL: https://your-domain.my.salesforce.com/services/apexrest/bland/webhook
 * 
 * Configure this URL in Bland.ai dashboard or include in CallRequest.webhook parameter.
 */
@RestResource(urlMapping='/bland/webhook/*')
global with sharing class BlandAIWebhookHandler {
    
    /**
     * @description Handle POST requests from Bland.ai webhooks
     */
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            String requestBody = req.requestBody.toString();
            
            if (String.isBlank(requestBody)) {
                respondError(res, 400, 'Request body is empty');
                return;
            }
            
            Map<String, Object> webhook = (Map<String, Object>)JSON.deserializeUntyped(requestBody);
            
            String eventType = (String)webhook.get('event');
            String callId = (String)webhook.get('call_id');
            
            if (String.isBlank(eventType)) {
                respondError(res, 400, 'Missing event type');
                return;
            }
            
            if (String.isBlank(callId)) {
                respondError(res, 400, 'Missing call_id');
                return;
            }
            
            // Route to appropriate handler based on event type
            switch on eventType {
                when 'call.started' {
                    handleCallStarted(callId, webhook);
                }
                when 'call.answered' {
                    handleCallAnswered(callId, webhook);
                }
                when 'call.completed' {
                    handleCallCompleted(callId, webhook);
                }
                when 'transcript.ready' {
                    handleTranscriptReady(callId, webhook);
                }
                when else {
                    System.debug('Unknown event type: ' + eventType);
                }
            }
            
            // Return success response
            res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
                'status' => 'success',
                'message' => 'Webhook processed'
            }));
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Webhook processing error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            respondError(res, 500, 'Internal server error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Handle call.started event
     */
    private static void handleCallStarted(String callId, Map<String, Object> data) {
        List<Call__c> calls = [
            SELECT Id, Status__c 
            FROM Call__c 
            WHERE Bland_Call_ID__c = :callId 
            LIMIT 1
        ];
        
        if (!calls.isEmpty()) {
            Call__c call = calls[0];
            call.Status__c = 'In Progress';
            call.Started_At__c = Datetime.now();
            
            // DML with security check
            if (Schema.sObjectType.Call__c.isUpdateable()) {
                update call;
            }
        } else {
            // Create new call record if it doesn't exist
            createCallRecord(callId, data);
        }
    }
    
    /**
     * @description Handle call.answered event
     */
    private static void handleCallAnswered(String callId, Map<String, Object> data) {
        List<Call__c> calls = [
            SELECT Id, Status__c 
            FROM Call__c 
            WHERE Bland_Call_ID__c = :callId 
            LIMIT 1
        ];
        
        if (!calls.isEmpty()) {
            Call__c call = calls[0];
            call.Status__c = 'Answered';
            call.Answered_At__c = Datetime.now();
            
            if (Schema.sObjectType.Call__c.isUpdateable()) {
                update call;
            }
        }
    }
    
    /**
     * @description Handle call.completed event
     */
    private static void handleCallCompleted(String callId, Map<String, Object> data) {
        List<Call__c> calls = [
            SELECT Id, Status__c, Related_To__c
            FROM Call__c 
            WHERE Bland_Call_ID__c = :callId 
            LIMIT 1
        ];
        
        if (!calls.isEmpty()) {
            Call__c call = calls[0];
            call.Status__c = 'Completed';
            call.Completed_At__c = Datetime.now();
            
            // Extract call details from webhook data
            if (data.containsKey('duration')) {
                call.Duration__c = (Decimal)data.get('duration');
            }
            
            if (data.containsKey('recording_url')) {
                call.Recording_URL__c = (String)data.get('recording_url');
            }
            
            if (data.containsKey('cost')) {
                call.Cost__c = (Decimal)data.get('cost');
            }
            
            if (data.containsKey('answered')) {
                Boolean answered = (Boolean)data.get('answered');
                if (!answered) {
                    call.Status__c = 'No Answer';
                }
            }
            
            if (Schema.sObjectType.Call__c.isUpdateable()) {
                update call;
            }
            
            // Create related Task
            createCallTask(call, data);
        }
    }
    
    /**
     * @description Handle transcript.ready event
     */
    private static void handleTranscriptReady(String callId, Map<String, Object> data) {
        List<Call__c> calls = [
            SELECT Id, Transcript__c 
            FROM Call__c 
            WHERE Bland_Call_ID__c = :callId 
            LIMIT 1
        ];
        
        if (!calls.isEmpty()) {
            Call__c call = calls[0];
            
            // Extract transcript from webhook or fetch via API
            if (data.containsKey('transcript')) {
                Object transcriptData = data.get('transcript');
                
                if (transcriptData instanceof String) {
                    call.Transcript__c = (String)transcriptData;
                } else {
                    // If transcript is an array of objects, serialize it
                    call.Transcript__c = JSON.serializePretty(transcriptData);
                }
            } else {
                // Fetch transcript via API if not in webhook
                try {
                    String transcript = BlandAICalloutService.getCallTranscript(callId);
                    call.Transcript__c = transcript;
                } catch (Exception e) {
                    System.debug('Failed to fetch transcript: ' + e.getMessage());
                }
            }
            
            if (Schema.sObjectType.Call__c.isUpdateable()) {
                update call;
            }
        }
    }
    
    /**
     * @description Create a new Call__c record from webhook data
     */
    private static void createCallRecord(String callId, Map<String, Object> data) {
        Call__c call = new Call__c(
            Bland_Call_ID__c = callId,
            Status__c = 'In Progress',
            Started_At__c = Datetime.now()
        );
        
        if (data.containsKey('phone_number')) {
            call.Phone_Number__c = (String)data.get('phone_number');
        }
        
        if (Schema.sObjectType.Call__c.isCreateable()) {
            insert call;
        }
    }
    
    /**
     * @description Create a Task record for completed call
     */
    private static void createCallTask(Call__c call, Map<String, Object> data) {
        if (call.Related_To__c == null) {
            return; // No related record to attach task to
        }
        
        Task callTask = new Task();
        callTask.WhatId = call.Related_To__c;
        callTask.Subject = 'Phone Call - ' + call.Status__c;
        callTask.Status = 'Completed';
        callTask.ActivityDate = Date.today();
        callTask.CallType = 'Outbound';
        
        if (call.Duration__c != null) {
            callTask.CallDurationInSeconds = Integer.valueOf(call.Duration__c);
        }
        
        String description = 'Bland.ai automated call\n';
        description += 'Call ID: ' + call.Bland_Call_ID__c + '\n';
        description += 'Duration: ' + (call.Duration__c ?? 0) + ' seconds\n';
        
        if (call.Recording_URL__c != null) {
            description += 'Recording: ' + call.Recording_URL__c + '\n';
        }
        
        callTask.Description = description;
        
        if (Schema.sObjectType.Task.isCreateable()) {
            insert callTask;
        }
    }
    
    /**
     * @description Send error response
     */
    private static void respondError(RestResponse res, Integer statusCode, String message) {
        res.statusCode = statusCode;
        res.responseBody = Blob.valueOf(JSON.serialize(new Map<String, String>{
            'status' => 'error',
            'message' => message
        }));
    }
}
