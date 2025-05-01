#!/bin/bash
# Python packages installation module
source /home/comfy/startup/utils.sh

log_message "Setting up Python packages..."

# Validate environment variables 
verify_env_vars "UV_PATH" "LOCAL_COMFYUI" "LOCAL_PYTHON" "UV_PATH"
validate_commands "which"

# Different behaviors based on role
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    # LEADER BEHAVIOR
    log_message "Installing Python packages as LEADER..."
    
    # Verify ComfyUI directory
    verify_dir "${LOCAL_COMFYUI}" "local ComfyUI directory"
    
    # Navigate to ComfyUI directory
    cd "${LOCAL_COMFYUI}" || {
        log_error "Failed to navigate to local ComfyUI directory"
        exit 1
    }
    
    # Verify requirements.txt exists
    if [ ! -f "requirements.txt" ]; then
        log_error "requirements.txt not found in ComfyUI directory"
        exit 1
    fi
    
    # Verify uv command exists
    if [ ! -f "${UV_PATH}" ]; then
        log_error "uv command not found at ${UV_PATH}"
        exit 1
    }
    
    source "${LOCAL_PYTHON}/.venv/bin/activate"
    
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
    ${UV_PATH} pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128 || {
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
    
    # Sync updated packages to workspace
    log_message "Syncing updated packages to workspace..."
    sync_dirs "${LOCAL_PYTHON}" "${WORKSPACE_PYTHON}" "Python packages"
    
    # Signal packages setup completion
    touch /workspace/.setup/packages_ready
    
else
    # FOLLOWER BEHAVIOR
    log_message "Setting up Python packages as FOLLOWER..."
    
    # Wait for leader to complete packages setup
    wait_for_leader_completion "packages_ready"
    
    # No need to install packages - they're already synced from leader
    log_message "Using Python packages installed by leader"
    
    # Just ensure venv is activated
    source "${LOCAL_PYTHON}/.venv/bin/activate"
fi

log_success "Python packages setup complete."