#!/bin/bash
set -e

ZIP_VERSION=$1
IS_LATEST=$2
SKIP_GIT=$3

echo "Production Git Operations"
echo "ZIP Version: $ZIP_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Skip Git: $SKIP_GIT"

if [ -z "$ZIP_VERSION" ]; then
  echo "Error: No ZIP version argument provided."
  exit 1
fi

if [ -z "$IS_LATEST" ]; then
  echo "Error: No IsLatest argument provided."
  exit 1
fi

if [ "$SKIP_GIT" = "true" ]; then
    echo "SkipGit is true, skipping git operations"
    exit 0
fi

echo "Processing Git operations for Production release"
echo "ZIP Version: $ZIP_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Skip Git: $SKIP_GIT"

# Note: using Github Actions bot
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

echo "Performing final git operations for production"

STAGING_BRANCH="release/$ZIP_VERSION"
PRODUCTION_BRANCH="production/$ZIP_VERSION"

# Checkout existing staging release branch (created by staging pipeline)
# Create production branch from staging release
echo "Creating Production branch: $PRODUCTION_BRANCH"

git checkout $STAGING_BRANCH
git checkout -b $PRODUCTION_BRANCH
git push --set-upstream origin $PRODUCTION_BRANCH


# If files changed, add, commit and push production branch
if [[ `git status --porcelain` ]]; then
    echo "Changes detected, committing and pushing..."
    git add repo-integrations/
    git commit -m "Production version with mend/ prefix for $ZIP_VERSION"
    git push
else
    echo "No changes detected, skipping commit"
fi

 # Create tag
git tag -a $ZIP_VERSION-prod -m "Production Release $ZIP_VERSION" || echo "Tag may already exist"
git push origin --tags


# If IsLatest is true, merge to develop branch
if [ "$IS_LATEST" = "true" ]; then
    echo "IsLatest is true, merging PRODUCTION branch to main"
    git checkout main
    git pull origin main
    git merge $PRODUCTION_BRANCH --no-ff -m "feat: Merge production branch $ZIP_VERSION to main"
    git push origin main
    echo "Successfully merged production release branch to main"
else
    echo "IsLatest is false, not merging to main branch"
fi

echo "Git operations completed successfully"
echo "Production branch created: $PRODUCTION_BRANCH"