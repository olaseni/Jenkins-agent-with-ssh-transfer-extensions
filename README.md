# Jenkins Agent with SSH Transfer Extensions

A Jenkins agent Docker image with enhanced SSH keyscanning capabilities that runs at container startup rather than build time.

## Features

- **Runtime SSH Keyscan**: SSH host keys are scanned and added to `known_hosts` when the container starts, not during build
- **Always-Scanned Hostnames**: `github.com`, `gitlab.com`, and `bitbucket.org` are always included for maximum compatibility
- **Flexible Hostname Configuration**: Add additional hosts via multiple `HOSTNAMES_TO_SCAN_*` environment variables
- **Backward Compatibility**: Legacy `SSH_HOSTNAMES` format still supported
- **Idempotent Operation**: Safe to restart containers - existing entries won't be duplicated
- **Flexible Configuration**: Enable/disable keyscan functionality per container

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `HOSTNAMES_TO_SCAN_*` | Comma-separated list of additional hostnames to scan (supports multiple variables with any suffix) | None |
| `SSH_HOSTNAMES` | Legacy: Comma-separated list of hostnames to scan (still supported for backward compatibility) | None |
| `SSH_KEYSCAN_ENABLED` | Enable/disable SSH keyscanning | `true` |

**Always-Scanned Hostnames**: `github.com`, `gitlab.com`, `bitbucket.org` are ALWAYS scanned regardless of configuration (unless `SSH_KEYSCAN_ENABLED=false`).

## Usage Examples

### Default Configuration (Always-Scanned Only)
```bash
docker run jenkins-agent-ssh:latest
# Scans: github.com, gitlab.com, bitbucket.org
```

### Additional Hostnames (New Format)
```bash
# Single group of additional hostnames
docker run -e HOSTNAMES_TO_SCAN_1="git.company.com,svn.legacy.com" jenkins-agent-ssh:latest

# Multiple groups with descriptive names
docker run \
  -e HOSTNAMES_TO_SCAN_PROD="prod.git.company.com,secure.bitbucket.com" \
  -e HOSTNAMES_TO_SCAN_DEV="dev.gitlab.com" \
  -e HOSTNAMES_TO_SCAN_LEGACY="old.svn.server.com" \
  jenkins-agent-ssh:latest
```

### Legacy Format (Still Supported)
```bash
docker run -e SSH_HOSTNAMES="git.example.com,custom.host.com" jenkins-agent-ssh:latest
# Scans: github.com, gitlab.com, bitbucket.org + git.example.com, custom.host.com
```

### Disable SSH Keyscan
```bash
docker run -e SSH_KEYSCAN_ENABLED=false jenkins-agent-ssh:latest
# No hostnames will be scanned (including always-scanned ones)
```

### Docker Compose
```yaml
version: '3.8'
services:
  jenkins-agent:
    image: jenkins-agent-ssh:latest
    environment:
      - HOSTNAMES_TO_SCAN_COMPANY=git.company.com,svn.company.com
      - HOSTNAMES_TO_SCAN_EXTERNAL=partner.gitlab.com
      - SSH_KEYSCAN_ENABLED=true
      # Always scans: github.com, gitlab.com, bitbucket.org (in addition to the above)
```

## Building and Testing

### Build the Image
```bash
docker build -t jenkins-agent-ssh .
```

### Run Tests
```bash
./test-ssh-keyscan.sh
```

### Example with Docker Compose
```bash
docker-compose -f docker-compose.example.yml up jenkins-agent-custom
```

## Files

- `Dockerfile` - Main Docker image definition
- `ssh-keyscan-setup.sh` - Runtime SSH keyscan script
- `docker-entrypoint.sh` - Container entrypoint that runs keyscan setup
- `test-ssh-keyscan.sh` - Test script to validate functionality
- `docker-compose.example.yml` - Example configurations

## Benefits of Runtime Keyscan

- **Flexibility**: No rebuild required for new hostnames
- **Dynamic Environments**: Works with orchestration platforms (Kubernetes, Docker Swarm)
- **Security**: Keys are always fresh and up-to-date
- **Portability**: Same image can be used with different host configurations