#!/bin/sh

# 启动 Xray 服务
xray -c /etc/xray/config.json &

if [ $? -ne 0 ]; then
    echo "Failed to start Xray service."
    exit 1
fi

# 使用传入的环境变量启动 OpenConnect
openconnect --useragent "$USER_AGENT" \
               --version-string "$VERSION" \
               --servercert "$SERVER_CERT" \
               --cookie "$COOKIE" \
               $SERVER_URL
