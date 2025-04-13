#!/bin/bash
# Python environment setup module
source /home/comfy/startup/utils.sh

log_message "Setting up Python environment..."

# Function to check Python version in a virtual environment
check_venv_python_version() {
    local venv_path="$1"
    local expected_version="$2"
    
    if [ ! -f "${venv_path}/bin/python3" ]; then
        return 1
    fi
    
    # Get the version using --version (simpler approach)
    local version_output=$(${venv_path}/bin/python3 --version 2>&1)
    local actual_version=$(echo "$version_output" | cut -d' ' -f2)
    
    if [[ "$actual_version" == "$expected_version"* ]]; then
        return 0
    else
        log_message "Python version mismatch: expected ${expected_version}, found ${actual_version}"
        return 1
    fi
}

# Step 1: Create or check local virtual environment
log_message "Setting up local Python virtual environment..."
local_venv_ok=false

if [ -d "${LOCAL_VENV}" ]; then
    if check_venv_python_version "${LOCAL_VENV}" "${PYTHON_VERSION}"; then
        log_message "Local Python virtual environment exists with correct version."
        local_venv_ok=true
    else
        log_message "Local Python virtual environment exists but has wrong version. Recreating..."
        rm -rf "${LOCAL_VENV}"
    fi
fi

if [ "$local_venv_ok" = false ]; then
    # Create local virtual environment with correct version
    log_message "Creating local Python virtual environment with uv..."
    ensure_dir "${LOCAL_VENV}" "comfy"
    $UV_PATH venv "${LOCAL_VENV}" --python="${PYTHON_VERSION}"
    log_success "Local Python virtual environment created successfully."
fi

# Step 2: Check workspace virtual environment and sync from local if needed
log_message "Checking workspace Python virtual environment..."
workspace_venv_ok=false

if [ -d "${WORKSPACE_VENV}" ]; then
    if check_venv_python_version "${WORKSPACE_VENV}" "${PYTHON_VERSION}"; then
        log_message "Workspace Python virtual environment exists with correct version."
        workspace_venv_ok=true
    else
        log_message "Workspace Python virtual environment exists but has wrong version. Recreating..."
        rm -rf "${WORKSPACE_VENV}"
    fi
fi

if [ "$workspace_venv_ok" = false ]; then
    # Do manual initial sync from local to workspace (lsyncd will handle ongoing syncs)
    log_message "Setting up workspace Python virtual environment from local..."
    ensure_dir "${WORKSPACE_VENV}" "comfy"
    sync_dirs "${LOCAL_VENV}" "${WORKSPACE_VENV}" "Python virtual environment"
    log_success "Workspace Python virtual environment synced successfully."
fi

# Step 3: Always add LOCAL_VENV to .bashrc if not already there
if ! grep -q "source ${LOCAL_VENV}/bin/activate" /home/comfy/.bashrc; then
    echo "source ${LOCAL_VENV}/bin/activate" >> /home/comfy/.bashrc
    log_message "Added local virtual environment activation to .bashrc"
fi

# Step 4: Activate the local virtual environment
source "${LOCAL_VENV}/bin/activate"
log_success "Python environment setup complete."