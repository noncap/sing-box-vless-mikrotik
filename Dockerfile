ARG SINGBOX_VERSION=v1.11.8

FROM ghcr.io/sagernet/sing-box:${SINGBOX_VERSION} AS sing-box

FROM alpine:latest
LABEL maintainer="Anton Kudriavtsev <anidetrix@proton.me>"
RUN apk add --no-cache bash tzdata ca-certificates nftables runit && apk --purge del apk-tools
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
COPY --chown=0:0 --chmod=755 service.sh /service/run
ENTRYPOINT ["/entrypoint.sh"]
