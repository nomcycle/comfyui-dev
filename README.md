# Secure ComfyUI Development Docker Container

![Example Usage](./media/example.gif)

* [Github](https://github.com/nomcycle/comfyui-dev)
* [Docker](https://hub.docker.com/repository/docker/nomcycle/comfyui-dev)

A secure, remote, and persistent development environment for ComfyUI that works with cloud GPU services. This container combines [Tailscale's](https://tailscale.com) secure VPN service with [VSCode's remote development](https://code.visualstudio.com/docs/remote/remote-overview) capabilities, making it perfect for developing on services like [RunPod](https://www.runpod.io/). Your development environment persists between sessions, so you only pay for GPU time when actively developing.

## Quick Start

1. Set up Tailscale and get an auth key ([Instructions](./docs/quickstart.md#1-tailscale-setup))
2. Configure VSCode with SSH keys ([Instructions](./docs/quickstart.md#2-vscode-setup))
3. Create a RunPod deployment with the required environment variables ([Instructions](./docs/quickstart.md#3-runpod-setup))
4. Connect to your development environment ([Instructions](./docs/quickstart.md#4-connect))
5. Start developing with ComfyUI!

## Environment Variables

**Required:**
- `COMFY_DEV_TAILSCALE_AUTH` - Your Tailscale authentication key
- `COMFY_DEV_SSH_PUBKEY` - Your SSH public key for VSCode remote access

**Optional:**
- `COMFY_DEV_PYTHON_VERSION` - Python version for the environment (default: 3.12.4)
- `COMFY_DEV_START_COMFY` - Set to `true` to start ComfyUI automatically
- `COMFY_DEV_GIT_FORK` - URL to your ComfyUI fork (if using one)
- `COMFY_DEV_TAILSCALE_MACHINENAME` - Custom name for Tailscale device

## Documentation

- [Quick Start Guide](./docs/quickstart.md)
- [Debugging & Breakpoints](./docs/quickstart.md#debugging--breakpoints)
- [Troubleshooting](./docs/quickstart.md#troubleshooting)

## Development

### Building the Container

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Build the Docker image
./scripts/build.sh

# Test the container locally
./scripts/test.sh --tailscale-auth YOUR_TAILSCALE_AUTH_KEY

# Push to Docker Hub (if you have permissions)
./scripts/push.sh
```

## Project Structure

```
comfyui-dev/
├── docker/            # Docker-related files
│   ├── Dockerfile     # Multi-stage Dockerfile
│   └── scripts/       # Container scripts
├── scripts/           # Build and utility scripts
├── config/            # Configuration files
│   ├── default.env    # Default environment settings
│   └── vscode/        # VSCode configurations
├── docs/              # Documentation
└── media/             # Images and media files
```

## Features

- **Secure Remote Access**: SSH and Tailscale VPN integration
- **Persistent Development**: State saved between sessions
- **GPU Acceleration**: CUDA 12.4 support for AI workloads
- **VSCode Integration**: Seamless remote development
- **Python Environment**: Optimized with uv package manager
- **Debugging Support**: Full debugging capabilities

## License

MIT License - See LICENSE file for details.

Need more help? [Open an issue](https://github.com/nomcycle/comfyui-dev/issues)