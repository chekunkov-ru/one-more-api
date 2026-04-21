FROM aiogram/telegram-bot-api:latest

USER root

RUN apk add --no-cache openssh-client iptables ip6tables

COPY entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

ENTRYPOINT ["/custom-entrypoint.sh"]
