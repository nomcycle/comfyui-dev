#!/bin/bash
source /home/comfy/startup/utils.sh

echo "Current environment variables:"
env | grep "COMFY_DOCKER_" | sort

# Dynamically construct COMFY_ENV_VARS
COMFY_ENV_VARS=$(env | grep "COMFY_DOCKER_" | awk '{print $1}' | paste -sd " " -)

echo "Consolidated COMFY_ENV_VARS: ${COMFY_ENV_VARS}"

log_message "Connecting to tailscale..."
tailscaled --tun=userspace-networking &
tailscale up --hostname=comfy --authkey=${COMFY_DOCKER_TAILSCALE_AUTH}

TAILSCALE_IP=$(tailscale ip -4)
log_message "Connected with address: ${TAILSCALE_IP}"

log_message "Starting ssh..."
service ssh start

log_message "Setting up python and repositories..."

# Run setup.sh with root's environment
su comfy -c "${COMFY_ENV_VARS} /home/comfy/startup/setup.sh"

if [ $# -eq 0 ] || [ "$1" = "bash" ]; then
    log_message "No command override, using default startup script..."
    su comfy -c "${COMFY_ENV_VARS} /home/comfy/startup/start.sh"
else
    log_message "Executing command: $*"
    su comfy -c "${COMFY_ENV_VARS} $*"
fi