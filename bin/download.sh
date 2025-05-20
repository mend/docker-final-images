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

RELEASE=$1

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Check if ../tmp/agent-4-github-enterprise-$RELEASE.zip exists
if [ ! -f ../tmp/agent-4-github-enterprise-$RELEASE.zip ]; then
  echo "Downloading agent-4-github-enterprise-$RELEASE.zip"
  mkdir -p ../tmp
  curl -o ../tmp/agent-4-github-enterprise-$RELEASE.zip https://integrations.mend.io/release/Agent-for-GitHub-Enterprise/agent-4-github-enterprise-$RELEASE.zip
fi

if [ ! -f ../tmp/agent-4-github-enterprise-$RELEASE.zip ]; then
    echo "Error: agent-4-github-enterprise-$RELEASE.zip not found."
    exit 1
fi

# Unzip agent-4-github-enterprise-$RELEASE.zip if the folder doesn't exist
if [ ! -d ../tmp/agent-4-github-enterprise-$RELEASE ]; then
  echo "Unzipping agent-4-github-enterprise-$RELEASE.zip"
  unzip -o ../tmp/agent-4-github-enterprise-$RELEASE.zip -d ../tmp
fi

# Check if ../tmp/agent-4-github-enterprise-$RELEASE exists
if [ ! -d ../tmp/agent-4-github-enterprise-$RELEASE ]; then
    echo "Error: agent-4-github-enterprise-$RELEASE not found."
    exit 1
fi
