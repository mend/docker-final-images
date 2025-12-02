#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION_PARAM=$2

echo "ZIP Version arg: $ZIP_VERSION"
if [ -n "$SAST_SELF_CONTAINED_VERSION_PARAM" ]; then
    echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION_PARAM"
fi

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi

echo "Copying Dockerfiles from pre-release and replacing ECR addresses with mend/ prefix"


### -------- Handle wss-ghe-app Dockerfile! ------------

echo "Processing wss-ghe-app Dockerfile for production"
appDockerfileTemplate=repo-integrations/wss-ghe-app/docker/Dockerfile
appdockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-ghe-app/docker/Dockerfile

if [ ! -f $appdockerfile ]; then
  echo "Error: $appdockerfile not found."
  exit 1
fi

# Copy the Dockerfile from pre-release and replace ECR with mend/ prefix
cp $appdockerfile $appDockerfileTemplate
sed -i "s|FROM [0-9]*\.dkr\.ecr\..*\.amazonaws\.com/base-repo-|FROM mend/base-repo-|g" $appDockerfileTemplate

echo "=== wss-ghe-app Dockerfile Content ==="
cat $appDockerfileTemplate
echo "=== End of wss-ghe-app Dockerfile ==="

### -------- Handle wss-scanner Dockerfile! ------------

echo "Processing wss-scanner Dockerfile for production"
scaScannerDockerfileTemplate=repo-integrations/wss-scanner/docker/Dockerfile
scaScannerDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker/Dockerfile

if [ ! -f $scaScannerDockerfile ]; then
  echo "Error: $scaScannerDockerfile not found."
  exit 1
fi

# Copy the Dockerfile from pre-release and replace ECR with mend/ prefix
cp $scaScannerDockerfile $scaScannerDockerfileTemplate
sed -i "s|FROM [0-9]*\.dkr\.ecr\..*\.amazonaws\.com/base-repo-|FROM mend/base-repo-|g" $scaScannerDockerfileTemplate

echo "=== wss-scanner Dockerfile Content ==="
cat $scaScannerDockerfileTemplate
echo "=== End of wss-scanner Dockerfile ==="

### -------- Handle wss-scanner Dockerfilefull! ------------

echo "Processing wss-scanner Dockerfilefull for production"
scaScannerDockerfilefullTemplate=repo-integrations/wss-scanner/docker/Dockerfilefull
scaScannerDockerfilefull=tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker/Dockerfilefull

if [ ! -f $scaScannerDockerfilefull ]; then
  echo "Error: $scaScannerDockerfilefull not found."
  exit 1
fi

# Copy the Dockerfile from pre-release and replace ECR with mend/ prefix
cp $scaScannerDockerfilefull $scaScannerDockerfilefullTemplate
sed -i "s|FROM [0-9]*\.dkr\.ecr\..*\.amazonaws\.com/base-repo-|FROM mend/base-repo-|g" $scaScannerDockerfilefullTemplate

echo "=== wss-scanner Dockerfilefull Content ==="
cat $scaScannerDockerfilefullTemplate
echo "=== End of wss-scanner Dockerfilefull ==="

### -------- Handle wss-scanner DockerfileSast! ------------

echo "Processing wss-scanner DockerfileSast for production"
sastScannerDockerfileTemplate=repo-integrations/wss-scanner/docker/DockerfileSast
sastScannerDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker/DockerfileSast

if [ ! -f $sastScannerDockerfile ]; then
  echo "Error: $sastScannerDockerfile not found."
  exit 1
fi

# Copy the Dockerfile from pre-release and replace ECR with mend/ prefix
cp $sastScannerDockerfile $sastScannerDockerfileTemplate
sed -i "s|FROM [0-9]*\.dkr\.ecr\..*\.amazonaws\.com/base-repo-|FROM mend/base-repo-|g" $sastScannerDockerfileTemplate

# Copy production SAST files to repo-integrations where Docker builds happen
echo "Copying production SAST files to repo-integrations directory"

# Find and copy the self-contained SAST tar.gz file (whatever version is in the prebuilt package)
SAST_TAR_FILE=$(find tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker -name "self-contained-sast-*.tar.gz" 2>/dev/null | head -1)
if [ -n "$SAST_TAR_FILE" ]; then
    echo "Copying SAST tar file: $(basename $SAST_TAR_FILE)"
    cp "$SAST_TAR_FILE" repo-integrations/wss-scanner/docker/
else
    echo "Warning: No self-contained SAST tar.gz file found in prebuilt package"
fi

# Copy the mend binary if it exists
MEND_BINARY="tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-scanner/docker/mend"
if [ -f "$MEND_BINARY" ]; then
    echo "Copying mend binary"
    cp "$MEND_BINARY" repo-integrations/wss-scanner/docker/
    chmod +x repo-integrations/wss-scanner/docker/mend
else
    echo "Warning: No mend binary found in prebuilt package"
fi

# Update SAST version references if SAST version is provided
if [ -n "$SAST_SELF_CONTAINED_VERSION_PARAM" ]; then
    echo "Updating SAST version references in DockerfileSast from auto-detected to: $SAST_SELF_CONTAINED_VERSION_PARAM"
    # Replace any existing SAST version references with the provided version
    sed -i "s|self-contained-sast-[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*|self-contained-sast-$SAST_SELF_CONTAINED_VERSION_PARAM|g" $sastScannerDockerfileTemplate
fi

echo "=== wss-scanner DockerfileSast Content ==="
cat $sastScannerDockerfileTemplate
echo "=== End of wss-scanner DockerfileSast ==="

### -------- Handle wss-remediate Dockerfile! ------------

echo "Processing wss-remediate Dockerfile for production"
remediateDockerfileTemplate=repo-integrations/wss-remediate/docker/Dockerfile
remediateDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt/wss-remediate/docker/Dockerfile

if [ ! -f $remediateDockerfile ]; then
  echo "Error: $remediateDockerfile not found."
  exit 1
fi

# Copy the Dockerfile from pre-release and replace ECR with mend/ prefix
cp $remediateDockerfile $remediateDockerfileTemplate
sed -i "s|FROM [0-9]*\.dkr\.ecr\..*\.amazonaws\.com/base-repo-|FROM mend/base-repo-|g" $remediateDockerfileTemplate

echo "=== wss-remediate Dockerfile Content ==="
cat $remediateDockerfileTemplate
echo "=== End of wss-remediate Dockerfile ==="

echo "Completed processing all Dockerfiles for production (using mend/ prefix)"
