#!/bin/sh

nohup /usr/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &

openconnect -v \
  --timestamp \
  --force-dpd=10 \
  --useragent "AnyConnect Linux_64 4.7.00136" \
  --version-string "4.7.00136" \
  --servercert "$SERVER_CERT" \
  --cookie "$COOKIE" \
  $SERVER_URL
