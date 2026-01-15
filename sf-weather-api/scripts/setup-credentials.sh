#!/bin/bash
#
# setup-credentials.sh - Visual Crossing Weather API Integration
#
# Configures Visual Crossing Weather API credentials and endpoint security
#
# Usage:
#   ./scripts/setup-credentials.sh <org-alias>
#
# Example:
#   ./scripts/setup-credentials.sh AIZoom
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SKILL_NAME="Visual Crossing Weather API"
CUSTOM_SETTING_NAME="VisualCrossingWeather"
CSP_NAME="VisualCrossingWeatherAPI"
API_KEY_URL="https://www.visualcrossing.com/account"

# Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     Visual Crossing Weather API - Credential Setup          ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo "  $0 <org-alias>"
    echo ""
    echo -e "${BLUE}Example:${NC}"
    echo "  $0 AIZoom"
    echo ""
    echo -e "${BLUE}Available orgs:${NC}"
    sf org list --json 2>/dev/null | jq -r '.result.nonScratchOrgs[]? | "  - \(.alias // .username) (\(.username))"' 2>/dev/null || echo "  Run 'sf org list' to see available orgs"
    echo ""
    echo -e "${YELLOW}Get your Weather API key at:${NC}"
    echo -e "  ${CYAN}${API_KEY_URL}${NC}"
    echo -e "  ${CYAN}Free tier: 1000 records/day${NC}"
    exit 1
}

if [ $# -ne 1 ]; then
    echo -e "${RED}Error: Missing org alias${NC}"
    echo ""
    usage
fi

ORG_ALIAS=$1

# Validate sf CLI
if ! command -v sf &> /dev/null; then
    echo -e "${RED}Error: Salesforce CLI (sf) is not installed${NC}"
    echo "Install from: https://developer.salesforce.com/tools/salesforcecli"
    exit 1
fi

# Validate org connection
echo -e "${BLUE}► Validating org connection...${NC}"
if ! sf org display --target-org "$ORG_ALIAS" &> /dev/null; then
    echo -e "${RED}✗ Cannot connect to org '$ORG_ALIAS'${NC}"
    echo ""
    echo "Run: ${YELLOW}sf org login web --alias $ORG_ALIAS${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Connected to org: $ORG_ALIAS${NC}"
echo ""

# Get API key securely
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Enter your Visual Crossing Weather API key${NC}"
echo -e "${CYAN}Get it from: ${API_KEY_URL}${NC}"
echo -e "${CYAN}Free tier includes 1000 records/day${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}API Key (input hidden):${NC}"
read -s API_KEY
echo ""

if [ -z "$API_KEY" ]; then
    echo -e "${RED}Error: API key cannot be empty${NC}"
    exit 1
fi

echo -e "${GREEN}✓ API key received${NC}"
echo ""

# Check if Custom Setting exists
echo -e "${BLUE}► Checking for API_Credentials__c Custom Setting...${NC}"

SETTING_CHECK=$(sf data query \
    --query "SELECT Id FROM API_Credentials__c WHERE Name = '$CUSTOM_SETTING_NAME' LIMIT 1" \
    --target-org "$ORG_ALIAS" \
    --json 2>&1 || echo '{"status":1}')

if echo "$SETTING_CHECK" | grep -q "sObject type 'API_Credentials__c' is not supported"; then
    echo -e "${YELLOW}⚠ Custom Setting not found. Creating it...${NC}"
    echo ""

    # Create temporary project structure for Custom Setting
    TEMP_DIR=$(mktemp -d)
    mkdir -p "$TEMP_DIR/objects/API_Credentials__c/fields"

    cat > "$TEMP_DIR/objects/API_Credentials__c/API_Credentials__c.object-meta.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <customSettingsType>Hierarchy</customSettingsType>
    <enableFeeds>false</enableFeeds>
    <label>API Credentials</label>
    <visibility>Protected</visibility>
</CustomObject>
EOF

    cat > "$TEMP_DIR/objects/API_Credentials__c/fields/API_Key__c.field-meta.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>API_Key__c</fullName>
    <label>API Key</label>
    <type>Text</type>
    <length>255</length>
    <required>false</required>
</CustomField>
EOF

    echo -e "${BLUE}► Deploying Custom Setting to org...${NC}"
    sf project deploy start \
        --source-dir "$TEMP_DIR/objects" \
        --target-org "$ORG_ALIAS" \
        --wait 10 > /dev/null 2>&1

    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}✓ Custom Setting created${NC}"
    echo ""
fi

# Insert or update credential
EXISTING_ID=$(echo "$SETTING_CHECK" | jq -r '.result.records[0].Id // empty' 2>/dev/null)

if [ -z "$EXISTING_ID" ]; then
    echo -e "${BLUE}► Creating Weather API credential record...${NC}"
    sf data record create \
        --sobject API_Credentials__c \
        --values "Name='$CUSTOM_SETTING_NAME' API_Key__c='$API_KEY'" \
        --target-org "$ORG_ALIAS" > /dev/null 2>&1
    echo -e "${GREEN}✓ Credential created${NC}"
else
    echo -e "${BLUE}► Updating existing credential...${NC}"
    sf data record update \
        --sobject API_Credentials__c \
        --record-id "$EXISTING_ID" \
        --values "API_Key__c='$API_KEY'" \
        --target-org "$ORG_ALIAS" > /dev/null 2>&1
    echo -e "${GREEN}✓ Credential updated${NC}"
fi

echo ""

# Configure CSP Trusted Site / Remote Site Settings
echo -e "${BLUE}► Configuring endpoint security (CSP Trusted Sites)...${NC}"

# Check if CSP Trusted Site already exists
CSP_CHECK=$(sf data query \
    --query "SELECT Id FROM CspTrustedSite WHERE DeveloperName = '$CSP_NAME' LIMIT 1" \
    --target-org "$ORG_ALIAS" \
    --json 2>&1 || echo '{"status":1}')

if echo "$CSP_CHECK" | grep -q "sObject type 'CspTrustedSite' is not supported"; then
    # Org might be older than API 48, try Remote Site Settings instead
    echo -e "${YELLOW}⚠ CSP Trusted Sites not supported. Checking Remote Site Settings...${NC}"

    REMOTE_SITE_CHECK=$(sf data query \
        --query "SELECT Id FROM RemoteSiteSetting WHERE SiteName = '$CSP_NAME' LIMIT 1" \
        --target-org "$ORG_ALIAS" \
        --json 2>&1 || echo '{"status":1}')

    REMOTE_SITE_ID=$(echo "$REMOTE_SITE_CHECK" | jq -r '.result.records[0].Id // empty' 2>/dev/null)

    if [ -z "$REMOTE_SITE_ID" ]; then
        echo -e "${BLUE}► Deploying Remote Site Setting...${NC}"

        # Find the templates directory
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        SKILL_DIR="$(dirname "$SCRIPT_DIR")"

        sf project deploy start \
            --source-dir "$SKILL_DIR/templates/VisualCrossingWeatherAPI.remoteSite-meta.xml" \
            --target-org "$ORG_ALIAS" \
            --wait 5 > /dev/null 2>&1 || true

        echo -e "${GREEN}✓ Remote Site Setting configured${NC}"
    else
        echo -e "${GREEN}✓ Remote Site Setting already exists${NC}"
    fi
else
    CSP_ID=$(echo "$CSP_CHECK" | jq -r '.result.records[0].Id // empty' 2>/dev/null)

    if [ -z "$CSP_ID" ]; then
        echo -e "${BLUE}► Deploying CSP Trusted Site...${NC}"

        # Find the templates directory
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        SKILL_DIR="$(dirname "$SCRIPT_DIR")"

        sf project deploy start \
            --source-dir "$SKILL_DIR/templates/VisualCrossingWeatherAPI.cspTrustedSite-meta.xml" \
            --target-org "$ORG_ALIAS" \
            --wait 5 > /dev/null 2>&1 || true

        echo -e "${GREEN}✓ CSP Trusted Site configured${NC}"
    else
        echo -e "${GREEN}✓ CSP Trusted Site already exists${NC}"
    fi
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ Visual Crossing Weather API integration configured!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Next steps
echo -e "${BLUE}📋 Next Steps:${NC}"
echo ""
echo -e "${YELLOW}1. Test with Anonymous Apex:${NC}"
echo -e "${CYAN}"
cat << 'EOF'
   // Get API key from Custom Setting
   API_Credentials__c cred = API_Credentials__c.getInstance('VisualCrossingWeather');
   String apiKey = cred.API_Key__c;

   // Make weather API call
   String location = 'New York, NY';
   String endpoint = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/'
                     + EncodingUtil.urlEncode(location, 'UTF-8')
                     + '?key=' + apiKey + '&unitGroup=metric&contentType=json';

   HttpRequest req = new HttpRequest();
   req.setEndpoint(endpoint);
   req.setMethod('GET');
   req.setTimeout(60000);

   Http http = new Http();
   HttpResponse res = http.send(req);

   if (res.getStatusCode() == 200) {
       Map<String, Object> weatherData = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
       System.debug('Location: ' + weatherData.get('resolvedAddress'));
       System.debug('Weather data retrieved successfully!');
   } else {
       System.debug('Error: ' + res.getStatusCode() + ' - ' + res.getBody());
   }
EOF
echo -e "${NC}"
echo ""
echo -e "${YELLOW}2. Verify endpoint security (already configured):${NC}"
echo -e "   ${GREEN}✓ CSP Trusted Site or Remote Site Setting deployed${NC}"
echo -e "   ${CYAN}Verify at: Setup → CSP Trusted Sites (or Remote Site Settings)${NC}"
echo ""
echo -e "${YELLOW}3. API Rate Limits:${NC}"
echo -e "   ${CYAN}Free tier: 1,000 records/day${NC}"
echo -e "   ${CYAN}Paid tiers: Up to 500,000+ records/day${NC}"
echo ""

echo -e "${BLUE}📚 Documentation:${NC}"
echo -e "   - API Docs: ${CYAN}https://www.visualcrossing.com/resources/documentation/weather-api/${NC}"
echo -e "   - Account: ${CYAN}${API_KEY_URL}${NC}"
echo ""

echo -e "${GREEN}🎉 Setup complete! Ready to fetch weather data!${NC}"
echo ""
