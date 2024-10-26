#!/bin/sh
# log
LOG_LEVEL="${LOG_LEVEL:-warn}"

# dns
DNS="${DNS:-local}"

# tun
TUN_STACK="${TUN_STACK:-system}"

# vless
REMOTE_ADDRESS="${REMOTE_ADDRESS:-}"
REMOTE_PORT="${REMOTE_PORT:-443}"
ID="${ID:-}"
FLOW="${FLOW:-xtls-rprx-vision}"
SERVER_NAME="${SERVER_NAME:-}"
FINGER_PRINT="${FINGER_PRINT:-chrome}"
PUBLIC_KEY="${PUBLIC_KEY:-}"
SHORT_ID="${SHORT_ID:-}"

cat > /singbox.json << EOF
{
  "log": {
    "level": "${LOG_LEVEL}",
    "timestamp": false
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-direct",
        "address": "${DNS}",
        "address_resolver": "dns-local",
        "detour": "direct"
      },
      {
        "tag": "dns-local",
        "address": "local",
        "detour": "direct"
      }
    ]
  },
  "inbounds": [
    {
      "type": "tun",
      "tag": "tun-in",
      "interface_name": "tun0",
      "address": ["198.18.0.1/30"],
      "mtu": 1500,
      "auto_route": true,
      "strict_route": true,
      "stack": "${TUN_STACK}",
      "sniff": false,
      "route_exclude_address": ["192.168.0.0/16", "172.16.0.0/12", "10.0.0.0/8"]
    }
  ],
  "outbounds": [
    {
      "type": "vless",
      "tag": "vless-out",
      "server": "${REMOTE_ADDRESS}",
      "server_port": ${REMOTE_PORT},
      "uuid": "${ID}",
      "flow": "${FLOW}",
      "tls": {
        "enabled": true,
        "server_name": "${SERVER_NAME}",
        "utls": {
          "enabled": true,
          "fingerprint": "${FINGER_PRINT}"
        },
        "reality": {
          "enabled": true,
          "public_key": "${PUBLIC_KEY}",
          "short_id": "${SHORT_ID}"
        }
      },
      "packet_encoding": "xudp"
    },
    {
      "type": "dns",
      "tag": "dns-out"
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "inbound": ["tun-in"],
        "outbound": "vless-out"
      },
      {
        "port": [53],
        "outbound": "dns-out"
      }
    ]
  }
}
EOF

sing-box check -c /singbox.json --disable-color || exit 1
exec sing-box run -c /singbox.json --disable-color
