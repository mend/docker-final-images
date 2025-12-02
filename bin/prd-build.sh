#!/bin/bash
set -e

ZIP_VERSION=$1

echo "Building Docker images for production"
echo "ZIP Version: $ZIP_VERSION"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path/.."

# Set build context
BUILD_CONTEXT="tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt"

if [ ! -d "$BUILD_CONTEXT" ]; then
    echo "Error: Build context directory $BUILD_CONTEXT not found."
    exit 1
fi

echo "Building Docker images from $BUILD_CONTEXT using buildwithsast.sh"

# Use the same build approach as staging
echo "Performing production docker build"
cd "$BUILD_CONTEXT"
./buildwithsast.sh

echo "Production Docker image build completed successfully"

# Verify images were built with mend/ prefix (as expected for production)
echo "Verifying built images:"
docker images | grep "mend/" || echo "Note: No mend/ prefixed images found, checking if images were built correctly"
docker images | grep "$ZIP_VERSION"

echo "Docker image build completed successfully"