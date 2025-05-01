#!/bin/bash
# Role setup module
source /home/comfy/startup/utils.sh

log_message "Setting up container role..."

# Get role from environment or default to LEADER
COMFY_DEV_ROLE="${COMFY_DEV_ROLE:-LEADER}"
export COMFY_DEV_ROLE

# Validate role
if [[ "${COMFY_DEV_ROLE}" != "LEADER" && "${COMFY_DEV_ROLE}" != "FOLLOWER" ]]; then
    log_error "Invalid role: ${COMFY_DEV_ROLE}. Must be LEADER or FOLLOWER."
    exit 1
fi

log_message "Container role: ${COMFY_DEV_ROLE}"

# Create .setup directory in workspace
ensure_dir "/workspace/.setup" "comfy"

if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    log_message "Setting up as LEADER..."
    
    # Mark as leader and clear any existing ready markers
    echo "${COMFY_DEV_TAILSCALE_MACHINENAME:-comfyui-leader}" > /workspace/.setup/leader
    rm -f /workspace/.setup/*_ready
    rm -f /workspace/.setup/setup_complete
    
    # Ensure workspace directories exist
    ensure_dir "${WORKSPACE_COMFYUI}" "comfy"
    ensure_dir "${WORKSPACE_PYTHON}" "comfy"
    ensure_dir "${WORKSPACE_CURSOR}" "comfy"
    
    log_success "Leader role initialized"
else
    log_message "Setting up as FOLLOWER..."
    
    # Verify that a leader is set
    if [[ ! -f "/workspace/.setup/leader" ]]; then
        log_warning "No leader marker found. This follower may start before the leader is ready."
    else
        leader_name=$(cat /workspace/.setup/leader)
        log_message "Found leader: ${leader_name}"
    fi
    
    log_success "Follower role initialized"
fi