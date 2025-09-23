#!/bin/bash

set -euo pipefail

# Run SSH keyscan setup as root (needed for file ownership)
echo "[ENTRYPOINT] Running SSH keyscan setup..."
/usr/local/bin/ssh-keyscan-setup.sh

# If no arguments provided, use default Jenkins agent command
if [ $# -eq 0 ]; then
    echo "[ENTRYPOINT] Starting Jenkins agent with default command..."
    exec gosu jenkins jenkins-agent
else
    echo "[ENTRYPOINT] Starting Jenkins agent with custom command: $*"
    exec gosu jenkins "$@"
fi