# Telegram Bot API Server Deployment

This repository contains the configuration for deploying a self-hosted Telegram Bot API server.

## Features
- **Local Mode**: Allows downloading and uploading files up to 2000 MB.
- **Improved Performance**: No rate limits for local requests.
- **Persistence**: Data is stored in a Docker volume.

## Prerequisites
You need to obtain `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` from [https://my.telegram.org](https://my.telegram.org).

## Deployment on Coolify

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd "One More API"
   ```
2. **Setup environment**:
   - Copy `.env.example` to `.env`.
   - Edit `.env` and provide your credentials.
3. **Deployment on Coolify**:
   - Create a new project or select an existing one.
   - Add "Docker Compose" resource.
   - Paste the content of `docker-compose.yaml`.
   - The server will use variables from the environment.
   - **Shared Volume (Crucial for large files)**:
     - To allow your Bot application to access files directly, ensure both the API server and the Bot share the same volume.
     - In Coolify, ensure `telegram-bot-api-data` is accessible to both services.
     - The path inside the API container is `/var/lib/telegram-bot-api`.

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

## Troubleshooting

### "File is too big" error
If your bot still receives this error:
1.  **Check Bot Configuration**: Ensure your bot is explicitly initialized to use the local server URL. 
2.  **Explicit Local Server Mode**: The server must be started with `TELEGRAM_LOCAL=true` (already set in `docker-compose.yaml`).
3.  **Proxy Limits**: If you are uploading files via the server, ensure your proxy (Nginx/Traefik) doesn't have a `client_max_body_size` limit. We've added labels to address this in Coolify.

### "Flood control exceeded" on `getUpdates`
This often happens if:
- Multiple bot instances are using the same token.
- A webhook is still active while you're trying to use long-polling. Use `deleteWebhook` to clear it.
- The local server is losing connection to Telegram. Check logs with `docker logs telegram-bot-api`.

## Health Check
Run the `test_api.sh` script to verify the server is responding.
