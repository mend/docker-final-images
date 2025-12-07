#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2

echo "Downloading production SAST files and replacing staging versions"
echo "ZIP Version: $ZIP_VERSION"

if [ -n "$SAST_SELF_CONTAINED_VERSION" ]; then
    echo "SAST Self-Contained Version (provided): $SAST_SELF_CONTAINED_VERSION"
fi

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"


if [ -n "$SAST_SELF_CONTAINED_VERSION" ]; then
    # Priority 1: Use provided parameter
    echo "Using provided SAST version parameter: $SAST_SELF_CONTAINED_VERSION"
else
    # Priority 2: Fallback to ZIP_VERSION
    SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
    echo "Could not auto-detect SAST version, using ZIP version as fallback: $SAST_SELF_CONTAINED_VERSION"
fi

echo "Using SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"

# Production download paths (update these with actual production paths)
SAST_SELF_CONTAINED_PROD_PATH="https://downloads.mend.io/production/sast/self-contained/linux_amd64/0455bde2-85ad-4a5e-9788-b51244f2d9ec/$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
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
