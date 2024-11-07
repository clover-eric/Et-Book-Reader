#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 克隆项目
clone_project() {
    log_info "克隆项目..."
    
    # 创建工作目录
    mkdir -p et-book
    cd et-book
    
    # 如果目录不存在，则克隆项目
    if [ ! -d ".git" ]; then
        git clone https://github.com/clover-eric/Et-Book-Reader.git .
    else
        log_warn "项目目录已存在，正在更新..."
        git pull
    fi
}

# 检查Docker环境
check_docker() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装"
        exit 1
    fi
}

# 创建必要的配置文件和目录
create_configs() {
    log_info "创建配置文件..."
    
    # 创建后端基础文
    mkdir -p backend/src
    
    # 创建后端入口文件
    cat > backend/src/server.js << EOF
const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();

// 中间件配置
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 健康检查路由
app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

// 根路由
app.get('/', (req, res) => {
    res.json({ message: 'Et-Book Reader API Server' });
});

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something broke!' });
});

const PORT = process.env.PORT || 3309;
app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});
EOF

    # 创建后端package.json
    cat > backend/package.json << EOF
{
  "name": "et-book-backend",
  "version": "1.0.0",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "nodemon src/server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "mysql2": "^3.6.0",
    "redis": "^4.6.7",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "nodemon": "^3.0.1"
  }
}
EOF

    # 修改后端Dockerfile
    cat > backend/Dockerfile << EOF
FROM node:14-alpine

WORKDIR /app

# 设置npm镜像
RUN npm config set registry https://registry.npmmirror.com
RUN npm config set disturl https://npmmirror.com/dist

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm install --production --no-package-lock && npm cache clean --force

# 复制源代码
COPY . .

# 创建日志目录
RUN mkdir -p logs

EXPOSE 3309

# 使用CMD而不是npm start，这样可以正确处理信号
CMD ["node", "src/server.js"]
EOF

    # 创建前端 Nginx 配置文件
    cat > frontend/nginx.conf << EOF
server {
    listen 80;
    server_name localhost;
    
    root /usr/share/nginx/html;
    index index.html;
    
    # 启用gzip压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 处理前端路由
    location / {
        try_files \$uri \$uri/ /index.html;
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }
    
    # 代理后端API请求
    location /api {
        proxy_pass http://backend:3309;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # 处理静态资源
    location /assets {
        expires 1y;
        add_header Cache-Control "public, no-transform";
    }
    
    # 禁止访问隐藏文件
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
EOF

    # 创建数据库初始化脚本
    cat > backend/database/init.sql << EOF
CREATE DATABASE IF NOT EXISTS et_book;
USE et_book;

CREATE TABLE IF NOT EXISTS books (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO books (title, author) VALUES
    ('Sample Book 1', 'Author 1'),
    ('Sample Book 2', 'Author 2');
EOF

    # 创建docker-compose.yml
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "8080:80"
    depends_on:
      - backend
    volumes:
      - npm_cache:/root/.npm

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "3309:3309"
    depends_on:
      - mysql
      - redis
    volumes:
      - npm_cache:/root/.npm
    environment:
      - DB_HOST=mysql
      - DB_USER=root
      - DB_PASSWORD=et-book-pass
      - DB_NAME=et_book
      - REDIS_HOST=redis
      - REDIS_PORT=6380
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
    command: redis-server --port 6380
    ports:
      - "6380:6380"
    volumes:
      - redis_data:/data

volumes:
  mysql_data:
  redis_data:
  npm_cache:
EOF

    # 创建前端 package.json
    cat > frontend/package.json << EOF
{
  "name": "et-book-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "vue": "^3.3.0",
    "vue-router": "^4.2.0",
    "vuex": "^4.1.0",
    "axios": "^1.6.0",
    "element-plus": "^2.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.5.0",
    "vite": "^5.0.0",
    "sass": "^1.69.0"
  }
}
EOF

    # 修改前端 Dockerfile
    cat > frontend/Dockerfile << EOF
FROM node:14-alpine as builder
WORKDIR /app

# 设置npm镜像
RUN npm config set registry https://registry.npmmirror.com
RUN npm config set disturl https://npmmirror.com/dist

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制源代码
COPY . .

# 创建index.html
cat > index.html << EOT
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Et-Book Reader</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOT

# 创建基础Vue组件
mkdir -p src
cat > src/App.vue << EOT
<template>
  <div id="app">
    <h1>Et-Book Reader</h1>
    <p>Welcome to Et-Book Reader!</p>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style>
#app {
  font-family: Arial, sans-serif;
  text-align: center;
  margin-top: 60px;
}
</style>
EOT

cat > src/main.js << EOT
import { createApp } from 'vue'
import App from './App.vue'

createApp(App).mount('#app')
EOT

# 构建前端
RUN npm run build

FROM nginx:alpine
# 复制构建产物
COPY --from=builder /app/dist /usr/share/nginx/html
# 复制nginx配置
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

    # 创建.npmrc文件以配置npm镜像
    cat > frontend/.npmrc << EOF
registry=https://registry.npmmirror.com
disturl=https://npmmirror.com/dist
EOF

    cat > backend/.npmrc << EOF
registry=https://registry.npmmirror.com
disturl=https://npmmirror.com/dist
EOF

    log_info "配置文件创建完成"
}

# 启动服务前的准备工作
prepare_build() {
    log_info "准备构建环境..."
    
    # 创建本地npm缓存目录
    mkdir -p ~/.npm-cache
    
    # 配置Docker构建参数
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    # 拉取基础镜像
    log_info "预拉取基础镜像..."
    docker pull node:14-alpine &
    docker pull nginx:alpine &
    wait
}

# 修改启动服务函数
start_services() {
    log_info "启动服务..."
    
    # 停止并删除现有容器
    docker-compose down
    
    # 清理旧的构建缓存
    docker builder prune -f
    
    # 使用buildkit并行构建
    DOCKER_BUILDKIT=1 docker-compose build --parallel
    
    # 启动服务
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 检查后端服务健康状态
    if ! curl -s http://localhost:3309/health &> /dev/null; then
        log_warn "后端服务未响应，等待更长时间..."
        sleep 20
        if ! curl -s http://localhost:3309/health &> /dev/null; then
            log_error "后端服务未正常启动"
            docker-compose logs backend
            exit 1
        fi
    fi
    
    log_info "后端服务启动成功！"
}

# 主函数
main() {
    log_info "开始Docker部署..."
    
    check_docker
    create_configs
    start_services
    
    log_info "部署完成！"
    log_info "前端访问地址: http://localhost:8080"
    log_info "后端API地址: http://localhost:3309"
}

# 执行主函数
main