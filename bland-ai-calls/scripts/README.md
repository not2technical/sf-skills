# Bland.ai Setup Scripts

Scripts for configuring the bland-ai-calls integration.

## 📜 Available Scripts

### `setup-credentials.sh` ⭐

**One-command credential setup for Bland.ai**

**Usage:**
```bash
./scripts/setup-credentials.sh <org-alias>
```

**Example:**
```bash
./scripts/setup-credentials.sh AIZoom
```

**What it does:**
1. ✅ Validates org connection
2. ✅ Prompts for Bland.ai API key (securely - input hidden)
3. ✅ Creates `API_Credentials__c` Custom Setting (if needed)
4. ✅ Stores API key in the org
5. ✅ Provides next steps for deployment and testing

**Get your API key:** https://app.bland.ai/settings/api

---

## 🚀 Complete Setup Flow

### Step 1: Run Setup Script
```bash
cd bland-ai-calls
./scripts/setup-credentials.sh AIZoom
```

**Output:**
```
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        Bland.ai Integration - Credential Setup              ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

► Validating org connection...
✓ Connected to org: AIZoom

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Enter your Bland.ai API key
Get it from: https://app.bland.ai/settings/api
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

API Key (input hidden): [paste your key]

✓ API key received

► Checking for API_Credentials__c Custom Setting...
✓ Custom Setting created

► Creating Bland.ai credential record...
✓ Credential created

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Bland.ai credentials configured successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Next Steps:

1. Deploy the Apex classes:
   sf project deploy start --source-dir bland-ai-calls/templates/ --target-org AIZoom

2. Test with Anonymous Apex:
   BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
   request.phone_number = '+15555551234';
   request.task = 'You are a friendly assistant. Say hello!';

   String callId = BlandAICalloutService.makeCall(request);

3. Configure Remote Site (if needed):
   Setup → Remote Site Settings → New
   Remote Site URL: https://api.bland.ai

🎉 Setup complete! Happy calling!
```

### Step 2: Deploy Apex Classes
```bash
sf project deploy start --source-dir templates/ --target-org AIZoom
```

### Step 3: Test
```apex
// Run in Developer Console → Execute Anonymous

BlandAICalloutService.CallRequest request = new BlandAICalloutService.CallRequest();
request.phone_number = '+15555551234';  // Your test number
request.task = 'You are a sales assistant. Introduce yourself briefly.';
request.voice = 'maya';

String callId = BlandAICalloutService.makeCall(request);
System.debug('✓ Call initiated! Call ID: ' + callId);
```

---

## 🔧 How It Works

The setup script uses **Custom Settings** for credential storage:

### Custom Setting Structure
```
API_Credentials__c (Hierarchy Custom Setting)
├── Name (Text) - "BlandAI"
└── API_Key__c (Text) - Your Bland.ai API key
```

### Apex Usage
```apex
// Retrieve API key
API_Credentials__c cred = API_Credentials__c.getInstance('BlandAI');
String apiKey = cred.API_Key__c;

// Use in HTTP request
HttpRequest req = new HttpRequest();
req.setEndpoint('https://api.bland.ai/v1/calls');
req.setHeader('Authorization', apiKey);
req.setHeader('Content-Type', 'application/json');
```

---

## 🌍 Multi-Org Setup

The script works across multiple orgs:

```bash
# Development org
./scripts/setup-credentials.sh DevOrg
# Enter test API key: sk_test_abc123

# Sandbox org
./scripts/setup-credentials.sh SandboxOrg
# Enter sandbox API key: sk_test_xyz789

# Production org
./scripts/setup-credentials.sh ProdOrg
# Enter production API key: sk_live_prod123
```

Each org stores its own API key independently.

---

## 🔐 Security Notes

### ✅ What the Script Does Right

1. **Secure Input**: API key input is hidden (doesn't echo to terminal)
2. **Protected Storage**: Uses Protected Custom Setting (encrypted at rest)
3. **No Source Control**: Script never writes keys to files
4. **Per-Org Keys**: Each org has its own credential

### ⚠️ Important Reminders

- **Never commit API keys** to source control
- **Use test keys** for dev/sandbox environments
- **Rotate keys regularly** (run script again to update)
- **Clear shell history** if you pass keys as arguments (not recommended)

---

## 🆘 Troubleshooting

### "Cannot connect to org"
**Fix:** Authenticate first
```bash
sf org login web --alias AIZoom
```

### "API key cannot be empty"
**Fix:** Make sure you paste the key when prompted
- Key should start with `sk_` for Bland.ai
- Get it from: https://app.bland.ai/settings/api

### "Unauthorized endpoint" when testing
**Fix:** Configure Remote Site Settings
```bash
sf org open --target-org AIZoom
# Navigate to: Setup → Remote Site Settings → New
# Remote Site URL: https://api.bland.ai
# Check "Active"
# Save
```

### Want to update/change the API key?
**Fix:** Just run the script again
```bash
./scripts/setup-credentials.sh AIZoom
# Enter new API key
```

### Script not executable
**Fix:** Make it executable
```bash
chmod +x scripts/setup-credentials.sh
```

---

## 📊 Alternative Approaches

### Named Credentials (Manual UI Setup)

If you prefer Named Credentials over Custom Settings:

```bash
# 1. Deploy Named Credential structure
sf project deploy start \
  --source-dir templates/bland-api-credential.namedCredential-meta.xml \
  --target-org AIZoom

# 2. Configure in UI
# Setup → Named Credentials → Edit "Bland AI API"
# Password field: [paste API key]
# Save

# 3. Update Apex to use Named Credential
req.setEndpoint('callout:Bland_AI_API/calls');
```

**Trade-offs:**
- ✅ More secure (Salesforce-encrypted)
- ✅ Better for production
- ⚠️ Requires manual UI step
- ⚠️ Can't fully automate

---

## 💡 Pro Tips

### 1. Create an Alias
```bash
# In your ~/.bashrc or ~/.zshrc
alias setup-bland='cd ~/sf-skills/bland-ai-calls && ./scripts/setup-credentials.sh'

# Usage
setup-bland AIZoom
```

### 2. Store Keys in Password Manager
```bash
# macOS Keychain example
security add-generic-password -s "BlandAI-Dev" -a "$USER" -w "sk_test_abc123"

# Retrieve and use
BLAND_KEY=$(security find-generic-password -s "BlandAI-Dev" -w)
# Paste when script prompts
```

### 3. Document Your Keys
```markdown
# .credentials-needed.md (don't commit actual keys!)

## Bland.ai API Keys
- Dev: Get from https://app.bland.ai/settings/api (test key)
- Sandbox: Get from https://app.bland.ai/settings/api (test key)
- Prod: Get from https://app.bland.ai/settings/api (production key)
```

### 4. CI/CD Integration
```yaml
# GitHub Actions example
- name: Configure Bland.ai
  run: |
    echo "${{ secrets.BLAND_API_KEY }}" | \
    ./bland-ai-calls/scripts/setup-credentials.sh ${{ vars.ORG_ALIAS }}
  env:
    BLAND_API_KEY: ${{ secrets.BLAND_API_KEY }}
```

---

## 📚 Related Documentation

- **Quick Start Guide:** `../QUICKSTART.md`
- **Setup Options:** `../SETUP.md`
- **Full Documentation:** `../SKILL.md`
- **Templates:** `../templates/`
- **Examples:** `../examples/`

---

**Ready to make calls?** 📞

```bash
./scripts/setup-credentials.sh AIZoom
```
