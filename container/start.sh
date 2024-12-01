#!/bin/bash

source /home/comfy/startup/utils.sh
source_conda

cd /workspace/ComfyUI

log_message "Activating comfy environment..."
conda activate comfy

log_message "Validating pip packages for comfy..."
python -m pip install --upgrade pip
python -m pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124
python -m pip install -r requirements.txt
python -m pip install onnxruntime

if [ "${COMFY_DEV_START_COMFY}" = "true" ]; then
    log_message "Starting comfy..."
    python main.py --listen "0.0.0.0"
else
    log_message "Running in idle mode..."
    while true; do
        sleep 60
    done
fi