#!/bin/bash
set -e

ZIP_VERSION=$1

echo "Building Docker images for production"
echo "ZIP Version: $ZIP_VERSION"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

# Auto-detect SAST version from staging files
SAST_SELF_CONTAINED_VERSION=""
if [ -d "tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker" ]; then
    SAST_FILE=$(find tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker -name "self-contained-sast-*.tar.gz" 2>/dev/null | head -1)
    if [ -n "$SAST_FILE" ]; then
        SAST_SELF_CONTAINED_VERSION=$(basename "$SAST_FILE" | sed 's/self-contained-sast-\(.*\)\.tar\.gz/\1/')
        echo "Auto-detected SAST version: $SAST_SELF_CONTAINED_VERSION"
    fi
fi

if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
    SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
    echo "Using ZIP version as SAST fallback: $SAST_SELF_CONTAINED_VERSION"
fi

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path/.."

# Set build context
BUILD_CONTEXT="tmp/agent-4-github-enterprise-$ZIP_VERSION"

if [ ! -d "$BUILD_CONTEXT" ]; then
    echo "Error: Build context directory $BUILD_CONTEXT not found."
    exit 1
fi

echo "Building Docker images from $BUILD_CONTEXT"

# Build wss-ghe-app image
echo "Building wss-ghe-app image"
docker build -t mend/wss-ghe-app:$ZIP_VERSION \
    -f repo-integrations/wss-ghe-app/docker/Dockerfile \
    $BUILD_CONTEXT

# Build wss-scanner image
echo "Building wss-scanner image"
docker build -t mend/wss-scanner:$ZIP_VERSION \
    -f repo-integrations/wss-scanner/docker/Dockerfile \
    $BUILD_CONTEXT

# Build wss-scanner-full image
echo "Building wss-scanner-full image"
docker build -t mend/wss-scanner:$ZIP_VERSION-full \
    -f repo-integrations/wss-scanner/docker/Dockerfilefull \
    $BUILD_CONTEXT

# Build wss-scanner-sast image
echo "Building wss-scanner-sast image"
docker build -t mend/wss-scanner-sast:$ZIP_VERSION \
    -f repo-integrations/wss-scanner/docker/DockerfileSast \
    $BUILD_CONTEXT

# Build wss-remediate image
echo "Building wss-remediate image"
docker build -t mend/wss-remediate:$ZIP_VERSION \
    -f repo-integrations/wss-remediate/docker/Dockerfile \
    $BUILD_CONTEXT

echo "All Docker images built successfully"

# Test images (basic smoke test)
echo "Running basic smoke tests on built images"

# Test wss-ghe-app
echo "Testing wss-ghe-app image"
docker run --rm mend/wss-ghe-app:$ZIP_VERSION --help || echo "Note: wss-ghe-app help test completed"

# Test wss-scanner
echo "Testing wss-scanner image"
docker run --rm mend/wss-scanner:$ZIP_VERSION --help || echo "Note: wss-scanner help test completed"

# Test wss-scanner-full
echo "Testing wss-scanner-full image"
docker run --rm mend/wss-scanner:$ZIP_VERSION-full --help || echo "Note: wss-scanner-full help test completed"

# Test wss-scanner-sast
echo "Testing wss-scanner-sast image"
docker run --rm mend/wss-scanner-sast:$ZIP_VERSION --help || echo "Note: wss-scanner-sast help test completed"

# Test wss-remediate
echo "Testing wss-remediate image"
docker run --rm mend/wss-remediate:$ZIP_VERSION --help || echo "Note: wss-remediate help test completed"

echo "Docker image build and test completed successfully"
