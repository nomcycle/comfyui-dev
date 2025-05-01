#!/bin/bash
# Cursor server setup module
source /home/comfy/startup/utils.sh
verify_env_vars "WORKSPACE_CURSOR" "LOCAL_CURSOR"

log_message "Setting up cursor-server..."

# Different behaviors based on role
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    # LEADER BEHAVIOR
    log_message "Setting up cursor-server as LEADER..."
    
    # Check if the workspace cursor directory exists
    if [ -d "${WORKSPACE_CURSOR}" ]; then
        log_message "Workspace cursor directory exists, syncing to local..."
        sync_dirs "${WORKSPACE_CURSOR}" "${LOCAL_CURSOR}" "Cursor server"
    else
        log_message "Workspace cursor directory does not exist, creating empty directory..."
        ensure_dir "${WORKSPACE_CURSOR}" "comfy"
        ensure_dir "${LOCAL_CURSOR}" "comfy"
    fi
    
    # Signal cursor setup completion
    touch /workspace/.setup/cursor_ready
    
else
    # FOLLOWER BEHAVIOR
    log_message "Setting up cursor-server as FOLLOWER..."
    
    # Wait for leader to complete cursor setup
    wait_for_leader_completion "cursor_ready"
    
    # Sync from workspace to local
    log_message "Syncing cursor-server from workspace to local..."
    sync_dirs "${WORKSPACE_CURSOR}" "${LOCAL_CURSOR}" "Cursor server"
fi

log_success "Cursor server setup complete."
