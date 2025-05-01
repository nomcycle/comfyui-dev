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
export WORKSPACE_PYTHON="${WORKSPACE_DIR}/python"
export WORKSPACE_COMFYUI="${WORKSPACE_DIR}/ComfyUI"
export WORKSPACE_CURSOR="${WORKSPACE_DIR}/.cursor-server"
export LOCAL_PYTHON="${HOME}/python"
export LOCAL_COMFYUI="${HOME}/ComfyUI"
export LOCAL_CURSOR="${HOME}/.cursor-server"
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
    local last_command=${BASH_COMMAND}

    log_error "Error in script at line $line_number (exit code $exit_code): '$last_command'"

    # Print stack trace
    local i=0
    local stack_size=${#FUNCNAME[@]}
    # Start from 1 to skip handle_error itself
    log_error "Call Stack:"
    for (( i=1; i<stack_size; i++ )); do
        local func="${FUNCNAME[$i]}"
        local line="${BASH_LINENO[$((i-1))]}" # Line number where the function at index i was called
        local source="${BASH_SOURCE[$i]}"
        # Handle cases where function name might be empty or 'main'
        [[ "$func" == "main" ]] || [[ -z "$func" ]] && func="top-level"
        log_error "  at ${func}() in ${source}:${line}"
    done

    # Exit with the original error code
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

# Path management - exits on failure via trap
setup_path() {
    log_message "Setting up PATH environment variable"
    
    # Verify key directories exist
    if [ ! -d "${HOME}/.local/bin" ]; then
        log_message "Creating ~/.local/bin directory"
        mkdir -p "${HOME}/.local/bin"
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

# Wait for leader to complete specific setup step
wait_for_leader_completion() {
    local marker="$1"
    local max_retries=${2:-60}  # Default: 30 minutes at 30-second intervals
    local retry_delay=${3:-30}
    local retries=0
    
    log_message "Waiting for leader to complete ${marker} setup..."
    
    while [[ ! -f "/workspace/.setup/${marker}" ]]; do
        retries=$((retries+1))
        if [[ $retries -ge $max_retries ]]; then
            log_error "Timed out waiting for leader to complete ${marker} setup"
            exit 1
        fi
        log_message "Waiting for leader to complete ${marker} setup (attempt ${retries}/${max_retries})..."
        sleep $retry_delay
    done
    
    log_success "Leader has completed ${marker} setup"
}

# Run command as comfy user with proper PATH
run_as_comfy() {
    local cmd="$1"
    shift
    su -l comfy -c "export PATH=${HOME}/.local/bin:$PATH:${HOME}/.cargo/bin; ${COMFY_ENV_VARS:-} $cmd $*"
}

#---------------------------------------------------------------
# PYTHON ENVIRONMENT MANAGEMENT
#---------------------------------------------------------------

# Check Python version in installation
# Returns 0 if version matches, 1 if not
check_python_version() {
    local python_version_path="$1"
    local expected_version="$2"

    if [ ! -f "$python_version_path" ]; then
        log_message "Python version not found at path: ${python_version_path}"
        return 1
    fi

    local current_python_version=$(cat "$python_version_path")
    
    if [[ "$current_python_version" != "$expected_version"* ]]; then
        log_message "Python version mismatch: expected ${expected_version}, found ${current_python_version}"
        return 1
    fi
    
    log_message "Python version verified: ${current_python_version}"
    return 0
}

# Initialize Python environment - function removed as we now use PATH directly

#---------------------------------------------------------------
# DIRECTORY MANAGEMENT HELPERS
#---------------------------------------------------------------

# Create directory with proper permissions - exits on failure via trap
ensure_dir() {
    local dir="$1"
    local owner="${2:-comfy}"
    
    if [ -z "$dir" ]; then
        log_error "ensure_dir: No directory path provided"
        exit 1
    fi
    
    if [ ! -d "$dir" ]; then
        log_message "Creating directory: $dir"
        mkdir -p "$dir"
    fi
    
    if [ "$owner" != "root" ]; then
        chown -R "$owner:$owner" "$dir"
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

# Sync directories using rsync - exits on failure via trap
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
    rsync -a --delete "$source_dir/" "$target_dir/"
    
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

# Start lsyncd service - exits on failure via trap
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