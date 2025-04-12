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
   * Start ComfyUI: `python main.py --listen 0.0.0.0`

# Debugging & Breakpoints
1. Install python vscode extension to remote instance.
2. Create launch.json in /workspace/ComfyUI/.vscode
3. Add the following content:
```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "ComfyUI",
            "type": "debugpy",
            "request": "launch",
            "program": "main.py",
            "console": "integratedTerminal",
            "args": "--listen 0.0.0.0",
            "python": "/workspace/.venv/bin/python",
            "justMyCode": true
        }
    ]
}
```
4. Press (F5) to run ComfyUI 

# Environment Variables

* `COMFY_DEV_TAILSCALE_AUTH`: Tailscale authentication key (required)
* `COMFY_DEV_SSH_PUBKEY`: SSH public key for access (required)
* `COMFY_DEV_PYTHON_VERSION`: Set Python version (default: 3.12.4)
* `COMFY_DEV_START_COMFY`: Set "true" for auto-start (default: false)
* `COMFY_DEV_GIT_FORK`: URL to your ComfyUI fork (default: official repo)
* `COMFY_DEV_TAILSCALE_MACHINENAME`: Custom Tailscale machine name

# Troubleshooting

* **Tailscale Timeout**: Remove old devices from Tailscale dashboard
* **SSH Key Error**: Verify `COMFY_DEV_SSH_PUBKEY` is set correctly
* **Python Environment Issues**: Check logs with `docker logs comfyui-dev`