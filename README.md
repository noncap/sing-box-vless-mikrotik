# singbox-vless-mikrotik

sing-box container for RouterOS, configured for VLESS with tun interface

- **Docker Hub**: https://hub.docker.com/r/ani1ak/singbox-vless-mikrotik
- **Source**: https://github.com/Anidetrix/singbox-vless-mikrotik

Required env variables:

```
/container envs
add name=vless key=REMOTE_ADDRESS value=XXX.vless-server.com
add name=vless key=ID value=XXXX-XXXX-XXXX-XXXX
add name=vless key=SERVER_NAME value=yahoo.com
add name=vless key=PUBLIC_KEY value=XXXX
add name=vless key=SHORT_ID value=XXXX
```

Optional env variables:

```
/container envs
add name=vless key=LOG_LEVEL value=debug
add name=vless key=REMOTE_PORT value=443
add name=vless key=FLOW value=xtls-rprx-vision
add name=vless key=FINGER_PRINT value=chrome
```
