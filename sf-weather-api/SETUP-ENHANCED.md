# Visual Crossing Weather API - Enhanced Named Credentials Setup

**Modern approach using External Credentials + Named Credentials + ConnectApi**

---

## 🚀 Quick Setup (4 Steps)

### Step 1: Deploy External Credential

```bash
cd sf-weather-api
sf project deploy start \
  --source-dir templates/VisualCrossingWeather.externalCredential-meta.xml \
  --target-org AIZoom
```

### Step 2: Deploy Named Credential + CSP Trusted Site

```bash
sf project deploy start \
  --source-dir templates/VisualCrossingWeatherAPI.namedCredential-meta.xml \
  --source-dir templates/VisualCrossingWeatherAPI.cspTrustedSite-meta.xml \
  --target-org AIZoom
```

### Step 3: Set API Key

```bash
cd ..
./scripts/configure-named-credential.sh VisualCrossingWeather weatherAPIKey AIZoom
# Enter your API key when prompted
```

**Get your API key:** https://www.visualcrossing.com/account (Free tier: 1,000 records/day)

### Step 4: Test with Apex

```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:VisualCrossingWeatherAPI/VisualCrossingWebServices/rest/services/timeline/London');
req.setMethod('GET');

Http http = new Http();
HttpResponse res = http.send(req);
System.debug(res.getBody());
```

---

## 📦 What Gets Deployed

### 1. External Credential (VisualCrossingWeather)
- **Stores:** API key securely encrypted
- **Auth Protocol:** Custom
- **Principal:** weatherAPIKey

### 2. Named Credential (VisualCrossingWeatherAPI)
- **Base URL:** https://weather.visualcrossing.com
- **References:** VisualCrossingWeather External Credential
- **Type:** SecuredEndpoint (Enhanced Named Credential)

### 3. CSP Trusted Site (VisualCrossingWeatherAPI)
- **Endpoint:** https://weather.visualcrossing.com
- **Allows:** Outbound HTTP callouts
- **Context:** All

---

## ✅ Verification

After setup, verify in Salesforce UI:

1. **Setup → External Credentials → VisualCrossingWeather**
   - Should show principal "weatherAPIKey" with credential set

2. **Setup → Named Credentials → VisualCrossingWeatherAPI**
   - Should show "VisualCrossingWeather" External Credential linked
   - Base URL should be https://weather.visualcrossing.com

3. **Setup → CSP Trusted Sites → VisualCrossingWeatherAPI**
   - Should show endpoint URL and Active status

---

## 🔍 Troubleshooting

### "External Credential not found"
Deploy External Credential first (Step 1)

### "Named Credential deployment failed"
External Credential must exist before deploying Named Credential

### "Unable to connect to endpoint"
Deploy CSP Trusted Site (Step 2)

### API key not working
- Verify key at https://www.visualcrossing.com/account
- Re-run configure script (Step 3)

---

## 📚 API Usage Examples

### Simple Weather Lookup
```apex
HttpRequest req = new HttpRequest();
req.setEndpoint('callout:VisualCrossingWeatherAPI/VisualCrossingWebServices/rest/services/timeline/San Francisco, CA');
req.setMethod('GET');

Http http = new Http();
HttpResponse res = http.send(req);

if (res.getStatusCode() == 200) {
    Map<String, Object> weatherData = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    System.debug('Location: ' + weatherData.get('resolvedAddress'));
    System.debug('Current Temp: ' + weatherData.get('currentConditions'));
}
```

### Date Range Query
```apex
String location = 'New York, NY';
String startDate = '2026-01-14';
String endDate = '2026-01-21';

HttpRequest req = new HttpRequest();
req.setEndpoint('callout:VisualCrossingWeatherAPI/VisualCrossingWebServices/rest/services/timeline/' +
                EncodingUtil.urlEncode(location, 'UTF-8') + '/' + startDate + '/' + endDate);
req.setMethod('GET');

Http http = new Http();
HttpResponse res = http.send(req);
```

**Note:** The API key is automatically included! No need to append `?key=...` to the URL.

---

## 🎯 Why This Approach?

✅ **Secure** - API key encrypted by Salesforce
✅ **No hardcoding** - Credentials separate from code
✅ **Portable** - Easy to change API keys per org
✅ **Modern** - Salesforce recommended approach
✅ **No query parameters** - API key handled automatically

---

## 🔄 Updating API Key

To change your API key:

```bash
./scripts/configure-named-credential.sh VisualCrossingWeather weatherAPIKey AIZoom
# Enter new API key when prompted
```

The script automatically detects existing credentials and updates them.

---

**Free tier includes 1,000 API calls per day!**
