#!/bin/sh
# log
LOG_LEVEL="${LOG_LEVEL:-warn}"

# dns
DNS="${DNS:-8.8.8.8}"

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

# rules
WHITELIST_MODE="${WHITELIST_MODE:-}"
RULESETS="${RULESETS:-}"
DOMAINS="${DOMAINS:-}"

out="vless-out"
out_rules="bypass"
if [ -n "${WHITELIST_MODE}" ]; then
  _out=${out}
  out=${out_rules}
  out_rules=${_out}
  unset _out
fi

cat > /singbox.json << EOF
{
  "log": {
    "level": "${LOG_LEVEL}",
    "timestamp": false
  },
  "dns": {
    "servers": [
      {
        "tag": "dns-proxy",
        "address": "${DNS}",
        "address_resolver": "dns-direct",
        "detour": "vless-out"
      },
      {
        "tag": "dns-direct",
        "address": "${DNS}",
        "address_resolver": "dns-local",
        "detour": "bypass"
      },
      {
        "tag": "dns-local",
        "address": "local",
        "detour": "bypass"
      }
    ],
    "strategy": "prefer_ipv4",
    "independent_cache": true,
    "reverse_mapping": true
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
      "route_exclude_address": [
        "192.168.0.0/16",
        "172.16.0.0/12",
        "10.0.0.0/8",
        "fc00::/7"
      ]
    },
    {
      "type": "socks",
      "tag": "socks-in",
      "listen": "$(ip -o -f inet address show eth0 | awk '/scope global/ {print $4}' | cut -d/ -f1)",
      "listen_port": 1080
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
      "type": "direct",
      "tag": "bypass"
    }
  ],
  "route": {
    "auto_detect_interface": true,
    "rules": [
      {
        "port": [53],
        "action": "hijack-dns"
      }
    ],
    "rule_set": [],
    "final": "${out}"
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF

if [ -n "${DOMAINS}" ]; then
  OLDIFS=$IFS
  IFS=,
  for domain in ${DOMAINS}; do
    jq -r --arg domain ${domain} --arg out ${out_rules} \
      '.route.rules += [{"domain_suffix":$domain,"action":"route","outbound":$out}]' /singbox.json > /singbox.json.new
    mv /singbox.json.new /singbox.json
  done
  IFS=$OLDIFS
fi

if [ -n "${RULESETS}" ]; then
  OLDIFS=$IFS
  IFS=,
  i=1
  for url in ${RULESETS}; do
    case "${url}" in
    *.json) format=source ;;
    *) format=binary ;;
    esac
    jq -r --arg tag "ruleset-${i}" --arg format ${format} --arg url ${url} --arg out ${out_rules} \
      '.route.rule_set += [{"tag":$tag,"type":"remote","format":$format,"url":$url,"download_detour":"vless-out","update_interval":"2h"}]
     | .route.rules += [{"rule_set":$tag,"action":"route","outbound":$out}]' /singbox.json > /singbox.json.new
    mv /singbox.json.new /singbox.json
    i=$((i + 1))
  done
  IFS=$OLDIFS
fi

sing-box check -c /singbox.json --disable-color || exit 1
exec sing-box run -c /singbox.json --disable-color
