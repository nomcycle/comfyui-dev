#!/bin/bash
# Python environment setup module
source /home/comfy/startup/utils.sh

log_message "Setting up Python environment..."

# Validate environment variables and commands
verify_env_vars "LOCAL_PYTHON" "WORKSPACE_DIR" "WORKSPACE_PYTHON" "PYTHON_VERSION" "UV_PATH"
validate_commands "mkdir" "rm" "grep" "sed"

# Different behaviors based on role
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    # LEADER BEHAVIOR
    log_message "Setting up Python as LEADER..."
    
    # Step 1: Check if workspace Python exists with correct Python version
    log_message "Checking workspace Python installation..."
    WORKSPACE_PYTHON_valid=false
    
    if [ -d "${WORKSPACE_PYTHON}" ]; then
        # Read current python version from .python-version
        if check_python_version "${WORKSPACE_DIR}/.python-version" "${PYTHON_VERSION}"; then
            log_message "Workspace Python exists with correct version."
            WORKSPACE_PYTHON_valid=true
        else
            log_message "Workspace Python exists but has wrong version. Recreating..."
            rm -rf "${WORKSPACE_PYTHON}"
        fi
    fi
    
    # Write selected PYTHON_VERSION to file .python-version
    echo "${PYTHON_VERSION}" > "${WORKSPACE_DIR}/.python-version"
    
    # Step 2: Install Python in local directory
    # If LOCAL_PYTHON exists, remove it
    if [ -d "${LOCAL_PYTHON}" ]; then
        log_message "Removing existing local Python installation..."
        rm -rf "${LOCAL_PYTHON}"
    fi
    
    log_message "Installing Python ${PYTHON_VERSION} with uv..."
    ensure_dir "${LOCAL_PYTHON}" "comfy" 
    
    $UV_PATH python install --managed-python --install-dir "${LOCAL_PYTHON}/python" "${PYTHON_VERSION}" || {
        log_error "Failed to install Python ${PYTHON_VERSION}"
        exit 1
    }
    
    ${UV_PATH} venv "${LOCAL_PYTHON}/.venv" --python ${PYTHON_VERSION} || {
        log_error "Failed to create virtual environment"
        exit 1
    }
    
    log_success "Python ${PYTHON_VERSION} installed successfully at ${LOCAL_PYTHON}."
    
    # Step 3: Sync the new installation from local to workspace
    log_message "Syncing Python installation from local to workspace..."
    sync_dirs "${LOCAL_PYTHON}" "${WORKSPACE_PYTHON}" "Python installation"
    
    # Signal Python setup completion
    touch /workspace/.setup/python_ready
    
else
    # FOLLOWER BEHAVIOR
    log_message "Setting up Python as FOLLOWER..."
    
    # Wait for leader to complete Python setup
    wait_for_leader_completion "python_ready"
    
    # For follower: always sync from workspace to local
    # Ensure local Python directory exists and is empty
    if [ -d "${LOCAL_PYTHON}" ]; then
        log_message "Removing existing local Python installation..."
        rm -rf "${LOCAL_PYTHON}"
    fi
    
    ensure_dir "${LOCAL_PYTHON}" "comfy"
    
    # Sync all Python files from workspace to local
    log_message "Syncing Python installation from workspace to local..."
    sync_dirs "${WORKSPACE_PYTHON}" "${LOCAL_PYTHON}" "Python installation"
    
    log_success "Python environment synced from workspace."
fi

# Add Python virtual environment activation to .bashrc
log_message "Adding Python virtual environment activation to .bashrc..."

# Create .bashrc file
echo "# Automatically activate Python virtual environment" > "/home/comfy/.bashrc"
echo "source ${LOCAL_PYTHON}/.venv/bin/activate" >> "/home/comfy/.bashrc"
log_success "Created .bashrc with virtual environment activation"

# Set proper permissions for .bashrc
chown comfy:comfy "/home/comfy/.bashrc"
chmod 644 "/home/comfy/.bashrc"

log_success "Python environment setup complete."