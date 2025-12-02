# Production Workflow Documentation

This document describes the production workflow for deploying Docker images to the production environment using the `main` branch.

## Overview

The production workflow is designed to:
- Download pre-built ZIP files from the staging bucket
- Auto-detect SAST version from staging files (no manual input required)
- Use `mend/` prefix for base images (public images) instead of ECR
- Work from the `main` branch and create production releases
- Replace staging SAST files with production versions
- Deploy to staging ECR with "prod/" prefix (for validation only)
- Upload final ZIP to production S3 bucket
- Send notifications to production Slack channels

## Key Features

- **Auto-detection of SAST version**: The workflow automatically detects the SAST version used in the staging pipeline, ensuring consistency
- **Simplified parameters**: Only requires ZIP version, latest flag, and git skip flag
- **Pattern-based Dockerfile replacement**: Uses regex patterns to replace ECR references with mend/ prefix
- **Production file replacement**: Downloads production SAST files and replaces the staging versions seamlessly

## Workflow Steps

1. **Download pre-built ZIP from staging** - Downloads the ZIP created by the staging pipeline
2. **Create production branch from staging release** - Creates `production/X.Y.Z` branch from existing `release/X.Y.Z`
3. **Modify Dockerfiles for production** - Changes ECR references to use `mend/` prefix
4. **Download production SAST files** - Replaces staging SAST files with production versions
5. **Build and test images** - Builds Docker images with production configuration
6. **Publish to Staging ECR with prod prefix** - Pushes images to staging ECR under "prod/" namespace for validation
7. **Upload to S3** - Uploads final ZIP to production S3 bucket
8. **Finalize git operations** - Commits changes to production branch, creates tags
9. **Merge to main if IsLatest** - Merges PRODUCTION branch (with mend/ prefix) to main for customer use
10. **Send notifications** - Posts to production Slack channel

## Git Branch Strategy

- **Staging pipeline** creates: `release/X.Y.Z` (with ECR staging images)
- **Production pipeline** creates: `production/X.Y.Z` (with mend/ prefix for customers)
- **Hotfixes** can be created from: `release/X.Y.Z` (preserving staging configuration)
- **Main branch** gets: Production version (mend/ prefix) when IsLatest=true

## Scripts

### Core Scripts

1. **`prd-workflow.sh`** - Main orchestration script for production
2. **`prd-download.sh`** - Downloads pre-built ZIP from staging bucket
3. **`prd-copy.sh`** - Modifies Dockerfiles to use mend/ prefix
4. **`prd-git-operations.sh`** - Handles git operations (initial and final)
5. **`prd-download-prod-files.sh`** - Downloads production SAST files and replaces staging versions
6. **`prd-build.sh`** - Builds and tests Docker images
7. **`prd-publish-images.sh`** - Publishes images to production ECR
8. **`prd-upload-s3.sh`** - Uploads ZIP to production S3 bucket
9. **`prd-send-notification.sh`** - Sends Slack notifications

## Environment Variables

Required environment variables for the production workflow:

```bash
# Staging ECR Registry (for production validation images with prod prefix)
export STAGING_ECR_REGISTRY=054331651301.dkr.ecr.us-east-1.amazonaws.com

# Production Slack webhook (for notifications)
export PRD_SLACK_WEBHOOK_URL=<your-production-slack-webhook>
```

## Usage

### Manual Execution

```bash
# Set required environment variables
export STAGING_ECR_REGISTRY=054331651301.dkr.ecr.us-east-1.amazonaws.com
export PRD_SLACK_WEBHOOK_URL=<your-production-slack-webhook>

# Run the complete production workflow
./bin/prd-workflow.sh <ZIP_VERSION> <IS_LATEST> <SKIP_GIT>

# Examples:
./bin/prd-workflow.sh 1.2.3 true false          # Basic usage - merge to main
./bin/prd-workflow.sh 1.2.3 false false         # Release branch only  
./bin/prd-workflow.sh 1.2.3 true true           # Skip git operations
```

**Note:** The SAST version is automatically detected from the staging files, eliminating the need to specify it manually.

### GitHub Actions

Use the workflow: `.github/workflows/prd-build-publish-tag-final-image.yaml`

## Key Differences from Staging

| Aspect | Staging | Production |
|--------|---------|------------|
| **Source Branch** | `develop` | `main` |
| **Base Images** | ECR registry (private) | `mend/` prefix (public) |
| **Input** | Downloads from production bucket | Downloads from staging bucket |
| **SAST Files** | Downloads from staging paths | Downloads from production paths |
| **ECR Push** | Staging ECR (for actual use) | Staging ECR with "prod/" prefix (validation only) |
| **S3 Upload** | Staging bucket | Production bucket |
| **Slack Channel** | Staging channel | Production channel |
| **Git Target** | Release branches from develop | Release branches from main |

## File Structure

The production workflow creates the following file structure:

```
tmp/
├── agent-4-github-enterprise-{version}-with-prebuilt-staging.zip  # Downloaded from staging
├── agent-4-github-enterprise-{version}/                           # Extracted and modified
├── agent-4-github-enterprise-{version}-with-prebuilt.zip         # Final production ZIP
├── self-contained-sast-{version}.tar.gz                          # Production SAST files
└── mend                                                           # Production SAST binary
```

## Integration with Staging Pipeline

The production pipeline is designed to work seamlessly with the staging pipeline:

1. **Staging pipeline** creates and uploads `agent-4-github-enterprise-{version}-with-prebuilt-staging.zip`
2. **Production pipeline** downloads this ZIP as its starting point
3. **Production pipeline** replaces staging-specific files with production versions
4. **Production pipeline** creates the final production ZIP for customer distribution

This ensures consistency between staging validation and production releases while allowing for environment-specific configurations.
