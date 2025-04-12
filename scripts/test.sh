#!/bin/bash

# Exit on error, undefined variables, and propagate pipe failures
set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/default.env"

# Function to print colored output
print_info() {
    echo -e "\033[36m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --tailscale-auth KEY    Tailscale authentication key (required)"
    echo "  --git-fork URL          URL to ComfyUI Git repository"
    echo "  --python-version VER    Python version to use"
    echo "  --ssh-folder-path PATH  Path to SSH folder (default: ~/.ssh)"
    echo "  --help                  Show this help message"
}

# Parse command line arguments
TAILSCALE_AUTH=""
GIT_FORK="${DEFAULT_COMFYUI_REPO}"
PYTHON_VERSION="${DEFAULT_PYTHON_VERSION}"
SSH_FOLDER_PATH="$HOME/.ssh"

while [[ $# -gt 0 ]]; do
    case $1 in
        --tailscale-auth)
            TAILSCALE_AUTH="$2"
            shift 2
            ;;
        --git-fork)
            GIT_FORK="$2"
            shift 2
            ;;
        --python-version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        --ssh-folder-path)
            SSH_FOLDER_PATH="$2"
            shift 2
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown argument: $1"
            print_usage
            exit 1
            ;;
    esac
done

# Verify required arguments
if [ -z "$TAILSCALE_AUTH" ]; then
    print_error "Missing required argument: --tailscale-auth"
    print_usage
    exit 1
fi

# Create SSH folder if it doesn't exist
mkdir -p "$SSH_FOLDER_PATH"

# Generate SSH key pair if it doesn't exist
SSH_KEY_PATH="$SSH_FOLDER_PATH/comfyui-dev"
if [ ! -f "$SSH_KEY_PATH" ]; then
    print_info "Generating SSH key pair at $SSH_KEY_PATH"
    ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "comfyui-dev"
fi

# Read public key into variable
PUBKEY=$(cat "${SSH_KEY_PATH}.pub")

# Remove existing container if it exists
print_info "Cleaning up any existing container..."
docker rm -f comfyui-dev 2>/dev/null || true

print_info "Starting ComfyUI development container"
print_info "Using Tailscale auth key: ${TAILSCALE_AUTH:0:5}..."
print_info "Using Git fork: $GIT_FORK"
print_info "Using Python version: $PYTHON_VERSION"
print_info "Using SSH folder path: $SSH_FOLDER_PATH"

# Run the Docker container
docker run \
  --name comfyui-dev \
  --gpus all \
  -e COMFY_DEV_SSH_PUBKEY="$PUBKEY" \
  -e COMFY_DEV_TAILSCALE_AUTH="$TAILSCALE_AUTH" \
  -e COMFY_DEV_PYTHON_VERSION="$PYTHON_VERSION" \
  -e COMFY_DEV_GIT_FORK="$GIT_FORK" \
  -e COMFY_DEV_WIN32="false" \
  -e COMFY_DEV_START_COMFY="false" \
  "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" || {
    print_error "Container failed to start"
    exit 1
  }

print_success "Container started successfully"
print_info "Use 'docker logs comfyui-dev' to view logs"