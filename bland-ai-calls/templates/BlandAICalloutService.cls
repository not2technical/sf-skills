/**
 * @description Apex service class for integrating with Bland.ai phone call API.
 *              Provides methods to initiate calls, retrieve call status, and manage call recordings.
 * 
 * @author Your Name
 * @date 2026-01-12
 * 
 * @example
 * BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
 * request.phone_number = '+15555551234';
 * request.task = 'You are a sales representative. Introduce our product.';
 * request.voice = 'maya';
 * 
 * String callId = BlandAICalloutService.makeCall(request);
 */
public with sharing class BlandAICalloutService {
    
    private static final String NAMED_CREDENTIAL = 'callout:Bland_AI_API';
    private static final Integer TIMEOUT = 120000; // 120 seconds
    
    /**
     * @description Request wrapper for initiating a call
     */
    public class CallRequest {
        public String phone_number;           // E.164 format: +15555551234
        public String task;                   // AI prompt/instructions
        public String voice;                  // Voice ID (maya, alex, etc.)
        public String language;               // Language code (en, es, etc.)
        public Boolean record;                // Whether to record call
        public Map<String, Object> request_data;  // Custom data passed to AI
        public String webhook;                // Webhook URL for updates
        public Integer max_duration;          // Max call duration in seconds
        
        public CallRequest() {
            this.record = true;
            this.language = 'en';
            this.voice = 'maya';
            this.max_duration = 300; // 5 minutes default
        }
    }
    
    /**
     * @description Response from Bland.ai after initiating a call
     */
    public class CallResponse {
        public String call_id;
        public String status;
        public String message;
    }
    
    /**
     * @description Initiate an outbound call via Bland.ai
     * 
     * @param request CallRequest object with phone number and call configuration
     * @return String Call ID from Bland.ai
     * 
     * @throws CalloutException if API call fails
     */
    public static String makeCall(CallRequest request) {
        validateCallRequest(request);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/calls');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(request, true));
        req.setTimeout(TIMEOUT);
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
        } catch (Exception e) {
            logError('makeCall', 'HTTP Request Failed', e);
            throw new CalloutException('Failed to connect to Bland.ai: ' + e.getMessage());
        }
        
        return handleCallResponse(res);
    }
    
    /**
     * @description Retrieve details about a specific call
     * 
     * @param callId The Bland.ai call ID
     * @return Map<String, Object> Call details including status, duration, recording URL
     * 
     * @throws CalloutException if API call fails
     */
    public static Map<String, Object> getCallDetails(String callId) {
        if (String.isBlank(callId)) {
            throw new IllegalArgumentException('Call ID cannot be blank');
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/calls/' + callId);
        req.setMethod('GET');
        req.setTimeout(TIMEOUT);
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
        } catch (Exception e) {
            logError('getCallDetails', 'HTTP Request Failed', e);
            throw new CalloutException('Failed to retrieve call details: ' + e.getMessage());
        }
        
        if (res.getStatusCode() == 200) {
            return (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        } else {
            String errorMsg = 'Bland.ai API Error: ' + res.getStatus() + ' - ' + res.getBody();
            logError('getCallDetails', errorMsg, null);
            throw new CalloutException(errorMsg);
        }
    }
    
    /**
     * @description Get the transcript for a completed call
     * 
     * @param callId The Bland.ai call ID
     * @return String Call transcript text
     */
    public static String getCallTranscript(String callId) {
        Map<String, Object> details = getCallDetails(callId);
        
        if (details.containsKey('transcript')) {
            return (String)details.get('transcript');
        }
        
        return null;
    }
    
    /**
     * @description Get the recording URL for a completed call
     * 
     * @param callId The Bland.ai call ID
     * @return String Recording URL
     */
    public static String getCallRecordingUrl(String callId) {
        Map<String, Object> details = getCallDetails(callId);
        
        if (details.containsKey('recording_url')) {
            return (String)details.get('recording_url');
        }
        
        return null;
    }
    
    /**
     * @description List all calls with optional filters
     * 
     * @param pageSize Number of results per page
     * @param pageNumber Page number to retrieve
     * @return List<Map<String, Object>> List of call records
     */
    public static List<Map<String, Object>> listCalls(Integer pageSize, Integer pageNumber) {
        pageSize = pageSize ?? 50;
        pageNumber = pageNumber ?? 1;
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/calls?page_size=' + pageSize + '&page=' + pageNumber);
        req.setMethod('GET');
        req.setTimeout(TIMEOUT);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            Map<String, Object> responseData = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
            return (List<Map<String, Object>>)responseData.get('calls');
        } else {
            throw new CalloutException('Failed to list calls: ' + res.getBody());
        }
    }
    
    // ========== PRIVATE HELPER METHODS ==========
    
    /**
     * @description Validate call request before sending to API
     */
    private static void validateCallRequest(CallRequest request) {
        if (request == null) {
            throw new IllegalArgumentException('CallRequest cannot be null');
        }
        
        if (String.isBlank(request.phone_number)) {
            throw new IllegalArgumentException('Phone number is required');
        }
        
        // Validate E.164 format (starts with +, followed by digits)
        if (!Pattern.matches('^\\+[1-9]\\d{1,14}$', request.phone_number)) {
            throw new IllegalArgumentException('Phone number must be in E.164 format: +15555551234');
        }
        
        if (String.isBlank(request.task)) {
            throw new IllegalArgumentException('Task/prompt is required');
        }
    }
    
    /**
     * @description Handle HTTP response from Bland.ai
     */
    private static String handleCallResponse(HttpResponse res) {
        Integer statusCode = res.getStatusCode();
        String responseBody = res.getBody();
        
        if (statusCode == 200 || statusCode == 201) {
            Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
            
            if (result.containsKey('call_id')) {
                return (String)result.get('call_id');
            } else if (result.containsKey('id')) {
                return (String)result.get('id');
            } else {
                throw new CalloutException('Unexpected API response format: ' + responseBody);
            }
        } else {
            String errorMsg = 'Bland.ai API Error [' + statusCode + ']: ' + res.getStatus();
            
            try {
                Map<String, Object> errorResponse = (Map<String, Object>)JSON.deserializeUntyped(responseBody);
                if (errorResponse.containsKey('error')) {
                    errorMsg += ' - ' + errorResponse.get('error');
                }
            } catch (Exception e) {
                errorMsg += ' - ' + responseBody;
            }
            
            logError('makeCall', errorMsg, null);
            throw new CalloutException(errorMsg);
        }
    }
    
    /**
     * @description Log errors to Platform Events or custom object
     */
    private static void logError(String methodName, String errorMessage, Exception ex) {
        // TODO: Implement error logging to Platform Event or custom Error_Log__c object
        System.debug(LoggingLevel.ERROR, 'BlandAICalloutService.' + methodName + ': ' + errorMessage);
        
        if (ex != null) {
            System.debug(LoggingLevel.ERROR, 'Exception: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack Trace: ' + ex.getStackTraceString());
        }
    }
    
    /**
     * @description Custom exception for callout failures
     */
    public class CalloutException extends Exception {}
}
