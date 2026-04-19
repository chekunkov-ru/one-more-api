#!/bin/sh
set -e

echo "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1 2>/dev/null || true
sysctl -w net.ipv6.conf.default.disable_ipv6=1 2>/dev/null || true

if [ -n "$SOCKS5_HOST" ] && [ -n "$SOCKS5_PORT" ]; then
  echo "Configuring transparent SOCKS5 proxy via redsocks -> ${SOCKS5_HOST}:${SOCKS5_PORT}"

  # Generate redsocks config
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
    ip = ${SOCKS5_HOST};
    port = ${SOCKS5_PORT};
    type = socks5;
    login = "${SOCKS5_USER}";
    password = "${SOCKS5_PASS}";
}
EOF

  # Start redsocks in background
  redsocks -c /etc/redsocks.conf

  # iptables rules to redirect all outgoing TCP traffic through redsocks
  # Exclude traffic to the SOCKS5 proxy itself and local networks
  iptables -t nat -N REDSOCKS || true
  iptables -t nat -F REDSOCKS

  # Don't redirect traffic to the proxy server itself (avoid loop)
  iptables -t nat -A REDSOCKS -d "${SOCKS5_HOST}" -j RETURN
  # Don't redirect local/private traffic
  iptables -t nat -A REDSOCKS -d 0.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 10.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
  iptables -t nat -A REDSOCKS -d 169.254.0.0/16 -j RETURN
  iptables -t nat -A REDSOCKS -d 172.16.0.0/12 -j RETURN
  iptables -t nat -A REDSOCKS -d 192.168.0.0/16 -j RETURN
  iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
  iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

  # Redirect everything else to redsocks
  iptables -t nat -A REDSOCKS -p tcp -j REDIRECT --to-ports 12345

  # Apply to all outgoing TCP traffic
  iptables -t nat -A OUTPUT -p tcp -j REDSOCKS

  echo "SOCKS5 transparent proxy configured successfully"
else
  echo "No SOCKS5 proxy configured (SOCKS5_HOST/SOCKS5_PORT not set), running directly"
fi

# Delegate to the original entrypoint
exec /docker-entrypoint.sh "$@"
