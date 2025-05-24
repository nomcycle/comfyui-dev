#!/bin/bash
# utils.sh - Common utility functions for comfyui-dev and ComfyUI_Cluster_Docker

# Standard logging functions
print_info() {
    echo -e "\033[36m[INFO]\033[0m $1"
}

print_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

print_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

print_cluster() {
    echo -e "\033[38;5;33m[CLUSTER]\033[0m $1"
}

# SSH key utilities
generate_ssh_key() {
    local ssh_folder="${1:-$HOME/.ssh}"
    local key_name="${2:-comfyui-dev}"
    
    mkdir -p "$ssh_folder"
    local key_path="$ssh_folder/$key_name"
    
    if [ ! -f "$key_path" ]; then
        print_info "Generating SSH key: $key_path"
        ssh-keygen -t ed25519 -f "$key_path" -N "" -C "$key_name"
    else
        print_info "Using existing SSH key: $key_path"
    fi
    
    cat "${key_path}.pub"
}

# Standard argument parsing function that can be extended
parse_standard_args() {
    # Default values
    TAILSCALE_AUTH=""
    GIT_FORK="${DEFAULT_COMFYUI_REPO:-https://github.com/comfyanonymous/ComfyUI}"
    PYTHON_VERSION="${DEFAULT_PYTHON_VERSION:-3.12.4}"
    SSH_FOLDER_PATH="$HOME/.ssh"
    START_COMFY="true"

    local unknown_args=()
    local i=1
    
    while [[ $i -le $# ]]; do
        arg="${!i}"
        case "$arg" in
            --tailscale-auth)
                i=$((i+1))
                TAILSCALE_AUTH="${!i}"
                ;;
            --git-fork)
                i=$((i+1))
                GIT_FORK="${!i}"
                ;;
            --python-version)
                i=$((i+1))
                PYTHON_VERSION="${!i}"
                ;;
            --ssh-folder-path)
                i=$((i+1))
                SSH_FOLDER_PATH="${!i}"
                ;;
            --start-comfy)
                i=$((i+1))
                START_COMFY="${!i}"
                ;;
            --help)
                # Return the help flag for caller to handle
                return 100
                ;;
            *)
                unknown_args+=("$arg")
                ;;
        esac
        i=$((i+1))
    done
    
    # Check required args
    if [ -z "$TAILSCALE_AUTH" ]; then
        print_error "Missing required argument: --tailscale-auth"
        return 1
    fi
    
    # Pass back unknown args if requested
    # if [[ "$RETURN_UNKNOWN_ARGS" == "true" ]]; then
    #     UNKNOWN_ARGS=("${unknown_args[@]}")
    # fi
    
    return 0
}

# Show standard usage information
show_standard_usage() {
    echo "General Options:"
    echo "  --tailscale-auth KEY    Tailscale authentication key (required)"
    echo "  --git-fork URL          URL to ComfyUI Git repository"
    echo "  --python-version VER    Python version to use"
    echo "  --ssh-folder-path PATH  Path to SSH folder (default: ~/.ssh)"
    echo "  --start-comfy           Start ComfyUI"
    echo "  --help                  Show this help message"
}

# Check if this script is being executed or sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_warning "This script is meant to be sourced, not executed directly."
    print_info "Usage: source $(basename "${BASH_SOURCE[0]}")"
    exit 1
fi