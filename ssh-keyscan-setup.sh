#!/bin/bash

# SSH Keyscan Setup Script
# Scans SSH host keys for specified hostnames and adds them to known_hosts

set -euo pipefail

# Always scanned hostnames - these are ALWAYS included regardless of other configuration
ALWAYS_SCANNED_HOSTNAMES="github.com,gitlab.com,bitbucket.org"

# Check if SSH keyscanning is enabled (default: true)
SSH_KEYSCAN_ENABLED=${SSH_KEYSCAN_ENABLED:-true}

# SSH directory and known_hosts file
SSH_DIR="/home/jenkins/.ssh"
KNOWN_HOSTS_FILE="$SSH_DIR/known_hosts"

# Internal log file
LOG_FILE=~/log.log

# Function to log messages
log() {
    echo "[SSH-KEYSCAN] $1"
    # Append a timestamped log copy to a file
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
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
    fi

    # Create known_hosts file if it doesn't exist
    if [[ ! -f "$KNOWN_HOSTS_FILE" ]]; then
        log "Creating known_hosts file: $KNOWN_HOSTS_FILE"
        touch "$KNOWN_HOSTS_FILE"
        chmod 644 "$KNOWN_HOSTS_FILE"
    fi

    # Collect all hostnames to scan
    declare -A unique_hostnames

    # Always include the always-scanned hostnames
    log "Adding always-scanned hostnames: $ALWAYS_SCANNED_HOSTNAMES"
    IFS=',' read -ra ALWAYS_HOSTS <<< "$ALWAYS_SCANNED_HOSTNAMES"
    for hostname in "${ALWAYS_HOSTS[@]}"; do
        hostname=$(echo "$hostname" | xargs)
        if [[ -n "$hostname" ]]; then
            unique_hostnames["$hostname"]=1
        fi
    done

    # log $SSH_HOSTNAMES for debugging
    if [[ -n "${SSH_HOSTNAMES:-}" ]]; then
        log "Legacy SSH_HOSTNAMES variable detected: ${SSH_HOSTNAMES}"
    fi

    # Log $HOSTNAMES_TO_SCAN_* variables for debugging
    log "Environment variables for hostnames to scan:"
    for var in $(env | grep '^HOSTNAMES_TO_SCAN_' | cut -d= -f1); do
        log "  $var=${!var}"
    done

    # Collect hostnames from HOSTNAMES_TO_SCAN_* environment variables
    for var in $(env | grep '^HOSTNAMES_TO_SCAN_' | cut -d= -f1); do
        hostnames_list="${!var}"
        log "Processing $var: $hostnames_list"
        IFS=',' read -ra HOST_LIST <<< "$hostnames_list"
        for hostname in "${HOST_LIST[@]}"; do
            hostname=$(echo "$hostname" | xargs)
            if [[ -n "$hostname" ]]; then
                unique_hostnames["$hostname"]=1
            fi
        done
    done

    # Also support legacy SSH_HOSTNAMES for backward compatibility (but always-scanned still apply)
    if [[ -n "${SSH_HOSTNAMES:-}" ]]; then
        log "Processing legacy SSH_HOSTNAMES: $SSH_HOSTNAMES"
        IFS=',' read -ra LEGACY_HOSTS <<< "$SSH_HOSTNAMES"
        for hostname in "${LEGACY_HOSTS[@]}"; do
            hostname=$(echo "$hostname" | xargs)
            if [[ -n "$hostname" ]]; then
                unique_hostnames["$hostname"]=1
            fi
        done
    fi

    # Process all unique hostnames
    if [[ ${#unique_hostnames[@]} -eq 0 ]]; then
        log "No hostnames to scan (this should not happen as always-scanned hostnames should be present)"
    else
        log "Total unique hostnames to scan: ${#unique_hostnames[@]}"
        for hostname in "${!unique_hostnames[@]}"; do
            if hostname_exists "$hostname"; then
                log "SSH keys for $hostname already exist in known_hosts"
            else
                scan_hostname "$hostname"
            fi
        done
    fi

    log "SSH keyscan setup completed"
}

# Run main function
main "$@"