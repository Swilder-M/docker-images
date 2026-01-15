#!/bin/sh

SESSION_FILE="/var/lib/openconnect/session"
mkdir -p /var/lib/openconnect

nohup /usr/bin/xray run -c /etc/xray.json > /var/log/xray.log 2>&1 &

# 公共参数
if [ "${HIP_CHECK:-0}" -eq 1 ]; then
  CSD_ARG="--csd-wrapper=/usr/bin/hipreport.sh"
else
  CSD_ARG=""
fi

# 尝试使用保存的会话 cookie
if [ -f "$SESSION_FILE" ]; then
  echo "[*] 尝试使用保存的会话 cookie..."
  SESSION_COOKIE=$(cat "$SESSION_FILE" | tr -d "'")

  openconnect --protocol=gp \
    --useragent "PAN GlobalProtect" \
    --user "$USERNAME" \
    --os linux-64 \
    --cookie "$SESSION_COOKIE" \
    $CSD_ARG \
    "$SERVER_URL" -vvv &
  OC_PID=$!

  sleep 10
  if kill -0 $OC_PID 2>/dev/null; then
    echo "[+] 会话恢复成功"
    wait $OC_PID
    exit $?
  else
    echo "[-] 会话 cookie 已失效，使用 prelogin-cookie 重新认证"
    rm -f "$SESSION_FILE"
  fi
fi

# 使用 prelogin-cookie 认证
echo "[*] 使用 prelogin-cookie 认证..."

AUTH_OUTPUT=$(echo "$COOKIE" | openconnect --protocol=gp \
  --useragent "PAN GlobalProtect" \
  --user "$USERNAME" \
  --os linux-64 \
  --usergroup gateway:prelogin-cookie \
  --authenticate \
  --passwd-on-stdin \
  $CSD_ARG \
  "$SERVER_URL" 2>&1)

AUTH_EXIT=$?
echo "[DEBUG] AUTH_OUTPUT:"
echo "$AUTH_OUTPUT"
echo "[DEBUG] END"

if [ $AUTH_EXIT -ne 0 ]; then
  echo "[-] 认证失败: $AUTH_OUTPUT"
  exit 1
fi

# 提取会话 cookie
# openconnect --authenticate 输出格式: COOKIE='authcookie=xxx&portal=xxx&user=xxx'
SESSION_COOKIE=$(echo "$AUTH_OUTPUT" | grep "^COOKIE=" | sed 's/^COOKIE=//' | tr -d "'")

if [ -n "$SESSION_COOKIE" ]; then
  echo "$SESSION_COOKIE" > "$SESSION_FILE"
  echo "[+] 会话 cookie 已保存: $SESSION_COOKIE"
else
  echo "[-] 未能提取会话 cookie，使用原始方式连接"
  echo "$COOKIE" | openconnect --protocol=gp \
    --useragent "PAN GlobalProtect" \
    --user "$USERNAME" \
    --os linux-64 \
    --usergroup gateway:prelogin-cookie \
    --passwd-on-stdin \
    $CSD_ARG \
    "$SERVER_URL" -vvv
  exit $?
fi

# 使用认证信息建立连接
echo "[*] 建立 VPN 连接..."
openconnect --protocol=gp \
  --useragent "PAN GlobalProtect" \
  --user "$USERNAME" \
  --os linux-64 \
  --cookie "$SESSION_COOKIE" \
  $CSD_ARG \
  "$SERVER_URL" -vvv
