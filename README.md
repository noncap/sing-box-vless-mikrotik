# singbox-vless-mikrotik

[sing-box](https://sing-box.sagernet.org) container for RouterOS, configured for VLESS with tun interface

- **Docker Hub**: <https://hub.docker.com/r/ani1ak/singbox-vless-mikrotik>
- **Source**: <https://github.com/Anidetrix/singbox-vless-mikrotik>

Required env variables:

```rsc
/container envs
add name=vless key=REMOTE_ADDRESS value=XXX.vless-server.com
add name=vless key=ID value=XXXX-XXXX-XXXX-XXXX
add name=vless key=SERVER_NAME value=yahoo.com
add name=vless key=PUBLIC_KEY value=XXXX
add name=vless key=SHORT_ID value=XXXX
```

Optional env variables:

```rsc
/container envs
add name=vless key=LOG_LEVEL value=warn
add name=vless key=DNS value=local
add name=vless key=TUN_STACK value=system
add name=vless key=REMOTE_PORT value=443
add name=vless key=FLOW value=xtls-rprx-vision
add name=vless key=FINGER_PRINT value=chrome
```

Rules env variables:

```rsc
/container envs
add name=vless key=WHITELIST_MODE value=1
add name=vless key=RULESETS value=https://example.com/ruleset_bin.srs,https://example.com/ruleset_src.json
add name=vless key=DOMAINS value=domain1.com,domain2.net
```
