#!/bin/bash
# Cursor server setup module
source /home/comfy/startup/utils.sh
verify_env_vars "WORKSPACE_CURSOR" "LOCAL_CURSOR"

log_message "Copying cached .cursor-server to home directory..."
# Check if the workspace cursor directory exists
if [ -d "${WORKSPACE_CURSOR}" ]; then
    log_message "Workspace cursor directory exists, syncing to local..."
    sync_dirs "${WORKSPACE_CURSOR}" "${LOCAL_CURSOR}" "Cursor server"
else
    log_message "Workspace cursor directory does not exist, creating empty directory..."
    ensure_dir "${LOCAL_CURSOR}" "comfy"
fi
