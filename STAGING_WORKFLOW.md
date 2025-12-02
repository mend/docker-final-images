# Staging Workflow Documentation

This document describes the new staging workflow for deploying Docker images to the staging environment using the `develop` branch.

## Overview

The staging workflow is designed to:
- Use the `develop` branch as the base (instead of `main` for production)
- Create release branches (`release/x.y.z`) from the provided version
- Include SAST engine files in the final package
- Deploy to staging ECR and S3 buckets
- Send notifications to staging Slack channels

## Scripts

### Core Scripts

1. **`stg-download.sh`** - Downloads ZIP files and SAST engine components
2. **`stg-copy.sh`** - Modifies Dockerfiles with new versions
3. **`stg-build.sh`** - Builds and tests Docker images
4. **`stg-workflow.sh`** - Main orchestration script

### Modular Action Scripts

5. **`stg-publish-images.sh`** - Publishes images to staging ECR
6. **`stg-upload-s3.sh`** - Uploads ZIP files to staging S3 bucket
7. **`stg-git-operations.sh`** - Handles all git operations and branching
8. **`stg-send-notification.sh`** - Sends Slack notifications

## Usage

### Manual Execution

```bash
# Set required environment variable
export ECR_REGISTRY=054331651301.dkr.ecr.us-east-1.amazonaws.com
export SLACK_WEBHOOK_URL=<your-staging-slack-webhook>

# Run the complete staging workflow
./bin/stg-workflow.sh <ZIP_VERSION> <SAST_SELF_CONTAINED_VERSION> <IS_LATEST> <SKIP_GIT> [PREVIOUS_TAG]

# Examples:
export ECR_REGISTRY=054331651301.dkr.ecr.us-east-1.amazonaws.com
./bin/stg-workflow.sh 1.2.3 2.1.0 true false          # Basic usage
./bin/stg-workflow.sh 1.2.3 "" false false           # Use ZIP_VERSION for SAST, release branch only  
./bin/stg-workflow.sh 1.2.3 2.1.0 true false 1.2.2   # With optional previous tag for future use
./bin/stg-workflow.sh 1.2.3 2.1.0 true true          # Skip git operations
```

### GitHub Actions

Use the workflow: `.github/workflows/new-stg-build-publish-tag-final-image.yaml`

**Parameters:**
- **ZipVersion**: ZIP version to be released (e.g., `1.2.3`)
- **SastSelfContainedVersion**: SAST self-contained engine version (optional, defaults to ZipVersion)
- **PreviousTag**: Previously deployed final image tag (optional, for future use)
- **IsLatest**: Whether to merge changes to develop branch (`true`/`false`)
- **SkipGit**: Skip git operations (`true`/`false`)

## Workflow Steps

1. **Download Files**
   - Download ZIP file based on version from pre-release S3 bucket
   - Download SAST engine files (defaults to ZIP version if not specified):
     - `self-contained-sast-<version>.tar.gz`
     - `mend` binary file

2. **Modify Dockerfiles**
   - Update base image sources for staging (uses ECR instead of Mend Hub):
     - Controller: `FROM mend/base-repo-controller:*` → `FROM 054331651301.dkr.ecr.us-east-1.amazonaws.com/base-repo-controller:$ZIP_VERSION`
     - Scanner: `FROM mend/base-repo-scanner:*` → `FROM 054331651301.dkr.ecr.us-east-1.amazonaws.com/base-repo-scanner:$ZIP_VERSION`
     - Scanner Full: `FROM mend/base-repo-scanner:*-full` → `FROM 054331651301.dkr.ecr.us-east-1.amazonaws.com/base-repo-scanner:$ZIP_VERSION-full`
     - Scanner SAST: `FROM mend/base-repo-scanner-sast:*` → `FROM 054331651301.dkr.ecr.us-east-1.amazonaws.com/base-repo-scanner-sast:$ZIP_VERSION`
     - Remediate: `FROM mend/base-repo-remediate:*` → `FROM 054331651301.dkr.ecr.us-east-1.amazonaws.com/base-repo-remediate:$ZIP_VERSION`
   - Copy changes from downloaded agent
   - Apply custom modifications from config files (optional)

3. **Git Operations**
   - Checkout `develop` branch
   - Create release branch `release/x.y.z`
   - Commit and push changes
   - Optionally merge to `develop` if `IsLatest=true`

4. **Build & Test**
   - Build Docker images
   - Validate successful builds
   - Create ZIP package with SAST files

5. **Publish**
   - Push images to staging ECR
   - Upload ZIP to staging S3 bucket

6. **Notify**
   - Send Slack notification to staging channel

## Image Source Strategy

The staging workflow uses different base image sources depending on the environment:

### **Staging/Development Environment**
- **Base Images**: ECR registry (`054331651301.dkr.ecr.us-east-1.amazonaws.com/base-repo-*`)
- **Branches**: `develop`, `release/*` branches
- **Reason**: Uses ECR-hosted base images for staging consistency and testing

### **Production Environment**
- **Base Images**: Mend Hub (`mend/base-repo-*`)
- **Branch**: `main` branch only
- **Reason**: Uses official Mend Hub images for production releases

This ensures staging environments test with ECR images while production maintains official Mend Hub image sources.

## Dockerfile Modifications

The workflow supports additional Dockerfile modifications through configuration files. After the standard Dockerfile processing, custom modifications can be applied.

### Configuration Files

Create modification files in the `config/` directory:
- `config/wss-ghe-app-modifications.txt`
- `config/wss-scanner-modifications.txt`
- `config/wss-scanner-full-modifications.txt`
- `config/wss-remediate-modifications.txt`

**Note**: SAST modifications for `wss-scanner-sast` are handled directly in the script with dynamic version numbers, so no separate configuration file is needed.

### Modification Commands

Each file uses the format: `ACTION:PATTERN:REPLACEMENT`

**Available Actions:**
- `REMOVE:pattern` - Remove lines matching pattern
- `COMMENT:pattern` - Comment out single lines matching pattern
- `COMMENT_BLOCK:pattern` - Comment out multi-line blocks (use with caution)
- `ADD_AFTER:pattern:new_line` - Add line after pattern
- `ADD_BEFORE:pattern:new_line` - Add line before pattern
- `REPLACE:pattern:new_line` - Replace line matching pattern

**Examples:**
```
# Comment out a specific package installation
COMMENT:RUN apt-get install.*nuget

# Add SAST engine files
ADD_AFTER:COPY docker-image/ /:COPY sast-engine/ /opt/sast/

# Add environment variable
ADD_AFTER:ENV WHITESOURCE_HOME=:ENV SAST_ENGINE_PATH=/opt/sast
```

## Configuration Placeholders

The following placeholders need to be updated with actual values:

### Download Configuration
- `GHE_BUCKET` - Pre-release S3 bucket for ZIP files in `stg-download.sh`
- `SAST_SELF_CONTAINED_BUCKET` - SAST S3 bucket URL (already configured)
- `SAST_BINARY_BUCKET` - SAST binary S3 bucket URL (needs confirmation)

### ECR Registry
- ✅ **Staging ECR**: Uses `aws-actions/amazon-ecr-login@v1` with `registries: "054331651301"` and `region: "us-east-1"`
- ✅ **Dynamic Registry**: ECR registry URL is set via `${{ steps.login-ecr.outputs.registry }}`
- ✅ **No Hard-coding**: Registry URL is generated automatically by the ECR login action

### S3 Bucket
- `PLACEHOLDER_STAGING_S3_BUCKET` in `stg-upload-s3.sh`
- Update workflow S3 upload command

### Slack Integration
- ✅ **Webhook Secret**: `STG_SLACK_WEBHOOK_URL` (configured in repository secrets)
- Add `SLACK_WEBHOOK_URL_STAGING` secret to repository

## Branch Strategy

- **`main`**: Production releases only
- **`develop`**: Staging releases and development
- **`release/x.y.z`**: Individual release branches

## File Structure

```
bin/
├── stg-download.sh      # Download ZIP and SAST files
├── stg-copy.sh          # Modify Dockerfiles  
├── stg-build.sh         # Build and test images
├── stg-workflow.sh      # Main orchestration
├── stg-publish-ecr.sh   # ECR publishing
├── stg-upload-s3.sh     # S3 upload
└── stg-send-notification.sh  # Slack notifications

.github/workflows/
└── new-stg-build-publish-tag-final-image.yaml  # GitHub Actions workflow
```

## Migration from Existing Scripts

The staging scripts are completely separate from the existing production scripts:

- Production: `download.sh`, `copy.sh`, `build.sh` → `main` branch
- Staging: `stg-*.sh` scripts → `develop` branch

This ensures no interference between staging and production workflows.

## Testing

Before using in production, test the workflow with:

```bash
# Test with dry-run (skip git operations)
./bin/stg-workflow.sh 1.2.3 2.1.0 false true
```

## Support

For issues or questions about the staging workflow, check:
1. Script output for detailed error messages
2. GitHub Actions logs for workflow execution details
3. Ensure all placeholder values are configured
