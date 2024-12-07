FROM alpine:latest

# 更新软件包列表并安装必要的软件包
RUN apk update && \
    apk add --no-cache \
    openconnect \
    iptables \
    bash \
    && apk clean && rm -rf /var/cache/apk/*

ENTRYPOINT ["/usr/sbin/openconnect"]
