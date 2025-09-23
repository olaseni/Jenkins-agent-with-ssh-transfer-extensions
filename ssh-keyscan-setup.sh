#!/bin/bash

# SSH Keyscan Setup Script
# Scans SSH host keys for specified hostnames and adds them to known_hosts

set -euo pipefail

# Default hostnames (backward compatibility)
DEFAULT_HOSTNAMES="github.com,projects.onproxmox.sh"

# Get hostnames from environment variable or use defaults
SSH_HOSTNAMES=${SSH_HOSTNAMES:-$DEFAULT_HOSTNAMES}

# Check if SSH keyscanning is enabled (default: true)
SSH_KEYSCAN_ENABLED=${SSH_KEYSCAN_ENABLED:-true}

# SSH directory and known_hosts file
SSH_DIR="/home/jenkins/.ssh"
KNOWN_HOSTS_FILE="$SSH_DIR/known_hosts"

# Function to log messages
log() {
    echo "[SSH-KEYSCAN] $1"
}

# Function to check if hostname already exists in known_hosts
hostname_exists() {
    local hostname="$1"
    if [[ -f "$KNOWN_HOSTS_FILE" ]]; then
        # Check for both hashed and non-hashed entries
        ssh-keygen -F "$hostname" -f "$KNOWN_HOSTS_FILE" >/dev/null 2>&1
    else
        return 1
    fi
}

# Function to scan and add hostname
scan_hostname() {
    local hostname="$1"
    log "Scanning SSH keys for $hostname..."

    # Scan for multiple key types and append to known_hosts with hashing
    if ssh-keyscan -t rsa,ecdsa,ed25519 -H "$hostname" >> "$KNOWN_HOSTS_FILE" 2>/dev/null; then
        log "Successfully added SSH keys for $hostname"
    else
        log "Warning: Failed to scan SSH keys for $hostname (host may be unreachable)"
    fi
}

# Main execution
main() {
    log "Starting SSH keyscan setup..."

    # Check if SSH keyscanning is disabled
    if [[ "$SSH_KEYSCAN_ENABLED" != "true" ]]; then
        log "SSH keyscanning is disabled (SSH_KEYSCAN_ENABLED=$SSH_KEYSCAN_ENABLED)"
        return 0
    fi

    # Ensure SSH directory exists with correct permissions
    if [[ ! -d "$SSH_DIR" ]]; then
        log "Creating SSH directory: $SSH_DIR"
        mkdir -p "$SSH_DIR"
        chmod 700 "$SSH_DIR"
        chown jenkins:jenkins "$SSH_DIR"
    fi

    # Create known_hosts file if it doesn't exist
    if [[ ! -f "$KNOWN_HOSTS_FILE" ]]; then
        log "Creating known_hosts file: $KNOWN_HOSTS_FILE"
        touch "$KNOWN_HOSTS_FILE"
        chmod 644 "$KNOWN_HOSTS_FILE"
        chown jenkins:jenkins "$KNOWN_HOSTS_FILE"
    fi

    # Process hostnames (comma-separated)
    if [[ -n "$SSH_HOSTNAMES" ]]; then
        IFS=',' read -ra HOSTNAMES <<< "$SSH_HOSTNAMES"
        for hostname in "${HOSTNAMES[@]}"; do
            # Trim whitespace
            hostname=$(echo "$hostname" | xargs)

            if [[ -n "$hostname" ]]; then
                if hostname_exists "$hostname"; then
                    log "SSH keys for $hostname already exist in known_hosts"
                else
                    scan_hostname "$hostname"
                fi
            fi
        done
    else
        log "No hostnames specified in SSH_HOSTNAMES"
    fi

    log "SSH keyscan setup completed"
}

# Run main function
main "$@"