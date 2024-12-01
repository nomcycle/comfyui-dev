# ComfyUI-Dev

This container provides a secure, remote, and persistent development environment for ComfyUI. By leveraging [Tailscale's](https://tailscale.com) secure WireGuard-based VPN service and [VSCode's remote development](https://code.visualstudio.com/docs/remote/remote-overview) capabilities, you can easily develop ComfyUI applications on rented GPU services like [RunPod](https://www.runpod.io/). The environment persists between sessions, allowing you to maintain your development setup while only paying for GPU time when needed.

## Setup

### Tailscale

1. Log in to Tailscale or create an account if you haven't already
2. Install Tailscale on the device you want to use to access ComfyUI and log in
3. Navigate to: `https://login.tailscale.com/admin/settings/keys`
4. Select **"Generate auth key..."**
5. Add a descriptor for your container (e.g., **"Comfy Container"**)
6. Toggle **"Reusable"** to allow reusing this key when recreating the container
7. Toggle **"Ephemeral"** to automatically remove devices authenticated by this key after going offline
8. Select **"Generate key"**
9. Copy the key to a secure location for later use

### VSCode

1. Open VSCode
2. Open the Extensions view (Ctrl + `) and install:
   * **"Remote - SSH"**
   * **"Python"**
3. Open the Command Palette (Ctrl + Shift + P)
4. Search for and select `Open User Settings (JSON)`
5. Add or append the following entries:
   
   *Setting `serverInstallPath` ensures remote extensions and VSCode configuration persist between container terminations*
    ```json
    "remote.SSH.remotePlatform": {
        "comfyui-dev": "linux"
    },
    "remote.SSH.serverInstallPath": {
        "comfy": "/workspace/"
    }
    ```
6. Open a terminal in VSCode (Ctrl + Shift + `)
7. Create the SSH directory: `mkdir -p ~/.ssh/`
8. Generate SSH keys for your container: `ssh-keygen -t ed25519 -f ~/.ssh/comfyui-dev -C "comfy"`
9. Add the following to `~/.ssh/config` to associate the private key with your container hostname:
    ```
    Host comfyui-dev
        HostName comfyui-dev
        User comfy
        IdentityFile ~/.ssh/comfyui-dev
    ```
10. Copy the contents of `~/.ssh/comfyui-dev.pub` for later use

### RunPod

1. Create a new secret in the RunPod web UI named `COMFY_DEV_TAILSCALE_AUTH` and paste your Tailscale API key
2. Create another secret named `COMFY_DEV_SSH_PUBKEY` and paste your SSH public key
3. Create a Network Volume:
   * Choose a data center region close to your location with good GPU availability
   * Recommended size: ~256GB (balances space and cost for model storage)
   * This volume mounts to `/workspace` and persists between container terminations
4. Create a new pod:
    1. Select your Network Volume
    2. Choose your preferred GPU
    3. Name your pod
    4. Click **"Change Template"** and search for `nomcycle/comfyui`
    5. Select **"Edit Template"** and expand **"Environment Variables"**
    6. Set the following:
        * Add your Tailscale auth secret to `COMFY_DEV_TAILSCALE_AUTH`
        * Add your SSH public key to `COMFY_DEV_SSH_PUBKEY`
        * (Optional) Set `COMFY_DEV_PYTHON_VERSION` to your preferred version
        * (Optional) Set `COMFY_DEV_START_COMFY` to `true` for automatic startup
    7. Click **"Set Overrides"**
    8. Click **"Deploy On-Demand"** to launch your container

*At this stage, RunPod and container scripts will:*
1. *Download and deploy the container image to a new instance*
2. *Configure and authenticate Tailscale for secure networking*
3. *Set up the Python environment with Conda*
4. *Clone the ComfyUI repository*
5. *Install all required pip packages and dependencies*

*This process typically takes 2-5 minutes depending on your network connection and chosen GPU instance.*

### Logging In
*Once the container is deployed and idling, you can remotely connect to it through visual code remote debugging*
1. Open VSCode.
2. Open the **Command Palette"** (Ctrl + P + `).
3. Type in: `Connect to Host...` after the `>`
4. In the dropdown, you shold see the `comfyui-dev` host, select it.
5. Then it will prompt you for the platform, select **"Linux"**. 
6. Select continue when prompted.

*VSCode remote development server will then be downloaded to `/workspace` folder, once it's finished it will have vscode open the folder in the root of the cloned ComfyUI repo in: `/workspace/ComfyUI/`*.