ARG SINGBOX_VERSION=v1.10.1

FROM ghcr.io/sagernet/sing-box:${SINGBOX_VERSION} AS sing-box
FROM ghcr.io/jqlang/jq:latest AS jq

FROM alpine:latest AS certs
RUN apk add --no-cache ca-certificates-bundle

FROM busybox:musl
LABEL maintainer="Anton Kudriavtsev <anidetrix@proton.me>"
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --from=jq /usr/local/bin/jq /bin/jq
COPY --from=certs /etc/ssl/certs /etc/ssl/certs
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
