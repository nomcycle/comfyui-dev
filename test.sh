#/bin/bash

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    # Switch on each argument.
    case $1 in
        --tailscale-auth)
            TAILSCALE_AUTH="$2"
            shift 2 # Remove $1 and $2 from arguments list.
            ;; # Break.
        --git-fork)
            GIT_FORK="$2"
            shift 2 # Remove $1 and $2 from arguments list.
            ;; # Break.
        *) # All other cases.
            echo "Unknown argument: $1"
            exit 1
            ;; # Break.
    esac
done

# Verify required arguments
if [ -z "$TAILSCALE_AUTH" ]; then
    echo "Error: --tailscale-auth is required"
    exit 1
fi

# Set default value for GIT_FORK if not provided
GIT_FORK="${GIT_FORK:-https://github.com/comfyanonymous/ComfyUI}"

# Generate SSH key pair if it doesn't exist
if [ ! -f "~/.ssh/comfyui-dev" ]; then
    ssh-keygen -t ed25519 -f ~/.ssh/comfyui-dev -N "" -C "comfyui-dev"
fi

# Read public key into variable
PUBKEY=$(cat ~/.ssh/comfyui-dev.pub)

docker run \
  --name comfyui-dev \
  --gpus all \
  -e COMFY_DEV_SSH_PUBKEY="$PUBKEY" \
  -e COMFY_DEV_TAILSCALE_AUTH="$TAILSCALE_AUTH" \
  -e COMFY_DEV_PYTHON_VERSION="3.12.4" \
  -e COMFY_DEV_GIT_FORK="$GIT_FORK" \
  -e COMFY_DEV_WIN32="false" \
  -e COMFY_DEV_START_COMFY="false" \
  nomcycle/comfyui-dev:latest