#!/bin/bash
# Synchronization setup module
source /home/comfy/startup/utils.sh

log_message "Setting up directory synchronization..."

# Validate environment variables
verify_env_vars "LSYNCD_CONFIG_DIR" "LSYNCD_CONFIG_FILE" "CONFIG_DIR"
validate_commands "lsyncd" "cp" "chown"

# Set up lsyncd for automatic syncing between local and workspace
log_message "Setting up lsyncd configuration..."

# Create config directory
ensure_dir "${LSYNCD_CONFIG_DIR}" "comfy"

log_message "Pre-creating cursor-server directory for lsyncd..."
mkdir -p /home/comfy/.cursor-server

# Determine which lsyncd config to use based on role
if [[ "${COMFY_DEV_ROLE}" == "LEADER" ]]; then
    SOURCE_LSYNCD_CONFIG="/home/comfy/startup/config/lsyncd/leader.conf.lua"
    log_message "Using LEADER lsyncd configuration (push to workspace)"
else
    SOURCE_LSYNCD_CONFIG="/home/comfy/startup/config/lsyncd/follower.conf.lua"
    log_message "Using FOLLOWER lsyncd configuration (pull from workspace)"
fi

# Verify source configuration file exists
if [ ! -f "$SOURCE_LSYNCD_CONFIG" ]; then
    log_error "Source lsyncd configuration file not found: $SOURCE_LSYNCD_CONFIG"
    exit 1
fi

# Copy configuration file
log_message "Copying lsyncd configuration file..."
cp "$SOURCE_LSYNCD_CONFIG" "${LSYNCD_CONFIG_FILE}"
chown -R comfy:comfy "${CONFIG_DIR}"

# Verify configuration is valid
verify_lsyncd_config "${LSYNCD_CONFIG_FILE}"

# Start lsyncd directly (not as a service)
start_lsyncd "${LSYNCD_CONFIG_FILE}"

log_success "Directory synchronization setup complete."