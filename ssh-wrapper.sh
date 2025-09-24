#!/bin/bash

# SSH Wrapper Script
# Transparently wraps ssh binary to run scan_configured_host_keys before SSH connections
# This ensures host keys are always scanned and added to known_hosts before SSH operations

set -euo pipefail

# Path to the real SSH binary (will be moved during Docker build)
REAL_SSH_PATH="/usr/bin/ssh.real"

# Run scan_configured_host_keys before SSH connection if it exists
# Suppress output to maintain transparent behavior
run_scan_function() {
    if command -v scan_configured_host_keys >/dev/null 2>&1; then
        scan_configured_host_keys >/dev/null 2>&1 || true
    fi
}

# Main wrapper logic
main() {
   run_scan_function

    # Execute the real SSH binary with all original arguments
    exec "$REAL_SSH_PATH" "$@"
}

# Run main function with all arguments
main "$@"