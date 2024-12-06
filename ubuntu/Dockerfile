FROM ubuntu:24.04

# 环境变量设置，用于不询问的情况下安装软件包
ENV DEBIAN_FRONTEND=noninteractive

# 更新并安装必要的软件包
RUN apt-get update && apt-get install -y \
    xubuntu-core^ \
    xrdp \
    dbus-x11 \
    systemd \
    sudo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 启用 systemd 初始化
ENV container docker

STOPSIGNAL SIGRTMIN+3

# 启动 xrdp 服务
RUN service xrdp start

# 开启 systemd 服务
CMD ["/lib/systemd/systemd"]

# 开放 3389 端口用于 xrdp 和 18123 端口用于其他用途
EXPOSE 3389 18123
