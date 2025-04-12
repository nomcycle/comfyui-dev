#!/bin/bash

source /home/comfy/startup/utils.sh
source_venv

cd /workspace/ComfyUI

log_message "Activating virtual environment..."
# Ensure we have the user's binaries in PATH
export PATH="$HOME/.local/bin:$PATH:$HOME/.cargo/bin"

log_message "Installing required packages with uv..."
# Use full path to uv to avoid PATH issues
$HOME/.local/bin/uv pip install pip
$HOME/.local/bin/uv pip install --upgrade pip
$HOME/.local/bin/uv pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
$HOME/.local/bin/uv pip install -r requirements.txt
$HOME/.local/bin/uv pip install onnxruntime

if [ "${COMFY_DEV_START_COMFY}" = "true" ]; then
    log_message "Starting comfy..."
    python main.py --listen "0.0.0.0"
else
    log_message "Running in idle mode..."
    while true; do
        sleep 60
    done
fi