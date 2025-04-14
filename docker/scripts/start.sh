#!/bin/bash
source /home/comfy/startup/utils.sh

log_message "Starting ComfyUI development environment..."

# Validate environment variables
verify_env_vars "UV_PATH" "LOCAL_PYTHON" "LOCAL_COMFYUI" "LSYNCD_CONFIG_FILE"
validate_commands "sleep"

# Setup standard PATH
setup_path

# Verify Python is now accessible
if ! ${UV_PATH} run python --version &>/dev/null; then
    log_error "Cannot execute Python from ${LOCAL_PYTHON}/bin"
    exit 1
fi

# Install required packages - script will exit on failure
source /home/comfy/startup/scripts/modules/packages_setup.sh

# Verify lsyncd is running and restart if needed
log_message "Verifying lsyncd service..."
if ! is_process_running "lsyncd"; then
    log_warning "Lsyncd is not running, restarting..."
    source /home/comfy/startup/scripts/modules/sync_setup.sh
else
    log_success "Lsyncd is running"
fi

# Start ComfyUI if requested
if [ "${COMFY_DEV_START_COMFY:-false}" = "true" ]; then
    log_message "Starting ComfyUI..."
    
    # Verify ComfyUI directory and navigate to it
    verify_dir "${LOCAL_COMFYUI}" "local ComfyUI directory"
    cd "${LOCAL_COMFYUI}" || {
        log_error "Failed to navigate to ComfyUI directory"
        exit 1
    }
    
    # Verify main.py exists
    if [ ! -f "main.py" ]; then
        log_error "main.py not found in ComfyUI directory"
        exit 1
    fi
    
    # Start ComfyUI with proper error handling
    python main.py --listen "0.0.0.0" || {
        log_error "Failed to start ComfyUI"
        exit 1
    }
else
    log_message "Running in idle mode..."
    log_message "Will check lsyncd status every minute"
    
    # Main monitoring loop
    while true; do
        # Check if lsyncd is still running every minute
        if ! is_process_running "lsyncd"; then
            log_warning "Lsyncd stopped, restarting..."
            source /home/comfy/startup/scripts/modules/sync_setup.sh
        fi
        sleep 60
    done
fi