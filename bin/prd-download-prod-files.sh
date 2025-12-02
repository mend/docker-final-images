#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION_PARAM=$2

echo "Downloading production SAST files and replacing staging versions"
echo "ZIP Version: $ZIP_VERSION"

if [ -n "$SAST_SELF_CONTAINED_VERSION_PARAM" ]; then
    echo "SAST Self-Contained Version (provided): $SAST_SELF_CONTAINED_VERSION_PARAM"
fi

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Determine SAST version with priority order:
# 1. Use provided parameter if available
# 2. Auto-detect from staging files
# 3. Fallback to ZIP_VERSION
SAST_SELF_CONTAINED_VERSION=""

if [ -n "$SAST_SELF_CONTAINED_VERSION_PARAM" ]; then
    # Priority 1: Use provided parameter
    SAST_SELF_CONTAINED_VERSION=$SAST_SELF_CONTAINED_VERSION_PARAM
    echo "Using provided SAST version parameter: $SAST_SELF_CONTAINED_VERSION"
else
    # Priority 2: Auto-detect from staging files
    echo "No SAST version parameter provided, attempting auto-detection from staging files..."

    # Look for existing SAST files in the extracted staging package to determine version
    if [ -d ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker ]; then
        # Check for existing SAST tar file to get version
        SAST_FILE=$(find ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker -name "self-contained-sast-*.tar.gz" 2>/dev/null | head -1)
        if [ -n "$SAST_FILE" ]; then
            # Extract version from filename: self-contained-sast-X.Y.Z.tar.gz
            SAST_SELF_CONTAINED_VERSION=$(basename "$SAST_FILE" | sed 's/self-contained-sast-\(.*\)\.tar\.gz/\1/')
            echo "Auto-detected SAST version from staging files: $SAST_SELF_CONTAINED_VERSION"
        fi
    fi

    # Priority 3: Fallback to ZIP_VERSION if auto-detection failed
    if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
        SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
        echo "Could not auto-detect SAST version, using ZIP version as fallback: $SAST_SELF_CONTAINED_VERSION"
    fi
fi

echo "Using SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"

# Production download paths (update these with actual production paths)
SAST_SELF_CONTAINED_PROD_PATH="https://mend-unified-cli.s3.amazonaws.com/production/sast/self-contained/linux_amd64/5139c224-38f2-4b2c-a9b7-34aa8d6f6285/$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
SAST_BINARY_PROD_PATH="https://downloads.mend.io/cli/linux_amd64/mend"

# Download production SAST self-contained tar.gz
echo "Downloading production SAST self-contained tar.gz"
curl -o ../tmp/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz $SAST_SELF_CONTAINED_PROD_PATH

if [ ! -f ../tmp/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ]; then
    echo "Error: Failed to download production self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
    exit 1
fi

# Download production SAST binary
echo "Downloading production SAST binary"
curl -o ../tmp/mend $SAST_BINARY_PROD_PATH

if [ ! -f ../tmp/mend ]; then
    echo "Error: Failed to download production mend binary"
    exit 1
fi

# Make mend binary executable
chmod +x ../tmp/mend

# Replace files in the extracted package with production versions
echo "Replacing staging SAST files with production versions"

# Replace self-contained tar.gz
echo "Replacing self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz with production version"
cp ../tmp/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker/

echo "Replacing mend binary with production version"
cp ../tmp/mend ../tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker/

echo "Production SAST files downloaded and replaced successfully"
