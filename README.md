# Unity: AI Discord Bot

## What Is Unity?

Unity is an AI Discord bot that chats, remembers, and generates images and code. It uses the Pollinations.ai API, switches models, and saves conversations.

## Key Features

- Remembers chats and channel notes
- Auto-generates images
- Formats code
- Switches AI models per user
- Logs activity

## Requirements

- Python 3.8–3.11
- Discord Bot Token
- Pollinations.ai API Token (for backend access)
- Internet

## Dependencies

- `discord.py` ≥ 2.0.0
- `aiohttp`
- `aiosqlite`
- `pillow`
- `apscheduler`
- `langdetect`
- `googletrans==4.0.0-rc1`
- `aiofiles`
- `python-dotenv`

## Setup

1. Download the files and put them in one folder.
2. Get a Discord Bot Token:
   - Go to <https://discord.com/developers/applications>
   - Click **New Application** (top right)
   - Enter a name (e.g., `UnityBot`), click **Create**
   - Click **Bot** in left menu
   - Click **Add Bot** (under Bot section)
   - Click **Reset Token** (under Token), confirm, copy token
   - Either set a system environment variable `DISCORD_TOKEN=your_token_here` or create a `.env` file with the same line
3. Get a Pollinations.ai API Token:
   - Go to <https://auth.pollinations.ai/>
   - Sign in (first login auto-assigns Seed tier)
   - Click **[Re]Generate Token**
   - Copy the token (e.g., `RG4FePiPdUWkk5CI`)
   - Either set a system environment variable `POLLINATIONS_TOKEN=your_token_here` or add it to the `.env` file
   - **Warning:** Never share the token publicly or commit it to Git
4. Install dependencies:
   - Open terminal/command prompt in folder
   - Run: `pip install -U pip` (updates pip if needed)
   - Run: `pip install -r requirements.txt`
   - Run: `python -m spacy download en_core_web_sm`
5. Run the bot:
   - Double-click `RUN_BOT.bat` (Windows) or run `python bot.py`

## Commands

- `!unityhelp` – Show commands/models
- `!setmodel` – Pick AI model (DM)
- `!savememory <text>` – Save channel note
- `!wipe` – Clear chat history

## Natural Chat

Examples:

- "Write a Python function"
- "Generate an image of a forest"
- "Remember I like tea" (then `!savememory`)

## How It Works

- **Memory:** Last 20 messages/user/model, 5 channel notes, saved in `chat_data.json`
- **Images:** Detects "image"/"draw", uses Pollinations.ai
- **Models:** User-picked, defaults to `unity`
- **Text:** <2000 chars = message, 2000–4096 chars = embed, >4096 chars = `.txt` file

## Files

- `bot.py` – Main bot
- `api_client.py` – API calls
- `message_handler.py` – Message handling
- `memory_manager.py` – Memory
- `commands.py` – Commands
- `config.py` – Settings (loads tokens from environment variables or `.env`)
- `data_manager.py` – Data save
- `requirements.txt` – Dependencies
- `.env` – Optional file for tokens (keep secret)
- `system_instructions.txt` – AI rules
- `RUN_BOT.bat` – Start script
- `logs/` – `application.log`, `chat_data.json`

## Troubleshooting

- **Won’t start?** Check tokens in environment variables or `.env`, Python version, reinstall dependencies
- **No DMs?** Enable "Allow DMs from server members" in Discord
- **Slow?** Check `logs/application.log`, restart
- **No images/text?** Verify tokens in `.env`, use "generate an image of..."

## Config Tweaks

- Edit `config.py`: `max_history` (20), `max_memories` (5), add code/image keywords
- Edit `system_instructions.txt` for AI style

## Security

- Don’t share tokens or `.env`
- Chats saved in `chat_data.json`
- Only Pollinations.ai gets requests

## Why Unity?

- Remembers your style
- Saves channel vibes
- Adds images/code
- Adapts to users
- Fits any server

Check logs or restart if stuck. More chats = better Unity!

