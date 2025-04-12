#!/bin/bash
log_message() {
    echo -e "\033[38;5;205m[INSTALL]\033[0m $1"
}

source_venv() {
    if [ -f "/workspace/.venv/bin/activate" ]; then
        source "/workspace/.venv/bin/activate"
    fi
}