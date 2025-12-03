#!/bin/bash
set -e

ZIP_VERSION=$1
STAGING_ECR_REGISTRY=$2

echo "Publishing Docker images to Staging ECR with prod prefix (for validation only)"
echo "ZIP Version: $ZIP_VERSION"
echo "Staging ECR Registry: $STAGING_ECR_REGISTRY"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$STAGING_ECR_REGISTRY" ]; then
  echo "Error: No staging ECR registry argument provided."
  exit 1
fi

# Tag and push images to staging ECR with prod prefix for differentiation
echo "Tagging and pushing images to staging ECR with prod prefix using prebuilt convention"

# Tag and push wss-ghe-app
echo "Publishing wss-ghe-app to staging ECR with prod prefix"
docker tag prod/wss-ghe-app-prebuilt:$ZIP_VERSION $STAGING_ECR_REGISTRY/prod/wss-ghe-app-prebuilt:$ZIP_VERSION
docker push $STAGING_ECR_REGISTRY/prod/wss-ghe-app-prebuilt:$ZIP_VERSION

# Tag and push wss-scanner
echo "Publishing wss-scanner to staging ECR with prod prefix"
docker tag prod/wss-scanner-prebuilt:$ZIP_VERSION $STAGING_ECR_REGISTRY/prod/wss-scanner-prebuilt:$ZIP_VERSION
docker push $STAGING_ECR_REGISTRY/prod/wss-scanner-prebuilt:$ZIP_VERSION

# Tag and push wss-scanner-full
echo "Publishing wss-scanner-full to staging ECR with prod prefix"
docker tag prod/wss-scanner-full-prebuilt:$ZIP_VERSION $STAGING_ECR_REGISTRY/prod/wss-scanner-full-prebuilt:$ZIP_VERSION
docker push $STAGING_ECR_REGISTRY/prod/wss-scanner-full-prebuilt:$ZIP_VERSION

# Tag and push wss-scanner-sast
echo "Publishing wss-scanner-sast to staging ECR with prod prefix"
docker tag prod/wss-scanner-sast-prebuilt:$ZIP_VERSION $STAGING_ECR_REGISTRY/prod/wss-scanner-sast-prebuilt:$ZIP_VERSION
docker push $STAGING_ECR_REGISTRY/prod/wss-scanner-sast-prebuilt:$ZIP_VERSION

# Tag and push wss-remediate
echo "Publishing wss-remediate to staging ECR with prod prefix"
docker tag prod/wss-remediate-prebuilt:$ZIP_VERSION $STAGING_ECR_REGISTRY/prod/wss-remediate-prebuilt:$ZIP_VERSION
docker push $STAGING_ECR_REGISTRY/prod/wss-remediate-prebuilt:$ZIP_VERSION

echo "All images published to staging ECR with prod prefix successfully"
echo ""
echo "Published images:"
echo "- $STAGING_ECR_REGISTRY/prod/wss-ghe-app-prebuilt:$ZIP_VERSION"
echo "- $STAGING_ECR_REGISTRY/prod/wss-scanner-prebuilt:$ZIP_VERSION"
echo "- $STAGING_ECR_REGISTRY/prod/wss-scanner-full-prebuilt:$ZIP_VERSION"
echo "- $STAGING_ECR_REGISTRY/prod/wss-scanner-sast-prebuilt:$ZIP_VERSION"
echo "- $STAGING_ECR_REGISTRY/prod/wss-remediate-prebuilt:$ZIP_VERSION"
