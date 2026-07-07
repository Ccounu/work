# Ubuntu 原生全栈部署指南（MySQL + Redis + Nginx）

适用于 Azure 等 Linux 云服务器（含 2 核 1GB 小内存机器），不依赖 Docker。本文以本项目为例，步骤可复用到其他 Spring Boot + MySQL + Redis 项目。

## 架构概览

```text
用户浏览器
    ↓ HTTPS
Nginx（静态前端 + 反代 /api）
    ↓ HTTP 127.0.0.1:8080
Spring Boot JAR（prod profile）
    ↓                    ↓
MySQL 8（本机）      Redis 7（本机）
```

前端在同域访问时自动走 `/api`（见 `frontend/app.js`），无需改前端代码。

## 前置条件

- Ubuntu 22.04 / 24.04 LTS（Azure 学生机常见）
- 域名已解析到服务器公网 IP（A 记录）
- Azure NSG 放行：`22`（SSH）、`80`（HTTP）、`443`（HTTPS）
- 本地或 CI 可执行 `mvn package` 构建 JAR

## 1. 服务器初始化

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget unzip nginx certbot python3-certbot-nginx
```

### 1.1 小内存机器建议开启 Swap（1GB 必做）

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
free -h
```

## 2. 安装 Java 8

本项目基于 Java 8 + Spring Boot 2.7：

```bash
sudo apt install -y openjdk-8-jre-headless
java -version
```

## 3. 安装并配置 MySQL 8

```bash
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql
```

### 3.1 小内存优化（1GB 服务器）

编辑 `/etc/mysql/mysql.conf.d/99-low-memory.cnf`：

```ini
[mysqld]
innodb_buffer_pool_size = 64M
max_connections = 30
performance_schema = OFF
```

```bash
sudo systemctl restart mysql
```

### 3.2 创建数据库与用户

将 `YOUR_DB_PASSWORD` 替换为强密码：

```bash
sudo mysql <<'SQL'
CREATE DATABASE IF NOT EXISTS railway_ticket_risk
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'railway'@'localhost' IDENTIFIED BY 'YOUR_DB_PASSWORD';
GRANT ALL PRIVILEGES ON railway_ticket_risk.* TO 'railway'@'localhost';
FLUSH PRIVILEGES;
SQL
```

## 4. 安装并配置 Redis

```bash
sudo apt install -y redis-server
```

编辑 `/etc/redis/redis.conf`（或通过 `sudo nano` 修改）：

```conf
bind 127.0.0.1 ::1
protected-mode yes
requirepass YOUR_REDIS_PASSWORD
maxmemory 64mb
maxmemory-policy allkeys-lru
```

```bash
sudo systemctl restart redis-server
redis-cli -a 'YOUR_REDIS_PASSWORD' ping
# 应返回 PONG
```

## 5. 目录规划

```bash
sudo mkdir -p /opt/railway/{app,frontend,data/avatars,logs/backend,secrets,backups}
sudo chown -R $USER:$USER /opt/railway
```

| 路径 | 用途 |
| --- | --- |
| `/opt/railway/app/app.jar` | 后端 JAR |
| `/opt/railway/frontend/` | 前端静态文件 |
| `/opt/railway/secrets/railway.env` | 环境变量（权限 600） |
| `/opt/railway/data/avatars/` | 头像上传目录 |
| `/opt/railway/logs/backend/` | 应用日志 |

## 6. 构建并上传 JAR

在开发机项目根目录：

```bash
cd backend
mvn -DskipTests package
```

上传到服务器（示例，按实际 IP 修改）：

```bash
scp target/railway-ticket-risk-system-0.1.0.jar user@YOUR_SERVER_IP:/opt/railway/app/app.jar
scp -r ../frontend/* user@YOUR_SERVER_IP:/opt/railway/frontend/
```

## 7. 配置环境变量

创建 `/opt/railway/secrets/railway.env`：

```bash
chmod 600 /opt/railway/secrets/railway.env
```

内容示例（**全部替换为随机强密码**）：

```env
SPRING_PROFILES_ACTIVE=prod
SERVER_PORT=8080

SPRING_DATASOURCE_URL=jdbc:mysql://127.0.0.1:3306/railway_ticket_risk?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Hong_Kong
SPRING_DATASOURCE_USERNAME=railway
SPRING_DATASOURCE_PASSWORD=YOUR_DB_PASSWORD

SPRING_REDIS_HOST=127.0.0.1
SPRING_REDIS_PORT=6379
SPRING_REDIS_PASSWORD=YOUR_REDIS_PASSWORD

JWT_SECRET=YOUR_JWT_SECRET_AT_LEAST_32_CHARS
PAYMENT_CALLBACK_SECRET=YOUR_PAYMENT_CALLBACK_SECRET
REFUND_CALLBACK_SECRET=YOUR_REFUND_CALLBACK_SECRET

RAILWAY_DEMO_DATA_ENABLED=true
AVATAR_STORAGE_DIR=/opt/railway/data/avatars
```

生成随机密钥：

```bash
openssl rand -hex 32
```

## 8. systemd 守护后端

创建 `/etc/systemd/system/railway-backend.service`：

```ini
[Unit]
Description=Railway Ticket Risk Backend
After=network.target mysql.service redis-server.service
Wants=mysql.service redis-server.service

[Service]
Type=simple
User=YOUR_LINUX_USER
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
```

将 `YOUR_LINUX_USER` 改为实际用户名（如 `azureuser`）。

```bash
sudo systemctl daemon-reload
sudo systemctl enable railway-backend
sudo systemctl start railway-backend
sudo systemctl status railway-backend
curl -s http://127.0.0.1:8080/api/health
```

## 9. 配置 Nginx

复制项目模板并修改域名：

```bash
sudo cp /opt/railway/frontend/../deployment/nginx-forbianlu.top.conf /etc/nginx/sites-available/railway
# 若未上传 deployment 目录，可直接新建，见下文「Nginx 配置要点」
```

将 `server_name`、SSL 证书路径中的域名改为你的域名，然后：

```bash
sudo ln -sf /etc/nginx/sites-available/railway /etc/nginx/sites-enabled/railway
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

### Nginx 配置要点

- `root` 指向 `/opt/railway/frontend`
- `/api/` 反代到 `127.0.0.1:8080`
- 生产环境屏蔽 Swagger / H2 控制台路径
- 8080 端口不对公网开放，仅本机访问

项目参考配置：`deployment/nginx-forbianlu.top.conf`

## 10. 申请 HTTPS 证书（Let's Encrypt）

```bash
sudo certbot --nginx -d YOUR_DOMAIN.com
```

按提示选择自动跳转 HTTPS。证书自动续期：

```bash
sudo certbot renew --dry-run
```

若使用 Cloudflare 等 CDN，答辩演示阶段可先直连源站 IP，避免缓存干扰。

## 11. 验证清单

```bash
# 后端健康
curl -s https://YOUR_DOMAIN.com/api/health

# 服务状态
sudo systemctl status railway-backend nginx mysql redis-server

# 内存占用
free -h
```

浏览器访问：

```text
https://YOUR_DOMAIN.com/           # 入口页
https://YOUR_DOMAIN.com/passenger  # 乘客端
https://YOUR_DOMAIN.com/admin      # 管理端
```

演示账号见项目 README。

## 12. 常用运维命令

```bash
# 查看后端日志
tail -f /opt/railway/logs/backend/app.log

# 重启后端
sudo systemctl restart railway-backend

# 更新 JAR 后
sudo systemctl restart railway-backend

# 更新前端后
sudo systemctl reload nginx
```

## 13. 答辩 / 演示建议

- 答辩前 30 分钟启动并完整走一遍：登录 → 查票 → 下单 → 支付 → 管理端看风险
- Azure 学生 VM 可能被关机，答辩当天确认 Running
- 笔记本本地 H2 模式作为备用
- 论文可写：「生产环境采用 Ubuntu 原生部署 MySQL 8、Redis 7，Nginx 提供 HTTPS 与同域 API 反代，Spring Boot 以 systemd 守护进程运行」

## 14. 迁移到其他 Spring Boot 项目的通用步骤

| 步骤 | 通用做法 |
| --- | --- |
| 运行时 | 安装对应 JDK 版本（8/11/17/21） |
| 数据库 | MySQL/PostgreSQL 本机安装 + 建库建用户 |
| 缓存 | Redis 本机安装 + requirepass + maxmemory |
| 应用 | `java -jar` + systemd + EnvironmentFile |
| 前端 | Nginx root + `/api/` 反代 |
| 安全 | 仅暴露 80/443；DB/Redis 只监听 127.0.0.1 |
| 小内存 | Swap + JVM -Xmx + MySQL buffer pool 调小 |

只需替换：JAR 名、数据库名、环境变量、Nginx `server_name` 和静态文件目录。

## 15. 故障排查

| 现象 | 排查 |
| --- | --- |
| 502 Bad Gateway | `systemctl status railway-backend`，看 JAR 是否启动 |
| 连不上 MySQL | 检查 `railway.env` 中 URL/密码；`sudo mysql -e "SHOW DATABASES;"` |
| Redis 认证失败 | `redis-cli -a '密码' ping`；确认 `SPRING_REDIS_PASSWORD` |
| 前端 401 | 先调登录接口拿 token；检查 JWT_SECRET 是否变更导致旧 token 失效 |
| OOM / 机器卡死 | `free -h`；确认 Swap 已开；降低 `-Xmx` 或 MySQL buffer pool |
| 域名无法访问 | 检查 Azure NSG 80/443；`dig YOUR_DOMAIN.com` 是否指向正确 IP |
