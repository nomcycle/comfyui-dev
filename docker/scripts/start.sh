#!/bin/bash
source /home/comfy/startup/utils.sh

log_message "Starting ComfyUI development environment..."

# Validate environment variables
verify_env_vars "LOCAL_VENV" "LOCAL_COMFYUI" "LSYNCD_CONFIG_FILE"
validate_commands "sleep"

# Verify python will be available in the virtual environment
if [ ! -f "${LOCAL_VENV}/bin/python" ]; then
    log_error "Python not found in virtual environment: ${LOCAL_VENV}/bin/python"
    exit 1
fi

# Setup standard PATH
setup_path

# Activate the virtual environment - will exit if activation fails
source_venv

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

# Verify that we have synchronized both the Python environment and ComfyUI repository
log_message "Verifying synchronized directories..."
if [ ! -f "${LOCAL_VENV}/bin/python3" ]; then
    log_warning "Local Python virtual environment might be corrupted, re-syncing from workspace..."
    sync_dirs "${WORKSPACE_VENV}" "${LOCAL_VENV}" "Python virtual environment"
fi

if [ ! -d "${LOCAL_COMFYUI}" ] || [ ! -f "${LOCAL_COMFYUI}/main.py" ]; then
    log_warning "Local ComfyUI repository might be corrupted, re-syncing from workspace..."
    sync_dirs "${WORKSPACE_COMFYUI}" "${LOCAL_COMFYUI}" "ComfyUI repository"
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