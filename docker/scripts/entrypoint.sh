#!/bin/bash
source /home/comfy/startup/utils.sh

log_message "Initializing ComfyUI development container..."

# Setup standard PATH
setup_path

# Validate essential commands
validate_commands "mkdir" "chmod" "chown" "tailscaled" "tailscale" "service" "grep" "awk" "paste"

# Dynamically construct COMFY_ENV_VARS for passing environment to subprocesses
# Collect both COMFY_DEV_ and COMFY_CLUSTER_ environment variables for passing to subprocesses
COMFY_DEV_VARS=$(env | grep "COMFY_DEV_" | awk '{print $1}' | paste -sd " " -)
COMFY_CLUSTER_VARS=$(env | grep "COMFY_CLUSTER_" | awk '{print $1}' | paste -sd " " -)
COMFY_ENV_VARS="${COMFY_DEV_VARS} ${COMFY_CLUSTER_VARS}"
export COMFY_ENV_VARS

# Validate required environment variables
verify_env_vars "COMFY_DEV_SSH_PUBKEY" "COMFY_DEV_TAILSCALE_AUTH"

# Set up SSH keys with proper error handling via trap
log_message "Setting up SSH public key..."
echo "$COMFY_DEV_SSH_PUBKEY" > /home/comfy/.ssh/authorized_keys
chmod 600 /home/comfy/.ssh/authorized_keys
chown comfy:comfy /home/comfy/.ssh/authorized_keys

# Setup Tailscale connectivity
log_message "Connecting to tailscale..."
mkdir -p /run/sshd

# Start tailscaled daemon
tailscaled --tun=userspace-networking & 
TAILSCALED_PID=$!

# Verify tailscaled is running
sleep 2
if ! kill -0 $TAILSCALED_PID 2>/dev/null; then
    log_error "Failed to start tailscaled"
    exit 1
fi

# Get machine name with default fallback
COMFY_DEV_TAILSCALE_MACHINENAME=${COMFY_DEV_TAILSCALE_MACHINENAME:-comfyui-dev-0}

# Connect to tailscale network
tailscale up --hostname=${COMFY_DEV_TAILSCALE_MACHINENAME} --authkey=${COMFY_DEV_TAILSCALE_AUTH}

# Get IP address from tailscale
TAILSCALE_IP=$(tailscale ip -4)
if [ -z "$TAILSCALE_IP" ]; then
    log_error "Failed to obtain Tailscale IP address"
    exit 1
fi

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