#!/bin/bash
# Follower-specific setup module
source /home/comfy/startup/utils.sh

log_message "Setting up follower environment..."

# Ensure local directories exist (already synced from workspace)
ensure_dir "${LOCAL_PYTHON}" "comfy"
ensure_dir "${LOCAL_COMFYUI}" "comfy"
ensure_dir "${LOCAL_CURSOR}" "comfy"

# Add Python virtual environment activation to .bashrc
log_message "Adding Python virtual environment activation to .bashrc..."
echo "# Automatically activate Python virtual environment" > "/home/comfy/.bashrc"
echo "source ${LOCAL_PYTHON}/.venv/bin/activate" >> "/home/comfy/.bashrc"
chown comfy:comfy "/home/comfy/.bashrc"
chmod 644 "/home/comfy/.bashrc"

# No need to install packages - they're already synced from leader
log_message "Using Python packages synced from leader..."

log_success "Follower environment setup complete."