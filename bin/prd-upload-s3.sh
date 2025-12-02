#!/bin/bash
set -e

ZIP_VERSION=$1

echo "Uploading ZIP file to production S3 bucket"
echo "ZIP Version: $ZIP_VERSION"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path/.."

# Create production ZIP file (repackage with production SAST files)
PROD_ZIP_NAME="agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip"
PROD_ZIP_PATH="tmp/$PROD_ZIP_NAME"

echo "Creating production ZIP file: $PROD_ZIP_NAME"

# Remove existing production zip if it exists
if [ -f "$PROD_ZIP_PATH" ]; then
    rm "$PROD_ZIP_PATH"
fi

# Create ZIP from the modified directory
cd tmp
zip -r "$PROD_ZIP_NAME" "agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt"
cd ..

if [ ! -f "$PROD_ZIP_PATH" ]; then
    echo "Error: Failed to create production ZIP file: $PROD_ZIP_PATH"
    exit 1
fi

# Upload to production S3 bucket
PROD_S3_PATH="s3://wsd-integration/release/Agent-for-GitHub-Enterprise-with-prebuilt/$PROD_ZIP_NAME"

echo "Uploading to production S3: $PROD_S3_PATH"
aws s3 cp "$PROD_ZIP_PATH" "$PROD_S3_PATH"

echo "Production ZIP file uploaded successfully"
echo "S3 Location: $PROD_S3_PATH"
