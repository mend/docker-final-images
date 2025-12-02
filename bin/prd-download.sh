#!/bin/bash
set -e

ZIP_VERSION=$1

echo "Downloading pre-built ZIP from staging bucket"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi

echo "Downloading pre-built ZIP version: $ZIP_VERSION"

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Download pre-built ZIP from staging S3 bucket
STAGING_GHE_ZIP_PATH="s3://wsd-integration/pre-release/Agent-for-GitHub-Enterprise-with-prebuilt/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip"

echo "Downloading pre-built staging ZIP: agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip"
mkdir -p ../tmp
aws s3 cp "$STAGING_GHE_ZIP_PATH" ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip


if [ ! -f ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip ]; then
    echo "Error: agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip not found."
    exit 1
fi

echo "Unzipping pre-built staging ZIP: agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip"
unzip -o ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip -d ../tmp

echo "Pre-built ZIP downloaded and extracted successfully"
