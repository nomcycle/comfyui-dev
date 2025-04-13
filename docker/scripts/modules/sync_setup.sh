#!/bin/bash
# Synchronization setup module
source /home/comfy/startup/utils.sh

log_message "Setting up directory synchronization..."

# Validate environment variables
verify_env_vars "LSYNCD_CONFIG_DIR" "LSYNCD_CONFIG_FILE" "CONFIG_DIR"
validate_commands "lsyncd" "cp" "chown"

# Set up lsyncd for automatic syncing between local and workspace
log_message "Setting up lsyncd configuration..."

# Create config directories
ensure_dir "${LSYNCD_CONFIG_DIR}" "comfy"
ensure_dir "${CONFIG_DIR}/systemd/user/" "comfy"

log_message "Pre-creating cursor-server directory for lsyncd..."
mkdir -p /home/comfy/.cursor-server

# Verify source configuration files exist
SOURCE_LSYNCD_CONFIG="/home/comfy/startup/config/lsyncd/lsyncd.conf.lua"
SOURCE_LSYNCD_SERVICE="/home/comfy/startup/config/systemd/lsyncd.service"

if [ ! -f "$SOURCE_LSYNCD_CONFIG" ]; then
    log_error "Source lsyncd configuration file not found: $SOURCE_LSYNCD_CONFIG"
    exit 1
fi

if [ ! -f "$SOURCE_LSYNCD_SERVICE" ]; then
    log_error "Source lsyncd service file not found: $SOURCE_LSYNCD_SERVICE"
    exit 1
fi

# Copy configuration files
log_message "Copying lsyncd configuration files..."
cp "$SOURCE_LSYNCD_CONFIG" "${LSYNCD_CONFIG_FILE}" || {
    log_error "Failed to copy lsyncd configuration file"
    exit 1
}

cp "$SOURCE_LSYNCD_SERVICE" "${CONFIG_DIR}/systemd/user/" || {
    log_error "Failed to copy lsyncd service file"
    exit 1
}

# Make sure the user owns the config files
chown -R comfy:comfy "${CONFIG_DIR}" || {
    log_error "Failed to set ownership on config directory"
    exit 1
}

# Verify configuration is valid
verify_lsyncd_config "${LSYNCD_CONFIG_FILE}"

# Start lsyncd service
start_lsyncd "${LSYNCD_CONFIG_FILE}"

log_success "Directory synchronization setup complete."