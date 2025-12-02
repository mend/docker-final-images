#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2

# Download configuration
GHE_ZIP_PATH="s3://wsd-integration/pre-release/Agent-for-GitHub-Enterprise/agent-4-github-enterprise-$ZIP_VERSION.zip"
SAST_SELF_CONTAINED_PATH="https://mend-unified-cli.s3.amazonaws.com/staging/sast/self-contained/linux_amd64/5139c224-38c2-427b-b080-a03a8d6f6285/$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
SAST_BINARY_PATH="https://mend-unified-cli.s3.amazonaws.com/staging/wrapper/latest/linux_amd64/mend"

echo "Downloading GHE ZIP and SAST self-contained tar.gz"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi

echo "Downloading ZIP version: $ZIP_VERSION"

# If SAST_SELF_CONTAINED_VERSION not provided, use ZIP_VERSION
if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
  SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
  echo "SAST self-contained version not provided, using ZIP version: $SAST_SELF_CONTAINED_VERSION"
else
  echo "SAST self-contained version: $SAST_SELF_CONTAINED_VERSION"
fi



if [ "$SAST_SELF_CONTAINED_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct SAST engine version"
  exit 1
fi


parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Always download agent-4-github-enterprise-$ZIP_VERSION.zip
echo "Downloading agent-4-github-enterprise-$ZIP_VERSION.zip from S3"
mkdir -p ../tmp
aws s3 cp $GHE_ZIP_PATH ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip

if [ ! -f ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip ]; then
    echo "Error: agent-4-github-enterprise-$ZIP_VERSION.zip not found."
    exit 1
fi

# Always unzip agent-4-github-enterprise-$ZIP_VERSION.zip
echo "Unzipping agent-4-github-enterprise-$ZIP_VERSION.zip"
unzip -o ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip -d ../tmp

# Check if ../tmp/agent-4-github-enterprise-$ZIP_VERSION exists
if [ ! -d ../tmp/agent-4-github-enterprise-$ZIP_VERSION ]; then
    echo "Error: agent-4-github-enterprise-$ZIP_VERSION not found."
    exit 1
fi

# Download SAST engine tar and binary files
echo "Downloading SAST engine files for version: $SAST_SELF_CONTAINED_VERSION"
mkdir -p ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION

# Always download self-contained-sast-<version>.tar.gz
echo "Downloading self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
curl -o ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz $SAST_SELF_CONTAINED_PATH

if [ ! -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ]; then
    echo "Error: self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz not found."
    exit 1
fi

# Always download mend binary file
echo "Downloading mend binary file"
curl -o ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend $SAST_BINARY_PATH

if [ ! -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend ]; then
    echo "Error: mend binary file not found."
    exit 1
fi

echo "SAST files download completed successfully"
