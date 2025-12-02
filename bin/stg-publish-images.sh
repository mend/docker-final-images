#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$2" ]; then
  echo "Error: No SAST self-contained version argument provided."
  exit 1
fi

if [ -z "$3" ]; then
  echo "Error: No ECR registry argument provided."
  exit 1
fi

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2
ECR_REGISTRY=$3
IS_LATEST=${4:-false}

echo "Publishing Docker images to Staging ECR"
echo "ZIP Version: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "ECR Registry: $ECR_REGISTRY"
echo "Is Latest: $IS_LATEST"

# Get the actual built image tags from docker
wssGheAppImage=$(docker images --filter "reference=wss-ghe-app-prebuilt:*" --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | head -1)
wssScannerImage=$(docker images --filter "reference=wss-scanner-prebuilt:*" --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | head -1)
wssScannerFullImage=$(docker images --filter "reference=wss-scanner-full-prebuilt:*" --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | head -1)
wssScannerSastImage=$(docker images --filter "reference=wss-scanner-sast-prebuilt:*" --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | head -1)
wssRemediateImage=$(docker images --filter "reference=wss-remediate-prebuilt:*" --format "table {{.Repository}}:{{.Tag}}" | grep -v REPOSITORY | head -1)

echo "Found local images:"
echo "  - $wssGheAppImage"
echo "  - $wssScannerImage (validation only)"
echo "  - $wssScannerFullImage (for ECR publishing)"
echo "  - $wssScannerSastImage"
echo "  - $wssRemediateImage"

# Verify required images exist (scanner full is required for ECR, regular scanner for validation)
if [ -z "$wssGheAppImage" ] || [ -z "$wssScannerFullImage" ] || [ -z "$wssScannerSastImage" ] || [ -z "$wssRemediateImage" ]; then
    echo "Error: Required Docker images not found locally (wss-ghe-app, wss-scanner full, wss-scanner-sast, wss-remediate)"
    exit 1
fi


# Tag images for staging ECR (using prebuilt- as version prefix)
echo "Tagging images for staging ECR..."
docker tag $wssGheAppImage $ECR_REGISTRY/wss-ghe-app-prebuilt:$ZIP_VERSION
docker tag $wssScannerFullImage $ECR_REGISTRY/wss-scanner-prebuilt:$ZIP_VERSION
docker tag $wssScannerFullImage $ECR_REGISTRY/wss-scanner-full-prebuilt:$ZIP_VERSION
docker tag $wssScannerSastImage $ECR_REGISTRY/wss-scanner-sast-prebuilt:$ZIP_VERSION
docker tag $wssRemediateImage $ECR_REGISTRY/wss-remediate-prebuilt:$ZIP_VERSION

# Tag as latest if this is a latest release
if [ "$IS_LATEST" = "true" ]; then
    echo "Tagging as latest..."
    docker tag $wssGheAppImage $ECR_REGISTRY/wss-ghe-app-prebuilt:latest
    docker tag $wssScannerFullImage $ECR_REGISTRY/wss-scanner-prebuilt:latest
    docker tag $wssScannerFullImage $ECR_REGISTRY/wss-scanner-full-prebuilt:latest
    docker tag $wssScannerSastImage $ECR_REGISTRY/wss-scanner-sast-prebuilt:latest
    docker tag $wssRemediateImage $ECR_REGISTRY/wss-remediate-prebuilt:latest
fi

# Push images to staging ECR (using prebuilt- as version prefix)
echo "Pushing images to staging ECR..."
docker push $ECR_REGISTRY/wss-ghe-app-prebuilt:$ZIP_VERSION
docker push $ECR_REGISTRY/wss-scanner-prebuilt:$ZIP_VERSION
docker push $ECR_REGISTRY/wss-scanner-full-prebuilt:$ZIP_VERSION
docker push $ECR_REGISTRY/wss-scanner-sast-prebuilt:$ZIP_VERSION
docker push $ECR_REGISTRY/wss-remediate-prebuilt:$ZIP_VERSION


if [ "$IS_LATEST" = "true" ]; then
    echo "Pushing latest tags..."
    docker push $ECR_REGISTRY/wss-ghe-app-prebuilt:latest
    docker push $ECR_REGISTRY/wss-scanner-prebuilt:latest
    docker push $ECR_REGISTRY/wss-scanner-full-prebuilt:latest
    docker push $ECR_REGISTRY/wss-scanner-sast-prebuilt:latest
    docker push $ECR_REGISTRY/wss-remediate-prebuilt:latest
fi

echo "Successfully published all images to staging ECR"
echo "Published images:"
echo "  - $ECR_REGISTRY/wss-ghe-app-prebuilt:$ZIP_VERSION"
echo "  - $ECR_REGISTRY/wss-scanner-prebuilt:$ZIP_VERSION"
echo "  - $ECR_REGISTRY/wss-scanner-full-prebuilt:$ZIP_VERSION"
echo "  - $ECR_REGISTRY/wss-scanner-sast-prebuilt:$ZIP_VERSION"
echo "  - $ECR_REGISTRY/wss-remediate-prebuilt:$ZIP_VERSION"

if [ "$IS_LATEST" = "true" ]; then
    echo "  - Latest tags also pushed"
fi
