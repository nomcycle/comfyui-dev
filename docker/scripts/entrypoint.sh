#!/bin/bash
source /home/comfy/startup/utils.sh

# Setup standard PATH 
setup_path

# Dynamically construct COMFY_ENV_VARS
COMFY_ENV_VARS=$(env | grep "COMFY_DEV_" | awk '{print $1}' | paste -sd " " -)
export COMFY_ENV_VARS

# Set up SSH keys
if [ ! -z "${COMFY_DEV_SSH_PUBKEY:-}" ]; then
    log_message "Setting up SSH public key"
    echo "$COMFY_DEV_SSH_PUBKEY" > /home/comfy/.ssh/authorized_keys
    chmod 600 /home/comfy/.ssh/authorized_keys
    chown comfy:comfy /home/comfy/.ssh/authorized_keys
else
    log_error "Missing required environment variable: COMFY_DEV_SSH_PUBKEY"
    exit 1
fi

# Setup Tailscale
log_message "Connecting to tailscale..."
mkdir -p /run/sshd
tailscaled --tun=userspace-networking &

# Check if auth key is provided
if [ -z "${COMFY_DEV_TAILSCALE_AUTH:-}" ]; then
    log_error "Missing required environment variable: COMFY_DEV_TAILSCALE_AUTH"
    exit 1
fi

COMFY_DEV_TAILSCALE_MACHINENAME=${COMFY_DEV_TAILSCALE_MACHINENAME:-comfyui-dev-0}
tailscale up --hostname=${COMFY_DEV_TAILSCALE_MACHINENAME} --authkey=${COMFY_DEV_TAILSCALE_AUTH}

TAILSCALE_IP=$(tailscale ip -4)
log_success "Connected with address: ${TAILSCALE_IP}"

# Start SSH service
log_message "Starting SSH service..."
service ssh start
log_success "SSH service started"

# Setup Python and repositories
log_message "Setting up python and repositories..."
run_as_comfy "/home/comfy/startup/setup.sh"

# Execute startup command or default script
if [ $# -eq 0 ] || [ "$1" = "bash" ]; then
    log_message "No command override, using default startup script..."
    run_as_comfy "/home/comfy/startup/start.sh"
else
    log_message "Executing command: $*"
    run_as_comfy "$*"
fi