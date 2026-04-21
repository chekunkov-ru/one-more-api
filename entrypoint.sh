#!/bin/sh
set -e

echo "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 2>/dev/null || true
ip6tables -A OUTPUT -j REJECT --reject-with icmp6-port-unreachable 2>/dev/null || true

if [ -n "$SOCKS5_HOST" ] && [ -n "$SOCKS5_PORT" ] && [ -n "$SOCKS5_KEY" ]; then
  echo "Setting up SSH SOCKS proxy -> ${SOCKS5_HOST}:${SOCKS5_PORT}"

  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  printf '%b\n' "$SOCKS5_KEY" > /root/.ssh/id_ed25519
  chmod 600 /root/.ssh/id_ed25519

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -o IdentitiesOnly=yes -o PasswordAuthentication=no \
      -N -D 127.0.0.1:1080 \
      "root@${SOCKS5_HOST}" -p "${SOCKS5_PORT}" \
      -i /root/.ssh/id_ed25519 &
  SSH_PID=$!

  for i in 1 2 3 4 5; do
    if nc -z 127.0.0.1 1080 2>/dev/null; then
      break
    fi
    sleep 1
  done

  if ! nc -z 127.0.0.1 1080 2>/dev/null; then
    echo "WARNING: SSH SOCKS proxy failed to start, continuing without proxy"
    unset SOCKS5_HOST
  else
    echo "SSH SOCKS proxy ready on 127.0.0.1:1080"

    apk add --no-cache redsocks >/dev/null 2>&1 || true

    cat > /etc/redsocks.conf <<EOF
base {
    log_debug = off;
    log_info = on;
    daemon = on;
    redirector = iptables;
}

redsocks {
    local_ip = 127.0.0.1;
    local_port = 12345;
    ip = 127.0.0.1;
    port = 1080;
    type = socks5;
}
EOF

    redsocks -c /etc/redsocks.conf

    iptables -t nat -N REDSOCKS || true
    iptables -t nat -F REDSOCKS
    iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
    iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345
    iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

    echo "Transparent proxy configured (redsocks -> SSH -> ${SOCKS5_HOST})"
  fi
else
  echo "No SOCKS5 proxy configured (need SOCKS5_HOST, SOCKS5_PORT, SOCKS5_KEY)"
fi

exec /docker-entrypoint.sh "$@"
