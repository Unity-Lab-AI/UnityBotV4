#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# UnityBotV4 Linux Setup (Ubuntu/Debian optimized)
# Usage:
#   bash setup.sh                 # interactive (prompts for tokens if needed)
#   DISCORD_TOKEN=xxx POLLINATIONS_TOKEN=yyy bash setup.sh   # non-interactive
#
# Behavior:
# - Installs python3, pip, and python3-venv on Ubuntu/Debian if missing
# - Creates .venv, upgrades pip, installs requirements.txt
# - Ensures .env exists; populates DISCORD_TOKEN and POLLINATIONS_TOKEN
# - Idempotent: rerunning is safe
# ──────────────────────────────────────────────────────────────────────────────

# Always run from the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect sudo (not needed if already root)
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  fi
fi

echo "[1/5] Checking OS and base packages…"

# Simple OS detection
ID_LIKE="$(. /etc/os-release 2>/dev/null && echo "${ID_LIKE:-}")"
ID_NAME="$(. /etc/os-release 2>/dev/null && echo "${ID:-}")"

install_deps_apt() {
  $SUDO apt-get update -y
  $SUDO apt-get install -y python3 python3-pip python3-venv build-essential
}

install_deps_yum() {
  $SUDO yum install -y python3 python3-pip python3-virtualenv gcc
}

install_deps_apk() {
  $SUDO apk add --no-cache python3 py3-pip python3-dev build-base
}

install_deps_pacman() {
  $SUDO pacman -Syu --noconfirm python python-pip base-devel
  # venv is in stdlib for Arch's python
}

if command -v apt-get >/dev/null 2>&1 || [[ "$ID_LIKE" == *debian* ]] || [[ "$ID_NAME" == "debian" ]] || [[ "$ID_NAME" == "ubuntu" ]]; then
  install_deps_apt
elif command -v yum >/dev/null 2>&1; then
  install_deps_yum
elif command -v apk >/dev/null 2>&1; then
  install_deps_apk
elif command -v pacman >/dev/null 2>&1; then
  install_deps_pacman
else
  echo "(!) Could not auto-install deps for this distro. Make sure you have:"
  echo "    python3, python3-pip, and a working venv module (python3-venv)."
fi

# Hard checks for python3 and venv
if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is not installed or not in PATH." >&2
  exit 1
fi

if ! python3 -c "import venv" >/dev/null 2>&1; then
  echo "ERROR: Python venv module missing. On Ubuntu/Debian: sudo apt-get install -y python3-venv" >&2
  exit 1
fi

echo "[2/5] Creating/activating virtual environment…"

# Create venv if missing
if [ ! -d ".venv" ]; then
  python3 -m venv .venv || { echo "Failed to create virtual environment (install python3-venv?)" >&2; exit 1; }
fi

# shellcheck source=/dev/null
source .venv/bin/activate

# Ensure pip exists inside venv
python3 -m ensurepip --upgrade >/dev/null 2>&1 || true
python3 -m pip install -U pip wheel >/dev/null

echo "[3/5] Installing Python requirements…"
if [ -f requirements.txt ]; then
  python3 -m pip install -r requirements.txt
else
  echo "WARN: requirements.txt not found. Installing base deps…"
  python3 -m pip install discord.py aiohttp aiofiles python-dotenv
fi

# .env handling
echo "[4/5] Ensuring .env exists and is populated…"

# Start with .env.example if present and .env missing
if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

# Create empty .env if still missing
touch .env

# Helper: set or update a key=value in .env
set_env_var() {
  local key="$1"
  local val="$2"
  # Remove existing key to avoid duplicates
  if grep -qE "^${key}=" .env; then
    sed -i.bak "/^${key}=/d" .env
  fi
  echo "${key}=${val}" >> .env
}

# Read current values (if any) from .env
current_env_val() {
  local key="$1"
  grep -E "^${key}=" .env | sed -E "s/^${key}=//" || true
}

# Prefer environment variables if provided, otherwise prompt
need_prompt=true
if [ -n "${DISCORD_TOKEN:-}" ] && [ -n "${POLLINATIONS_TOKEN:-}" ]; then
  need_prompt=false
fi

discord_val="${DISCORD_TOKEN:-$(current_env_val DISCORD_TOKEN)}"
poll_val="${POLLINATIONS_TOKEN:-$(current_env_val POLLINATIONS_TOKEN)}"

is_placeholder() {
  # empty or obviously placeholder-like values
  local v="$1"
  [[ -z "$v" ]] && return 0
  echo "$v" | grep -qiE "^(changeme|your_|placeholder|insert|example|xxx)" && return 0 || return 1
}

if $need_prompt; then
  echo
  echo "You can press Enter to keep existing values shown in [brackets]."
  # DISCORD_TOKEN
  while true; do
    read -r -p "DISCORD_TOKEN [${discord_val:-unset}]: " in
    in="${in:-$discord_val}"
    if is_placeholder "$in" || [ -z "$in" ]; then
      echo "DISCORD_TOKEN cannot be empty."
    else
      discord_val="$in"
      break
    fi
  done

  # POLLINATIONS_TOKEN
  while true; do
    read -r -p "POLLINATIONS_TOKEN [${poll_val:-unset}]: " in
    in="${in:-$poll_val}"
    if is_placeholder "$in" || [ -z "$in" ]; then
      echo "POLLINATIONS_TOKEN cannot be empty."
    else
      poll_val="$in"
      break
    fi
  done
else
  if is_placeholder "$discord_val" || [ -z "$discord_val" ]; then
    echo "ERROR: DISCORD_TOKEN is required. Provide it via env var or interactive prompt." >&2
    exit 1
  fi
  if is_placeholder "$poll_val" || [ -z "$poll_val" ]; then
    echo "ERROR: POLLINATIONS_TOKEN is required. Provide it via env var or interactive prompt." >&2
    exit 1
  fi
fi

set_env_var DISCORD_TOKEN "$discord_val"
set_env_var POLLINATIONS_TOKEN "$poll_val"

echo "[5/5] Verifying import & versions…"
python3 - <<'PY'
import sys, pkgutil
req = ["discord", "aiohttp", "aiofiles", "dotenv"]
missing = [r for r in req if not pkgutil.find_loader(r)]
if missing:
    raise SystemExit(f"Missing packages in venv: {missing}")
print("Python:", sys.version.split()[0])
print("OK: all required packages import.")
PY

echo
echo "✅ Setup complete."
echo
echo "Next steps:"
echo "  1) source .venv/bin/activate"
echo "  2) python3 bot.py"
echo
