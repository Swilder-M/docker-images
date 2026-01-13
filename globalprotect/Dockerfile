FROM --platform=$BUILDPLATFORM busybox AS copy-stage
ARG TARGETPLATFORM

WORKDIR /build

COPY xray-amd64 ./
COPY xray-arm64 ./
COPY xray-s390x ./
COPY run.sh ./
COPY hipreport.sh ./
COPY vpnc-script ./

RUN mkdir -p /build-output

RUN case "$TARGETPLATFORM" in \
        "linux/amd64") cp xray-amd64 /build-output/xray ;; \
        "linux/arm64") cp xray-arm64 /build-output/xray ;; \
        "linux/s390x") cp xray-s390x /build-output/xray ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac
COPY run.sh /build-output/run.sh
COPY hipreport.sh /build-output/hipreport.sh
COPY vpnc-script /build-output/vpnc-script

FROM alpine:latest AS final-stage

COPY --from=copy-stage /build-output/xray /usr/bin/xray
COPY --from=copy-stage /build-output/run.sh /run.sh
COPY --from=copy-stage /build-output/hipreport.sh /usr/bin/hipreport.sh
COPY --from=copy-stage /build-output/vpnc-script /etc/vpnc/vpnc-script

RUN apk update && \
    apk add --no-cache \
    openconnect \
    iptables \
    iproute2 \
    bash \
    curl

RUN chmod +x /run.sh && chmod +x /usr/bin/xray && chmod 755 /etc/vpnc/vpnc-script && chmod +x /usr/bin/hipreport.sh

HEALTHCHECK --interval=3m --timeout=5s \
  CMD curl -sSL ip.sb --interface tun0 || exit 1
