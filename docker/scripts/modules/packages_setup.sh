#!/bin/bash
# Python packages installation module
source /home/comfy/startup/utils.sh

log_message "Installing required Python packages..."

# Ensure we're in ComfyUI directory
cd "${LOCAL_COMFYUI}" || {
    log_error "Local ComfyUI directory not found"
    exit 1
}

# Verify that we're using the correct virtual environment
current_python=$(which python)
if [[ "$current_python" != "${LOCAL_VENV}/bin/python"* ]]; then
    log_warning "Not using local virtual environment. Using: $current_python"
    log_message "Explicitly activating local virtual environment..."
    
    # Explicitly activate the local environment
    source "${LOCAL_VENV}/bin/activate"
    export VIRTUAL_ENV="${LOCAL_VENV}"
    export PATH="${LOCAL_VENV}/bin:$PATH"
    
    current_python=$(which python)
    log_message "Now using Python: $current_python"
fi

# Install required packages
log_message "Upgrading pip with uv..."
$UV_PATH pip install pip
$UV_PATH pip install --upgrade pip

log_message "Installing PyTorch..."
$UV_PATH pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124

log_message "Installing project requirements..."
$UV_PATH pip install -r requirements.txt

log_message "Installing onnxruntime..."
$UV_PATH pip install onnxruntime

log_success "All required packages installed successfully."