# 部署文档

## 环境要求
- Node.js >= 14
- MySQL >= 8.0
- Redis >= 6.0
- PM2 (用于生产环境进程管理)

## 部署步骤

### 1. 准备环境
```bash
# 安装 Node.js
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装 MySQL
sudo apt-get install mysql-server

# 安装 Redis
sudo apt-get install redis-server

# 安装 PM2
npm install -g pm2
```

### 2. 配置数据库
```bash
# 创建数据库和表
mysql -u root < backend/database/init.sql
```

### 3. 配置环境变量
```bash
# 后端配置
cp backend/.env.example backend/.env
vim backend/.env

# 前端配置
cp frontend/.env.example frontend/.env
vim frontend/.env
```

### 4. 构建前端
```bash
cd frontend
npm install
npm run build
```

### 5. 部署后端
```bash
cd backend
npm install
pm2 start ecosystem.config.js
```

### 6. Nginx配置
```nginx
server {
    listen 80;
    server_name your-domain.com;

    # 前端静态文件
    location / {
        root /path/to/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # 后端API
    location /api {
        proxy_pass http://localhost:3309;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 监控和日志
- 使用PM2监控进程
- 日志位于`backend/logs`目录
- 使用`pm2 logs`查看实时日志

## 备份策略
- 每日自动备份MySQL数据库
- 定期备份Redis数据
- 保留最近7天的备份

## 更新部署
1. 拉取最新代码
2. 构建前端
3. 重启后端服务
```bash
git pull
cd frontend && npm run build
pm2 restart all
```

## 回滚策略
1. 使用git回滚到上一个稳定版本
2. 重新构建前端
3. 重启后端服务

## Docker容器化部署

### 前置要求
- Docker >= 20.10
- Docker Compose >= 2.0

### 1. 一键部署命令
```bash
# 克隆项目后执行
./deploy-docker.sh

# 或者直接使用curl执行（推荐）
curl -fsSL https://raw.githubusercontent.com/clover-eric/Et-Book-Reader/main/deploy-docker.sh | bash
```

### 2. Docker部署文件说明

#### docker-compose.yml
```yaml
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3306:80"
    depends_on:
      - backend
    environment:
      - VITE_API_URL=http://localhost:3309

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3309:3309"
    depends_on:
      - mysql
      - redis
    environment:
      - DB_HOST=mysql
      - DB_USER=root
      - DB_PASSWORD=et-book-pass
      - DB_NAME=et_book
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - NODE_ENV=production

  mysql:
    image: mysql:8.0
    ports:
      - "3307:3306"
    environment:
      - MYSQL_ROOT_PASSWORD=et-book-pass
      - MYSQL_DATABASE=et_book
    volumes:
      - mysql_data:/var/lib/mysql
      - ./backend/database/init.sql:/docker-entrypoint-initdb.d/init.sql

  redis:
    image: redis:6.2
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  mysql_data:
  redis_data:
```

#### Frontend Dockerfile
```dockerfile
# frontend/Dockerfile
FROM node:14 as builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

#### Backend Dockerfile
```dockerfile
# backend/Dockerfile
FROM node:14
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3309
CMD ["npm", "start"]
```

### 3. 部署脚本说明
deploy-docker.sh 脚本会自动执行以下操作：
1. 检查必要的环境依赖
2. 创建必要的配置文件
3. 构建并启动所有容器
4. 执行数据库初始化
5. 检查服务健康状态

### 4. 常用Docker命令
```bash
# 启动所有服务
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f

# 停止所有服务
docker-compose down

# 重新构建并启动服务
docker-compose up -d --build

# 清理所有数据（包括数据库）
docker-compose down -v
```

### 5. 数据备份
```bash
# 备份MySQL数据
docker exec et-book-mysql mysqldump -u root -p et_book > backup.sql

# 备份Redis数据
docker exec et-book-redis redis-cli SAVE
docker cp et-book-redis:/data/dump.rdb ./redis-backup.rdb
```

### 6. 监控和日志
- 使用 Docker 原生日志系统
- 可以通过 Portainer 进行可视化管理
- 推荐使用 Prometheus + Grafana 进行监控

### 7. 扩展建议
- 使用 Docker Swarm 或 Kubernetes 进行容器编排
- 使用 Traefik 作为反向代理
- 配置 Docker 容器自动重启策略

### 8. 故障排除
1. 容器无法启动
   - 检查端口占用
   - 查看容器日志
   - 确认配置文件正确

2. 数据库连接失败
   - 确认环境变量配置
   - 检查网络连接
   - 验证数据库初始化状态

3. Redis连接问题
   - 检查Redis容器状态
   - 确认连接配置
   - 验证持久化设置
