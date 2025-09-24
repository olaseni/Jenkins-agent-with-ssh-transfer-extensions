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

## Pre-built Image

The image is automatically built and published to GitHub Container Registry on every release.

### Quick Start with Pre-built Image
```bash
# Pull the latest image
docker pull ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:latest

# Pull a specific version (recommended for production)
docker pull ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:2024.09.24.1

# Pull latest build for a specific date
docker pull ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:2024.09.24

# Run with default configuration (scans github.com, gitlab.com, bitbucket.org)
docker run ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:latest

# Run with additional hostnames
docker run -e HOSTNAMES_TO_SCAN_1="git.company.com" \
  ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:latest
```

## Building and Testing

### Build the Image Locally
```bash
docker build -t jenkins-agent-ssh .
```

### Using the Publish Script
```bash
# Build only
./publish.sh -r your-username/jenkins-agent-ssh -b

# Build and test
./publish.sh -r your-username/jenkins-agent-ssh

# Build, test, and push to registry
./publish.sh -r your-username/jenkins-agent-ssh -p

# See all options
./publish.sh --help
```

### Run Tests
```bash
./test-ssh-keyscan.sh
```

### Example with Docker Compose
```bash
docker-compose -f docker-compose.example.yml up jenkins-agent-custom
```

## Versioning System

The image uses an automatic versioning system that creates multiple tags for each build:

### Tag Format
- **`latest`**: Always points to the most recent build from the main branch
- **`YYYY.MM.DD.BUILD`**: Specific version (e.g., `2024.09.24.1`, `2024.09.24.2`)
- **`YYYY.MM.DD`**: Latest build for a specific date (e.g., `2024.09.24`)

### Version Generation
- **Date**: Current date in YYYY.MM.DD format
- **Build Number**: Number of commits made on the current day (starting from 1)
- **Full Version**: Combination of date and build number

### Choosing the Right Tag
```bash
# For development - always get the latest features
docker pull ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:latest

# For production - pin to a specific version
docker pull ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:2024.09.24.1

# For staging - use latest build of a specific day
docker pull ghcr.io/3wr/jenkins-agent-with-ssh-transfer-extensions:2024.09.24
```

## Automated Publishing

The image is automatically built and published via GitHub Actions:

- **On push to main**: Builds and publishes with auto-generated version tags + `latest`
- **On tag push (v*)**: Builds and publishes with both semver and auto-generated tags
- **On pull request**: Builds but doesn't publish (for testing)

The workflow supports multi-platform builds (linux/amd64, linux/arm64) and includes automated testing.

## Files

- `Dockerfile` - Main Docker image definition
- `ssh-keyscan-setup.sh` - Runtime SSH keyscan script
- `docker-entrypoint.sh` - Container entrypoint that runs keyscan setup
- `test-ssh-keyscan.sh` - Test script to validate functionality
- `docker-compose.example.yml` - Example configurations
- `publish.sh` - Helper script for building and publishing images
- `.github/workflows/publish-docker-image.yml` - GitHub Actions workflow for automated publishing

## Benefits of Runtime Keyscan

- **Flexibility**: No rebuild required for new hostnames
- **Dynamic Environments**: Works with orchestration platforms (Kubernetes, Docker Swarm)
- **Security**: Keys are always fresh and up-to-date
- **Portability**: Same image can be used with different host configurations