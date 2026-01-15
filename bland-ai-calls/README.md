# bland-ai-calls: Bland.ai Phone Call Integration

> 📞 **Integrate Bland.ai's powerful voice AI with Salesforce for automated calls, webhooks, and call logging**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Expert integration skill for connecting Bland.ai phone call API with Salesforce, enabling automated outbound calls, webhook handling, call logging, and voice-enabled workflows.

## 🎯 What This Skill Does

- **Automated Outbound Calls**: Trigger calls from Salesforce events (Lead qualified, Case closed, etc.)
- **Call Logging**: Automatically log call data, recordings, and transcripts to Salesforce
- **Webhook Handling**: Receive real-time updates from Bland.ai (call status, transcripts)
- **Voice Workflows**: Integrate with Flow for voice-enabled automation
- **Bulk Call Management**: Queue and process hundreds of calls with rate limit handling

## 🚀 Quick Start

### Prerequisites

- Salesforce org with API access
- Bland.ai account and API key ([Get one here](https://app.bland.ai/))
- Salesforce CLI (`sf`)
- Python 3.10+ (for validation hooks)

### Installation

**Claude Code:**
```bash
/plugin marketplace add Jaganpro/sf-skills
/plugin install bland-ai-calls
```

**Other CLIs:**
```bash
python tools/installer.py --cli <your-cli> --skills bland-ai-calls
```

### Basic Usage

**1. Make an Outbound Call**
```
"Create a Bland.ai integration to call qualified leads"
"Set up automated appointment reminder calls"
```

**2. Handle Webhooks**
```
"Create webhook handler for Bland.ai call completion events"
"Log call transcripts to custom Call object"
```

**3. Build Voice Workflows**
```
"Create Flow that triggers Bland.ai call when Case is closed"
"Set up daily scheduled flow for appointment reminders"
```

## 📚 Features

### Core Capabilities

| Feature | Description | Template |
|---------|-------------|----------|
| **Named Credential** | Secure API key storage | `bland-api-credential.namedCredential-meta.xml` |
| **Callout Service** | Apex wrapper for Bland.ai API | `BlandAICalloutService.cls` |
| **Webhook Handler** | Receive call status updates | `BlandAIWebhookHandler.cls` |
| **Call Logger** | Log to Tasks or custom Call__c | `BlandAICallLogger.cls` |
| **Queueable Jobs** | Bulk call processing | `BlandAICallQueueable.cls` |

### Bland.ai API Features Supported

- ✅ Initiate outbound calls
- ✅ Retrieve call status and details
- ✅ Get call recordings
- ✅ Get call transcripts
- ✅ List all calls
- ✅ Webhook events (started, completed, transcript ready)

## 🏗️ Architecture

```
Salesforce Trigger/Flow
    ↓
Apex Callout Service (Named Credential)
    ↓
Bland.ai API (Make Call)
    ↓
Bland.ai Webhook → Salesforce REST Endpoint
    ↓
Update Call__c / Create Task
```

## 📖 Documentation

- **[Webhook Events Guide](docs/webhook-events-guide.md)** - Complete webhook reference
- **[Call Logging Patterns](docs/call-logging-patterns.md)** - Best practices for logging calls
- **[Flow Integration Guide](docs/flow-integration-guide.md)** - Connect with Salesforce Flow
- **[Rate Limit Handling](docs/rate-limit-handling.md)** - Manage API limits

## 🎨 Templates

All templates are in the `templates/` directory:

### Metadata
- `bland-api-credential.namedCredential-meta.xml` - Named Credential for API authentication
- `Call__c.object-meta.xml` - Custom object for call tracking

### Apex Classes
- `BlandAICalloutService.cls` - Main API service
- `BlandAIWebhookHandler.cls` - Webhook REST endpoint
- `BlandAICallLogger.cls` - Call logging utility
- `BlandAICallQueueable.cls` - Async call queueing
- `BlandAICalloutServiceTest.cls` - Test class

## 🧪 Testing

The skill includes comprehensive test classes:

```bash
# Run all tests
sf apex run test --class-names BlandAICalloutServiceTest --target-org your-org --test-level RunLocalTests

# Check coverage
sf apex get test --test-run-id <test-run-id> --target-org your-org
```

## 🔐 Security Best Practices

- ✅ Use Named Credentials (never hardcode API keys)
- ✅ Implement webhook signature verification
- ✅ Use `with sharing` on all Apex classes
- ✅ Validate phone numbers before calling
- ✅ Log all API errors for auditing

## 📊 Scoring System

Every integration is scored against **100 points** across 5 categories:

| Category | Points | Focus |
|----------|--------|-------|
| **Security** | 25 | Named Credentials, webhook security |
| **Error Handling** | 25 | Retry logic, validation, logging |
| **Data Management** | 20 | Call records, transcripts, recordings |
| **Architecture** | 20 | Async patterns, service layer |
| **Best Practices** | 10 | Rate limits, bulk processing |

**Thresholds**: 90+ = Excellent | 80-89 = Very Good | 70-79 = Good | 60-69 = Needs Work | <60 = Block

## 🔗 Related Skills

- **sf-integration**: General integration patterns and Named Credentials
- **sf-apex**: Custom Apex logic for call routing
- **sf-flow**: Voice-enabled automation workflows
- **sf-metadata**: Custom object and field creation
- **sf-deploy**: Deployment automation

## 🤝 Contributing

Contributions are welcome! See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

## 📄 License

MIT License - Copyright (c) 2026

## 🆘 Support

- [Bland.ai Documentation](https://docs.bland.ai/)
- [Bland.ai Support](https://bland.ai/support)
- [GitHub Issues](https://github.com/Jaganpro/sf-skills/issues)

---

**Made with ❤️ for the Salesforce community**
