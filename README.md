# Jenkins Agent with SSH Transfer Extensions

A Jenkins agent Docker image with enhanced SSH keyscanning capabilities that runs at container startup rather than build time.

## Features

- **Runtime SSH Keyscan**: SSH host keys are scanned and added to `known_hosts` when the container starts, not during build
- **Configurable Hostnames**: Specify which hosts to scan via environment variables
- **Backward Compatibility**: Defaults to scanning `github.com` and `projects.onproxmox.sh` if no configuration provided
- **Idempotent Operation**: Safe to restart containers - existing entries won't be duplicated
- **Flexible Configuration**: Enable/disable keyscan functionality per container

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `SSH_HOSTNAMES` | Comma-separated list of hostnames to scan | `github.com,projects.onproxmox.sh` |
| `SSH_KEYSCAN_ENABLED` | Enable/disable SSH keyscanning | `true` |

## Usage Examples

### Default Configuration
```bash
docker run jenkins-agent-ssh:latest
# Scans: github.com, projects.onproxmox.sh
```

### Custom Hostnames
```bash
docker run -e SSH_HOSTNAMES="gitlab.com,bitbucket.org,git.company.com" jenkins-agent-ssh:latest
```

### Disable SSH Keyscan
```bash
docker run -e SSH_KEYSCAN_ENABLED=false jenkins-agent-ssh:latest
```

### Docker Compose
```yaml
version: '3.8'
services:
  jenkins-agent:
    image: jenkins-agent-ssh:latest
    environment:
      - SSH_HOSTNAMES=github.com,gitlab.com,bitbucket.org
      - SSH_KEYSCAN_ENABLED=true
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