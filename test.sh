#!/bin/bash

# Test script for SSH keyscan functionality
# This script builds the Docker image and tests different configurations

set -euo pipefail

IMAGE_NAME="jenkins-agent-ssh-test"

docker run --rm -e SSH_KEYSCAN_ENABLED=true -e HOSTNAMES_TO_SCAN_1="projects.onproxmox.sh" "$IMAGE_NAME" bash -c "
    ls -la /home/jenkins/.ssh/known_hosts 2>/dev/null || echo 'known_hosts file does not exist'
    if [[ -f /home/jenkins/.ssh/known_hosts ]]; then
        wc -l /home/jenkins/.ssh/known_hosts
    fi
    
    which rsync && echo 'rsync is installed' || echo 'rsync is NOT installed'
"
