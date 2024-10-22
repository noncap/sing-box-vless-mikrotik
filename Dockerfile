ARG SINGBOX_VERSION=v1.10.1

FROM ghcr.io/sagernet/sing-box:${SINGBOX_VERSION} AS sing-box
FROM alpine:3.20 as deps
RUN apk add --no-cache tzdata ca-certificates

FROM busybox:1.37-musl
LABEL maintainer="Anton Kudriavtsev <anidetrix@proton.me>"
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --from=deps /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=deps /etc/ssl /etc/ssl
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
