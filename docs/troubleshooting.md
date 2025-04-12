# Troubleshooting Guide

This guide addresses common issues you might encounter when using the ComfyUI Development Container.

## Tailscale Connectivity Issues

### Problem: Unable to Connect to Tailscale Network

**Symptoms:**
- Container logs show Tailscale connection errors
- Cannot connect to container via SSH

**Solutions:**
1. Check your Tailscale auth key:
   ```bash
   # View container logs
   docker logs comfyui-dev
   ```

2. Remove old device registrations:
   - Go to [Tailscale Admin Console](https://login.tailscale.com/admin/machines)
   - Delete any old devices with the same name
   - Recreate the container

3. Verify firewall settings:
   - Ensure ports for Tailscale (UDP 41641) are not blocked
   - Check if your network restricts VPN connections

## SSH Connection Issues

### Problem: Permission Denied (publickey)

**Symptoms:**
- SSH connection is refused with "Permission denied (publickey)" error
- Cannot connect to container from VSCode

**Solutions:**
1. Verify SSH public key:
   ```bash
   # Check if the key used in environment variable matches your local key
   cat ~/.ssh/comfyui-dev.pub
   ```

2. Check SSH key permissions:
   ```bash
   # Local machine
   chmod 600 ~/.ssh/comfyui-dev
   chmod 644 ~/.ssh/comfyui-dev.pub
   ```

3. Verify SSH config file format:
   ```bash
   # Ensure proper format in ~/.ssh/config
   Host comfyui-dev
       HostName comfyui-dev
       User comfy
       IdentityFile ~/.ssh/comfyui-dev
   ```

## Python Environment Issues

### Problem: Python Packages Not Installing

**Symptoms:**
- Errors related to pip or package installation
- Missing dependencies when running ComfyUI

**Solutions:**
1. Check the virtual environment:
   ```bash
   # Inside container
   ls -la /workspace/.venv
   ```

2. Manually activate and install:
   ```bash
   # Inside container
   source /workspace/.venv/bin/activate
   cd /workspace/ComfyUI
   pip install -r requirements.txt
   ```

3. Check disk space:
   ```bash
   # Inside container
   df -h
   ```

### Problem: UV Command Not Found

**Symptoms:**
- Error messages showing "uv: command not found"
- Python environment setup fails

**Solutions:**
1. Check if uv is installed:
   ```bash
   # Inside container
   ls -la $HOME/.local/bin/uv
   ```

2. Reinstall uv:
   ```bash
   # Inside container
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

3. Verify PATH environment:
   ```bash
   # Inside container
   echo $PATH
   ```

## GPU Issues

### Problem: CUDA Not Available

**Symptoms:**
- ComfyUI reports no GPU available
- Torch reports CUDA not available

**Solutions:**
1. Check CUDA installation:
   ```bash
   # Inside container
   nvcc --version
   nvidia-smi
   ```

2. Verify PyTorch installation:
   ```bash
   # Inside container
   python -c "import torch; print(torch.cuda.is_available())"
   ```

3. Ensure container has GPU access:
   ```bash
   # Host machine
   docker run --gpus all --rm nvidia/cuda:12.4.1-base-ubuntu22.04 nvidia-smi
   ```

## Container Start-up Issues

### Problem: Container Exits Immediately

**Symptoms:**
- Container starts and then exits
- Logs show errors during initialization

**Solutions:**
1. Check for missing environment variables:
   ```bash
   # Start with debug logs
   docker run -e DEBUG=1 --name comfyui-dev-debug --gpus all -e COMFY_DEV_SSH_PUBKEY="..." -e COMFY_DEV_TAILSCALE_AUTH="..." nomcycle/comfyui-dev:latest
   ```

2. Verify volume mounts:
   ```bash
   # Check if volume exists and is accessible
   docker volume ls
   ```

3. Inspect container logs:
   ```bash
   docker logs comfyui-dev
   ```

## Still Having Issues?

If you're still experiencing problems:

1. [Open an issue](https://github.com/nomcycle/comfyui-dev/issues) with:
   - Detailed description of the problem
   - Steps to reproduce
   - Container logs
   - Host environment information

2. Try rebuilding the container from scratch:
   ```bash
   # Rebuild from source
   git clone https://github.com/nomcycle/comfyui-dev.git
   cd comfyui-dev
   ./scripts/build.sh
   ./scripts/test.sh --tailscale-auth YOUR_KEY
   ```