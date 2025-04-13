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
# ENVIRONMENT VALIDATION
#---------------------------------------------------------------

# Verify required environment variables
verify_env_vars() {
    local required_vars=("$@")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
    
    log_message "Environment variables verified"
}

# Validate commands exist
validate_commands() {
    local required_cmds=("$@")
    local missing_cmds=()
    
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_cmds+=("$cmd")
        fi
    done
    
    if [ ${#missing_cmds[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing_cmds[*]}"
        exit 1
    fi
    
    log_message "Required commands verified"
}

#---------------------------------------------------------------
# UTILITY FUNCTIONS
#---------------------------------------------------------------

# Path management - exits on failure
setup_path() {
    log_message "Setting up PATH environment variable"
    
    # Verify key directories exist
    if [ ! -d "${HOME}/.local/bin" ]; then
        log_message "Creating ~/.local/bin directory"
        mkdir -p "${HOME}/.local/bin" || {
            log_error "Failed to create ~/.local/bin directory"
            exit 1
        }
    fi
    
    # Configure standard PATH additions for all scripts
    export PATH="${HOME}/.local/bin:$PATH:${HOME}/.cargo/bin"
    
    # Verify path is set correctly
    if ! echo "$PATH" | grep -q "${HOME}/.local/bin"; then
        log_error "Failed to set PATH correctly"
        exit 1
    fi
    
    log_message "PATH setup complete: $PATH"
}

# Run command as comfy user with proper PATH
run_as_comfy() {
    local cmd="$1"
    shift
    su -l comfy -c "export PATH=${HOME}/.local/bin:$PATH:${HOME}/.cargo/bin; ${COMFY_ENV_VARS:-} $cmd $*"
}

#---------------------------------------------------------------
# VIRTUAL ENVIRONMENT MANAGEMENT
#---------------------------------------------------------------

# Check Python version in a virtual environment
# Returns 0 if version matches, 1 if not
check_venv_python_version() {
    local venv_path="$1"
    local expected_version="$2"
    
    if [ ! -f "${venv_path}/bin/python3" ]; then
        log_message "Python interpreter not found in virtual environment: ${venv_path}"
        return 1
    fi
    
    local version_output=$(${venv_path}/bin/python3 --version 2>&1)
    local actual_version=$(echo "$version_output" | cut -d' ' -f2)
    
    if [[ "$actual_version" != "$expected_version"* ]]; then
        log_message "Python version mismatch in ${venv_path}: expected ${expected_version}, found ${actual_version}"
        return 1
    fi
    
    log_message "Python version verified in ${venv_path}: ${actual_version}"
    return 0
}

# Activate virtual environment - exits on failure
source_venv() {
    if [ ! -f "${LOCAL_VENV}/bin/activate" ]; then
        log_error "Local virtual environment activation script not found"
        exit 1
    fi
    
    # Direct source to ensure environment changes propagate
    source "${LOCAL_VENV}/bin/activate"
    
    # Export VIRTUAL_ENV to ensure it's set correctly for all processes
    export VIRTUAL_ENV="${LOCAL_VENV}"
    export PATH="${LOCAL_VENV}/bin:$PATH"
    
    # Verify Python interpreter exists in the virtual environment
    if [ ! -f "${LOCAL_VENV}/bin/python" ]; then
        log_error "Python interpreter not found in virtual environment"
        exit 1
    fi
    
    # Verify we can execute python
    if ! "${LOCAL_VENV}/bin/python" --version &>/dev/null; then
        log_error "Cannot execute Python from virtual environment"
        exit 1
    fi
    
    log_message "Activated virtual environment: ${LOCAL_VENV}"
}

#---------------------------------------------------------------
# DIRECTORY MANAGEMENT HELPERS
#---------------------------------------------------------------

# Create directory with proper permissions - exits on failure
ensure_dir() {
    local dir="$1"
    local owner="${2:-comfy}"
    
    if [ -z "$dir" ]; then
        log_error "ensure_dir: No directory path provided"
        exit 1
    fi
    
    if [ ! -d "$dir" ]; then
        log_message "Creating directory: $dir"
        mkdir -p "$dir" || {
            log_error "Failed to create directory: $dir"
            exit 1
        }
    fi
    
    if [ "$owner" != "root" ]; then
        chown -R "$owner:$owner" "$dir" || {
            log_error "Failed to set ownership on directory: $dir"
            exit 1
        }
    fi
    
    log_message "Directory ensured: $dir"
}

# Verify directory exists - exits on failure
verify_dir() {
    local dir="$1"
    local description="${2:-directory}"
    
    if [ -z "$dir" ]; then
        log_error "verify_dir: No directory path provided"
        exit 1
    fi
    
    if [ ! -d "$dir" ]; then
        log_error "Required $description not found: $dir"
        exit 1
    fi
    
    log_message "Verified $description: $dir"
}

#---------------------------------------------------------------
# SYNC HELPERS
#---------------------------------------------------------------

# Sync directories using rsync - exits on failure
sync_dirs() {
    local source_dir="$1"
    local target_dir="$2"
    local description="${3:-directories}"
    
    if [ -z "$source_dir" ] || [ -z "$target_dir" ]; then
        log_error "sync_dirs: Source or target directory not provided"
        exit 1
    fi
    
    if [ ! -d "$source_dir" ]; then
        log_error "Source directory does not exist: $source_dir"
        exit 1
    fi
    
    # Ensure target directory's parent exists
    ensure_dir "$(dirname "$target_dir")"
    
    log_message "Syncing $description from $source_dir to $target_dir"
    
    rsync -a --delete "$source_dir/" "$target_dir/" || {
        log_error "Failed to sync $description"
        exit 1
    }
    
    log_success "Successfully synced $description"
}

# Verify lsyncd configuration file - exits on failure
verify_lsyncd_config() {
    local config_file="$1"
    
    if [ -z "$config_file" ]; then
        log_error "verify_lsyncd_config: No config file provided"
        exit 1
    fi
    
    if [ ! -f "$config_file" ]; then
        log_error "Lsyncd configuration file not found: $config_file"
        exit 1
    fi
    
    # Check if lsyncd is available
    if ! command -v lsyncd &> /dev/null; then
        log_error "lsyncd command not found"
        exit 1
    fi
    
    log_message "Lsyncd configuration verified: $config_file"
}

# Start lsyncd service - exits on failure
start_lsyncd() {
    local config_file="$1"
    
    verify_lsyncd_config "$config_file"
    
    log_message "Starting lsyncd with config: $config_file"
    
    # Start lsyncd with nohup to ensure it keeps running after shell exits
    nohup lsyncd "$config_file" > /tmp/lsyncd.out 2>&1 &
    local lsyncd_pid=$!
    
    # Verify it's running
    sleep 2
    if ! kill -0 $lsyncd_pid 2>/dev/null; then
        log_error "Failed to start lsyncd. Lsyncd output:"
        cat /tmp/lsyncd.out
        exit 1
    fi
    
    log_success "Lsyncd started with PID $lsyncd_pid"
}

# Check if process is running - exits on failure if check_critical=true
is_process_running() {
    local process_name="$1"
    local check_critical="${2:-false}"
    
    if [ -z "$process_name" ]; then
        log_error "is_process_running: No process name provided"
        exit 1
    fi
    
    if ! pgrep "$process_name" > /dev/null; then
        if [ "$check_critical" = "true" ]; then
            log_error "Critical process not running: $process_name"
            exit 1
        fi
        return 1
    fi
    
    return 0
}

# Verify lsyncd is running - exits on failure
verify_lsyncd() {
    log_message "Verifying lsyncd is running..."
    is_process_running "lsyncd" "true"
    log_success "Lsyncd is running"
}