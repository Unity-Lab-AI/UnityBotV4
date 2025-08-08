#!/bin/bash

# Install UnityBotV4 as a systemd service on Linux
set -e

SERVICE_NAME="unitybot"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

if ! command -v systemctl >/dev/null; then
    echo "systemctl not found. This installer requires systemd." >&2
    exit 1
fi
if [ ! -d /run/systemd/system ]; then
    echo "systemd is not running. Cannot install service." >&2
    exit 1
fi

VENV_PYTHON="${SCRIPT_DIR}/.venv/bin/python"
if [ ! -x "$VENV_PYTHON" ]; then
    echo "Virtual environment not found. Run setup.sh before installing the service." >&2
    exit 1
fi

cat <<EOF | $SUDO tee /etc/systemd/system/${SERVICE_NAME}.service >/dev/null
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

$SUDO systemctl daemon-reload
$SUDO systemctl enable ${SERVICE_NAME}
$SUDO systemctl start ${SERVICE_NAME}

echo "Service ${SERVICE_NAME} installed and started."

