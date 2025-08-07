#!/bin/bash

# Install UnityBotV4 as a systemd service on Linux
set -e

SERVICE_NAME="unitybot"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}.service >/dev/null
[Unit]
Description=UnityBot Discord Bot
After=network.target

[Service]
Type=simple
WorkingDirectory=${SCRIPT_DIR}
ExecStart=$(command -v python3) ${SCRIPT_DIR}/bot.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

echo "Service ${SERVICE_NAME} installed and started."

