#!/bin/bash

# Install UnityBotV4 as a systemd service on Linux
set -e

SERVICE_NAME="unitybot"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

VENV_PYTHON="${SCRIPT_DIR}/.venv/bin/python"
if [ ! -x "$VENV_PYTHON" ]; then
    echo "Virtual environment not found. Run setup.sh before installing the service." >&2
    exit 1
fi

cat <<EOF | sudo tee /etc/systemd/system/${SERVICE_NAME}.service >/dev/null
[Unit]
Description=UnityBot Discord Bot
After=network.target

[Service]
Type=simple
WorkingDirectory=${SCRIPT_DIR}
EnvironmentFile=-${SCRIPT_DIR}/.env
EnvironmentFile=-/etc/environment
ExecStart=${VENV_PYTHON} ${SCRIPT_DIR}/bot.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable ${SERVICE_NAME}
sudo systemctl start ${SERVICE_NAME}

echo "Service ${SERVICE_NAME} installed and started."

