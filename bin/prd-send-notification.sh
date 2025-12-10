#!/bin/bash
set -e

ZIP_VERSION=$1
IS_LATEST=$2
JOB_STATUS=$3
GITHUB_ACTION_URL=$4
SAST_SELF_CONTAINED_VERSION=$5

echo "Sending Slack notification to production channel"
echo "ZIP Version: $ZIP_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Job Status: $JOB_STATUS"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$IS_LATEST" ]; then
  echo "Error: No IS_LATEST argument provided."
  exit 1
fi

if [ -z "$JOB_STATUS" ]; then
  echo "Error: No job status argument provided."
  exit 1
fi

if [ -z "$GITHUB_ACTION_URL" ]; then
  echo "Error: No GitHub Action URL argument provided."
  exit 1
fi

# Get webhook URL from environment variable
if [ -z "$SLACK_WEBHOOK_URL" ]; then
  echo "Warning: No SLACK_WEBHOOK_URL environment variable provided, skipping Slack notification"
  exit 0
fi

if [ -n "$SAST_SELF_CONTAINED_VERSION" ]; then
    echo "SAST Self-Contained Version (provided): $SAST_SELF_CONTAINED_VERSION"
fi

# Mask the webhook URL in GitHub Actions logs
echo "::add-mask::$SLACK_WEBHOOK_URL"

if [ -n "$SAST_SELF_CONTAINED_VERSION" ]; then
    # Priority 1: Use provided parameter
    echo "Using provided SAST version parameter: $SAST_SELF_CONTAINED_VERSION"
else
    # Priority 2: Fallback to ZIP_VERSION
    SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
    echo "Could not auto-detect SAST version, using ZIP version as fallback: $SAST_SELF_CONTAINED_VERSION"
fi

# Determine branch info
if [ "$IS_LATEST" = "true" ]; then
    BRANCH_INFO="Merged to main branch"
    RELEASE_TYPE="Latest Release"
else
    BRANCH_INFO="Release branch created (not merged to main)"
    RELEASE_TYPE="Release"
fi

# S3 production zip information
S3_PRODUCTION_ZIP_NAME="agent-4-github-enterprise-${ZIP_VERSION}-with-prebuilt.zip"

echo "GitHub Action URL: $GITHUB_ACTION_URL"
echo "S3 Production ZIP: $S3_PRODUCTION_ZIP_NAME"

# Create Slack message
SLACK_MESSAGE=$(cat <<EOF
{
  "text": "🚀 Production Docker Images Release - $ZIP_VERSION",
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🚀 Production Docker Images Release"
      }
    },
    {
      "type": "section",
      "fields": [
        {
          "type": "mrkdwn",
          "text": "*Version:*\n\`$ZIP_VERSION\`"
        },
        {
          "type": "mrkdwn",
          "text": "*SAST Version:*\n\`$SAST_SELF_CONTAINED_VERSION\`"
        },
        {
          "type": "mrkdwn",
          "text": "*Release Type:*\n$RELEASE_TYPE"
        },
        {
          "type": "mrkdwn",
          "text": "*Job Status:*\n$JOB_STATUS"
        },
        {
          "type": "mrkdwn",
          "text": "*Branch Status:*\n$BRANCH_INFO"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*✅ Completed Actions:*\n• Downloaded pre-built staging ZIP\n• Modified Dockerfiles for production (mend/ prefix)\n• Replaced staging SAST files with production versions\n• Built and validated Docker images\n• Published images to Staging ECR with prod/ prefix\n• Uploaded ZIP to production S3 bucket"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*📦 Artifacts:*\n• ZIP: \`agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip\`\n• Staging ECR images with prod/ prefix for validation\n• S3 upload: production bucket"
      }
    }$([ -n "$GITHUB_ACTION_URL" ] && echo ",
    {
      \"type\": \"section\",
      \"text\": {
        \"type\": \"mrkdwn\",
        \"text\": \"*🔗 Build Details:*\n• <$GITHUB_ACTION_URL|View GitHub Action Run>\"
      }
    }")
  ]
}
EOF
)

# Send Slack notification
echo "Sending Slack notification..."
curl -X POST -H 'Content-type: application/json' \
  --data "$SLACK_MESSAGE" \
  "$SLACK_WEBHOOK_URL"

echo ""
echo "Production Slack notification sent successfully"
