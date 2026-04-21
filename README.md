# Telegram Bot API Server Deployment

Self-hosted Telegram Bot API server with transparent SOCKS5 proxy support and IPv6 disabled.

## Features
- **Local Mode**: Downloading and uploading files up to 2000 MB.
- **No Rate Limits**: For local requests.
- **SOCKS5 Proxy**: Transparent proxying via redsocks + iptables (for servers where Telegram DC is blocked).
- **IPv6 Disabled**: Prevents "Network unreachable" errors to Telegram DC IPv6 endpoints.
- **Persistence**: Data stored on host volume.

## Prerequisites
- `TELEGRAM_API_ID` and `TELEGRAM_API_HASH` from [my.telegram.org](https://my.telegram.org).
- A working SOCKS5 proxy if Telegram is blocked on the server.

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `TELEGRAM_API_ID` | Yes | Telegram API application ID |
| `TELEGRAM_API_HASH` | Yes | Telegram API application hash |
| `SOCKS5_HOST` | No | SOCKS5 proxy hostname/IP |
| `SOCKS5_PORT` | No | SOCKS5 proxy port |
| `SOCKS5_USER` | No | SOCKS5 proxy username |
| `SOCKS5_PASS` | No | SOCKS5 proxy password |

## Deployment on Coolify

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd "One More API"
   ```
2. **Setup environment**:
   - Copy `.env.example` to `.env`.
   - Fill in `TELEGRAM_API_ID`, `TELEGRAM_API_HASH`.
   - If Telegram is blocked: fill in `SOCKS5_HOST`, `SOCKS5_PORT`, `SOCKS5_USER`, `SOCKS5_PASS`.
3. **Deployment on Coolify**:
   - Create a new project or select an existing one.
   - Add "Docker Compose" resource.
   - The container builds from `Dockerfile` (adds redsocks + iptables to the base image).
   - Set environment variables in Coolify.
   - **Shared Volume**: The path `/data/shared/telegram-api` on the host maps to `/var/lib/telegram-bot-api` in the container. Ensure your bot containers can access it.

4. **Deploy**: The server will be available on port `8081`.

## How SOCKS5 Proxy Works

The official `telegram-bot-api` binary does not support SOCKS5 natively. This setup uses:
1. **redsocks** — a transparent redirector that runs inside the container.
2. **iptables** — NAT rules redirect all outgoing TCP traffic through redsocks.
3. redsocks forwards the traffic to your SOCKS5 proxy.

This requires `NET_ADMIN` capability (set in `docker-compose.yaml`).

If `SOCKS5_HOST` is not set, the container runs without any proxy (direct connection).

## Client Configuration (aiogram example)

```python
from aiogram import Bot
from aiogram.client.telegram import TelegramAPIServer

local_server = TelegramAPIServer.from_base("http://your-coolify-host:8081")
bot = Bot(token="YOUR_BOT_TOKEN", server=local_server)
```

## Troubleshooting

### Server hangs / no HTTP response
If TCP ports are open but no HTTP response:
1. **Check SOCKS5 proxy**: `curl -v --socks5 HOST:PORT --proxy-user USER:PASS https://api.telegram.org/`
2. **Dead proxy = stuck server**: The API server hangs on every request if Telegram DC is unreachable.
3. **Check logs**: `docker logs telegram-bot-api` — look for `ConnectionCreator` errors.

### "File is too big" error
1. Ensure your bot uses the local server URL.
2. `TELEGRAM_LOCAL=true` must be set (already configured).
3. Check proxy (Nginx/Traefik) doesn't limit upload size.

### "Flood control exceeded" on `getUpdates`
- Multiple bot instances using the same token.
- A webhook is still active while using long-polling. Use `deleteWebhook` to clear.
- Connection to Telegram DC is unstable. Check logs.

### IPv6 "Network unreachable" errors
IPv6 is disabled via `sysctls` in `docker-compose.yaml`. If you still see these errors, the sysctl may not be applying — check that the host kernel allows unprivileged sysctl changes.

## Health Check
```bash
./test_api.sh              # checks localhost:8081
./test_api.sh http://shh.thept.ru:8081  # checks remote
```
