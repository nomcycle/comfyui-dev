#!/bin/bash
# ComfyUI repository setup module
source /home/comfy/startup/utils.sh

log_message "Setting up ComfyUI repository..."

# Validate environment variables and commands
verify_env_vars "WORKSPACE_DIR" "WORKSPACE_COMFYUI" "LOCAL_COMFYUI" "COMFY_REPO"
validate_commands "git" "grep" "sed"

# Different behaviors based on role
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    # LEADER BEHAVIOR
    log_message "Setting up ComfyUI as LEADER..."
    
    # Navigate to workspace - exit if workspace directory doesn't exist
    verify_dir "${WORKSPACE_DIR}" "workspace directory"
    cd "${WORKSPACE_DIR}"
    
    # Clone ComfyUI repository if it doesn't exist
    if [ ! -d "${WORKSPACE_COMFYUI}" ]; then
        log_message "Cloning ComfyUI repository from ${COMFY_REPO}..."
        
        git clone "${COMFY_REPO}"
        
        log_success "ComfyUI repository cloned successfully."
    elif [ ! -d "${WORKSPACE_COMFYUI}/.git" ]; then
        log_error "ComfyUI directory exists but is not a git repository"
        exit 1
    else
        log_message "ComfyUI directory exists in workspace."
    fi
    
    # Verify the workspace ComfyUI directory is valid
    verify_dir "${WORKSPACE_COMFYUI}" "ComfyUI repository"
    
    log_message "Copying extra_model_paths.yaml to ComfyUI directory..."
    cp -vf ~/startup/config/comfy/extra_model_paths.yaml "${WORKSPACE_COMFYUI}/"
    
    # Set up local ComfyUI directory for faster operations
    log_message "Setting up local ComfyUI directory..."
    ensure_dir "${LOCAL_COMFYUI}" "comfy"
    
    # Sync from workspace to local to ensure the latest content
    log_message "Syncing ComfyUI repository to local directory..."
    sync_dirs "${WORKSPACE_COMFYUI}" "${LOCAL_COMFYUI}" "ComfyUI repository"
    
    # Signal ComfyUI setup completion
    touch /workspace/.setup/comfyui_ready
    
else
    # FOLLOWER BEHAVIOR
    log_message "Setting up ComfyUI as FOLLOWER..."
    
    # Wait for leader to complete ComfyUI setup
    wait_for_leader_completion "comfyui_ready"
    
    # Verify the workspace ComfyUI directory is valid
    verify_dir "${WORKSPACE_COMFYUI}" "ComfyUI repository (from leader)"
    
    # Set up local ComfyUI directory
    log_message "Setting up local ComfyUI directory..."
    ensure_dir "${LOCAL_COMFYUI}" "comfy"
    
    # Sync from workspace to local
    log_message "Syncing ComfyUI repository from workspace to local..."
    sync_dirs "${WORKSPACE_COMFYUI}" "${LOCAL_COMFYUI}" "ComfyUI repository"
fi

log_success "ComfyUI repository setup complete."