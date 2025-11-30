#!/bin/bash
set -e

# Function to apply Docker file modifications
apply_dockerfile_modifications() {
    local dockerfile=$1
    local config_name=$2
    local config_file="config/${config_name}-modifications.txt"

    if [ -f "$config_file" ] && [ -s "$config_file" ]; then
        echo "Applying modifications to $dockerfile using $config_file"
        ./bin/modify-dockerfile.sh "$dockerfile" "$config_file"
    else
        echo "No modifications configured for $dockerfile (config: $config_file)"
    fi
}

ZIP_VERSION=$1
PREVIOUS_RELEASE=$2
SAST_SELF_CONTAINED_VERSION=${3:-$ZIP_VERSION}

echo "ZIP Version arg: $ZIP_VERSION"
echo "Previous Release arg: $PREVIOUS_RELEASE"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi

if [ -z "$PREVIOUS_RELEASE" ]; then
  echo "Error: No previous release argument provided."
  exit 1
fi

if [ "$PREVIOUS_RELEASE" = "1.1.1" ]; then
  echo "Error: Default previous release version tag provided. Please provide the correct tag"
  exit 1
fi


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

sastScannerDockerfileTemplate=repo-integrations/wss-scanner/docker/DockerfileSast
if ! grep -q $PREVIOUS_RELEASE "$sastScannerDockerfileTemplate"; then
  echo "Previous Release does not exist in scanner dockerfileSast template. Please check that Previous Release argument is correct."
  exit 1
fi

remediateDockerfileTemplate=repo-integrations/wss-remediate/docker/Dockerfile
if ! grep -q $PREVIOUS_RELEASE "$remediateDockerfileTemplate"; then
  echo "Previous Release does not exist in remediate dockerfile template. Please check that Previous Release argument is correct."
  exit 1
fi

### -------- Handle wss-ghe-app Dockerfile! ------------

echo "Processing wss-ghe-app Dockerfile"
appdockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-ghe-app/docker/Dockerfile
if [ ! -f $appdockerfile ]; then
  echo "Error: $appdockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $appDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$ZIP_VERSION/g" $appDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $appdockerfile >> $appDockerfileTemplate

### -------- Handle wss-scanner Dockerfile! ------------

echo "Processing wss-scanner Dockerfile"
scaScannerDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/Dockerfile

if [ ! -f $scaScannerDockerfile ]; then
  echo "Error: $scaScannerDockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $scaScannerDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$ZIP_VERSION/g" $scaScannerDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent, excluding version scanner block
sed '1,/# END OF BASE IMAGE/ d' $scaScannerDockerfile | \
sed '/^# Temporarily copying.*Dockerfile.*installed-versions/,/&& rm \/tmp\/target-dockerfile && rm \/generate_versions_json\.sh$/d' >> $scaScannerDockerfileTemplate

### -------- Handle wss-scanner Dockerfilefull! ------------

echo "Processing wss-scanner Dockerfilefull"
scaScannerDockerfilefull=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/Dockerfilefull

if [ ! -f $scaScannerDockerfilefull ]; then
  echo "Error: $scaScannerDockerfilefull not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $scaScannerDockerfilefullTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$ZIP_VERSION/g" $scaScannerDockerfilefullTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent, excluding version scanner block
sed '1,/# END OF BASE IMAGE/ d' $scaScannerDockerfilefull | \
sed '/^# Temporarily copying.*Dockerfile.*installed-versions/,/&& rm \/tmp\/target-dockerfile && rm \/generate_versions_json\.sh$/d' >> $scaScannerDockerfilefullTemplate

### -------- Handle wss-scanner DockerfileSast! ------------

echo "Processing wss-scanner DockerfileSast"
sastScannerDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/DockerfileSast
if [ ! -f $sastScannerDockerfile ]; then
  echo "Error: $sastScannerDockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $sastScannerDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$ZIP_VERSION/g" $sastScannerDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $sastScannerDockerfile >> $sastScannerDockerfileTemplate

# Create dynamic SAST configuration with current version
echo "Creating dynamic SAST configuration for version $SAST_SELF_CONTAINED_VERSION"
cat > "config/wss-scanner-sast-modifications-dynamic.txt" << EOF
# Comment out the entire mono installation block
COMMENT_BLOCK:# Download the SAST CLI

# Add all SAST engine installation commands as a bulk after END OF BASE IMAGE
ADD_AFTER:# END OF BASE IMAGE:COPY self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz .|COPY mend /sast/bin/mend|RUN chmod 0775 /sast/bin/mend|ENV PATH="/sast/bin:\${PATH}"|RUN echo "Extracting Mend SAST artifacts"|RUN mkdir -p \${USER_HOME}/.mend \\|    && tar -xzf self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz -C \${USER_HOME}/.mend \\|    && chown -R wss-scanner:wss-scanner \${USER_HOME}/.mend \\|    && rm self-contained-sast-$SAST_SELF_CONTAINED_VERSION.tar.gz
EOF

apply_dockerfile_modifications $sastScannerDockerfileTemplate "wss-scanner-sast-modifications-dynamic"

# Clean up dynamic file
rm -f "config/wss-scanner-sast-modifications-dynamic.txt"

### -------- Handle wss-remediate Dockerfile! ------------

echo "Processing wss-remediate Dockerfile"
remediateDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-remediate/docker/Dockerfile

if [ ! -f $remediateDockerfile ]; then
  echo "Error: $remediateDockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $remediateDockerfileTemplate
#Replace the previous release tag with the new tag
sed -i "s/$PREVIOUS_RELEASE/$ZIP_VERSION/g" $remediateDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $remediateDockerfile >> $remediateDockerfileTemplate

echo "Completed processing all Dockerfiles"

# Apply any additional Docker file modifications to other templates
echo "Applying additional modifications to other services..."
apply_dockerfile_modifications $appDockerfileTemplate "wss-ghe-app"
apply_dockerfile_modifications $scaScannerDockerfileTemplate "wss-scanner"
apply_dockerfile_modifications $scaScannerDockerfilefullTemplate "wss-scanner-full"
apply_dockerfile_modifications $remediateDockerfileTemplate "wss-remediate"

echo "All Dockerfile processing and modifications completed"

