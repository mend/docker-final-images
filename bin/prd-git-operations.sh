#!/bin/bash
set -e

ZIP_VERSION=$1
IS_LATEST=$2
SKIP_GIT=$3
FINAL_STEP=${4:-"false"}

echo "Production Git Operations"
echo "ZIP Version: $ZIP_VERSION"
echo "Is Latest: $IS_LATEST"
echo "Skip Git: $SKIP_GIT"
echo "Final Step: $FINAL_STEP"

if [ "$SKIP_GIT" = "true" ]; then
    echo "SkipGit is true, skipping git operations"
    exit 0
fi

STAGING_BRANCH="release/$ZIP_VERSION"
PRODUCTION_BRANCH="production/$ZIP_VERSION"

# Note: using Github Actions bot
git config user.name "github-actions[bot]"
git config user.email "41898282+github-actions[bot]@users.noreply.github.com"

if [ "$FINAL_STEP" = "true" ]; then
    # Final step - commit production changes, tag, and merge if needed
    echo "Performing final git operations for production"

    # Switch to production branch
    git checkout $PRODUCTION_BRANCH

    # If files changed, add, commit and push
    if [[ `git status --porcelain` ]]; then
        echo "Changes detected, committing and pushing production changes."
        git add .
        git commit -m "Production version with mend/ prefix for $ZIP_VERSION"
        git push
    else
        echo "No changes detected, skipping commit"
    fi

    # Create production tag
    git tag -a $ZIP_VERSION-prod -m "Production Release $ZIP_VERSION" || echo "Tag may already exist"
    git push origin --tags

    # Merge production branch to main if IsLatest
    if [ "$IS_LATEST" = "true" ]; then
        echo "IsLatest is true, merging PRODUCTION branch to main"
        git checkout main
        git merge $PRODUCTION_BRANCH --commit --no-edit
        git push
        echo "Production branch merged to main (customers get production version)"
    else
        echo "IsLatest is false, production branch remains separate"
    fi
else
    # Initial step - create production branch from staging release
    echo "Creating production branch from staging release"

    # Checkout existing staging release branch (created by staging pipeline)
    git checkout $STAGING_BRANCH

    # Check if production branch already exists
    if git show-ref --verify --quiet refs/heads/$PRODUCTION_BRANCH; then
        echo "Production branch $PRODUCTION_BRANCH already exists, checking it out"
        git checkout $PRODUCTION_BRANCH
    else
        echo "Creating new production branch $PRODUCTION_BRANCH from staging release"
        git checkout -b $PRODUCTION_BRANCH
        git push origin $PRODUCTION_BRANCH
    fi
    echo "Production branch $PRODUCTION_BRANCH is ready"
fi

echo "Git operations completed"


