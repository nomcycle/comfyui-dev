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

# Ensure user is logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    print_error "You are not logged in to Docker Hub. Please run 'docker login' first."
    exit 1
fi

# Push the Docker image
print_info "Pushing Docker image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
docker push "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}" || {
    print_error "Failed to push Docker image"
    exit 1
}

print_success "Docker image pushed successfully: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"