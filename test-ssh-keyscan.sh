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
echo "=== Test 2: Additional hostnames using HOSTNAMES_TO_SCAN_1 ==="
docker run --rm -e HOSTNAMES_TO_SCAN_1="git.example.com,custom.host.com" "$IMAGE_NAME" bash -c "
    echo 'Checking for always-scanned github.com entry:'
    ssh-keygen -F github.com -f /home/jenkins/.ssh/known_hosts && echo 'FOUND (expected)' || echo 'NOT FOUND (unexpected)'
    echo 'Checking for always-scanned gitlab.com entry:'
    ssh-keygen -F gitlab.com -f /home/jenkins/.ssh/known_hosts && echo 'FOUND (expected)' || echo 'NOT FOUND (unexpected)'
    echo 'Checking for always-scanned bitbucket.org entry:'
    ssh-keygen -F bitbucket.org -f /home/jenkins/.ssh/known_hosts && echo 'FOUND (expected)' || echo 'NOT FOUND (unexpected)'
    echo 'Checking for additional git.example.com entry:'
    ssh-keygen -F git.example.com -f /home/jenkins/.ssh/known_hosts && echo 'FOUND' || echo 'NOT FOUND (may be unreachable)'
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
echo "=== Test 4: Multiple HOSTNAMES_TO_SCAN variables ==="
docker run --rm \
    -e HOSTNAMES_TO_SCAN_1="git.company1.com,svn.legacy.com" \
    -e HOSTNAMES_TO_SCAN_DEV="dev.gitlab.com" \
    -e HOSTNAMES_TO_SCAN_PROD="prod.gitlab.com,secure.bitbucket.com" \
    "$IMAGE_NAME" bash -c "
    echo 'Checking for always-scanned entries (should always be present):'
    ssh-keygen -F github.com -f /home/jenkins/.ssh/known_hosts && echo 'github.com: FOUND' || echo 'github.com: NOT FOUND'
    ssh-keygen -F gitlab.com -f /home/jenkins/.ssh/known_hosts && echo 'gitlab.com: FOUND' || echo 'gitlab.com: NOT FOUND'
    ssh-keygen -F bitbucket.org -f /home/jenkins/.ssh/known_hosts && echo 'bitbucket.org: FOUND' || echo 'bitbucket.org: NOT FOUND'
    echo 'Total lines in known_hosts file:'
    wc -l /home/jenkins/.ssh/known_hosts
"

echo ""
echo "=== Test 5: Always-scanned with disabled SSH_KEYSCAN_ENABLED ==="
docker run --rm -e SSH_KEYSCAN_ENABLED=false "$IMAGE_NAME" bash -c "
    echo 'Checking known_hosts file size when keyscan is disabled (should be empty or very small):'
    ls -la /home/jenkins/.ssh/known_hosts 2>/dev/null || echo 'known_hosts file does not exist (expected)'
    if [[ -f /home/jenkins/.ssh/known_hosts ]]; then
        wc -l /home/jenkins/.ssh/known_hosts
    fi
"

echo ""
echo "=== All tests completed ==="