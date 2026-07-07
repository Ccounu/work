#!/bin/bash
# cleanup hook: 证书签发后可在阿里云控制台删除 _acme-challenge TXT 记录
LOG="/tmp/acme-dns-challenges.log"
echo "CLEANUP ${CERTBOT_DOMAIN} ${CERTBOT_VALIDATION}" >> "$LOG"
