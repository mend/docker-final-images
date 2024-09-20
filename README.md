# mend/docker-final-images

This repository is non-Open Source and is used to build Mend's Repository Integrations "final" images.

The Dockerfiles in this repository are built off their corresponding "base" images, which are sourced from https://github.com/mend/docker-base-images

## How to maintain this repository

Whenever a self-hosted release is available:

- Download the release zip file and extract it locally
- For each of the Dockerfiles in this repository, copy/paste the relevant contents to these files
- Update each Dockerfile with the relevant `FROM` tag to align it to the correct release (e.g. `24.9.1`)
- Commit the changes

Usually:
- App and Remediate files do not change, except for the `FROM` line
- Scanner files change the `FROM` line plus the PSB version 