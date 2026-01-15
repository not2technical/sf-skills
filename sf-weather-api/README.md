# Visual Crossing Weather API Integration

Integration skill for fetching weather data from Visual Crossing Weather API into Salesforce.

## 🌤️ Features

- Real-time weather data retrieval
- Historical weather data access
- Weather forecasts (up to 15 days)
- Automatic credential and endpoint security configuration
- Support for both modern (CSP Trusted Sites) and legacy (Remote Site Settings) orgs

## 🚀 Quick Setup

### One Command Installation

```bash
cd sf-weather-api
./scripts/setup-credentials.sh AIZoom
```

**What it does:**
1. ✅ Prompts for your Visual Crossing API key (securely)
2. ✅ Creates Custom Setting for credential storage
3. ✅ Deploys CSP Trusted Site or Remote Site Setting
4. ✅ Stores API key in Salesforce org

**Get your API key:** https://www.visualcrossing.com/account

**Free tier:** 1,000 records/day

---

## 📋 API Information

**Base URL:** `https://weather.visualcrossing.com`

**Endpoint:** `/VisualCrossingWebServices/rest/services/timeline/{location}`

**Authentication:** API Key via query parameter

**Documentation:** https://www.visualcrossing.com/resources/documentation/weather-api/

---

## 🧪 Testing

### Anonymous Apex Test

```apex
// Retrieve API key from Custom Setting
API_Credentials__c cred = API_Credentials__c.getInstance('VisualCrossingWeather');
String apiKey = cred.API_Key__c;

// Build endpoint
String location = 'New York, NY';
String endpoint = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/'
                  + EncodingUtil.urlEncode(location, 'UTF-8')
                  + '?key=' + apiKey
                  + '&unitGroup=metric&contentType=json';

// Make HTTP request
HttpRequest req = new HttpRequest();
req.setEndpoint(endpoint);
req.setMethod('GET');
req.setTimeout(60000);

Http http = new Http();
HttpResponse res = http.send(req);

// Process response
if (res.getStatusCode() == 200) {
    Map<String, Object> weatherData = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    System.debug('Location: ' + weatherData.get('resolvedAddress'));

    List<Object> days = (List<Object>)weatherData.get('days');
    for (Object dayObj : days) {
        Map<String, Object> day = (Map<String, Object>)dayObj;
        System.debug('Date: ' + day.get('datetime')
                     + ', Max: ' + day.get('tempmax') + '°C'
                     + ', Min: ' + day.get('tempmin') + '°C');
    }
} else {
    System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
}
```

---

## 📊 Use Cases

### 1. Weather-Based Alerts
Trigger notifications when weather conditions affect business operations

### 2. Field Service Optimization
Schedule field technicians based on weather forecasts

### 3. Event Planning
Check weather for upcoming events and meetings

### 4. Sales Intelligence
Correlate weather patterns with sales data

### 5. Logistics Planning
Route optimization based on weather conditions

---

## 🔐 Security

- **API Key Storage:** Protected Custom Setting (encrypted at rest)
- **Endpoint Security:** Automatic CSP Trusted Site or Remote Site Setting deployment
- **HTTPS Only:** All connections encrypted (disableProtocolSecurity=false)

---

## 📈 Rate Limits

| Tier | Records/Day | Cost |
|------|-------------|------|
| **Free** | 1,000 | Free |
| **Starter** | 10,000 | $9/month |
| **Professional** | 50,000 | $29/month |
| **Enterprise** | 500,000+ | Custom |

---

## 🆘 Troubleshooting

### "API key cannot be empty"
**Fix:** Make sure you paste your API key when prompted
- Get it from: https://www.visualcrossing.com/account

### "Unauthorized" (401 error)
**Fix:** Invalid API key
- Verify key at: https://www.visualcrossing.com/account
- Run setup script again to update: `./scripts/setup-credentials.sh AIZoom`

### "Too Many Requests" (429 error)
**Fix:** Rate limit exceeded
- Check your usage at: https://www.visualcrossing.com/account
- Upgrade plan or wait for limit reset (midnight UTC)

### "Unable to connect to endpoint"
**Fix:** Endpoint security not configured
- Script should have configured this automatically
- Verify: Setup → CSP Trusted Sites → VisualCrossingWeatherAPI
- Or: Setup → Remote Site Settings → VisualCrossingWeatherAPI

---

## 📚 API Response Structure

```json
{
  "resolvedAddress": "New York, NY, United States",
  "days": [
    {
      "datetime": "2026-01-14",
      "tempmax": 8.5,
      "tempmin": 2.1,
      "temp": 5.3,
      "humidity": 65.2,
      "precip": 0.0,
      "conditions": "Partially cloudy",
      "description": "Partly cloudy throughout the day."
    }
  ]
}
```

---

## 🔄 Updating API Key

To update your API key:

```bash
./scripts/setup-credentials.sh AIZoom
# Enter new API key when prompted
```

---

## 🌍 Supported Locations

- **City names:** "New York, NY"
- **ZIP codes:** "10001"
- **Coordinates:** "40.7128,-74.0060"
- **Addresses:** "1600 Amphitheatre Parkway, Mountain View, CA"

---

## 📖 Example Python Equivalent

The Python code that inspired this integration:

```python
import json
import urllib.request

API_KEY = "YOUR_API_KEY"
LOCATION = "New York, NY"
BASE_URL = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/"

url = f"{BASE_URL}{urllib.parse.quote_plus(LOCATION)}?key={API_KEY}&unitGroup=metric&contentType=json"

with urllib.request.urlopen(url) as response:
    weather_data = json.loads(response.read().decode())

for day in weather_data.get('days', []):
    print(f"Date: {day['datetime']}, Max: {day['tempmax']}°C, Min: {day['tempmin']}°C")
```

---

**Ready to integrate weather data?** ☀️

```bash
./scripts/setup-credentials.sh AIZoom
```
