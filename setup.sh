#!/bin/bash

# Setup script for UnityBotV4 on Linux
set -e

read -p "Use .env file for configuration? (y/n): " use_env

if [[ "$use_env" =~ ^[Yy]$ ]]; then
    TARGET="env"
else
    TARGET="system"
fi

prompt_var() {
    local var_name=$1
    local current=""
    if [[ "$TARGET" == "system" ]]; then
        current=$(printenv "$var_name")
    else
        [[ -f .env ]] && current=$(grep -E "^${var_name}=" .env | cut -d'=' -f2-)
    fi

    if [[ -n "$current" ]]; then
        echo "$var_name already set. Skipping prompt."
        return
    fi

    read -p "Enter value for $var_name: " value
    if [[ "$TARGET" == "system" ]]; then
        if grep -q "^$var_name=" /etc/environment 2>/dev/null; then
            sudo sed -i "s/^$var_name=.*/$var_name=\"$value\"/" /etc/environment
        else
            echo "$var_name=\"$value\"" | sudo tee -a /etc/environment >/dev/null
        fi
        export "$var_name"="$value"
    else
        [[ -f .env ]] && grep -v "^$var_name=" .env > .env.tmp && mv .env.tmp .env
        echo "$var_name=$value" >> .env
    fi
}

prompt_var "DISCORD_TOKEN"
prompt_var "POLLINATIONS_TOKEN"

pip install -r requirements.txt

echo "Setup complete."

