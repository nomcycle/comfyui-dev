#!/bin/bash
source /home/comfy/startup/utils.sh

# Setup standard PATH
setup_path

log_message "Using Python version: ${PYTHON_VERSION}"

# Initialize setup components in the correct order
# First set up Python and ComfyUI environments
source /home/comfy/startup/scripts/modules/python_setup.sh
source /home/comfy/startup/scripts/modules/comfyui_setup.sh
# Then start synchronization service
source /home/comfy/startup/scripts/modules/sync_setup.sh

log_success "Environment setup complete."