#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Error: No release argument provided."
  exit 1
fi

if [ "$1" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct tag"
  exit 1
fi 

RELEASE=$1

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Check if ../tmp/agent-4-github-enterprise-$RELEASE.zip exists
if [ ! -f ../tmp/agent-4-github-enterprise-$RELEASE.zip ]; then
  echo "Downloading agent-4-github-enterprise-$RELEASE.zip"
  mkdir -p ../tmp
  curl -o ../tmp/agent-4-github-enterprise-$RELEASE.zip https://integrations.mend.io/release/Agent-for-GitHub-Enterprise/agent-4-github-enterprise-$RELEASE.zip
fi

if [ ! -f ../tmp/agent-4-github-enterprise-$RELEASE.zip ]; then
    echo "Error: agent-4-github-enterprise-$RELEASE.zip not found."
    exit 1
fi

# Unzip agent-4-github-enterprise-$RELEASE.zip if the folder doesn't exist
if [ ! -d ../tmp/agent-4-github-enterprise-$RELEASE ]; then
  echo "Unzipping agent-4-github-enterprise-$RELEASE.zip"
  unzip -o ../tmp/agent-4-github-enterprise-$RELEASE.zip -d ../tmp
fi

# Check if ../tmp/agent-4-github-enterprise-$RELEASE exists
if [ ! -d ../tmp/agent-4-github-enterprise-$RELEASE ]; then
    echo "Error: agent-4-github-enterprise-$RELEASE not found."
    exit 1
fi

cp ../repo-integrations/wss-ghe-app/docker/Dockerfile ../tmp/agent-4-github-enterprise-$RELEASE/wss-ghe-app/docker/
cp ../repo-integrations/wss-remediate/docker/Dockerfile ../tmp/agent-4-github-enterprise-$RELEASE/wss-remediate/docker/
cp ../repo-integrations/wss-scanner/docker/Docker* ../tmp/agent-4-github-enterprise-$RELEASE/wss-scanner/docker/

echo "Performing sanity test docker build"
cd ../tmp/agent-4-github-enterprise-$RELEASE
./build.sh

#Validate built images successfully created 
#We need to get the specifc build.sh version numbers because build.sh versions are weird
wssGheAppVersion=$(grep -Eo -m 1 'wss-ghe-app:([1-9][0-9]*)(\.[1-9][0-9]*)*(-[a-zA-Z0-9-]+)?' build.sh | head -1)
echo "Found version: $wssGheAppVersion"
if [ -z "$(docker images -q $wssGheAppVersion 2> /dev/null)" ]; then
  echo "wss-ghe-app:$RELEASE was not built successfully"
  exit 1
else
  echo "$wssGheAppVersion Built successfully!"
fi

wssScannerVersion=$(grep -Eo -m 1 'wss-scanner:([1-9][0-9]*)(\.[1-9][0-9]*)*(-[a-zA-Z0-9-]+)?' build.sh | head -1)
echo "Found version: $wssScannerVersion"
if [ -z "$(docker images -q $wssScannerVersion 2> /dev/null)" ]; then
  echo "wss-scanner:$RELEASE was not built successfully"
  exit 1
else
  echo "$wssScannerVersion Built successfully!"
fi

wssRemediateVersion=$(grep -Eo -m 1 'wss-remediate:([1-9][0-9]*)(\.[1-9][0-9]*)*(-[a-zA-Z0-9-]+)?' build.sh | head -1)
echo "Found version: $wssRemediateVersion"
if [ -z "$(docker images -q $wssRemediateVersion 2> /dev/null)" ]; then
  echo "wss-remediate:$RELEASE was not built successfully"
  exit 1
else
  echo "$wssRemediateVersion Built successfully!"
fi

echo "Building agent-4-github-enterprise-$RELEASE-with-prebuilt.zip"
cd ..
# zip up the agent-4-github-enterprise-$RELEASE folder
zip -r agent-4-github-enterprise-$RELEASE-with-prebuilt.zip agent-4-github-enterprise-$RELEASE

# sanity check unzip to a new folder
unzip -o agent-4-github-enterprise-$RELEASE-with-prebuilt.zip -d agent-4-github-enterprise-$RELEASE-with-prebuilt

exit 0
