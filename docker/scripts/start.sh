#!/bin/bash
source /home/comfy/startup/utils.sh

# Setup standard PATH
setup_path

# Activate the virtual environment
source_venv
log_message "Activated virtual environment"

# Navigate to ComfyUI directory
cd /workspace/ComfyUI || {
    log_error "ComfyUI directory not found"
    exit 1
}

# Install required packages
log_message "Installing required packages with uv..."
$HOME/.local/bin/uv pip install pip
$HOME/.local/bin/uv pip install --upgrade pip
log_message "Installing PyTorch..."
$HOME/.local/bin/uv pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
log_message "Installing project requirements..."
$HOME/.local/bin/uv pip install -r requirements.txt
log_message "Installing onnxruntime..."
$HOME/.local/bin/uv pip install onnxruntime

log_success "All required packages installed"

# Start ComfyUI if requested
if [ "${COMFY_DEV_START_COMFY:-false}" = "true" ]; then
    log_message "Starting ComfyUI..."
    python main.py --listen "0.0.0.0"
else
    log_message "Running in idle mode..."
    while true; do
        sleep 60
    done
fi