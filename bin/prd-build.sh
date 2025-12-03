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

echo "Building Docker images from $BUILD_CONTEXT using manual docker build commands"

# Use the same build approach as staging - build each image individually
echo "Performing production docker build"
cd "$BUILD_CONTEXT"

# Build all images like staging does with prebuilt naming convention and prod/ prefix
docker build -t prod/wss-ghe-app-prebuilt:$ZIP_VERSION wss-ghe-app/docker
docker build -t prod/wss-scanner-prebuilt:$ZIP_VERSION wss-scanner/docker
docker build -t prod/wss-scanner-sast-prebuilt:$ZIP_VERSION -f wss-scanner/docker/DockerfileSast wss-scanner/docker
docker build -t prod/wss-scanner-full-prebuilt:$ZIP_VERSION -f wss-scanner/docker/Dockerfilefull wss-scanner/docker
docker build -t prod/wss-remediate-prebuilt:$ZIP_VERSION wss-remediate/docker

echo "Production Docker image build completed successfully"

#Validate built images successfully created
echo "Verifying built images:"
if [ -z "$(docker images -q prod/wss-ghe-app-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "prod/wss-ghe-app-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "prod/wss-ghe-app-prebuilt:$ZIP_VERSION Built successfully!"
fi

if [ -z "$(docker images -q prod/wss-scanner-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "prod/wss-scanner-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "prod/wss-scanner-prebuilt:$ZIP_VERSION Built successfully!"
fi

if [ -z "$(docker images -q prod/wss-scanner-sast-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "prod/wss-scanner-sast-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "prod/wss-scanner-sast-prebuilt:$ZIP_VERSION Built successfully!"
fi

if [ -z "$(docker images -q prod/wss-scanner-full-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "prod/wss-scanner-full-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "prod/wss-scanner-full-prebuilt:$ZIP_VERSION Built successfully!"
fi

if [ -z "$(docker images -q prod/wss-remediate-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "prod/wss-remediate-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "prod/wss-remediate-prebuilt:$ZIP_VERSION Built successfully!"
fi

echo "Docker image build completed successfully"