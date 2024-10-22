ARG SINGBOX_VERSION=v1.10.1

FROM ghcr.io/sagernet/sing-box:${SINGBOX_VERSION} AS sing-box
LABEL maintainer="Anton Kudriavtsev <anidetrix@proton.me>"

FROM alpine:3.20
# RUN apk add --no-cache tzdata ca-certificates nftables
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
