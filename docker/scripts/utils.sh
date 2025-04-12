#!/bin/bash

# Exit on error, undefined variables, and propagate pipe failures
set -euo pipefail

# Log levels
log_message() {
    echo -e "\033[38;5;205m[INSTALL]\033[0m $1"
}

log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

log_warning() {
    echo -e "\033[33m[WARNING]\033[0m $1"
}

log_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1"
}

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Error in script at line $line_number with exit code $exit_code"
    exit $exit_code
}

# Set up error trap
trap 'handle_error $LINENO' ERR

# Path management
setup_path() {
    # Configure standard PATH additions for all scripts
    export PATH="$HOME/.local/bin:$PATH:$HOME/.cargo/bin"
}

# Run command as comfy user with proper PATH
run_as_comfy() {
    local cmd="$1"
    shift
    su -l comfy -c "export PATH=$HOME/.local/bin:$PATH:$HOME/.cargo/bin; ${COMFY_ENV_VARS:-} $cmd $*"
}

# Virtual environment management
source_venv() {
    if [ -f "/workspace/.venv/bin/activate" ]; then
        source "/workspace/.venv/bin/activate"
    fi
}