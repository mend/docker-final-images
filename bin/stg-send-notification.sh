#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2
IS_LATEST=$3
JOB_STATUS=$4
GITHUB_ACTION_URL=$5

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
  echo "Error: No SAST self-contained version argument provided. Setting to $ZIP_VERSION."
  SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
fi

if [ -z "$IS_LATEST" ]; then
  echo "Error: No IsLatest argument provided."
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

# S3 prebuilt zip information
S3_ZIP_NAME="agent-4-github-enterprise-${ZIP_VERSION}-with-prebuilt.zip"

echo "Sending Slack notification for staging release"
echo "ZIP Version: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Job Status: $JOB_STATUS"
echo "Release Branch: $RELEASE_BRANCH"
echo "GitHub Action URL: $GITHUB_ACTION_URL"
echo "S3 Prebuilt ZIP: $S3_ZIP_NAME"

# Create JSON payload using jq for safe variable substitution
JSON_PAYLOAD=$(jq -n \
  --arg zip_version "$ZIP_VERSION" \
  --arg sast_version "$SAST_SELF_CONTAINED_VERSION" \
  --arg release_branch "$RELEASE_BRANCH" \
  --arg is_latest "$IS_LATEST" \
  --arg job_status "$JOB_STATUS" \
  --arg ecr_registry "$ECR_REGISTRY" \
  --arg github_url "$GITHUB_ACTION_URL" \
  --arg s3_zip_name "$S3_ZIP_NAME" \
  '{
    "text": ("🚀 *New Staging Images Published!*\n\n*Version Details:*\n• ZIP Version: `" + $zip_version + "`\n• SAST Self-Contained Version: `" + $sast_version + "`\n• Release Branch: `" + $release_branch + "`\n• Merged to develop: `" + $is_latest + "`\n• Job Status: `" + $job_status + "`\n\n*Images Published:*\n• `" + $ecr_registry + "/wss-ghe-app:prebuilt-" + $zip_version + "`\n• `" + $ecr_registry + "/wss-scanner:prebuilt-" + $zip_version + "`\n• `" + $ecr_registry + "/wss-scanner:prebuilt-" + $zip_version + "-full`\n• `" + $ecr_registry + "/wss-scanner-sast:prebuilt-" + $zip_version + "`\n• `" + $ecr_registry + "/wss-remediate:prebuilt-" + $zip_version + "`\n\n*S3 Prebuilt Package:*\n• `" + $s3_zip_name + "`\n\n" + (if $github_url != "" then "*GitHub Action:* <" + $github_url + "|View Build Details>\n\n" else "" end) + "*Staging Environment Ready for Testing* ✅"),
    "username": "GitHub Actions - Staging",
    "icon_emoji": ":rocket:"
  }')

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
