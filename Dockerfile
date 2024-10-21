ARG SINGBOX_VERSION=v1.11.0-alpha.1

# FROM superng6/singbox:${SINGBOX_VERSION}
FROM ghcr.io/sagernet/sing-box:${SINGBOX_VERSION} AS sing-box
LABEL maintainer="Anton Kudriavtsev <boblobl4@gmail.com>"

FROM alpine:3.20.3
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
