FROM aiogram/telegram-bot-api:latest

USER root

# Install redsocks and iptables for transparent SOCKS5 proxying
RUN apk add --no-cache redsocks iptables

COPY entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

ENTRYPOINT ["/custom-entrypoint.sh"]
