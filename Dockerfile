FROM --platform=$BUILDPLATFORM busybox AS copy-stage
ARG TARGETPLATFORM

WORKDIR /build

COPY xray-amd64 ./
COPY xray-arm64 ./
COPY run-openconnect.sh ./

RUN mkdir -p /build-output

RUN case "$TARGETPLATFORM" in \
        "linux/amd64") cp xray-amd64 /build-output/xray ;; \
        "linux/arm64") cp xray-arm64 /build-output/xray ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac
COPY run-openconnect.sh /build-output/run-openconnect.sh

FROM alpine:latest AS final-stage

COPY --from=copy-stage /build-output/xray /usr/bin/xray
COPY --from=copy-stage /build-output/run-openconnect.sh /run-openconnect.sh

RUN apk update && \
    apk add --no-cache \
    openconnect \
    iptables \
    iproute2 \
    bash \
    curl

RUN chmod +x /run-openconnect.sh && chmod +x /usr/bin/xray

HEALTHCHECK --interval=3m --timeout=5s \
  CMD curl -sSL ip.sb || exit 1

# ENTRYPOINT ["/entrypoint.sh"]
