#!/bin/sh

nohup /usr/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &

echo $COOKIE | openconnect --protocol=gp \
  --useragent "PAN GlobalProtect" \
  --user $USERNAME \
  --os linux-64 \
  --usergroup gateway:prelogin-cookie \
  --passwd-on-stdin $SERVER_URL
