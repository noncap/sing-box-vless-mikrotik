ARG SINGBOX_VERSION=v1.10.1

FROM ghcr.io/sagernet/sing-box:${SINGBOX_VERSION} AS sing-box

FROM alpine:latest AS certs
RUN apk add --no-cache ca-certificates-bundle

# jq #
FROM alpine:latest AS jq
RUN apk add --no-cache build-base
WORKDIR /app
COPY . /app
RUN autoreconf -i \
    && ./configure \
    --disable-docs \
    --with-oniguruma=builtin \
    --enable-static \
    --enable-all-static \
    --prefix=/usr/local \
    && make -j$(nproc) \
    && make check VERBOSE=yes \
    && make install-strip
# --- #

FROM busybox:musl
LABEL maintainer="Anton Kudriavtsev <anidetrix@proton.me>"
COPY --from=sing-box /usr/local/bin/sing-box /bin/sing-box
COPY --from=jq /usr/local/bin/jq /bin/jq
COPY --from=certs /etc/ssl/certs /etc/ssl/certs
COPY --chown=0:0 --chmod=755 entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
