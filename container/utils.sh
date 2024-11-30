#!/bin/bash
log_message() {
    echo -e "\033[38;5;205m[INSTALL]\033[0m $1"
}

source_conda() {
    if [ -f "/workspace/miniconda/etc/profile.d/conda.sh" ]; then
        source "/workspace/miniconda/etc/profile.d/conda.sh"
    fi
}
