#!/bin/sh

nohup /usr/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &

if [ "${HIP_CHECK:-0}" -eq 1 ]; then
  echo $COOKIE | openconnect --protocol=gp \
    --useragent "PAN GlobalProtect" \
    --user $USERNAME \
    --os linux-64 \
    --usergroup gateway:prelogin-cookie \
    --csd-wrapper=/usr/bin/hipreport.sh \
    --passwd-on-stdin $SERVER_URL -vvv
else
  echo $COOKIE | openconnect --protocol=gp \
    --useragent "PAN GlobalProtect" \
    --user $USERNAME \
    --os linux-64 \
    --usergroup gateway:prelogin-cookie \
    --passwd-on-stdin $SERVER_URL -vvv
fi
