# Quick Setup Guide

**1. Tailscale Setup**
   * Create/login to [Tailscale](https://tailscale.com)
   * Go to `login.tailscale.com/admin/settings/keys`
   * Generate auth key (enable "Reusable" and "Ephemeral")
   * Save key for `COMFY_DEV_TAILSCALE_AUTH`

**2. VSCode Setup**
   * Install extensions: "Remote - SSH" and "Python"
   * Run in terminal:
     ```bash
     mkdir -p ~/.ssh/
     ssh-keygen -t ed25519 -f ~/.ssh/comfyui-dev -C "comfy"
     ```
   * Add to `~/.ssh/config`:
     ```
     Host comfyui-dev
         HostName comfyui-dev
         User comfy
         IdentityFile ~/.ssh/comfyui-dev
     ```
   * Copy `~/.ssh/comfyui-dev.pub` content for `COMFY_DEV_SSH_PUBKEY`

**3. RunPod Setup**
   * Create secrets:
     - `COMFY_DEV_TAILSCALE_AUTH`: Your Tailscale key
     - `COMFY_DEV_SSH_PUBKEY`: Your SSH public key
   * Create Network Volume (~256GB recommended)
   * Deploy pod with template `nomcycle/comfyui-dev`

**4. Connect**
   * Open VSCode
   * Press Ctrl+Shift+P
   * Type "Connect to Host..."
   * Select "comfyui-dev"
   * Open folder: `/workspace/ComfyUI`

Optional Environment Variables:
* `COMFY_DEV_PYTHON_VERSION`: Set Python version
* `COMFY_DEV_START_COMFY`: Set "true" for auto-start
* `COMFY_DEV_GIT_FORK`: Your ComfyUI fork URL

Troubleshooting:
* Host Timeout: Remove old devices from Tailscale dashboard
* Key Denied: Verify `COMFY_DEV_SSH_PUBKEY` is set correctly

Container Source:
* [Github](https://github.com/nomcycle/comfyui-dev)
* [Docker](https://hub.docker.com/repository/docker/nomcycle/comfyui-dev)