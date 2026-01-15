# Example: Automated Appointment Reminders

Complete implementation guide for building an automated appointment reminder system using Bland.ai and Salesforce.

## Use Case

**Goal**: Automatically call customers 24 hours before their scheduled appointments to:
- Remind them of the appointment
- Confirm they can still make it
- Offer to reschedule if needed
- Reduce no-shows

## Architecture

```
Scheduled Flow (Daily at 9 AM)
    ↓
Query Events (ActivityDate = TOMORROW)
    ↓
Loop through Events
    ↓
Apex Action: Make Bland.ai Call
    ↓
Create Call__c record
    ↓
Bland.ai makes call
    ↓
Webhook updates Call__c with result
    ↓
If no answer → Create follow-up task
```

## Implementation

### Step 1: Create Custom Fields on Event

Add these fields to the Event object:

```xml
<!-- Event.Reminder_Call_Sent__c -->
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Reminder_Call_Sent__c</fullName>
    <label>Reminder Call Sent</label>
    <type>Checkbox</type>
    <defaultValue>false</defaultValue>
</CustomField>

<!-- Event.Reminder_Call_Status__c -->
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Reminder_Call_Status__c</fullName>
    <label>Reminder Call Status</label>
    <type>Picklist</type>
    <valueSet>
        <valueSetDefinition>
            <value><fullName>Not Sent</fullName></value>
            <value><fullName>Sent</fullName></value>
            <value><fullName>Answered</fullName></value>
            <value><fullName>No Answer</fullName></value>
            <value><fullName>Failed</fullName></value>
        </valueSetDefinition>
    </valueSet>
</CustomField>

<!-- Event.Customer_Phone__c (if not using standard fields) -->
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>Customer_Phone__c</fullName>
    <label>Customer Phone</label>
    <type>Phone</type>
</CustomField>
```

### Step 2: Create Invocable Apex Action

```apex
/**
 * @description Invocable method for making appointment reminder calls
 */
public with sharing class AppointmentReminderActions {
    
    @InvocableMethod(
        label='Send Appointment Reminder Call'
        description='Makes a Bland.ai call to remind customer about appointment'
        category='Appointments'
    )
    public static List<Response> sendReminderCall(List<Request> requests) {
        List<Response> responses = new List<Response>();
        
        for (Request req : requests) {
            Response res = new Response();
            
            try {
                // Validate phone number
                if (String.isBlank(req.phoneNumber)) {
                    throw new IllegalArgumentException('Phone number is required');
                }
                
                // Build AI prompt
                String prompt = buildReminderPrompt(
                    req.customerName,
                    req.appointmentDateTime,
                    req.appointmentLocation,
                    req.appointmentType
                );
                
                // Create call request
                BlandAICalloutService.CallRequest callReq = new BlandAICalloutService.CallRequest();
                callReq.phone_number = req.phoneNumber;
                callReq.task = prompt;
                callReq.voice = 'maya';
                callReq.language = 'en';
                callReq.max_duration = 180; // 3 minutes max
                
                // Make the call
                String callId = BlandAICalloutService.makeCall(callReq);
                
                // Create Call record
                Call__c call = new Call__c(
                    Bland_Call_ID__c = callId,
                    Related_To__c = req.eventId,
                    Status__c = 'Queued',
                    Phone_Number__c = req.phoneNumber,
                    Call_Type__c = 'Appointment Reminder',
                    Queued_At__c = Datetime.now()
                );
                insert call;
                
                res.isSuccess = true;
                res.callId = callId;
                res.callRecordId = call.Id;
                res.message = 'Reminder call initiated successfully';
                
            } catch (Exception e) {
                res.isSuccess = false;
                res.message = 'Error: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, 'Reminder call failed: ' + e.getMessage());
            }
            
            responses.add(res);
        }
        
        return responses;
    }
    
    /**
     * @description Build AI prompt for appointment reminder
     */
    private static String buildReminderPrompt(
        String customerName,
        Datetime appointmentDateTime,
        String location,
        String appointmentType
    ) {
        String dayOfWeek = appointmentDateTime.format('EEEE');
        String timeOfDay = appointmentDateTime.format('h:mm a');
        String dateFormatted = appointmentDateTime.format('MMMM d');
        
        String prompt = 'You are calling ' + customerName + ' to remind them about their appointment.\n\n';
        prompt += 'Appointment Details:\n';
        prompt += '- Date: ' + dayOfWeek + ', ' + dateFormatted + '\n';
        prompt += '- Time: ' + timeOfDay + '\n';
        
        if (String.isNotBlank(location)) {
            prompt += '- Location: ' + location + '\n';
        }
        
        if (String.isNotBlank(appointmentType)) {
            prompt += '- Type: ' + appointmentType + '\n';
        }
        
        prompt += '\nYour script:\n';
        prompt += '1. Greet the customer by name\n';
        prompt += '2. Remind them about their appointment tomorrow\n';
        prompt += '3. Ask if they can still make it\n';
        prompt += '4. If they say NO, offer to help reschedule\n';
        prompt += '5. If they say YES, thank them and remind them to arrive 10 minutes early\n';
        prompt += '6. End the call politely\n\n';
        prompt += 'Be warm, friendly, and professional. Keep the call under 2 minutes.';
        
        return prompt;
    }
    
    public class Request {
        @InvocableVariable(label='Event ID' required=true)
        public Id eventId;
        
        @InvocableVariable(label='Customer Name' required=true)
        public String customerName;
        
        @InvocableVariable(label='Phone Number' required=true)
        public String phoneNumber;
        
        @InvocableVariable(label='Appointment Date/Time' required=true)
        public Datetime appointmentDateTime;
        
        @InvocableVariable(label='Appointment Location' required=false)
        public String appointmentLocation;
        
        @InvocableVariable(label='Appointment Type' required=false)
        public String appointmentType;
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

### Step 3: Create Scheduled Flow

**Flow Name**: `Daily_Appointment_Reminders`

**Flow Type**: Scheduled Flow

**Schedule**: Daily at 9:00 AM

**Flow Steps**:

1. **Get Records** - Query tomorrow's appointments
   - Object: `Event`
   - Filter Conditions:
     - `ActivityDate EQUALS {!$Flow.CurrentDate + 1}`
     - `Customer_Phone__c NOT EQUALS null`
     - `Reminder_Call_Sent__c EQUALS false`
   - Store in: `EventCollection`

2. **Decision** - Check if any events found
   - Outcome: `Has Events`
   - Condition: `{!EventCollection} Is Null = false`

3. **Loop** - Process each event
   - Collection: `{!EventCollection}`
   - Direction: `First item to last item`

4. **Get Records** - Get Contact/Lead for customer name
   - Object: Based on `{!Event.WhoId}` object type
   - Store in: `CustomerRecord`

5. **Action** - Send Reminder Call
   - Action: `Send Appointment Reminder Call`
   - Inputs:
     - Event ID: `{!Event.Id}`
     - Customer Name: `{!CustomerRecord.Name}`
     - Phone Number: `{!Event.Customer_Phone__c}`
     - Appointment Date/Time: `{!Event.StartDateTime}`
     - Appointment Location: `{!Event.Location}`
     - Appointment Type: `{!Event.Subject}`
   - Store Output: `CallResponse`

6. **Update Records** - Mark event as processed
   - Record: `{!Event}`
   - Fields:
     - `Reminder_Call_Sent__c = true`
     - `Reminder_Call_Status__c = Sent`

7. **Decision** - Check if call failed
   - Outcome: `Call Failed`
   - Condition: `{!CallResponse.isSuccess} EQUALS false`

8. **Create Records** - Create follow-up task if failed
   - Object: `Task`
   - Fields:
     - `WhatId = {!Event.Id}`
     - `Subject = Failed to send reminder call`
     - `Description = {!CallResponse.message}`
     - `Status = Not Started`
     - `Priority = High`

### Step 4: Create Webhook Handler for Status Updates

Extend the webhook handler to update Event records:

```apex
/**
 * @description Update Event when reminder call completes
 */
private static void handleCallCompleted(String callId, Map<String, Object> data) {
    // Find Call record
    List<Call__c> calls = [
        SELECT Id, Related_To__c, Status__c 
        FROM Call__c 
        WHERE Bland_Call_ID__c = :callId 
        LIMIT 1
    ];
    
    if (calls.isEmpty()) return;
    
    Call__c call = calls[0];
    Boolean answered = (Boolean)data.get('answered');
    
    // Update Call record
    call.Status__c = answered ? 'Completed' : 'No Answer';
    call.Duration__c = (Decimal)data.get('duration');
    call.Recording_URL__c = (String)data.get('recording_url');
    call.Completed_At__c = Datetime.now();
    update call;
    
    // Update related Event if it's an appointment
    if (call.Related_To__c != null && 
        String.valueOf(call.Related_To__c).startsWith('00U')) { // Event ID prefix
        
        Event evt = [SELECT Id, Reminder_Call_Status__c FROM Event WHERE Id = :call.Related_To__c];
        evt.Reminder_Call_Status__c = answered ? 'Answered' : 'No Answer';
        update evt;
        
        // If no answer, create follow-up task
        if (!answered) {
            Task followUp = new Task(
                WhatId = evt.Id,
                Subject = 'Follow up - Reminder call not answered',
                Status = 'Not Started',
                Priority = 'Normal',
                ActivityDate = Date.today()
            );
            insert followUp;
        }
    }
}
```

### Step 5: Create Report and Dashboard

**Report: Reminder Call Effectiveness**

- Object: Events with Calls
- Columns:
  - Subject
  - Start Date/Time
  - Reminder Call Status
  - Call Duration
  - Recording URL
- Group by: Reminder Call Status
- Chart: Donut chart showing status distribution

**Dashboard Components**:

1. **Calls This Week**: Count of reminder calls sent
2. **Answer Rate**: % of calls answered vs. no answer
3. **No-Show Rate**: Compare before/after implementing reminders
4. **Average Call Duration**: Track efficiency

## Testing

### Test Scenario 1: Successful Reminder

```apex
@IsTest
static void testSuccessfulReminder() {
    // Create test contact
    Contact contact = new Contact(
        FirstName = 'John',
        LastName = 'Doe',
        Phone = '+15555551234'
    );
    insert contact;
    
    // Create test event (tomorrow)
    Event evt = new Event(
        Subject = 'Dental Appointment',
        StartDateTime = Datetime.now().addDays(1).addHours(10),
        EndDateTime = Datetime.now().addDays(1).addHours(11),
        WhoId = contact.Id,
        Customer_Phone__c = contact.Phone,
        Location = '123 Main St',
        Reminder_Call_Sent__c = false
    );
    insert evt;
    
    // Setup mock
    Test.setMock(HttpCalloutMock.class, new BlandAIMockSuccess());
    
    // Create request
    AppointmentReminderActions.Request req = new AppointmentReminderActions.Request();
    req.eventId = evt.Id;
    req.customerName = 'John Doe';
    req.phoneNumber = contact.Phone;
    req.appointmentDateTime = evt.StartDateTime;
    req.appointmentLocation = evt.Location;
    req.appointmentType = evt.Subject;
    
    Test.startTest();
    List<AppointmentReminderActions.Response> responses = 
        AppointmentReminderActions.sendReminderCall(new List<AppointmentReminderActions.Request>{ req });
    Test.stopTest();
    
    // Verify
    Assert.areEqual(1, responses.size());
    Assert.isTrue(responses[0].isSuccess);
    
    // Verify Call record created
    List<Call__c> calls = [SELECT Id, Status__c FROM Call__c WHERE Related_To__c = :evt.Id];
    Assert.areEqual(1, calls.size());
    Assert.areEqual('Queued', calls[0].Status__c);
}
```

### Manual Testing

1. **Create Test Event**:
   - Subject: "Test Appointment"
   - Start Date: Tomorrow at 2:00 PM
   - Related To: Test Contact with valid phone
   - Customer Phone: Your test number

2. **Run Flow Manually**:
   - Setup → Flows → Daily_Appointment_Reminders
   - Click **Run**

3. **Verify**:
   - Check Call__c object for new record
   - Phone should ring within 10 seconds
   - After call, check Event for updated Reminder_Call_Status__c

## Enhancements

### Enhancement 1: Multi-Language Support

```apex
// Detect customer language from Contact
String language = 'en';
String voice = 'maya';

if (contact.Language__c == 'Spanish') {
    language = 'es';
    voice = 'miguel';
} else if (contact.Language__c == 'French') {
    language = 'fr';
    voice = 'marie';
}
```

### Enhancement 2: Smart Scheduling

Don't call too early or too late:

```apex
// In Flow, add Decision before Action
Time callTime = Time.newInstance(9, 0, 0, 0); // 9 AM
Time endTime = Time.newInstance(20, 0, 0, 0); // 8 PM
Time now = Time.newInstance(Datetime.now().hour(), Datetime.now().minute(), 0, 0);

if (now < callTime || now > endTime) {
    // Queue for later
} else {
    // Make call now
}
```

### Enhancement 3: Retry Logic

If no answer, retry once in the evening:

```apex
// In webhook handler
if (!answered && call.Retry_Count__c < 1) {
    // Schedule retry for 6 PM
    Datetime retryTime = Datetime.newInstance(
        Date.today(),
        Time.newInstance(18, 0, 0, 0)
    );
    
    // Create Platform Event to trigger retry
    Bland_Call_Retry__e retryEvent = new Bland_Call_Retry__e(
        Call_Id__c = call.Id,
        Retry_At__c = retryTime
    );
    EventBus.publish(retryEvent);
}
```

## Results

After implementing this system, you should see:

- **📉 30-50% reduction in no-shows**
- **📞 80%+ answer rate** (if calling during business hours)
- **⏱️ Average call duration: 60-90 seconds**
- **💰 ROI: Saved appointment slots = increased revenue**

## See Also

- [Flow Integration Guide](../docs/flow-integration-guide.md)
- [Webhook Events Guide](../docs/webhook-events-guide.md)
- [Call Logging Patterns](../docs/call-logging-patterns.md)
