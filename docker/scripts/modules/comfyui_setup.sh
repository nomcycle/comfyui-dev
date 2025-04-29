#!/bin/bash
# ComfyUI repository setup module
source /home/comfy/startup/utils.sh

log_message "Setting up ComfyUI repository..."

# Validate environment variables and commands
verify_env_vars "WORKSPACE_DIR" "WORKSPACE_COMFYUI" "LOCAL_COMFYUI" "COMFY_REPO"
validate_commands "git" "grep" "sed"

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

# Always sync from workspace to local to ensure the latest content
log_message "Syncing ComfyUI repository to local directory..."
sync_dirs "${WORKSPACE_COMFYUI}" "${LOCAL_COMFYUI}" "ComfyUI repository"

log_success "ComfyUI repository setup complete."