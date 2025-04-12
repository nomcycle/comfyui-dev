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

# Print build info
print_info "Building Docker image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
print_info "Using configuration from: ${SCRIPT_DIR}/../config/default.env"

# Build the Docker image
docker build \
    -t "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" \
    -f "${SCRIPT_DIR}/../docker/Dockerfile" \
    "${SCRIPT_DIR}/.." \
    || { print_error "Docker build failed"; exit 1; }

print_success "Docker image built successfully: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"