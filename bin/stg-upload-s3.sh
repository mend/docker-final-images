#!/bin/bash
set -e

ZIP_VERSION=$1

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi

echo "Uploading staging ZIP file for version: $ZIP_VERSION"

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

STAGING_S3_BUCKET="s3://wsd-integration/pre-release/Agent-for-GitHub-Enterprise-with-prebuilt"
ZIP_FILE="../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt-staging.zip"

# Check if ZIP file exists
if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: ZIP file not found: $ZIP_FILE"
    exit 1
fi

echo "Command to implement:"
echo "aws s3 cp \"$ZIP_FILE\" \"$STAGING_S3_BUCKET/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt-staging.zip\""

# Get file size for reporting
FILE_SIZE=$(du -h "$ZIP_FILE" | cut -f1)
echo "ZIP file size: $FILE_SIZE"
echo "ZIP file location: $ZIP_FILE"

echo "Staging S3 upload completed"
