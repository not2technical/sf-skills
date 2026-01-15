# Bland.ai Integration Setup Guide

Quick setup guide for the bland-ai-calls skill.

## 🚀 One-Command Setup (Fully Automated) ⚡

**From the sf-skills directory:**

```bash
./bland-ai-calls/scripts/setup-credentials.sh AIZoom
```

**That's it!** The script will:
- ✅ Prompt for your Bland.ai API key (securely)
- ✅ Create the Custom Setting automatically
- ✅ Store your credentials in the org
- ✅ Show you next steps for testing

---

## 📋 Detailed Setup Options

### Option 1: Skill Setup Script (Recommended) ⭐

**One command setup - no UI required:**

```bash
cd bland-ai-calls
./scripts/setup-credentials.sh AIZoom
```

**What happens:**
1. Script prompts for your Bland.ai API key (input hidden)
2. Creates `API_Credentials__c` Custom Setting automatically
3. Stores your API key securely
4. Shows code example for using in Apex

**Get your API key:** https://app.bland.ai/settings/api

---

### Option 2: Named Credentials (Recommended for Production)

**Two-step setup:**

```bash
# Step 1: Deploy Named Credential structure
sf project deploy start \
  --source-dir bland-ai-calls/templates/bland-api-credential.namedCredential-meta.xml \
  --target-org AIZoom

# Step 2: Configure credentials
./scripts/configure-named-credential.sh Bland_AI_API AIZoom
```

**Complete setup in Salesforce UI:**
1. Setup → Named Credentials → Edit "Bland AI API"
2. Paste your API key in the Password field
3. Save

---

## 📝 Update Apex Code (if using Custom Settings)

If you chose **Option 1 (Custom Settings)**, update the `BlandAICalloutService.cls`:

### Before (Named Credential):
```apex
private static final String NAMED_CREDENTIAL = 'callout:Bland_AI_API';
```

### After (Custom Settings):
```apex
private static String getApiKey() {
    API_Credentials__c cred = API_Credentials__c.getInstance('BlandAI');
    if (cred == null || String.isBlank(cred.API_Key__c)) {
        throw new CalloutException('Bland.ai API key not configured');
    }
    return cred.API_Key__c;
}

public static String makeCall(CallRequest request) {
    validateCallRequest(request);

    HttpRequest req = new HttpRequest();
    req.setEndpoint('https://api.bland.ai/v1/calls');  // Direct endpoint
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', getApiKey());  // Use Custom Setting
    req.setBody(JSON.serialize(request, true));
    req.setTimeout(TIMEOUT);

    Http http = new Http();
    HttpResponse res = http.send(req);

    return handleCallResponse(res);
}
```

---

## 🧪 Test Your Integration

```apex
// Run in Developer Console → Execute Anonymous

BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
request.phone_number = '+15555551234';  // Your test number
request.task = 'You are a friendly assistant. Say hello and ask how they are doing.';
request.voice = 'maya';

try {
    String callId = BlandAICalloutService.makeCall(request);
    System.debug('✓ Call initiated! Call ID: ' + callId);
} catch (Exception e) {
    System.debug('❌ Error: ' + e.getMessage());
}
```

---

## 🔄 Switch Between Methods

### From Custom Settings → Named Credentials

```bash
# Deploy Named Credential
sf project deploy start \
  --metadata NamedCredential:Bland_AI_API \
  --target-org AIZoom

# Get your current API key
sf data query \
  --query "SELECT API_Key__c FROM API_Credentials__c WHERE Name='BlandAI'" \
  --target-org AIZoom

# Configure Named Credential in UI with same key
```

### From Named Credentials → Custom Settings

```bash
# Run the setup script
./scripts/set-api-credential.sh BlandAI - AIZoom

# Update Apex code (see "Update Apex Code" section above)
```

---

## 🌍 Multi-Org Setup

```bash
# Development
./scripts/set-api-credential.sh BlandAI - DevOrg
# Enter: sk_test_abc123 (test API key)

# Sandbox
./scripts/set-api-credential.sh BlandAI - SandboxOrg
# Enter: sk_test_xyz789 (sandbox API key)

# Production (use Named Credentials for better security)
sf project deploy start --metadata NamedCredential:Bland_AI_API --target-org ProdOrg
./scripts/configure-named-credential.sh Bland_AI_API ProdOrg
# Configure via UI with production API key
```

---

## 📊 Comparison: Which Method to Use?

| Scenario | Use This | Why |
|----------|----------|-----|
| **Quick testing** | Custom Settings | Fastest setup, fully automated |
| **CI/CD pipeline** | Custom Settings | Can script everything |
| **Production deployment** | Named Credentials | Most secure, encrypted storage |
| **Multiple environments** | Custom Settings | Easy to script per org |
| **OAuth integrations** | Named Credentials | Built-in OAuth support |
| **Learning/Development** | Custom Settings | No UI steps to remember |

---

## 🆘 Troubleshooting

### "API key not configured"
**Fix:** Run setup script again
```bash
./scripts/set-api-credential.sh BlandAI - AIZoom
```

### "Unauthorized endpoint"
**Fix:** Check Remote Site Settings
```bash
sf org open --target-org AIZoom
# Navigate to: Setup → Remote Site Settings → New
# Remote Site URL: https://api.bland.ai
```

### "Invalid phone number"
**Fix:** Use E.164 format
```apex
// ✅ Correct
request.phone_number = '+15555551234';

// ❌ Wrong
request.phone_number = '(555) 555-1234';
request.phone_number = '555-555-1234';
```

---

## 💡 Pro Tips

1. **Use test mode first:**
   - Bland.ai charges per call
   - Test with your own number first
   - Use short prompts during testing

2. **Store credentials per environment:**
   ```bash
   # Dev uses test key
   ./scripts/set-api-credential.sh BlandAI sk_test_dev_key DevOrg

   # Prod uses production key
   ./scripts/set-api-credential.sh BlandAI sk_live_prod_key ProdOrg
   ```

3. **Create a wrapper script:**
   ```bash
   # bland-ai-calls/setup.sh
   #!/bin/bash
   ../scripts/set-api-credential.sh BlandAI - $1
   echo "✓ Bland.ai credentials configured for $1"
   ```

4. **Document your setup:**
   ```markdown
   # .env.example
   BLAND_API_KEY=your-api-key-here
   TARGET_ORG=AIZoom
   ```

---

**Ready to make your first call? 📞**

```bash
# Run the setup
./scripts/set-api-credential.sh BlandAI - AIZoom

# Deploy the Apex classes
sf project deploy start --source-dir bland-ai-calls/templates/ --target-org AIZoom

# Make a test call (see "Test Your Integration" above)
```

For more details, see: [QUICKSTART.md](QUICKSTART.md)
