#!/bin/bash

# Helper script for building and publishing the Jenkins Agent Docker image
# Usage: ./publish.sh [OPTIONS]

set -euo pipefail

# Default values
REGISTRY="ghcr.io"
REPOSITORY=""
TAG="latest"
BUILD_ONLY=false
PUSH=false
TEST=true
PLATFORMS="linux/amd64,linux/arm64"
DRY_RUN=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Help function
show_help() {
    cat << EOF
Usage: ./publish.sh [OPTIONS]

Options:
    -r, --repository REPO   Repository name (e.g., username/repo-name)
    -t, --tag TAG          Image tag (default: latest)
    -p, --push             Push to registry after building
    -b, --build-only       Only build, don't test or push
    --no-test              Skip testing
    --registry REGISTRY    Registry URL (default: ghcr.io)
    --platforms PLATFORMS  Target platforms (default: linux/amd64,linux/arm64)
    --dry-run              Show what would be done without executing
    -h, --help             Show this help message

Examples:
    ./publish.sh -r myuser/jenkins-agent-ssh -t v1.0.0 -p
    ./publish.sh --repository myuser/jenkins-agent-ssh --build-only
    ./publish.sh --dry-run -r myuser/jenkins-agent-ssh -p
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repository)
            REPOSITORY="$2"
            shift 2
            ;;
        -t|--tag)
            TAG="$2"
            shift 2
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        -b|--build-only)
            BUILD_ONLY=true
            shift
            ;;
        --no-test)
            TEST=false
            shift
            ;;
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --platforms)
            PLATFORMS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$REPOSITORY" ]]; then
    log_error "Repository name is required. Use -r or --repository to specify."
    show_help
    exit 1
fi

# Construct full image name
FULL_IMAGE_NAME="$REGISTRY/$REPOSITORY:$TAG"

# Show configuration
log_info "Configuration:"
echo "  Registry: $REGISTRY"
echo "  Repository: $REPOSITORY"
echo "  Tag: $TAG"
echo "  Full image name: $FULL_IMAGE_NAME"
echo "  Platforms: $PLATFORMS"
echo "  Build only: $BUILD_ONLY"
echo "  Push: $PUSH"
echo "  Test: $TEST"
echo "  Dry run: $DRY_RUN"
echo ""

# Check if we're in the right directory
if [[ ! -f "Dockerfile" ]]; then
    log_error "Dockerfile not found in current directory"
    exit 1
fi

# Function to run commands with dry-run support
run_cmd() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "[DRY RUN] Would execute: $*"
    else
        log_info "Executing: $*"
        "$@"
    fi
}

# Check Docker buildx
if ! docker buildx version >/dev/null 2>&1; then
    log_error "Docker buildx is required but not available"
    exit 1
fi

# Create buildx builder if needed (for multi-platform builds)
if [[ "$PLATFORMS" == *","* ]]; then
    log_info "Setting up buildx builder for multi-platform build..."
    run_cmd docker buildx create --use --name jenkins-agent-builder --driver docker-container || true
fi

# Build the image
log_info "Building Docker image..."
BUILD_ARGS=(
    "buildx" "build"
    "--platform" "$PLATFORMS"
    "-t" "$FULL_IMAGE_NAME"
    "."
)

if [[ "$PUSH" == "true" && "$DRY_RUN" == "false" ]]; then
    BUILD_ARGS+=("--push")
elif [[ "$DRY_RUN" == "false" ]]; then
    BUILD_ARGS+=("--load")
fi

run_cmd docker "${BUILD_ARGS[@]}"

if [[ "$BUILD_ONLY" == "true" ]]; then
    log_success "Build completed (build-only mode)"
    exit 0
fi

# Test the image (only if not pushing or if loaded locally)
if [[ "$TEST" == "true" && ("$PUSH" == "false" || "$DRY_RUN" == "true") ]]; then
    log_info "Testing Docker image..."

    if [[ "$DRY_RUN" == "false" ]]; then
        # Test default configuration
        log_info "Testing default configuration..."
        docker run --rm "$FULL_IMAGE_NAME" bash -c "
            test -f /home/jenkins/.ssh/known_hosts || exit 1
            ssh-keygen -F github.com -f /home/jenkins/.ssh/known_hosts > /dev/null || exit 1
            ssh-keygen -F gitlab.com -f /home/jenkins/.ssh/known_hosts > /dev/null || exit 1
            ssh-keygen -F bitbucket.org -f /home/jenkins/.ssh/known_hosts > /dev/null || exit 1
            echo 'Default configuration test passed!'
        "

        # Test custom hostnames
        log_info "Testing custom hostnames..."
        docker run --rm -e HOSTNAMES_TO_SCAN_1="git.example.com" "$FULL_IMAGE_NAME" bash -c "
            ssh-keygen -F github.com -f /home/jenkins/.ssh/known_hosts > /dev/null || exit 1
            echo 'Custom hostname test passed!'
        "

        log_success "All tests passed!"
    else
        log_info "[DRY RUN] Would test the image"
    fi
fi

# Push if requested (and not already pushed during build)
if [[ "$PUSH" == "true" && "$DRY_RUN" == "false" ]]; then
    if [[ "${BUILD_ARGS[*]}" != *"--push"* ]]; then
        log_info "Pushing image to registry..."
        run_cmd docker push "$FULL_IMAGE_NAME"
    fi
    log_success "Image pushed successfully: $FULL_IMAGE_NAME"
else
    log_info "Image built locally: $FULL_IMAGE_NAME"
fi

# Show usage instructions
echo ""
log_success "Build completed successfully!"
echo ""
echo "Usage instructions:"
echo "  docker pull $FULL_IMAGE_NAME"
echo "  docker run $FULL_IMAGE_NAME"
echo ""
echo "With custom hostnames:"
echo "  docker run -e HOSTNAMES_TO_SCAN_1=\"git.company.com\" $FULL_IMAGE_NAME"