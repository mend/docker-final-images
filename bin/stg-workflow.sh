#!/bin/bash
set -e

# Function to print usage
usage() {
    echo "Usage: $0 <ZIP_VERSION> <SAST_SELF_CONTAINED_VERSION> <IS_LATEST> <SKIP_GIT> <PREVIOUS_RELEASE>"
    echo "  ZIP_VERSION: The ZIP version to be released"
    echo "  SAST_SELF_CONTAINED_VERSION: The version of the SAST self-contained engine (optional, defaults to ZIP_VERSION)"
    echo "  IS_LATEST: 'true' to merge to develop branch, 'false' to create release branch only"
    echo "  SKIP_GIT: 'true' to skip git operations, 'false' for normal operation"
    echo "  PREVIOUS_RELEASE: Previously deployed final image tag"
    echo ""
    echo "Example: $0 1.2.3 2.1.0 true false 1.2.2"
    echo "Example: $0 1.2.3 '' false true 1.2.2   # Uses ZIP_VERSION for SAST"
    exit 1
}

# Check arguments
if [ -z "$1" ] || [ -z "$3" ] || [ -z "$4" ] || [ -z "$5" ]; then
    echo "Error: Missing required arguments."
    usage
fi

if [ "$1" = "1.1.1" ] || [ "$5" = "1.1.1" ]; then
    echo "Error: Default version tags provided. Please provide correct versions."
    exit 1
fi

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2
IS_LATEST=$3
SKIP_GIT=$4
PREVIOUS_RELEASE=$5

RELEASE_BRANCH="release/$ZIP_VERSION"

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path/.."

echo "=== Starting Staging Workflow ==="
echo "ZIP Version: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Skip Git: $SKIP_GIT"
echo "Previous Release: $PREVIOUS_RELEASE"
echo "Release Branch: $RELEASE_BRANCH"
echo ""

# Step 1: Download ZIP file and SAST files
echo "=== Step 1: Downloading files ==="
./bin/stg-download.sh "$ZIP_VERSION" "$SAST_SELF_CONTAINED_VERSION"

# Step 2: Modify Dockerfiles
echo "=== Step 2: Modifying Dockerfiles ==="
./bin/stg-copy.sh "$ZIP_VERSION" "$PREVIOUS_RELEASE"

# Step 3: Build and test images
echo "=== Step 3: Building and testing Docker images ==="
./bin/stg-build.sh "$ZIP_VERSION" "$SAST_SELF_CONTAINED_VERSION"

# Step 4: Publish to Staging ECR
echo "=== Step 4: Publishing to Staging ECR ==="
./bin/stg-publish-images.sh "$ZIP_VERSION" "$SAST_SELF_CONTAINED_VERSION" "054331651301.dkr.ecr.us-east-1.amazonaws.com" "$IS_LATEST"

# Step 5: Upload ZIP file
echo "=== Step 5: Uploading ZIP file ==="
./bin/stg-upload-s3.sh "$ZIP_VERSION"

# Step 6: Git operations (if not skipped)
echo "=== Step 6: Git operations ==="
./bin/stg-git-operations.sh "$ZIP_VERSION" "$SAST_SELF_CONTAINED_VERSION" "$IS_LATEST" "$SKIP_GIT"

# Step 7: Send Slack notification
echo "=== Step 7: Sending Slack notification ==="
./bin/stg-send-notification.sh "$ZIP_VERSION" "$SAST_SELF_CONTAINED_VERSION" "$IS_LATEST" "PLACEHOLDER_SLACK_WEBHOOK_URL"

echo ""
echo "=== Staging Workflow Completed Successfully ==="
echo "Release branch created: $RELEASE_BRANCH"
echo "ZIP file created: tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt-staging.zip"
echo "Docker images built and validated"
