#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=${2:-$ZIP_VERSION}
PREVIOUS_TAG=${3:-""}

# Check if ECR_REGISTRY is set
if [ -z "$ECR_REGISTRY" ]; then
  echo "Error: ECR_REGISTRY environment variable not set."
  exit 1
fi

echo "ZIP Version arg: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "ECR Registry: $ECR_REGISTRY"

if [ -n "$PREVIOUS_TAG" ]; then
    echo "Previous Tag (optional): $PREVIOUS_TAG"
else
    echo "Previous Tag: Not provided (using ECR pattern-based replacement)"
fi

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ "$ZIP_VERSION" = "1.1.1" ]; then
  echo "Error: Default version tag provided. Please provide the correct ZIP version"
  exit 1
fi


### -------- Handle wss-ghe-app Dockerfile! ------------

echo "Processing wss-ghe-app Dockerfile"
appDockerfileTemplate=repo-integrations/wss-ghe-app/docker/Dockerfile
appdockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-ghe-app/docker/Dockerfile

if [ ! -f $appdockerfile ]; then
  echo "Error: $appdockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $appDockerfileTemplate
#Replace the base image to use ECR instead of mend/ for staging
sed -i "s|FROM $ECR_REGISTRY/base-repo-controller:.*|FROM $ECR_REGISTRY/base-repo-controller:$ZIP_VERSION|g" $appDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $appdockerfile >> $appDockerfileTemplate

echo "=== Current wss-ghe-app Dockerfile Template Content ==="
cat $appDockerfileTemplate
echo "=== End of wss-ghe-app Dockerfile Template ==="

### -------- Handle wss-remediate Dockerfile! ------------

echo "Processing wss-scanner Dockerfile"
scaScannerDockerfileTemplate=repo-integrations/wss-scanner/docker/Dockerfile
scaScannerDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/Dockerfile

if [ ! -f $scaScannerDockerfile ]; then
  echo "Error: $scaScannerDockerfile not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $scaScannerDockerfileTemplate
#Replace the base image to use ECR instead of mend/ for staging
sed -i "s|FROM $ECR_REGISTRY/base-repo-scanner:.*|FROM $ECR_REGISTRY/base-repo-scanner:$ZIP_VERSION|g" $scaScannerDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent, excluding version scanner block
sed '1,/# END OF BASE IMAGE/ d' $scaScannerDockerfile | \
sed '/^# Temporarily copying.*Dockerfile.*installed-versions/,/&& rm \/tmp\/target-dockerfile && rm \/generate_versions_json\.sh$/d' >> $scaScannerDockerfileTemplate


echo "=== Current wss-scanner Dockerfile Template Content ==="
cat $scaScannerDockerfileTemplate
echo "=== End of wss-scanner Dockerfile Template ==="

### -------- Handle wss-scanner Dockerfilefull! ------------

echo "Processing wss-scanner Dockerfilefull"
scaScannerDockerfilefullTemplate=repo-integrations/wss-scanner/docker/Dockerfilefull
scaScannerDockerfilefull=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/Dockerfilefull

if [ ! -f $scaScannerDockerfilefull ]; then
  echo "Error: $scaScannerDockerfilefull not found."
  exit 1
fi

#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $scaScannerDockerfilefullTemplate
#Replace the base image to use ECR instead of mend/ for staging with -full suffix
sed -i "s|FROM $ECR_REGISTRY/base-repo-scanner:.*-full|FROM $ECR_REGISTRY/base-repo-scanner:$ZIP_VERSION-full|g" $scaScannerDockerfilefullTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent, excluding version scanner block
sed '1,/# END OF BASE IMAGE/ d' $scaScannerDockerfilefull | \
sed '/^# Temporarily copying.*Dockerfile.*installed-versions/,/&& rm \/tmp\/target-dockerfile && rm \/generate_versions_json\.sh$/d' >> $scaScannerDockerfilefullTemplate

echo "=== Current wss-scanner Dockerfilefull Template Content ==="
cat $scaScannerDockerfilefullTemplate
echo "=== End of wss-scanner Dockerfilefull Template ==="
### -------- Handle wss-scanner DockerfileSast! ------------

echo "Processing wss-scanner DockerfileSast"
sastScannerDockerfileTemplate=repo-integrations/wss-scanner/docker/DockerfileSast
sastScannerDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-scanner/docker/DockerfileSast

if [ ! -f $sastScannerDockerfile ]; then
  echo "Error: $sastScannerDockerfile not found."
  exit 1
fi


#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $sastScannerDockerfileTemplate
#Replace the base image version using pattern matching for SAST scanner
sed -i "s|FROM $ECR_REGISTRY/base-repo-scanner-sast:.*|FROM $ECR_REGISTRY/base-repo-scanner-sast:$ZIP_VERSION|g" $sastScannerDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $sastScannerDockerfile >> $sastScannerDockerfileTemplate

# Apply SAST modifications directly (comment out SAST CLI download and add our files)
echo "Applying SAST modifications directly to $sastScannerDockerfileTemplate"

# Comment out the SAST CLI download block
sed -i '/# Download the SAST CLI/,/^$/s/^/# /' $sastScannerDockerfileTemplate

# Add SAST installation commands after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/a\
COPY self-contained-sast-'$SAST_SELF_CONTAINED_VERSION'.tar.gz .\
COPY mend /sast/bin/mend\
RUN chmod 0775 /sast/bin/mend\
ENV PATH="/sast/bin:${PATH}"\
RUN echo "Extracting Mend SAST artifacts"\
RUN mkdir -p ${USER_HOME}/.mend \\\
    && tar -xzf self-contained-sast-'$SAST_SELF_CONTAINED_VERSION'.tar.gz -C ${USER_HOME}/.mend \\\
    && chown -R wss-scanner:wss-scanner ${USER_HOME}/.mend \\\
    && rm self-contained-sast-'$SAST_SELF_CONTAINED_VERSION'.tar.gz' $sastScannerDockerfileTemplate


echo "=== Current wss-scanner DockerfileSast Template Content ==="
cat $sastScannerDockerfileTemplate
echo "=== End of wss-scanner DockerfileSast Template ==="

### -------- Handle wss-remediate Dockerfile! ------------

echo "Processing wss-remediate Dockerfile"
remediateDockerfileTemplate=repo-integrations/wss-remediate/docker/Dockerfile
remediateDockerfile=tmp/agent-4-github-enterprise-$ZIP_VERSION/wss-remediate/docker/Dockerfile

if [ ! -f $remediateDockerfile ]; then
  echo "Error: $remediateDockerfile not found."
  exit 1
fi


#First delete everything in repo file after # START OF FINAL IMAGE
sed -i '/# START OF FINAL IMAGE/{s/\(.*# START OF FINAL IMAGE\).*/\1/;q}' $remediateDockerfileTemplate
#Replace the base image version using pattern matching
sed -i "s|FROM $ECR_REGISTRY/base-repo-remediate:.*|FROM $ECR_REGISTRY/base-repo-remediate:$ZIP_VERSION|g" $remediateDockerfileTemplate
#Now copy over everything after # END OF BASE IMAGE from the downloaded agent
sed '1,/# END OF BASE IMAGE/ d' $remediateDockerfile >> $remediateDockerfileTemplate

echo "=== Current wss-remediate Dockerfile Template Content ==="
cat $remediateDockerfileTemplate
echo "=== End of wss-remediate Dockerfile Template ==="

echo "Completed processing all Dockerfiles"

