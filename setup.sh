#!/bin/bash

# Setup script for UnityBotV4 on Linux
set -e

read -p "Use .env file for configuration? (y/n): " use_env

if [[ "$use_env" =~ ^[Yy]$ ]]; then
    TARGET="env"
else
    TARGET="system"
fi

# Ensure pyenv and Python are available
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if ! command -v pyenv >/dev/null; then
    echo "pyenv not found. Installing..."
    curl https://pyenv.run | bash || { echo "Failed to install pyenv"; exit 1; }
    export PATH="$PYENV_ROOT/bin:$PATH"
fi

if command -v pyenv >/dev/null; then
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    PY_VERSION="3.11.6"
    pyenv install -s "$PY_VERSION"
    if ! pyenv virtualenvs --bare | grep -q "^unitybot-env$"; then
        pyenv virtualenv "$PY_VERSION" unitybot-env
    fi
    pyenv local unitybot-env
else
    echo "pyenv installation failed. Exiting."
    exit 1
fi

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

pip install -r requirements.txt

echo "Setup complete."

