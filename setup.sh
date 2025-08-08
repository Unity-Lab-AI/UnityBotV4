#!/bin/bash

# Setup script for UnityBotV4 on Linux
set -e

read -p "Use .env file for configuration? (y/n): " use_env

if [[ "$use_env" =~ ^[Yy]$ ]]; then
    TARGET="env"
else
    TARGET="system"
fi

# Ensure system Python is available without compiling
if ! command -v python3 >/dev/null; then
    echo "python3 not found. Installing..."
    if command -v apt-get >/dev/null; then
        sudo apt-get update && sudo apt-get install -y python3 python3-venv python3-pip
    else
        echo "Package manager not supported. Please install Python 3.8+ manually." >&2
        exit 1
    fi
fi

# Verify Python version
python3 - <<'PYTHON'
import sys
sys.exit(0 if sys.version_info >= (3, 8) else 1)
PYTHON
if [ $? -ne 0 ]; then
    echo "Python 3.8+ is required. Please install a supported version." >&2
    exit 1
fi

# Create and activate virtual environment
if [ ! -d .venv ]; then
    python3 -m venv .venv
fi
source .venv/bin/activate

prompt_var() {
    local var_name=$1
    local env_val=$(printenv "$var_name")
    local file_val=""
    [[ -f .env ]] && file_val=$(grep -E "^${var_name}=" .env | cut -d'=' -f2-)

    if [[ "$TARGET" == "env" ]]; then
        if [[ -n "$file_val" ]]; then
            echo "$var_name already set in .env. Skipping prompt."
        else
            read -p "Enter value for $var_name${env_val:+ [$env_val]}: " value
            value=${value:-$env_val}
            [[ -f .env ]] && grep -v "^$var_name=" .env > .env.tmp && mv .env.tmp .env
            echo "$var_name=$value" >> .env
        fi
    else
        if [[ -n "$env_val" ]]; then
            echo "$var_name already set. Skipping prompt."
        else
            read -p "Enter value for $var_name: " value
            if grep -q "^$var_name=" /etc/environment 2>/dev/null; then
                sudo sed -i "s/^$var_name=.*/$var_name=\"${value}\"/" /etc/environment
            else
                echo "$var_name=\"${value}\"" | sudo tee -a /etc/environment >/dev/null
            fi
            export "$var_name"="$value"
        fi
    fi
}

prompt_var "DISCORD_TOKEN"
prompt_var "POLLINATIONS_TOKEN"

pip install -U pip
pip install -r requirements.txt

echo "Setup complete."

