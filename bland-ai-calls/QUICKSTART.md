# Bland.ai Integration Quick Start Guide

Get your Bland.ai + Salesforce integration up and running in 15 minutes.

## 📋 Prerequisites Checklist

- [ ] Salesforce org (Developer, Sandbox, or Production)
- [ ] Bland.ai account with API key ([Sign up here](https://app.bland.ai))
- [ ] Salesforce CLI installed (`sf` command)
- [ ] Claude Code or compatible AI coding tool

## 🚀 5-Minute Setup

### Quick Start (Recommended) ⚡

**One command to rule them all:**

```bash
# Run the setup script
./scripts/setup-credentials.sh AIZoom
```

The script will prompt for your Bland.ai API key and configure everything automatically!

**Get your API key:** https://app.bland.ai/settings/api

---

### Manual Setup (Alternative)

### Step 1: Get Your Bland.ai API Key

1. Log in to [Bland.ai Dashboard](https://app.bland.ai)
2. Navigate to **Settings → API Keys**
3. Create a new API key
4. Copy the key (you'll need it in Step 3)

### Step 2: Deploy the Skill (Choose One)

**Option A: Claude Code (Recommended)**
```bash
/plugin marketplace add Jaganpro/sf-skills
/plugin install bland-ai-calls
```

**Option B: Manual Install**
```bash
# Clone the repository
git clone https://github.com/Jaganpro/sf-skills
cd sf-skills/bland-ai-calls

# Deploy to your org
sf project deploy start --source-dir templates/ --target-org your-org-alias
```

### Step 3: Configure Named Credential

1. Go to **Setup → Named Credentials**
2. Click **New Named Credential** (or **New** → **Named Credential**)
3. Configure:
   - **Label**: Bland AI API
   - **Name**: `Bland_AI_API`
   - **URL**: `https://api.bland.ai/v1`
   - **Authentication**: **Password Authentication**
   - **Username**: `api`
   - **Password**: [Your Bland.ai API Key from Step 1]
4. Click **Save**

### Step 4: Test the Integration

**Anonymous Apex Test**:
```apex
// Run this in Developer Console → Debug → Open Execute Anonymous Window

BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
request.phone_number = '+15555551234'; // Replace with your test number
request.task = 'You are a friendly assistant. Say hello and ask how the person is doing.';
request.voice = 'maya';

String callId = BlandAICalloutService.makeCall(request);
System.debug('Call initiated! Call ID: ' + callId);

// Check the Call__c object for the record
List<Call__c> calls = [SELECT Id, Bland_Call_ID__c, Status__c FROM Call__c WHERE Bland_Call_ID__c = :callId];
System.debug('Call record created: ' + calls);
```

### Step 5: Set Up Webhook Handler (Optional but Recommended)

1. **Create Salesforce Site**:
   - Setup → Sites → New
   - Name: `BlandWebhooks`
   - Active Site Home Page: Any standard page
   - Active

2. **Enable Public Access**:
   - Sites → Site Label → Public Access Settings
   - Apex Class Access → Add `BlandAIWebhookHandler`
   - Save

3. **Get Webhook URL**:
   ```
   https://[your-domain].my.salesforce-sites.com/services/apexrest/bland/webhook
   ```

4. **Configure in Bland.ai**:
   - Bland.ai Dashboard → Settings → Webhooks
   - Add webhook URL
   - Save

---

## 🎯 Your First Automation

### Scenario: Auto-call qualified leads

**What we'll build**: When a Lead status changes to "Qualified", automatically initiate a Bland.ai call.

### Implementation

**Option 1: Using Flow (No Code)**

1. **Create Record-Triggered Flow**:
   - Setup → Flows → New Flow → Record-Triggered Flow
   - Object: **Lead**
   - Trigger: **A record is updated**
   - Entry Conditions: **Status EQUALS Qualified**

2. **Add Apex Action**:
   - Add Element → Action → **Make Bland.ai Call**
   - Configure inputs:
     - Phone Number: `{!$Record.Phone}`
     - AI Prompt: 
       ```
       You are calling {!$Record.FirstName} {!$Record.LastName} from {!$Record.Company}.
       Introduce yourself as a sales representative from [Your Company].
       Explain that they were marked as a qualified lead.
       Ask if they'd like to schedule a product demo.
       Be friendly and conversational.
       ```
     - Related Record ID: `{!$Record.Id}`
     - Voice: `maya`
     - Language: `en`

3. **Save and Activate**:
   - Name: `Auto Call Qualified Leads`
   - API Name: `Auto_Call_Qualified_Leads`
   - Activate ✅

**Option 2: Using Apex Trigger (With Code)**

```apex
trigger LeadTrigger on Lead (after update) {
    List<BlandAICallQueueable.CallQueueItem> callQueue = new List<BlandAICallQueueable.CallQueueItem>();
    
    for (Lead lead : Trigger.new) {
        Lead oldLead = Trigger.oldMap.get(lead.Id);
        
        // Check if status changed to Qualified and has phone number
        if (lead.Status == 'Qualified' 
            && oldLead.Status != 'Qualified' 
            && String.isNotBlank(lead.Phone)) {
            
            BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
            request.phone_number = lead.Phone;
            request.task = 'You are calling ' + lead.FirstName + ' ' + lead.LastName + 
                          ' from ' + lead.Company + '. Introduce yourself and offer to schedule a demo.';
            request.voice = 'maya';
            
            callQueue.add(new BlandAICallQueueable.CallQueueItem(request, lead.Id));
        }
    }
    
    if (!callQueue.isEmpty()) {
        System.enqueueJob(new BlandAICallQueueable(callQueue));
    }
}
```

### Test It

1. **Update a Lead**:
   - Open any Lead record
   - Change Status to **Qualified**
   - Save

2. **Verify**:
   - Check the **Call__c** object for a new record
   - Status should be "Queued" or "In Progress"
   - Phone should ring within 5-10 seconds

3. **Review Results**:
   - After call completes, check Call record for:
     - Status: "Completed"
     - Duration
     - Recording URL
     - Transcript (available ~60 seconds after call ends)

---

## 📊 Monitor Your Calls

### Create a Dashboard

1. **Create Report**:
   - Reports → New Report → **Calls**
   - Add columns: Status, Duration, Cost, Created Date, Related To
   - Group by: Status
   - Chart: Donut chart showing status distribution

2. **Create Dashboard**:
   - Dashboards → New Dashboard
   - Add component: **Call Status Distribution** (from report above)
   - Add component: **Calls This Week** (filter: Created Date = THIS_WEEK)
   - Add component: **Total Call Cost This Month** (sum of Cost field)

### Key Metrics to Track

- **Total Calls**: Count of Call__c records
- **Answer Rate**: % where Status = "Completed" vs "No Answer"
- **Average Duration**: Average of Duration__c field
- **Cost Analysis**: Sum of Cost__c field grouped by month
- **Sentiment**: Count of calls by Sentiment__c field

---

## 🔧 Troubleshooting

### Issue: "Unauthorized endpoint" error

**Cause**: Named Credential not configured or API key invalid

**Fix**:
1. Verify Named Credential exists: Setup → Named Credentials → `Bland_AI_API`
2. Test API key in Bland.ai dashboard
3. Re-save Named Credential with correct API key

### Issue: Calls not connecting

**Cause**: Invalid phone number format

**Fix**: Ensure phone numbers are in E.164 format:
- ✅ Correct: `+15555551234`
- ❌ Wrong: `555-555-1234`, `(555) 555-1234`

**Apex helper**:
```apex
public static String formatPhoneE164(String phone, String countryCode) {
    // Strip non-digits
    String digits = phone.replaceAll('\\D', '');
    
    // Add country code if missing
    if (!digits.startsWith(countryCode)) {
        digits = countryCode + digits;
    }
    
    return '+' + digits;
}

// Usage
String formatted = formatPhoneE164('(555) 555-1234', '1'); // Returns +15555551234
```

### Issue: Webhooks not received

**Cause**: Site not public or REST class not accessible

**Fix**:
1. Verify Site is **Active**: Setup → Sites → [Your Site] → Active = ✅
2. Check Public Access: Sites → Public Access Settings → Apex Class Access → `BlandAIWebhookHandler` present
3. Test webhook URL in browser (should return JSON response)

### Issue: Rate limit errors

**Cause**: Exceeded Bland.ai rate limits

**Fix**:
1. Check your Bland.ai plan limits
2. Implement queueing pattern (see [rate-limit-handling.md](docs/rate-limit-handling.md))
3. Reduce batch size in Queueable jobs

---

## 📚 Next Steps

### Explore Advanced Features

1. **[Webhook Events Guide](docs/webhook-events-guide.md)**: Handle call lifecycle events
2. **[Flow Integration Guide](docs/flow-integration-guide.md)**: Build complex voice workflows
3. **[Call Logging Patterns](docs/call-logging-patterns.md)**: Best practices for data storage
4. **[Rate Limit Handling](docs/rate-limit-handling.md)**: Scale to thousands of calls

### Use Cases to Build

- **Appointment Reminders**: Daily scheduled flow
- **Post-Case Surveys**: Trigger on Case closure
- **Lead Nurturing Campaigns**: Weekly follow-ups
- **Emergency Notifications**: Critical alerts
- **Customer Onboarding**: Welcome calls for new customers

### Join the Community

- **GitHub Issues**: Report bugs or request features
- **Bland.ai Community**: Share use cases and patterns
- **Trailblazer Community**: Connect with other Salesforce devs

---

## 🆘 Getting Help

**Bland.ai API Issues**:
- Documentation: https://docs.bland.ai
- Support: support@bland.ai

**Salesforce Integration Issues**:
- GitHub Issues: [Create an issue](https://github.com/Jaganpro/sf-skills/issues)
- Trailblazer Community: [Ask a question](https://trailblazers.salesforce.com)

**Skill-Specific Questions**:
- Review full documentation in `/docs` folder
- Check templates in `/templates` folder
- Run validation hook to score your integration

---

**Happy building! 🎉**
