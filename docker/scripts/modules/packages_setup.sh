#!/bin/bash
# Python packages installation module
source /home/comfy/startup/utils.sh

log_message "Installing required Python packages..."

# Validate environment variables 
verify_env_vars "LOCAL_COMFYUI" "LOCAL_VENV" "UV_PATH"
validate_commands "which"

# Python command will be available after activation

# Verify ComfyUI directory
verify_dir "${LOCAL_COMFYUI}" "local ComfyUI directory"

# Navigate to ComfyUI directory
cd "${LOCAL_COMFYUI}" || {
    log_error "Failed to navigate to local ComfyUI directory"
    exit 1
}

# Activate the virtual environment - will exit if activation fails
source_venv

# Now we can verify python is available
if ! command -v python &> /dev/null; then
    log_error "Python command still not available after virtual environment activation"
    exit 1
fi

log_message "Using Python: $(which python) ($(python --version 2>&1))"

# Verify requirements.txt exists
if [ ! -f "requirements.txt" ]; then
    log_error "requirements.txt not found in ComfyUI directory"
    exit 1
fi

# Verify uv command exists
if [ ! -f "${UV_PATH}" ]; then
    log_error "uv command not found at ${UV_PATH}"
    exit 1
fi

# Install required packages with strict error checking
log_message "Upgrading pip with uv..."
${UV_PATH} pip install pip || {
    log_error "Failed to install pip"
    exit 1
}

${UV_PATH} pip install --upgrade pip || {
    log_error "Failed to upgrade pip"
    exit 1
}

log_message "Installing PyTorch..."
${UV_PATH} pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu124 || {
    log_error "Failed to install PyTorch"
    exit 1
}

log_message "Installing project requirements..."
${UV_PATH} pip install -r requirements.txt || {
    log_error "Failed to install project requirements"
    exit 1
}

log_message "Installing onnxruntime..."
${UV_PATH} pip install onnxruntime || {
    log_error "Failed to install onnxruntime"
    exit 1
}

log_success "All required packages installed successfully."