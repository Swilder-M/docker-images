FROM --platform=$BUILDPLATFORM busybox AS copy-stage
ARG TARGETPLATFORM

WORKDIR /build

COPY snell-server-amd64 ./
COPY snell-server-arm64 ./
COPY run-openconnect.sh ./

RUN mkdir -p /build-output

RUN case "$TARGETPLATFORM" in \
        "linux/amd64") cp snell-server-amd64 /build-output/snell-server ;; \
        "linux/arm64") cp snell-server-arm64 /build-output/snell-server ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac
COPY run-openconnect.sh /build-output/run-openconnect.sh

FROM alpine:latest AS final-stage

COPY --from=copy-stage /build-output/snell-server /usr/bin/snell-server
COPY --from=copy-stage /build-output/run-openconnect.sh /run-openconnect.sh

RUN apk update && \
    apk add --no-cache \
    openconnect \
    iptables \
    iproute2 \
    bash \
    curl

RUN chmod +x /run-openconnect.sh && chmod +x /usr/bin/snell-server

HEALTHCHECK --interval=10m --timeout=5s \
  CMD curl -sSL ip.sb || exit 1

# ENTRYPOINT ["/entrypoint.sh"]
