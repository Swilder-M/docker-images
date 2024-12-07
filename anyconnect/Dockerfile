FROM --platform=$BUILDPLATFORM busybox AS copy-stage
ARG TARGETPLATFORM

RUN mkdir -p /build-output

RUN case "$TARGETPLATFORM" in \
        "linux/amd64") cp ./xray-amd64 /build-output/xray ;; \
        "linux/arm64") cp ./xray-arm64 /build-output/xray ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac

FROM alpine:latest AS final-stage

COPY --from=copy-stage /build-output/xray /usr/bin/xray
RUN apk update && \
    apk add --no-cache \
    openconnect \
    iptables \
    iproute2 \
    bash

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && chmod +x /usr/bin/xray

ENTRYPOINT ["/entrypoint.sh"]
