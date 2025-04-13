#!/bin/bash
# Python environment setup module
source /home/comfy/startup/utils.sh

log_message "Setting up Python environment..."

# Validate environment variables and commands
verify_env_vars "LOCAL_VENV" "WORKSPACE_VENV" "PYTHON_VERSION" "UV_PATH"
validate_commands "mkdir" "rm" "grep" "sed"

# Step 1: Check if workspace virtual environment exists with correct Python version
log_message "Checking workspace Python virtual environment..."
workspace_venv_valid=false

if [ -d "${WORKSPACE_VENV}" ]; then
    if check_venv_python_version "${WORKSPACE_VENV}" "${PYTHON_VERSION}"; then
        log_message "Workspace virtual environment exists with correct Python version."
        workspace_venv_valid=true
    else
        log_message "Workspace virtual environment exists but has wrong Python version. Recreating..."
        rm -rf "${WORKSPACE_VENV}"
    fi
fi

# Step 2: Create workspace virtual environment if it doesn't exist or has wrong version
if [ "$workspace_venv_valid" = false ]; then
    log_message "Creating new workspace Python virtual environment with uv..."
    ensure_dir "${WORKSPACE_VENV}" "comfy" 
    
    $UV_PATH venv "${WORKSPACE_VENV}" --python="${PYTHON_VERSION}" || {
        log_error "Failed to create workspace virtual environment"
        exit 1
    }
    log_success "Workspace Python virtual environment created successfully."
fi

# Step 3: Create local virtual environment (always fresh at container startup)
log_message "Setting up local Python virtual environment..."

# If LOCAL_VENV exists (unlikely, but possible), remove it
if [ -d "${LOCAL_VENV}" ]; then
    log_message "Removing existing local virtual environment..."
    rm -rf "${LOCAL_VENV}"
fi

# Create directory for local venv
ensure_dir "${LOCAL_VENV}" "comfy"

# Step 4: Sync from workspace to local
log_message "Syncing virtual environment from workspace to local..."
sync_dirs "${WORKSPACE_VENV}" "${LOCAL_VENV}" "Python virtual environment"

# Step 5: Always add LOCAL_VENV to .bashrc
if ! grep -q "source ${LOCAL_VENV}/bin/activate" /home/comfy/.bashrc; then
    echo "source ${LOCAL_VENV}/bin/activate" >> /home/comfy/.bashrc || {
        log_error "Failed to update .bashrc"
        exit 1
    }
    log_message "Added local virtual environment activation to .bashrc"
fi

# Step 6: Activate the local virtual environment
source_venv
log_success "Python environment setup complete."