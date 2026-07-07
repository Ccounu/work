#!/bin/bash
set -euo pipefail

CREDS="/opt/railway/secrets/aliyun-dns.ini"
CERTBOT="/opt/certbot/bin/certbot"

if [[ ! -f "$CREDS" ]]; then
  echo "MISSING_ALIYUN_CREDS"
  exit 2
fi

sudo "$CERTBOT" certonly \
  --non-interactive \
  --agree-tos \
  --register-unsafely-without-email \
  --authenticator dns-aliyun \
  --dns-aliyun-credentials "$CREDS" \
  --cert-name wangyanming.xyz \
  --key-type ecdsa \
  -d "wangyanming.xyz" \
  -d "*.wangyanming.xyz"

echo WILDCARD_CERT_OK
