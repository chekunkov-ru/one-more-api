# Telegram Bot API Server Deployment

This repository contains the configuration for deploying a self-hosted Telegram Bot API server.

## Features
- **Local Mode**: Allows downloading and uploading files up to 2000 MB.
- **Improved Performance**: No rate limits for local requests.
- **Persistence**: Data is stored in a Docker volume.

## Prerequisites
You need to obtain `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` from [https://my.telegram.org](https://my.telegram.org).

## Deployment on Coolify

1. **Create a New Project**: In Coolify, create a new project or select an existing one.
2. **Add Resource**: Choose "Docker Compose".
3. **Configuration**: 
   - Paste the content of `docker-compose.yaml`.
   - In the "Environment Variables" section, add:
     - `TELEGRAM_API_ID`
     - `TELEGRAM_API_HASH`
4. **Deploy**: Click "Deploy". The server will be available on port `8081` by default.

## Client Configuration (aiogram example)

To use this server in your bot (e.g., using `aiogram`):

```python
from aiogram import Bot
from aiogram.client.telegram import TelegramAPIServer

# Use your local server URL
local_server = TelegramAPIServer.from_base("http://your-coolify-host:8081")

bot = Bot(token="YOUR_BOT_TOKEN", server=local_server)
```

## Health Check
Run the `test_api.sh` script to verify the server is responding.
