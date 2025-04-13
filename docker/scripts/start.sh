#!/bin/bash
source /home/comfy/startup/utils.sh

# Setup standard PATH
setup_path

# Explicitly activate the virtual environment
if [ ! -f "${LOCAL_VENV}/bin/activate" ]; then
    log_error "Local virtual environment not found"
    exit 1
fi

source "${LOCAL_VENV}/bin/activate"
export VIRTUAL_ENV="${LOCAL_VENV}"
export PATH="${LOCAL_VENV}/bin:$PATH"
log_message "Activated local virtual environment: $(which python)"

# Install required packages
source /home/comfy/startup/scripts/modules/packages_setup.sh

# Verify lsyncd is still running
verify_lsyncd || {
    log_warning "Lsyncd is not running, restarting..."
    source /home/comfy/startup/scripts/modules/sync_setup.sh
}

# Start ComfyUI if requested
if [ "${COMFY_DEV_START_COMFY:-false}" = "true" ]; then
    log_message "Starting ComfyUI..."
    cd "${LOCAL_COMFYUI}" || {
        log_error "ComfyUI directory not found"
        exit 1
    }
    python main.py --listen "0.0.0.0"
else
    log_message "Running in idle mode..."
    while true; do
        # Check if lsyncd is still running every minute
        if ! verify_lsyncd; then
            log_warning "Lsyncd stopped, restarting..."
            source /home/comfy/startup/scripts/modules/sync_setup.sh
        fi
        sleep 60
    done
fi