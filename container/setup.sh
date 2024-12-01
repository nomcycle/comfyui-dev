#!/bin/bash
source /home/comfy/startup/utils.sh
source_conda

# Check if conda is available
log_message "Checking if conda is available..."
if ! command -v conda &> /dev/null; then
    log_message "Conda not found. Installing Miniconda..."
    if [ ! -d "/workspace/miniconda" ]; then
        log_message "Downloading miniconda..."
        wget --no-check-certificate https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
        bash /tmp/miniconda.sh -b -p /workspace/miniconda && \
        rm /tmp/miniconda.sh
        log_message "Miniconda installed successfully."

        log_message "Initializing conda..."

        source_conda
        conda init bash

        echo '. /workspace/miniconda/etc/profile.d/conda.sh' >> /home/comfy/.bashrc
        echo 'conda activate comfy' >> /home/comfy/.bashrc
    fi

    log_message "Restarting this script..."
    exec "$0"
else
    log_message "Conda is already available."
    if ! conda info --envs | grep -q '^comfy\s'; then
        log_message "Conda environment 'comfy' not found. Creating it... COMFY_DEV_WIN32 is set to: ${COMFY_DEV_WIN32}"
        if [ "${COMFY_DEV_WIN32}" = "true" ]; then
            conda create --prefix /home/comfy/.condaenvs/comfy python=${COMFY_DEV_PYTHON_VERSION} -y
        else
            conda create --name comfy python=${COMFY_DEV_PYTHON_VERSION} -y
        fi
        log_message "Conda environment 'comfy' created successfully."
    fi
fi

cd /workspace

if [ ! -d "/workspace/ComfyUI" ]; then
    log_message "Cloning ComfyUI repository..."
    git clone https://github.com/nomcycle/ComfyUI
    cd ComfyUI
    git remote add upstream https://github.com/comfyanonymous/ComfyUI
    log_message "ComfyUI repository cloned."

    if ! grep -q "cd /workspace/ComfyUI" /home/comfy/.bashrc; then
        echo 'cd /workspace/ComfyUI' >> /home/comfy/.bashrc
    fi
else
    log_message "ComfyUI directory already exists."
fi

log_message "Finished setting up python and repositories."
