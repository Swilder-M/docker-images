#!/bin/sh

snell-server -c /etc/snell-server.conf >> /var/log/snell.log 2>&1 &

if [ $? -ne 0 ]; then
    echo "Failed to start Snell service."
    exit 1
fi

# 使用传入的环境变量启动 OpenConnect
openconnect -v \
  --timestamp \
  --force-dpd=10 \
  --useragent "AnyConnect Linux_64 4.7.00136" \
  --version-string "4.7.00136" \
  --servercert "$SERVER_CERT" \
  --cookie "$COOKIE" \
  $SERVER_URL
