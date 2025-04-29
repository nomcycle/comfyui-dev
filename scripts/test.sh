#!/bin/bash
# test.sh - Tests the comfyui-dev Docker container

# Exit on error, undefined variables, and propagate pipe failures
set -euo pipefail

# Load configuration and utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/../config" && pwd)"

# Source utils.sh for common functions
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || {
    print_warning "Failed to source utils.sh - using minimal built-in functions"
}

# Load configuration
source "${CONFIG_DIR}/default.env" 2>/dev/null || {
    print_warning "Failed to load default.env - using default values"
    # Default values if config not found
    DEFAULT_PYTHON_VERSION="3.12.4"
    DEFAULT_COMFYUI_REPO="https://github.com/comfyanonymous/ComfyUI"
    DOCKER_IMAGE_NAME="nomcycle/comfyui-dev"
    DOCKER_IMAGE_TAG="latest"
}

# Define variables for source mode detection
SOURCED=false
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    SOURCED=true
    return 0  # Return early if being sourced
fi

# Display usage information
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    show_standard_usage
}

# Parse arguments using the standardized function
parse_args() {
    parse_standard_args "$@"
    local result=$?
    
    if [ $result -eq 100 ]; then
        # Help requested
        print_usage
        exit 0
    elif [ $result -ne 0 ]; then
        # Validation failed
        print_usage
        exit 1
    fi
}

# Run the Docker container
run_test() {
    # Generate SSH key
    SSH_KEY_PATH="$SSH_FOLDER_PATH/comfyui-dev"
    PUBKEY=$(generate_ssh_key "$SSH_FOLDER_PATH" "comfyui-dev")
    
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
}

# Main function
main() {
    parse_args "$@"
    run_test
}

# Run main if not being sourced
main "$@"