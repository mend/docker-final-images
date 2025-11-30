#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2
IS_LATEST=$3
SLACK_WEBHOOK_URL=$4

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
  echo "Error: No SAST self-contained version argument provided."
  exit 1
fi

if [ -z "$IS_LATEST" ]; then
  echo "Error: No IsLatest argument provided."
  exit 1
fi

if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "Error: No Slack webhook URL provided."
  exit 1
fi



RELEASE_BRANCH="release/$ZIP_VERSION"

echo "Sending Slack notification for staging release"
echo "ZIP Version: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Release Branch: $RELEASE_BRANCH"

# Prepare message payload
MESSAGE="🚀 *New Staging Images Published!*

*Version Details:*
• ZIP Version: \`$ZIP_VERSION\`
• SAST Self-Contained Version: \`$SAST_SELF_CONTAINED_VERSION\`
• Release Branch: \`$RELEASE_BRANCH\`
• Merged to develop: \`$IS_LATEST\`

*Images Published:*
• \`wss-ghe-app:prebuilt-$ZIP_VERSION\`
• \`wss-scanner:prebuilt-$ZIP_VERSION\`
• \`wss-scanner-sast:prebuilt-$ZIP_VERSION\`
• \`wss-remediate:prebuilt-$ZIP_VERSION\`

*Staging Environment Ready for Testing* ✅"

# Create JSON payload
JSON_PAYLOAD=$(cat << EOF
{
  "text": "$MESSAGE",
  "username": "GitHub Actions - Staging",
  "icon_emoji": ":rocket:"
}
EOF
)

echo "Sending notification to Slack..."

# Send to Slack
RESPONSE=$(curl -s -X POST -H 'Content-type: application/json' \
    --data "$JSON_PAYLOAD" \
    "$SLACK_WEBHOOK_URL")

if [ "$RESPONSE" = "ok" ]; then
    echo "Slack notification sent successfully"
else
    echo "Error sending Slack notification: $RESPONSE"
    exit 1
fi

echo "Staging release notification completed"
