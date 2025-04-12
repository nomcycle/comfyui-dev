#/bin/bash

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    # Switch on each argument.
    case $1 in
        # Optional argument
        --ssh-folder-path)
            SSH_FOLDER_PATH="${2:-$HOME/.ssh}"
            shift 2 # Remove $1 and $2 from arguments list.
            ;; # Break.
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

echo "SSH folder path: $SSH_FOLDER_PATH"

# Generate SSH key pair if it doesn't exist
if [ ! -f "$SSH_FOLDER_PATH/comfyui-dev" ]; then
    echo "Generating SSH key pair..."
    ssh-keygen -t ed25519 -f ~/.ssh/comfyui-dev -N "" -C "comfyui-dev"
fi

# Read public key into variable
# Print the path to the key
PUBKEY=$(cat "$SSH_FOLDER_PATH/comfyui-dev.pub")

# Remove existing container if it exists
echo "Cleaning up any existing container..."
docker rm -f comfyui-dev 2>/dev/null || true

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