#!/bin/bash
# Synchronization setup module
source /home/comfy/startup/utils.sh

log_message "Setting up directory synchronization..."

# Set up lsyncd for automatic syncing between local and workspace
log_message "Setting up lsyncd configuration..."

# Create config directories
ensure_dir "${LSYNCD_CONFIG_DIR}" "comfy"
ensure_dir "${CONFIG_DIR}/systemd/user/" "comfy"

# Copy lsyncd configuration from container files
if [ ! -f "/home/comfy/startup/config/lsyncd/lsyncd.conf.lua" ]; then
    log_error "Lsyncd configuration file not found"
    exit 1
fi

if [ ! -f "/home/comfy/startup/config/systemd/lsyncd.service" ]; then
    log_error "Lsyncd service file not found"
    exit 1
fi

cp /home/comfy/startup/config/lsyncd/lsyncd.conf.lua "${LSYNCD_CONFIG_FILE}"
cp /home/comfy/startup/config/systemd/lsyncd.service "${CONFIG_DIR}/systemd/user/"

# Make sure the user owns the config files
chown -R comfy:comfy "${CONFIG_DIR}"

# Start lsyncd and verify it started
log_message "Starting lsyncd service..."

# Start lsyncd with nohup to keep it running after the script exits
nohup lsyncd "${LSYNCD_CONFIG_FILE}" > /tmp/lsyncd.out 2>&1 &
LSYNCD_PID=$!

# Give lsyncd a moment to start
sleep 2

# Verify lsyncd is running
if ! kill -0 $LSYNCD_PID 2>/dev/null; then
    log_error "Failed to start lsyncd service. Check the output in /tmp/lsyncd.out"
    cat /tmp/lsyncd.out
    exit 1
fi

log_success "Lsyncd started with PID $LSYNCD_PID"
log_success "Directory synchronization setup complete."