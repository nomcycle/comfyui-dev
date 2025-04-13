#!/bin/bash

# Exit on error, undefined variables, and propagate pipe failures
set -euo pipefail

# Make bash exit on first error in functions and subshells too
set -E

#---------------------------------------------------------------
# CENTRALIZED CONFIGURATION 
#---------------------------------------------------------------
# Common paths
export WORKSPACE_DIR="/workspace"
export WORKSPACE_VENV="${WORKSPACE_DIR}/.venv"
export WORKSPACE_COMFYUI="${WORKSPACE_DIR}/ComfyUI"
export LOCAL_VENV="${HOME}/.venv"
export LOCAL_COMFYUI="${HOME}/ComfyUI"
export CONFIG_DIR="${HOME}/.config"
export LSYNCD_CONFIG_DIR="${CONFIG_DIR}/lsyncd"
export LSYNCD_CONFIG_FILE="${LSYNCD_CONFIG_DIR}/lsyncd.conf.lua"
export LSYNCD_LOG_FILE="${LSYNCD_CONFIG_DIR}/lsyncd.log"
export LSYNCD_STATUS_FILE="${LSYNCD_CONFIG_DIR}/lsyncd.status"

# Python version
export PYTHON_VERSION="${COMFY_DEV_PYTHON_VERSION:-3.12.4}"

# Git repo
export COMFY_REPO="${COMFY_DEV_GIT_FORK:-https://github.com/comfyanonymous/ComfyUI}"

# UV path
export UV_PATH="${HOME}/.local/bin/uv"

#---------------------------------------------------------------
# LOG FUNCTIONS
#---------------------------------------------------------------

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

#---------------------------------------------------------------
# ERROR HANDLING
#---------------------------------------------------------------

# Error handling function
handle_error() {
    local exit_code=$?
    local line_number=$1
    log_error "Error in script at line $line_number with exit code $exit_code"
    exit $exit_code
}

# Set up error trap
trap 'handle_error $LINENO' ERR

#---------------------------------------------------------------
# UTILITY FUNCTIONS
#---------------------------------------------------------------

# Path management
setup_path() {
    # Configure standard PATH additions for all scripts
    export PATH="${HOME}/.local/bin:$PATH:${HOME}/.cargo/bin"
}

# Run command as comfy user with proper PATH
run_as_comfy() {
    local cmd="$1"
    shift
    su -l comfy -c "export PATH=${HOME}/.local/bin:$PATH:${HOME}/.cargo/bin; ${COMFY_ENV_VARS:-} $cmd $*"
}

# Virtual environment management
source_venv() {
    if [ -f "${LOCAL_VENV}/bin/activate" ]; then
        # Direct source to ensure environment changes propagate
        source "${LOCAL_VENV}/bin/activate"
        # Export VIRTUAL_ENV to ensure it's set correctly for all processes
        export VIRTUAL_ENV="${LOCAL_VENV}"
        export PATH="${LOCAL_VENV}/bin:$PATH"
    else
        log_error "Local virtual environment activation script not found"
        exit 1
    fi
}

#---------------------------------------------------------------
# DIRECTORY MANAGEMENT HELPERS
#---------------------------------------------------------------

# Create directory with proper permissions
ensure_dir() {
    local dir="$1"
    local owner="${2:-comfy}"
    
    if [ ! -d "$dir" ]; then
        log_message "Creating directory: $dir"
        mkdir -p "$dir"
    fi
    
    if [ "$owner" != "root" ]; then
        chown -R "$owner:$owner" "$dir"
    fi
}

# Check if a directory exists and is valid
verify_dir() {
    local dir="$1"
    local description="${2:-directory}"
    
    if [ ! -d "$dir" ]; then
        log_error "Required $description not found: $dir"
        return 1
    fi
    return 0
}

#---------------------------------------------------------------
# SYNC HELPERS
#---------------------------------------------------------------

# Sync directories using rsync
sync_dirs() {
    local source_dir="$1"
    local target_dir="$2"
    local description="${3:-directories}"
    
    log_message "Syncing $description from $source_dir to $target_dir"
    
    if ! rsync -a --delete "$source_dir/" "$target_dir/"; then
        log_error "Failed to sync $description"
        return 1
    fi
    
    log_success "Successfully synced $description"
    return 0
}

# Start lsyncd service
start_lsyncd() {
    local config_file="$1"
    
    log_message "Starting lsyncd with config: $config_file"
    
    # Ensure config directory exists
    ensure_dir "$(dirname "$config_file")"
    
    # Start lsyncd with nohup to ensure it keeps running after shell exits
    nohup lsyncd "$config_file" > /tmp/lsyncd.out 2>&1 &
    local lsyncd_pid=$!
    
    # Verify it's running
    sleep 2
    if ! kill -0 $lsyncd_pid 2>/dev/null; then
        log_error "Failed to start lsyncd"
        log_error "Lsyncd output:"
        cat /tmp/lsyncd.out
        return 1
    fi
    
    log_success "Lsyncd started with PID $lsyncd_pid"
    return 0
}

# Check if process is running
is_process_running() {
    local process_name="$1"
    pgrep "$process_name" > /dev/null
    return $?
}

# Verify lsyncd is running
verify_lsyncd() {
    if ! is_process_running "lsyncd"; then
        log_error "Lsyncd is not running"
        return 1
    fi
    return 0
}