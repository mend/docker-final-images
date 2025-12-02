#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2
IS_LATEST=$3

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

# Get webhook URL from environment variable instead of parameter
if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "Error: SLACK_WEBHOOK_URL environment variable not provided."
  exit 1
fi

# Check if ECR_REGISTRY is provided, otherwise use default
if [ -z "$ECR_REGISTRY" ]; then
  ECR_REGISTRY="054331651301.dkr.ecr.us-east-1.amazonaws.com"
  echo "Using default ECR registry: $ECR_REGISTRY"
else
  echo "Using ECR registry from environment: $ECR_REGISTRY"
fi

# Mask the webhook URL in GitHub Actions logs
echo "::add-mask::$SLACK_WEBHOOK_URL"

RELEASE_BRANCH="release/$ZIP_VERSION"

echo "Sending Slack notification for staging release"
echo "ZIP Version: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Release Branch: $RELEASE_BRANCH"

# Create JSON payload with proper escaping
JSON_PAYLOAD=$(cat << 'EOF'
{
  "text": "🚀 *New Staging Images Published!*\n\n*Version Details:*\n• ZIP Version: `$ZIP_VERSION`\n• SAST Self-Contained Version: `$SAST_SELF_CONTAINED_VERSION`\n• Release Branch: `$RELEASE_BRANCH`\n• Merged to develop: `$IS_LATEST`\n\n*Images Published:*\n• `$ECR_REGISTRY/wss-ghe-app:prebuilt-$ZIP_VERSION`\n• `$ECR_REGISTRY/wss-scanner:prebuilt-$ZIP_VERSION`\n• `$ECR_REGISTRY/wss-scanner:prebuilt-$ZIP_VERSION-full`\n• `$ECR_REGISTRY/wss-scanner-sast:prebuilt-$ZIP_VERSION`\n• `$ECR_REGISTRY/wss-remediate:prebuilt-$ZIP_VERSION`\n\n*Staging Environment Ready for Testing* ✅",
  "username": "GitHub Actions - Staging",
  "icon_emoji": ":rocket:"
}
EOF
)

# Substitute variables in the JSON payload
JSON_PAYLOAD=$(echo "$JSON_PAYLOAD" | sed "s/\$ZIP_VERSION/$ZIP_VERSION/g" | sed "s/\$SAST_SELF_CONTAINED_VERSION/$SAST_SELF_CONTAINED_VERSION/g" | sed "s/\$RELEASE_BRANCH/$RELEASE_BRANCH/g" | sed "s/\$IS_LATEST/$IS_LATEST/g" | sed "s/\$ECR_REGISTRY/$ECR_REGISTRY/g")

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
