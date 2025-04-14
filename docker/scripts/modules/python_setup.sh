#!/bin/bash
# Python environment setup module
source /home/comfy/startup/utils.sh

log_message "Setting up Python environment..."

# Validate environment variables and commands
verify_env_vars "LOCAL_VENV" "WORKSPACE_DIR" "WORKSPACE_VENV" "PYTHON_VERSION" "UV_PATH"
validate_commands "mkdir" "rm" "grep" "sed"

# Step 1: Check if workspace virtual environment exists with correct Python version
log_message "Checking workspace Python virtual environment..."
workspace_venv_valid=false

if [ -d "${WORKSPACE_VENV}" ]; then
    # Read current python version from .python-version
    if check_venv_python_version "${WORKSPACE_DIR}/.python-version" "${PYTHON_VERSION}"; then
        log_message "Workspace virtual environment exists with correct Python version."
        workspace_venv_valid=true
    else
        log_message "Workspace virtual environment exists but has wrong Python version. Recreating..."
        rm -rf "${WORKSPACE_VENV}"
    fi
fi

# Write selected PYTHON_VERSION to file .python-version
echo "${PYTHON_VERSION}" > "${WORKSPACE_DIR}/.python-version"

# Step 2: Always create venv in local directory.

# If LOCAL_VENV exists (unlikely, but possible), remove it
if [ -d "${LOCAL_VENV}" ]; then
    log_message "Removing existing local virtual environment..."
    rm -rf "${LOCAL_VENV}"
fi

log_message "Creating new workspace Python copied virtual environment with uv..."
ensure_dir "${LOCAL_VENV}" "comfy" 

$UV_PATH venv --link-mode=copy "${LOCAL_VENV}" --python="${PYTHON_VERSION}" || {
    log_error "Failed to create workspace virtual environment"
    exit 1
}
log_success "Workspace Python virtual environment created successfully."

# Step 3: If our workspace venv is invalid, then we sync the new venv from local to workspace.
if [ "$workspace_venv_valid" = false ]; then
    log_message "Syncing virtual environment from local to workspace..."
    sync_dirs "${LOCAL_VENV}" "${WORKSPACE_VENV}" "Python virtual environment"
else
    log_message "Syncing virtual environment from workspace to local..."
    sync_dirs "${WORKSPACE_VENV}" "${LOCAL_VENV}" "Python virtual environment"
fi

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