#!/bin/bash
set -e

ZIP_VERSION=$1
SAST_SELF_CONTAINED_VERSION=$2
IS_LATEST=$3
SKIP_GIT=$4



if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$SAST_SELF_CONTAINED_VERSION" ]; then
  echo "Error: No SAST self-contained version argument provided. Setting to $ZIP_VERSION."
  SAST_SELF_CONTAINED_VERSION=$ZIP_VERSION
fi

if [ -z "$IS_LATEST" ]; then
  echo "Error: No IsLatest argument provided."
  exit 1
fi

if [ -z "$SKIP_GIT" ]; then
  echo "Error: No SkipGit argument provided."
  exit 1
fi

echo "Processing Git operations for staging release"
echo "ZIP Version: $ZIP_VERSION"
echo "SAST Self-Contained Version: $SAST_SELF_CONTAINED_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Skip Git: $SKIP_GIT"

# If SkipGit is true, don't modify repo
if [ "$SKIP_GIT" = "true" ]; then
    echo "SkipGit is true, skipping all git operations"
    exit 0
fi

# Configure git
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

# Ensure we're on develop branch
echo "Checking out develop branch..."
git checkout develop
git pull origin develop

# Create Release branch
RELEASE_BRANCH="release/$ZIP_VERSION"
echo "Creating release branch: $RELEASE_BRANCH"
git checkout -b $RELEASE_BRANCH
git push --set-upstream origin $RELEASE_BRANCH

# If files changed, add, commit and push
if [[ `git status --porcelain` ]]; then
    echo "Changes detected, committing and pushing..."
    git add repo-integrations/
    git commit -m "feat: Update Dockerfiles for staging release $ZIP_VERSION with SAST self-contained $SAST_SELF_CONTAINED_VERSION"
    git push
else
    echo "No changes were detected in Dockerfiles"
fi

 # Create tag
git tag -a $$ZIP_VERSION -m "Automated Tag for Release $ZIP_VERSION"
git push origin --tags


# If IsLatest is true, merge to develop branch
if [ "$IS_LATEST" = "true" ]; then
    echo "IsLatest is true, merging changes to develop branch"
    git checkout develop
    git merge $RELEASE_BRANCH --no-ff -m "feat: Merge staging release $ZIP_VERSION"
    git push origin develop
    echo "Successfully merged release branch to develop"
else
    echo "IsLatest is false, not merging to develop branch"
fi

echo "Git operations completed successfully"
echo "Release branch created: $RELEASE_BRANCH"
if [ "$IS_LATEST" = "true" ]; then
    echo "Changes merged to develop branch"
fi
