#!/bin/bash
source /home/comfy/startup/utils.sh

# Setup standard PATH
setup_path

# Set default Python version if not specified
PYTHON_VERSION="${COMFY_DEV_PYTHON_VERSION:-3.12.4}"
log_message "Using Python version: ${PYTHON_VERSION}"

# Check if Python virtual environment exists
log_message "Checking if Python virtual environment exists..."
if [ ! -d "/workspace/.venv" ]; then
    log_message "Python virtual environment not found. Creating one with uv..."
    
    # Create virtual environment with uv
    $HOME/.local/bin/uv venv /workspace/.venv --python="${PYTHON_VERSION}"
    log_success "Python virtual environment created successfully."
    
    # Add to .bashrc
    if ! grep -q "source /workspace/.venv/bin/activate" /home/comfy/.bashrc; then
        echo 'source /workspace/.venv/bin/activate' >> /home/comfy/.bashrc
        log_message "Added virtual environment activation to .bashrc"
    fi
else
    log_message "Python virtual environment already exists."
fi

# Activate the virtual environment
source_venv

# Navigate to workspace
cd /workspace

# Clone ComfyUI repository if it doesn't exist
COMFY_REPO="${COMFY_DEV_GIT_FORK:-https://github.com/comfyanonymous/ComfyUI}"
if [ ! -d "/workspace/ComfyUI" ]; then
    log_message "Cloning ComfyUI repository from ${COMFY_REPO}..."
    git clone ${COMFY_REPO}
    
    if [ $? -ne 0 ]; then
        log_error "Failed to clone repository"
        exit 1
    fi
    
    cd ComfyUI
    log_success "ComfyUI repository cloned successfully."

    # Add workspace navigation to .bashrc
    if ! grep -q "cd /workspace/ComfyUI" /home/comfy/.bashrc; then
        echo 'cd /workspace/ComfyUI' >> /home/comfy/.bashrc
        log_message "Added workspace navigation to .bashrc"
    fi
else
    log_message "ComfyUI directory already exists."
fi

log_success "Python environment and repositories setup complete."