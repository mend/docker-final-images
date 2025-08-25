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

if [ -z "$2" ]; then
  echo "Error: No previous release argument provided."
  exit 1
fi 

if [ "$2" = "1.1.1" ]; then
  echo "Error: Default previous release version tag provided. Please provide the correct tag"
  exit 1
fi

RELEASE=$1
PREVIOUS_RELEASE=$2
echo "Release arg: $RELEASE"
echo "Previous Release arg: $PREVIOUS_RELEASE"

### -------- Test that previous release exists in the old dockerfile templates ---------
appDockerfileTemplate=repo-integrations/wss-ghe-app/docker/Dockerfile
if ! grep -q $PREVIOUS_RELEASE "$appDockerfileTemplate"; then
  echo "Previous Release does not exist in controller dockerfile template. Please check that Previous Release argument is correct."
  exit 1
fi
scaScannerDockerfileTemplate=repo-integrations/wss-scanner/docker/Dockerfile
if ! grep -q $PREVIOUS_RELEASE "$scaScannerDockerfileTemplate"; then
  echo "Previous Release does not exist in scanner dockerfile template. Please check that Previous Release argument is correct."
  exit 1
fi
scaScannerDockerfilefullTemplate=repo-integrations/wss-scanner/docker/Dockerfilefull
if ! grep -q $PREVIOUS_RELEASE "$scaScannerDockerfilefullTemplate"; then
  echo "Previous Release does not exist in scanner dockerfilefull template. Please check that Previous Release argument is correct."
  exit 1
fi
remediateDockerfileTemplate=repo-integrations/wss-remediate/docker/Dockerfile
if ! grep -q $PREVIOUS_RELEASE "$remediateDockerfileTemplate"; then
  echo "Previous Release does not exist in remediate dockerfile template. Please check that Previous Release argument is correct."
  exit 1
fi

### -------- Handle wss-ghe-app Dockerfile! ------------

echo "Processing wss-ghe-app Dockerfile"
appdockerfile=tmp/agent-4-github-enterprise-$RELEASE/wss-ghe-app/docker/Dockerfile
if [ ! -f $appdockerfile ]; then
  echo "Error: $appdockerfile not found."
  exit 1
fi


#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $appDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$RELEASE/g" $appDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $appdockerfile >> $appDockerfileTemplate


### -------- Handle wss-scanner Dockerfile! ------------

echo "Processing wss-scanner Dockerfile"
scaScannerDockerfile=tmp/agent-4-github-enterprise-$RELEASE/wss-scanner/docker/Dockerfile


if [ ! -f $scaScannerDockerfile ]; then
  echo "Error: $scaScannerDockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $scaScannerDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$RELEASE/g" $scaScannerDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent, excluding version scanner block
sed '1,/# END OF BASE IMAGE/ d' $scaScannerDockerfile | \
sed '/^# Temporarily copying.*Dockerfile.*installed-versions/,/&& rm \/tmp\/target-dockerfile && rm \/generate_versions_json\.sh$/d' >> $scaScannerDockerfileTemplate


### -------- Handle wss-scanner Dockerfilefull! ------------

echo "Processing wss-scanner Dockerfilefull"
scaScannerDockerfilefull=tmp/agent-4-github-enterprise-$RELEASE/wss-scanner/docker/Dockerfilefull


if [ ! -f $scaScannerDockerfilefull ]; then
  echo "Error: $scaScannerDockerfilefull not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $scaScannerDockerfilefullTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$RELEASE/g" $scaScannerDockerfilefullTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent, excluding version scanner block
sed '1,/# END OF BASE IMAGE/ d' $scaScannerDockerfilefull | \
sed '/^# Temporarily copying.*Dockerfile.*installed-versions/,/&& rm \/tmp\/target-dockerfile && rm \/generate_versions_json\.sh$/d' >> $scaScannerDockerfilefullTemplate

### -------- Handle wss-remediate Dockerfile! ------------

echo "Processing wss-remediate Dockerfile"
remediateDockerfile=tmp/agent-4-github-enterprise-$RELEASE/wss-remediate/docker/Dockerfile


if [ ! -f $remediateDockerfile ]; then
  echo "Error: $remediateDockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $remediateDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$RELEASE/g" $remediateDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $remediateDockerfile >> $remediateDockerfileTemplate

echo "Completed processing all Dockerfiles"
