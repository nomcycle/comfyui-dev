#!/bin/bash
source /home/comfy/startup/utils.sh

log_message "Setting up ComfyUI development environment..."

# Validate environment variables
verify_env_vars "PYTHON_VERSION" "WORKSPACE_DIR" "WORKSPACE_VENV" "WORKSPACE_COMFYUI" "LOCAL_VENV" "LOCAL_COMFYUI"

# Setup standard PATH
setup_path

# List all files in the workspace directory
log_message "Listing files in /workspace directory:"
ls -la /workspace --all || {
    log_error "Failed to list files in /workspace directory"
    exit 1
}

log_message "Using Python version: ${PYTHON_VERSION}"

# Initialize setup components in the correct order with proper validation
log_message "======================= CURSOR SETUP ========================"
source /home/comfy/startup/scripts/modules/cursor_setup.sh || {
    log_error "Cursor setup failed"
    exit 1
}

log_message "======================= PYTHON SETUP ========================"
source /home/comfy/startup/scripts/modules/python_setup.sh || {
    log_error "Python setup failed"
    exit 1
}

log_message "======================= COMFYUI SETUP ======================="
source /home/comfy/startup/scripts/modules/comfyui_setup.sh || {
    log_error "ComfyUI setup failed"
    exit 1
}

log_message "======================= SYNC SETUP =========================="
source /home/comfy/startup/scripts/modules/sync_setup.sh || {
    log_error "Sync setup failed"
    exit 1
}

log_success "Environment setup complete!"