#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2

# Download configuration
GHE_ZIP_PATH="https://integrations.mend.io/release/Agent-for-GitHub-Enterprise/agent-4-github-enterprise-$ZIP_VERSION.zip"
SAST_SELF_CONTAINED_PATH="https://mend-unified-cli.s3.amazonaws.com/staging/sast/self-contained/linux_amd64/5139c224-38[…]a8d6f6285/$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
SAST_BINARY_PATH="TODO_CONFIRM_BINARY_PATH/mend" # TODO: Confirm if same as self-contained bucket or different path

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

# Check if ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip exists
if [ ! -f ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip ]; then
  echo "Downloading agent-4-github-enterprise-$ZIP_VERSION.zip"
  mkdir -p ../tmp
  curl -o ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip $GHE_ZIP_PATH
fi

if [ ! -f ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip ]; then
    echo "Error: agent-4-github-enterprise-$ZIP_VERSION.zip not found."
    exit 1
fi

# Unzip agent-4-github-enterprise-$ZIP_VERSION.zip if the folder doesn't exist
if [ ! -d ../tmp/agent-4-github-enterprise-$ZIP_VERSION ]; then
  echo "Unzipping agent-4-github-enterprise-$ZIP_VERSION.zip"
  unzip -o ../tmp/agent-4-github-enterprise-$ZIP_VERSION.zip -d ../tmp
fi

# Check if ../tmp/agent-4-github-enterprise-$ZIP_VERSION exists
if [ ! -d ../tmp/agent-4-github-enterprise-$ZIP_VERSION ]; then
    echo "Error: agent-4-github-enterprise-$ZIP_VERSION not found."
    exit 1
fi

# Download SAST engine tar and binary files
echo "Downloading SAST engine files for version: $SAST_SELF_CONTAINED_VERSION"
mkdir -p ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION

# Download self-contained-sast-<version>.tar.gz
if [ ! -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ]; then
  echo "Downloading self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
  curl -o ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz $SAST_SELF_CONTAINED_PATH
fi

if [ ! -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ]; then
    echo "Error: self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz not found."
    exit 1
fi

# Download mend binary file
if [ ! -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend ]; then
  echo "Downloading mend binary file"
  curl -o ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend $SAST_BINARY_PATH
fi

if [ ! -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend ]; then
    echo "Error: mend binary file not found."
    exit 1
fi

echo "SAST files download completed successfully"
