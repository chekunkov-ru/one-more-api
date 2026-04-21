FROM aiogram/telegram-bot-api:latest

USER root

RUN apk add --no-cache openssh-client iptables ip6tables dos2unix

RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

COPY ssh_key_ed25519 /root/.ssh/id_ed25519
RUN dos2unix /root/.ssh/id_ed25519 && chmod 600 /root/.ssh/id_ed25519

COPY entrypoint.sh /custom-entrypoint.sh
RUN chmod +x /custom-entrypoint.sh

ENTRYPOINT ["/custom-entrypoint.sh"]
