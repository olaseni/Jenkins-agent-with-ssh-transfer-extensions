#!/bin/bash

# Test script for SSH keyscan functionality
# This script builds the Docker image and tests different configurations

set -euo pipefail

IMAGE_NAME="jenkins-agent-ssh-test"

echo "=== Building Docker image ==="
docker build -t "$IMAGE_NAME" .

echo ""
echo "=== Test 1: Default configuration ==="
docker run --rm "$IMAGE_NAME" bash -c "
    echo 'Checking known_hosts file content:'
    cat /home/jenkins/.ssh/known_hosts | head -5
    echo ''
    echo 'Checking for github.com entry:'
    ssh-keygen -F github.com -f /home/jenkins/.ssh/known_hosts && echo 'FOUND' || echo 'NOT FOUND'
    echo 'Checking for projects.onproxmox.sh entry:'
    ssh-keygen -F projects.onproxmox.sh -f /home/jenkins/.ssh/known_hosts && echo 'FOUND' || echo 'NOT FOUND'
"

echo ""
echo "=== Test 2: Custom hostnames ==="
docker run --rm -e SSH_HOSTNAMES="gitlab.com,bitbucket.org" "$IMAGE_NAME" bash -c "
    echo 'Checking for gitlab.com entry:'
    ssh-keygen -F gitlab.com -f /home/jenkins/.ssh/known_hosts && echo 'FOUND' || echo 'NOT FOUND'
    echo 'Checking for bitbucket.org entry:'
    ssh-keygen -F bitbucket.org -f /home/jenkins/.ssh/known_hosts && echo 'FOUND' || echo 'NOT FOUND'
    echo 'Checking that github.com is NOT present:'
    ssh-keygen -F github.com -f /home/jenkins/.ssh/known_hosts && echo 'FOUND (unexpected)' || echo 'NOT FOUND (expected)'
"

echo ""
echo "=== Test 3: Disabled keyscan ==="
docker run --rm -e SSH_KEYSCAN_ENABLED=false "$IMAGE_NAME" bash -c "
    echo 'Checking known_hosts file size (should be empty or very small):'
    ls -la /home/jenkins/.ssh/known_hosts 2>/dev/null || echo 'known_hosts file does not exist (expected)'
    if [[ -f /home/jenkins/.ssh/known_hosts ]]; then
        wc -l /home/jenkins/.ssh/known_hosts
    fi
"

echo ""
echo "=== Test 4: Empty hostnames ==="
docker run --rm -e SSH_HOSTNAMES="" "$IMAGE_NAME" bash -c "
    echo 'Checking known_hosts file with empty hostnames:'
    ls -la /home/jenkins/.ssh/known_hosts 2>/dev/null || echo 'known_hosts file does not exist'
    if [[ -f /home/jenkins/.ssh/known_hosts ]]; then
        echo 'File size:'
        wc -l /home/jenkins/.ssh/known_hosts
    fi
"

echo ""
echo "=== All tests completed ==="