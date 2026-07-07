#!/bin/bash
set -euo pipefail

sudo tee /etc/nginx/sites-available/railway > /dev/null <<'NGINX'
upstream railway_backend {
    server 127.0.0.1:8080;
    keepalive 16;
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name forbianlu.top 104.208.113.212 _;

    root /opt/railway/frontend;
    index index.html;

    client_max_body_size 20m;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;

    location = / {
        try_files /index.html =404;
    }

    location = /passenger {
        try_files /passenger.html =404;
    }

    location = /admin {
        try_files /admin.html =404;
    }

    location /api/ {
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";
        proxy_read_timeout 60s;
        proxy_send_timeout 60s;
        proxy_pass http://railway_backend;
    }

    location ~* ^/(?:h2-console|swagger-ui|v3/api-docs|webjars)(?:/|$) {
        return 404;
    }

    location ~* \.(?:css|js|png|jpg|jpeg|gif|ico|svg|webp)$ {
        expires 30d;
        try_files $uri =404;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/railway /etc/nginx/sites-enabled/railway
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
echo NGINX_OK
