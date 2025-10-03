#!/bin/bash

set -euo pipefail

# Run SSH keyscan setup as jenkins user
echo "[ENTRYPOINT] Running SSH keyscan setup..."
scan_configured_host_keys

# If no arguments provided, use default Jenkins agent command
if [ $# -eq 0 ]; then
    # echo "[ENTRYPOINT] Starting Jenkins agent with default command..."
    exec jenkins-agent
else
    # echo "[ENTRYPOINT] Starting Jenkins agent with custom command: $*"
    exec "$@"
fi