#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi

if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
  echo "Error: No SAST self-contained version argument provided."
  exit 1
fi

if [ "$SAST_SELF_CONTAINED_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct SAST self-contained version"
  exit 1
fi



parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

echo "Building staging images for ZIP version: $ZIP_VERSION with SAST self-contained version: $SAST_SELF_CONTAINED_VERSION"

# Copy updated Dockerfiles to the extracted folder
cp ../repo-integrations/wss-ghe-app/docker/Dockerfile ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-ghe-app/docker/
cp ../repo-integrations/wss-remediate/docker/Dockerfile ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-remediate/docker/
cp ../repo-integrations/wss-scanner/docker/Docker* ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/

# Print updated Dockerfile contents for logging and triage
echo "=== Updated wss-ghe-app Dockerfile Content ==="
cat ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-ghe-app/docker/Dockerfile
echo "=== End of wss-ghe-app Dockerfile ==="

echo "=== Updated wss-remediate Dockerfile Content ==="
cat ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-remediate/docker/Dockerfile
echo "=== End of wss-remediate Dockerfile ==="

echo "=== Updated wss-scanner Dockerfile Content ==="
cat ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/Dockerfile
echo "=== End of wss-scanner Dockerfile ==="

echo "=== Updated wss-scanner Dockerfilefull Content ==="
cat ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/Dockerfilefull
echo "=== End of wss-scanner Dockerfilefull ==="

echo "=== Updated wss-scanner DockerfileSast Content ==="
cat ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/DockerfileSast
echo "=== End of wss-scanner DockerfileSast ==="


# Copy SAST engine files to the package
echo "Adding SAST engine files to the package"

# Copy SAST files to wss-scanner/docker directory for Docker build access
echo "Copying SAST files to wss-scanner/docker directory"
if [ -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ]; then
    cp ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/
    echo "Added SAST tar file to wss-scanner/docker: self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz"
else
    echo "Warning: SAST tar file not found for wss-scanner/docker copy"
fi

if [ -f ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend ]; then
    cp ../tmp/sast-engine-$SAST_SELF_CONTAINED_VERSION/mend ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/
    chmod +x ../tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/mend
    echo "Added SAST binary file to wss-scanner/docker: mend"
else
    echo "Warning: SAST binary file not found for wss-scanner/docker copy"
fi

echo "Performing sanity test docker build"

cd ../tmp/agent-4-github-enterprise-$ZIP_VERSION
docker build -t wss-ghe-app-prebuilt:$ZIP_VERSION wss-ghe-app/docker
docker build -t wss-scanner-prebuilt:$ZIP_VERSION wss-scanner/docker
docker build -t wss-scanner-sast-prebuilt:$ZIP_VERSION -f wss-scanner/docker/DockerfileSast wss-scanner/docker
docker build -t wss-scanner-full-prebuilt:$ZIP_VERSION -f wss-scanner/docker/Dockerfilefull wss-scanner/docker
docker build -t wss-remediate-prebuilt:$ZIP_VERSION wss-remediate/docker

#Validate built images successfully created
echo "Validating built images..."

if [ -z "$(docker images -q wss-ghe-app-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "wss-ghe-app-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "wss-ghe-app-prebuilt:$ZIP_VERSION built successfully!"
fi

if [ -z "$(docker images -q wss-scanner-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "wss-scanner-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "wss-scanner-prebuilt:$ZIP_VERSION built successfully!"
fi

if [ -z "$(docker images -q wss-scanner-sast-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "wss-scanner-sast-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "wss-scanner-sast-prebuilt:$ZIP_VERSION built successfully!"
fi

if [ -z "$(docker images -q wss-scanner-full-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "wss-scanner-full-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "wss-scanner-full-prebuilt:$ZIP_VERSION built successfully!"
fi

if [ -z "$(docker images -q wss-remediate-prebuilt:$ZIP_VERSION 2> /dev/null)" ]; then
  echo "wss-remediate-prebuilt:$ZIP_VERSION was not built successfully"
  exit 1
else
  echo "wss-remediate-prebuilt:$ZIP_VERSION built successfully!"
fi

echo "Building agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip"
cd ..
# zip up the agent-4-github-enterprise-$ZIP_VERSION folder with SAST files included
mv agent-4-github-enterprise-$ZIP_VERSION agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt
zip -r agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt

# sanity check unzip to a new folder
unzip -o agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt.zip -d agent-4-github-enterprise-$ZIP_VERSION-with-prebuilt

echo "Staging build completed successfully!"
exit 0
