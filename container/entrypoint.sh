#!/bin/bash
source /home/comfy/startup/utils.sh

# Dynamically construct COMFY_ENV_VARS
COMFY_ENV_VARS=$(env | grep "COMFY_DEV_" | awk '{print $1}' | paste -sd " " -)

if [ ! -z "$COMFY_DEV_SSH_PUBKEY" ]; then
    echo "$COMFY_DEV_SSH_PUBKEY" > /home/comfy/.ssh/authorized_keys
    chmod 600 /home/comfy/.ssh/authorized_keys
    chown comfy:comfy /home/comfy/.ssh/authorized_keys
else
    log_message "Missing public SSH key in environment variable: \"COMFY_DEV_SSH_PUBKEY\"."
fi

log_message "Connecting to tailscale..."
mkdir -p /run/sshd
tailscaled --tun=userspace-networking &
COMFY_DEV_TAILSCALE_MACHINENAME=${COMFY_DEV_TAILSCALE_MACHINENAME:-comfyui-dev-0}
tailscale up --hostname=${COMFY_DEV_TAILSCALE_MACHINENAME} --authkey=${COMFY_DEV_TAILSCALE_AUTH}

TAILSCALE_IP=$(tailscale ip -4)
log_message "Connected with address: ${TAILSCALE_IP}"

log_message "Starting ssh..."
service ssh start

log_message "Setting up python and repositories..."
# Preserve PATH when switching to comfy user
su -l comfy -c "export PATH=$HOME/.local/bin:$PATH:$HOME/.cargo/bin; ${COMFY_ENV_VARS} /home/comfy/startup/setup.sh"

if [ $# -eq 0 ] || [ "$1" = "bash" ]; then
    log_message "No command override, using default startup script..."
    su -l comfy -c "export PATH=$HOME/.local/bin:$PATH:$HOME/.cargo/bin; ${COMFY_ENV_VARS} /home/comfy/startup/start.sh"
else
    log_message "Executing command: $*"
    su -l comfy -c "export PATH=$HOME/.local/bin:$PATH:$HOME/.cargo/bin; ${COMFY_ENV_VARS} $*"
fi