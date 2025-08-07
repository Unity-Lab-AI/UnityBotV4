#!/bin/bash

# Update script for UnityBotV4 on Linux
set -e

SERVICE_NAME="unitybot"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if systemctl list-units --full -all | grep -Fq "${SERVICE_NAME}.service"; then
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        sudo systemctl stop ${SERVICE_NAME}
    fi
fi

if [ -f "${SCRIPT_DIR}/.env" ]; then
    mv "${SCRIPT_DIR}/.env" ~/
fi

git fetch
git pull

pip install -r requirements.txt

if [ -f "${HOME}/.env" ]; then
    mv "${HOME}/.env" "${SCRIPT_DIR}/.env"
fi

if systemctl list-units --full -all | grep -Fq "${SERVICE_NAME}.service"; then
    sudo systemctl start ${SERVICE_NAME}
else
    echo "Service ${SERVICE_NAME} not installed. Run install.sh to install it."
fi

echo "Update complete."

