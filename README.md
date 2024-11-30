# Setup

## Tailscale

1. Login to tailscale or create an account if you haven't already.
2. Install tailscale onto device you want to be able to access comfy with and login.
3. Back in the web browser, Navigate to: `https://login.tailscale.com/admin/settings/keys`
4. Select **"Generate auth key..."**
5. Add a descriptor to describe your container such as: **"Comfy Container"**
6. Toggle **"Resusable"** so that we can reuse this key everytime we recreate this container.
7. Toggle **"Ephemeral"** to flag that: **"Devices authenticated by this key will be automatically removed after going offline."**
8. Select **"Generate key"**.
9. Copy the the key somewhere safe as we will use it later in this setup.

## VSCode

1. Open VSCode.
2. Open the extension view (Ctrl + `) and install the following extensions if you haven't already:
   * **"Remote - SSH"**
   * **"Python"**
3. Open the command palette (Ctrl + Shift + P).
4. Type in `Open User Settings (JSON)` after the `>`.
5. Append or add the following entries to `remote.SSH.remotePlatform` and `remote.SSH.serverInstallPath`:

   *Setting `serverInstallPath` is important as it will insure that the remote extensions and vscode configuration persist between container terminations*
    ```
        "remote.SSH.remotePlatform": {
            "comfy": "linux",
        },
        "remote.SSH.serverInstallPath": {
            "comfy": "/workspace/"
        }
    ```
6. Open a powershell/terminal in VSCode (Ctrl + Shift + `).
7. Create the `~/.ssh` folder if it doesn't already exist: `mkdir -p ~/.ssh/` 
8. Create SSH keys dedicated to your container using the following command: `ssh-keygen -t ed25519 -f ~/.ssh/comfyui-dev -C "comfy"`
9.  Open `~/.ssh/config` and append the following to associate the private key with our container hostname:
    ```
    Host comfy
        HostName comfy
        User comfy
        IdentityFile ~/.ssh/comfy
    ```
10. Open the public key: `~/.ssh/comfyui-dev.pub` and copy it's components somewhere, as we will need it later.

## Runpod

1. Create a new secret in the runpod webui under secrets, and name it: `COMFY_DEV_TAILSCALE_AUTH` then paste in [tailscale API](#tailscale) key as the secret value that you saved at step 9.
2. Create a new secret in the runpod webui under secrets, and name it: `COMFY_DEV_SSH_PUBKEY` then paste your [public key](#vscode) as the secret value that you saved at step 10.
   * *We will reference this secret as a environment variable when we start our runpod.*
3. Create a new Network Volume in the runpod webui and pick a data center region that is near your physical location and has good availability for the GPUs you want.
   * *This network volume will be mounted by the container under `/workspace` and act as persistent storage between terminations of your container. I recommend ~256GBs of storage which is a good balance of space and price to hold all your models long term. You can also explore Backblaze for cheaper long term storage. However, I've found in practice that the synchronization speed is to slow between terminations of the container.*
4. Begin the process of creating a new pod in the runpod webui.
    1. Under Network Volume, select the volume we just created.
    2. Select the GPU you'd like to rent by the hour.
    3. Name your pod whatever you'd like.
    4. Select **"Change Template"** and search for: `nomcycle/comfyui` and select the first template you see.
    5. Select **"Edit Template"**, and expand the **"Environment Variables"**
    6. Apply your tailscale auth secret to the `COMFY_DEV_TAILSCALE_AUTH` environment variable.
    7. Apply the public key you saved to the `COMFY_DEV_SSH_PUBKEY` environment variable.
    8. **(Optional)** Perform the following
        * Set the python version you'd like to use for the `COMFY_DEV_PYTHON_VERSION`.
        * If you'd like comfy to automatically start when the container loads instead of executing it from visual code, set `COMFY_DEV_START_COMFY` to `true`.
    9. Select **"Set Overrides"** to tweak the container template.
    10. Select **"Deploy On-Demand`** to start your container.
5. 