#!/bin/bash
source /home/comfy/startup/utils.sh

# Add uv to path
export PATH="$HOME/.local/bin:$PATH:$HOME/.cargo/bin"

# Check if Python virtual environment exists
log_message "Checking if Python virtual environment exists..."
if [ ! -d "/workspace/.venv" ]; then
    log_message "Python virtual environment not found. Creating one with uv..."
    
    # Create virtual environment with uv
    $HOME/.local/bin/uv venv /workspace/.venv --python="${COMFY_DEV_PYTHON_VERSION:-3.10}"
    log_message "Python virtual environment created successfully."
    
    # Add to .bashrc
    if ! grep -q "source /workspace/.venv/bin/activate" /home/comfy/.bashrc; then
        echo 'source /workspace/.venv/bin/activate' >> /home/comfy/.bashrc
    fi
else
    log_message "Python virtual environment already exists."
fi

# Activate the virtual environment
source_venv

cd /workspace

if [ ! -d "/workspace/ComfyUI" ]; then
    log_message "Cloning ComfyUI repository..."
    git clone ${COMFY_DEV_GIT_FORK}
    cd ComfyUI
    log_message "ComfyUI repository cloned."

    if ! grep -q "cd /workspace/ComfyUI" /home/comfy/.bashrc; then
        echo 'cd /workspace/ComfyUI' >> /home/comfy/.bashrc
    fi
else
    log_message "ComfyUI directory already exists."
fi

log_message "Finished setting up python and repositories."