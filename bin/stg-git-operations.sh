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
  echo "Error: No SAST self-contained version argument provided."
  exit 1
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

# Create Release branch from current state (main with modifications)
RELEASE_BRANCH="release/$ZIP_VERSION"
echo "Creating release branch: $RELEASE_BRANCH from current state..."
git checkout -b $RELEASE_BRANCH
git push --set-upstream origin $RELEASE_BRANCH

# If files changed, add, commit and push
if [[ `git status --porcelain` ]]; then
    echo "OK: Changes detected, committing and pushing..."
    git add .
    git commit -m "feat: Update Dockerfiles for staging release $ZIP_VERSION with SAST self-contained $SAST_SELF_CONTAINED_VERSION"
    git push
else
    echo "WARNING: No changes were detected. This is fine though, skipping commit"
fi

# Create tag
git tag -a "$ZIP_VERSION" -m "Automated Staging Release $ZIP_VERSION with SAST $SAST_SELF_CONTAINED_VERSION"
git push origin --tags

# Create GitHub release
if [ "$IS_LATEST" = "false" ]; then
    gh release create "$ZIP_VERSION" --latest=false --generate-notes --target "$RELEASE_BRANCH" --title "Staging Release $ZIP_VERSION"
    echo "IsLatest is false, not merging release branch back into develop"
    exit 0
else
    gh release create "$ZIP_VERSION" --latest --generate-notes --target "$RELEASE_BRANCH" --title "Staging Release $ZIP_VERSION"
fi

# Merge release branch back into develop
echo "IsLatest is true, merging release branch back into develop..."
git checkout develop
git merge "$RELEASE_BRANCH" --commit --no-edit
git push

echo "Git operations completed successfully"
echo "Release branch created: $RELEASE_BRANCH"
echo "Changes merged to develop branch"
