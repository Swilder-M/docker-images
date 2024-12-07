FROM --platform=$BUILDPLATFORM busybox AS copy-stage
ARG TARGETPLATFORM

WORKDIR /build

COPY snell-server-amd64 ./
COPY snell-server-arm64 ./
COPY entrypoint.sh ./

RUN mkdir -p /build-output

RUN case "$TARGETPLATFORM" in \
        "linux/amd64") cp snell-server-amd64 /build-output/snell-server ;; \
        "linux/arm64") cp snell-server-arm64 /build-output/snell-server ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac
COPY entrypoint.sh /build-output/entrypoint.sh

FROM alpine:latest AS final-stage

COPY --from=copy-stage /build-output/snell-server /usr/bin/snell-server
COPY --from=copy-stage /build-output/entrypoint.sh /entrypoint.sh

RUN apk update && \
    apk add --no-cache \
    openconnect \
    iptables \
    iproute2 \
    bash

RUN chmod +x /entrypoint.sh && chmod +x /usr/bin/snell-server

ENTRYPOINT ["/entrypoint.sh"]
