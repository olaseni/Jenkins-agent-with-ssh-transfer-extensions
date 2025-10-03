#!/bin/bash

set -euo pipefail

# Run SSH keyscan setup as jenkins user
scan_configured_host_keys

# If no arguments provided, use default Jenkins agent command
if [ $# -eq 0 ]; then
    exec jenkins-agent
else
    exec "$@"
fi