#!/usr/bin/env bash
set -euo pipefail

# Setup script for UnityBotV4 on Linux

# Ensure the script runs from its own directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null; then
        SUDO="sudo"
    else
        echo "sudo is required but not installed. Please run as root or install sudo." >&2
        exit 1
    fi
fi

read -r -p "Use .env file for configuration? (y/n): " use_env

if [[ "$use_env" =~ ^[Yy]$ ]]; then
    TARGET="env"
else
    TARGET="system"
fi

# Ensure system Python and required modules are available
if ! command -v python3 >/dev/null; then
    echo "python3 not found. Installing..."
    if command -v apt-get >/dev/null; then
        $SUDO apt-get update && $SUDO apt-get install -y python3 python3-venv python3-pip
    else
        echo "Package manager not supported. Please install Python 3.8+ manually." >&2
        exit 1
    fi
else
    # python3 present – ensure venv and pip modules are available
    if ! python3 -m venv --help >/dev/null 2>&1; then
        if command -v apt-get >/dev/null; then
            echo "python3-venv not found. Installing..."
            $SUDO apt-get update && $SUDO apt-get install -y python3-venv
        else
            echo "python3-venv is required but could not be installed automatically." >&2
            exit 1
        fi
    fi
    if ! python3 -m pip --version >/dev/null 2>&1; then
        if command -v apt-get >/dev/null; then
            echo "python3-pip not found. Installing..."
            $SUDO apt-get update && $SUDO apt-get install -y python3-pip
        else
            echo "python3-pip is required but could not be installed automatically." >&2
            exit 1
        fi
    fi
fi

# Verify Python version
if ! python3 - <<'PYTHON'
import sys
sys.exit(0 if sys.version_info >= (3, 8) else 1)
PYTHON
then
    echo "Python 3.8+ is required. Please install a supported version." >&2
    exit 1
fi

# Create and activate virtual environment
if [ ! -d .venv ]; then
    python3 -m venv .venv || { echo "Failed to create virtual environment" >&2; exit 1; }
fi
# shellcheck source=/dev/null
source .venv/bin/activate

is_placeholder() {
    local val="$1"
    [[ -z "$val" || "$val" == *Your*Here* ]]
}

prompt_var() {
    local var_name="$1"
    local env_val
    env_val=$(printenv "$var_name" 2>/dev/null || true)
    local file_val=""
    [[ -f .env ]] && file_val=$(grep -E "^${var_name}=" .env | cut -d'=' -f2- 2>/dev/null || true)

    if [[ "$TARGET" == "env" ]]; then
        if [[ -n "$file_val" ]] && ! is_placeholder "$file_val"; then
            echo "$var_name already set in .env. Skipping prompt."
        else
            local default=""
            if [[ -n "$env_val" ]] && ! is_placeholder "$env_val"; then
                default="$env_val"
            fi
            while true; do
                read -r -p "Enter value for ${var_name}${default:+ [${default}]}: " value
                value="${value:-$default}"
                if is_placeholder "$value"; then
                    echo "Value cannot be empty or default."
                else
                    break
                fi
            done
            [[ -f .env ]] && grep -v "^${var_name}=" .env > .env.tmp && mv .env.tmp .env
            echo "${var_name}=${value}" >> .env
        fi
    else
        if [[ -n "$env_val" ]] && ! is_placeholder "$env_val"; then
            echo "$var_name already set. Skipping prompt."
        else
            while true; do
                read -r -p "Enter value for ${var_name}: " value
                if is_placeholder "$value"; then
                    echo "Value cannot be empty or default."
                else
                    break
                fi
            done
            if grep -q "^${var_name}=" /etc/environment 2>/dev/null; then
                $SUDO sed -i "s/^${var_name}=.*/${var_name}=\"${value}\"/" /etc/environment
            else
                echo "${var_name}=\"${value}\"" | $SUDO tee -a /etc/environment >/dev/null
            fi
            export "${var_name}"="${value}"
        fi
    fi
}

prompt_var "DISCORD_TOKEN"
prompt_var "POLLINATIONS_TOKEN"

python -m pip install -U pip
python -m pip install -r requirements.txt

echo "Setup complete."

