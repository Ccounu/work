#!/bin/bash
set -euo pipefail

DB_PASS=$(openssl rand -hex 12)
REDIS_PASS=$(openssl rand -hex 12)
JWT_SECRET=$(openssl rand -hex 32)
PAY_SECRET=$(openssl rand -hex 24)
REF_SECRET=$(openssl rand -hex 24)

sudo mkdir -p /opt/railway/app /opt/railway/frontend /opt/railway/data/avatars /opt/railway/logs/backend /opt/railway/secrets
sudo chown -R ikun:ikun /opt/railway

sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS railway_ticket_risk CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'railway'@'localhost' IDENTIFIED BY '${DB_PASS}';
ALTER USER 'railway'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON railway_ticket_risk.* TO 'railway'@'localhost';
FLUSH PRIVILEGES;
SQL

sudo sed -i '/^requirepass /d' /etc/redis/redis.conf
sudo sed -i '/^maxmemory /d' /etc/redis/redis.conf
sudo sed -i '/^maxmemory-policy /d' /etc/redis/redis.conf
printf '\nrequirepass %s\nmaxmemory 64mb\nmaxmemory-policy allkeys-lru\n' "$REDIS_PASS" | sudo tee -a /etc/redis/redis.conf > /dev/null
sudo systemctl restart redis-server

cat > /opt/railway/secrets/railway.env <<ENV
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080
SPRING_DATASOURCE_URL=jdbc:mysql://127.0.0.1:3306/railway_ticket_risk?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Hong_Kong
SPRING_DATASOURCE_USERNAME=railway
SPRING_DATASOURCE_PASSWORD=${DB_PASS}
SPRING_REDIS_HOST=127.0.0.1
SPRING_REDIS_PORT=6379
SPRING_REDIS_PASSWORD=${REDIS_PASS}
JWT_SECRET=${JWT_SECRET}
PAYMENT_CALLBACK_SECRET=${PAY_SECRET}
REFUND_CALLBACK_SECRET=${REF_SECRET}
RAILWAY_DEMO_DATA_ENABLED=true
AVATAR_STORAGE_DIR=/opt/railway/data/avatars
ENV
chmod 600 /opt/railway/secrets/railway.env

redis-cli -a "$REDIS_PASS" ping
mysql -urailway -p"$DB_PASS" -e "SELECT 1 AS ok" railway_ticket_risk
echo CONFIG_OK
