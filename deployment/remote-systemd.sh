#!/bin/bash
set -euo pipefail

sudo tee /etc/systemd/system/railway-backend.service > /dev/null <<'UNIT'
[Unit]
Description=Railway Ticket Risk Backend
After=network.target mysql.service redis-server.service
Wants=mysql.service redis-server.service

[Service]
Type=simple
User=ikun
WorkingDirectory=/opt/railway/app
EnvironmentFile=/opt/railway/secrets/railway.env
ExecStart=/usr/bin/java -Xms128m -Xmx256m -jar /opt/railway/app/app.jar
SuccessExitStatus=143
Restart=on-failure
RestartSec=5
StandardOutput=append:/opt/railway/logs/backend/app.log
StandardError=append:/opt/railway/logs/backend/app.log

[Install]
WantedBy=multi-user.target
UNIT

sudo systemctl daemon-reload
sudo systemctl enable railway-backend
sudo systemctl restart railway-backend
sleep 8
curl -sf http://127.0.0.1:8080/api/health
echo
echo SYSTEMD_OK
