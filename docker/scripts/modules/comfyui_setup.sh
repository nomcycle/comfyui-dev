#!/bin/bash
# ComfyUI repository setup module
source /home/comfy/startup/utils.sh

log_message "Setting up ComfyUI repository..."

# Navigate to workspace
cd $WORKSPACE_DIR

# Clone ComfyUI repository if it doesn't exist
if [ ! -d "${WORKSPACE_COMFYUI}" ]; then
    log_message "Cloning ComfyUI repository from ${COMFY_REPO}..."
    git clone ${COMFY_REPO}
    
    if [ $? -ne 0 ]; then
        log_error "Failed to clone repository"
        exit 1
    fi
    
    log_success "ComfyUI repository cloned successfully."
else
    log_message "ComfyUI directory exists in workspace."
fi

# Set up local ComfyUI directory for faster operations
if [ ! -d "${LOCAL_COMFYUI}" ]; then
    log_message "Creating local ComfyUI directory for faster operations..."
    ensure_dir "${LOCAL_COMFYUI}" "comfy"
    
    # Initial sync from workspace to local
    sync_dirs "${WORKSPACE_COMFYUI}" "${LOCAL_COMFYUI}" "ComfyUI repository"
else
    log_message "Local ComfyUI directory already exists."
fi

# Update navigation in .bashrc to use local directory
if ! grep -q "cd ${LOCAL_COMFYUI}" /home/comfy/.bashrc; then
    # Remove old navigation path if it exists
    sed -i "/cd \/workspace\/ComfyUI/d" /home/comfy/.bashrc
    
    # Add new navigation path
    echo "cd ${LOCAL_COMFYUI}" >> /home/comfy/.bashrc
    log_message "Updated .bashrc to use local ComfyUI directory"
fi

log_success "ComfyUI repository setup complete."