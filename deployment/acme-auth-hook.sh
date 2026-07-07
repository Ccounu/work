#!/bin/bash
set -euo pipefail

LOG="/tmp/acme-dns-challenges.log"
RECORD="_acme-challenge.${CERTBOT_DOMAIN}"
echo "=== $(date -Is) ===" >> "$LOG"
echo "DOMAIN=${CERTBOT_DOMAIN}" >> "$LOG"
echo "TXT_NAME=${RECORD}" >> "$LOG"
echo "TXT_VALUE=${CERTBOT_VALIDATION}" >> "$LOG"
echo "请在阿里云 DNS 为 ${CERTBOT_DOMAIN} 添加 TXT 记录：" >> "$LOG"
echo "  主机记录: _acme-challenge（泛域名与主域名均用此主机记录）" >> "$LOG"
echo "  记录值: ${CERTBOT_VALIDATION}" >> "$LOG"

# 等待 DNS 传播，最多 20 分钟
for i in $(seq 1 120); do
  if dig +short TXT "$RECORD" @223.5.5.5 | tr -d '"' | grep -Fq "$CERTBOT_VALIDATION"; then
    echo "PROPAGATED after ${i}0s for ${CERTBOT_DOMAIN}" >> "$LOG"
    exit 0
  fi
  sleep 10
done

echo "TIMEOUT waiting DNS for ${CERTBOT_DOMAIN}" >> "$LOG"
exit 1
