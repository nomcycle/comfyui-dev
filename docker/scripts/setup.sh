#!/bin/bash
source /home/comfy/startup/utils.sh

log_message "Setting up ComfyUI development environment..."

# Validate environment variables
verify_env_vars "PYTHON_VERSION" "WORKSPACE_DIR" "WORKSPACE_PYTHON" "WORKSPACE_COMFYUI" "LOCAL_PYTHON" "LOCAL_COMFYUI"

# Setup standard PATH
setup_path

# List all files in the workspace directory
log_message "Listing files in /workspace directory:"
ls -la /workspace --all || {
    log_error "Failed to list files in /workspace directory"
    exit 1
}

log_message "Using Python version: ${PYTHON_VERSION}"

# Initialize role first
log_message "======================= ROLE SETUP =========================="
source /home/comfy/startup/scripts/modules/role_setup.sh || {
    log_error "Role setup failed"
    exit 1
}

# Leader/follower specific setup paths
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    # LEADER SETUP SEQUENCE
    log_message "Running LEADER setup sequence..."
    
    # Wait for leader to finish complete setup (follower only)
    if [[ "${COMFY_DEV_ROLE}" == "FOLLOWER" ]]; then
        wait_for_leader_completion "packages_ready"
    fi
else
    # FOLLOWER SETUP SEQUENCE
    log_message "Running FOLLOWER setup sequence..."
    
    # Wait for leader to finish complete setup
    wait_for_leader_completion "packages_ready"
fi

# Common setup components in correct order with proper validation
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

log_message "======================= PACKAGES SETUP ======================"
source /home/comfy/startup/scripts/modules/packages_setup.sh || {
    log_error "Packages setup failed"
    exit 1
}

log_message "======================= CURSOR SETUP ========================"
source /home/comfy/startup/scripts/modules/cursor_setup.sh || {
    log_error "Cursor setup failed"
    exit 1
}

log_message "======================= SYNC SETUP =========================="
source /home/comfy/startup/scripts/modules/sync_setup.sh || {
    log_error "Sync setup failed"
    exit 1
}

# Signal complete setup (leader only)
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    touch /workspace/.setup/setup_complete
    log_success "LEADER environment setup complete!"
else
    log_success "FOLLOWER environment setup complete!"
fi