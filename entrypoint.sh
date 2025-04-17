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

cat << EOF > /singbox.json
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
    "final": "${out}"
  },
  "experimental": {
    "cache_file": {
      "enabled": true
    }
  }
}
EOF

IFS=,
if [ -n "${RULESETS}" ]; then
	i=1
	_rulesets=""
	for url in ${RULESETS}; do
		_tmp=$(mktemp)
		tag="ruleset-${i}"
		case "${url}" in
		*.json) format=source ;;
		*) format=binary ;;
		esac
		cat <<- EOF > ${_tmp}
			{
			  "route": {
			    "rule_set": [
			      {
			        "tag": "${tag}",
			        "type": "remote",
			        "format": "${format}",
			        "url": "${url}",
			        "download_detour": "vless-out",
			        "update_interval": "2h"
			      }
			    ]
			  }
			}
		EOF
		i=$((i + 1))
		_rulesets="${_rulesets}\"${tag}\","
		sing-box merge singbox.json -D / -c /singbox.json -c ${_tmp} --disable-color 2> /dev/null
		rm -f ${_tmp}
		unset _tmp
	done
	_tmp=$(mktemp)
	cat <<- EOF > ${_tmp}
		{
		  "route": {
		    "rules": [
		      {
		        "rule_set": [${_rulesets%?}],
		        "action": "route",
		        "outbound": "${out_rules}"
		      }
		    ]
		  }
		}
	EOF
	sing-box merge singbox.json -D / -c /singbox.json -c ${_tmp} --disable-color 2> /dev/null
	rm -f ${_tmp}
	unset _rulesets _tmp
fi
if [ -n "${DOMAINS}" ]; then
	_domains=""
	for domain in ${DOMAINS}; do _domains="${_domains}\"${domain}\","; done
	_tmp=$(mktemp)
	cat <<- EOF > ${_tmp}
		{
		  "route": {
		    "rules": [
		      {
		        "domain_suffix": [${_domains%?}],
		        "action": "route",
		        "outbound": "${out_rules}"
		      }
		    ]
		  }
		}
	EOF
	sing-box merge singbox.json -D / -c /singbox.json -c ${_tmp} --disable-color 2> /dev/null
	rm -f ${_tmp}
	unset _domains _tmp
fi

_tmp=$(mktemp)
echo '{"route":{"rules":[{"port":[53],"action":"hijack-dns"}]}}' > ${_tmp}
sing-box merge singbox.json -D / -c /singbox.json -c ${_tmp} --disable-color 2> /dev/null
rm -f ${_tmp}
unset _tmp

sing-box check -c /singbox.json --disable-color || exit 1
exec sing-box run -c /singbox.json --disable-color
