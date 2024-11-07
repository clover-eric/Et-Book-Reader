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

# 检查环境
check_environment() {
    log_info "检查环境依赖..."
    
    # 检查 Node.js
    if ! command -v node >/dev/null 2>&1; then
        log_error "请安装 Node.js"
        exit 1
    fi
    
    # 检查 Redis
    redis-cli ping >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_warn "Redis 未运行，正在启动..."
        brew services start redis || {
            log_error "Redis 启动失败，请手动启动 Redis"
            exit 1
        }
        sleep 2
    fi
    
    # 检查 MySQL
    mysql --version >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        log_error "请安装 MySQL"
        exit 1
    fi
    
    log_info "环境检查完成"
}

# 创建前端项目结构
setup_frontend() {
    log_info "创建前端项目结构..."
    
    # 强制重新创建前端目录
    rm -rf frontend
    mkdir -p frontend
    mkdir -p frontend/src/{components,services,utils,styles,views,router,store}
    mkdir -p frontend/public
    
    # 创建 package.json
    cat > frontend/package.json << EOF
{
  "name": "et-book-frontend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "build:dev": "vite build --mode development",
    "preview": "vite preview",
    "test": "jest"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "vue": "^3.3.0",
    "vue-router": "^4.2.0",
    "vuex": "^4.1.0",
    "element-plus": "^2.4.0"
  },
  "devDependencies": {
    "@vitejs/plugin-vue": "^4.5.0",
    "vite": "^5.0.0",
    "jest": "^29.7.0",
    "@vue/test-utils": "^2.4.0",
    "sass": "^1.69.0"
  }
}
EOF

    # 创建 vite.config.js
    cat > frontend/vite.config.js << EOF
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src')
    }
  },
  server: {
    port: 3306
  }
})
EOF

    # 创建 index.html
    cat > frontend/index.html << EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Et-Book</title>
  </head>
  <body>
    <div id="app"></div>
    <script type="module" src="/src/main.js"></script>
  </body>
</html>
EOF

    # 创建 main.js
    cat > frontend/src/main.js << EOF
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import ElementPlus from 'element-plus'
import 'element-plus/dist/index.css'

const app = createApp(App)

app.use(router)
app.use(store)
app.use(ElementPlus)

app.mount('#app')
EOF

    # 创建 App.vue
    cat > frontend/src/App.vue << EOF
<template>
  <div id="app">
    <router-view></router-view>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>
EOF

    # 创建 .env.example
    cat > frontend/.env.example << EOF
VITE_API_URL=http://localhost:3309
EOF

    # 创建路由配置
    cat > frontend/src/router/index.js << EOF
import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/about',
    name: 'About',
    component: () => import('@/views/About.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
EOF

    # 创建状态管理配置
    cat > frontend/src/store/index.js << EOF
import { createStore } from 'vuex'

export default createStore({
  state: {
    user: null,
    books: []
  },
  mutations: {
    setUser(state, user) {
      state.user = user
    },
    setBooks(state, books) {
      state.books = books
    }
  },
  actions: {
    async fetchBooks({ commit }) {
      try {
        const response = await fetch(\`\${import.meta.env.VITE_API_URL}/api/books\`)
        const data = await response.json()
        commit('setBooks', data)
      } catch (error) {
        console.error('Error fetching books:', error)
      }
    }
  }
})
EOF

    # 创建基础视图组件
    cat > frontend/src/views/Home.vue << EOF
<template>
  <div class="home">
    <h1>Welcome to Et-Book</h1>
    <el-button type="primary" @click="fetchBooks">Load Books</el-button>
    <div v-if="books.length">
      <el-card v-for="book in books" :key="book.id" class="book-card">
        {{ book.title }}
      </el-card>
    </div>
  </div>
</template>

<script>
import { mapState, mapActions } from 'vuex'

export default {
  name: 'Home',
  computed: {
    ...mapState(['books'])
  },
  methods: {
    ...mapActions(['fetchBooks'])
  }
}
</script>

<style scoped>
.home {
  padding: 20px;
}
.book-card {
  margin: 10px 0;
}
</style>
EOF

    cat > frontend/src/views/About.vue << EOF
<template>
  <div class="about">
    <h1>About Et-Book</h1>
    <p>This is a book management system.</p>
  </div>
</template>

<script>
export default {
  name: 'About'
}
</script>

<style scoped>
.about {
  padding: 20px;
}
</style>
EOF

    # 更新 App.vue 添加导航
    cat > frontend/src/App.vue << EOF
<template>
  <div id="app">
    <el-container>
      <el-header>
        <el-menu mode="horizontal" router>
          <el-menu-item index="/">Home</el-menu-item>
          <el-menu-item index="/about">About</el-menu-item>
        </el-menu>
      </el-header>
      <el-main>
        <router-view></router-view>
      </el-main>
    </el-container>
  </div>
</template>

<script>
export default {
  name: 'App'
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
}

.el-header {
  padding: 0;
}
</style>
EOF

    log_info "前端项目结构创建完成"
}

# 安装依赖
install_dependencies() {
    log_info "安装项目依赖..."
    
    # 后端依赖
    cd backend
    npm install
    if [ $? -ne 0 ]; then
        log_error "后端依赖安装失败"
        exit 1
    fi
    cd ..
    
    # 前端依赖
    cd frontend
    if [ -f "package.json" ]; then
        npm install --force
        if [ $? -ne 0 ]; then
            log_error "前端依赖安装失败"
            exit 1
        fi
    else
        log_warn "前端 package.json 不存在，跳过安装"
    fi
    cd ..
    
    log_info "依赖安装完成"
}

# 配置数据库
setup_database() {
    log_info "配置数据库..."
    
    # 创建必要的数据库目录
    mkdir -p backend/database/migrations
    
    # 检查MySQL服务状态并重置root密码
    if ! mysql.server status > /dev/null 2>&1; then
        log_info "启动 MySQL 服务..."
        mysql.server start
        sleep 2
    fi
    
    # 以安全模式重置密码
    log_info "正在重置 MySQL root 密码..."
    mysql.server stop
    
    # 以跳过授权表方式启动
    mysqld_safe --skip-grant-tables --skip-networking &
    sleep 5
    
    # 重置root密码
    mysql << EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
FLUSH PRIVILEGES;
EOF
    
    # 停止MySQL并正常重启
    mysqladmin -u root shutdown
    sleep 2
    mysql.server start
    sleep 2
    
    # 创建初始化SQL文件
    cat > backend/database/init.sql << EOF
-- 创建数据库
CREATE DATABASE IF NOT EXISTS et_book CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE et_book;

-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('user', 'admin') DEFAULT 'user',
    status ENUM('active', 'inactive', 'banned') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX (status),
    UNIQUE INDEX (username),
    UNIQUE INDEX (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 系统配置表
CREATE TABLE IF NOT EXISTS system_configs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    config_key VARCHAR(50) NOT NULL,
    config_value JSON,
    updated_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE INDEX (config_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 系统日志表
CREATE TABLE IF NOT EXISTS system_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    log_type VARCHAR(20) NOT NULL,
    message TEXT,
    details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (log_type, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 错误日志表
CREATE TABLE IF NOT EXISTS error_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    error_type VARCHAR(50) NOT NULL,
    error_message TEXT,
    stack_trace TEXT,
    context JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (error_type, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 系统告警表
CREATE TABLE IF NOT EXISTS system_alerts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    alert_type VARCHAR(50) NOT NULL,
    message TEXT,
    status ENUM('active', 'resolved', 'ignored') DEFAULT 'active',
    alert_data JSON,
    handled_by INT,
    handled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
EOF

    # 执行数据库初始化
    if mysql -u root < backend/database/init.sql; then
        log_info "数据库初始化成功"
    else
        log_error "数据库初始化失败"
        exit 1
    fi
    
    log_info "数据库配置完成"
}

# 配置Redis
setup_redis() {
    log_info "配置Redis..."
    
    # 检查Redis服务
    redis-cli ping > /dev/null
    if [ $? -ne 0 ]; then
        log_error "Redis服务未启动"
        exit 1
    fi
    
    # 清理缓存
    redis-cli flushall
    
    log_info "Redis配置完成"
}

# 构建前端
build_frontend() {
    log_info "构建前端..."
    
    if [ ! -d "frontend" ]; then
        log_error "前端目录不存在"
        exit 1
    fi
    
    cd frontend
    
    # 检查 package.json 是否存在
    if [ ! -f "package.json" ]; then
        log_error "package.json 不存在，请先运行 setup_frontend"
        exit 1
    fi
    
    # 安装依赖
    npm install || {
        log_error "前端依赖安装失败"
        cd ..
        exit 1
    }
    
    # 构建项目
    if [ "$MODE" = "dev" ]; then
        log_info "跳过生产环境构建"
    else
        npm run build || {
            log_error "前端构建失败"
            cd ..
            exit 1
        }
    fi
    
    cd ..
    log_info "前端构建完成"
}

# 运行测试
run_tests() {
    log_info "运行测试..."
    
    # 后端测试
    cd backend
    npm test
    if [ $? -ne 0 ]; then
        log_warn "后端测试未通过"
    fi
    cd ..
    
    # 前端测试
    cd frontend
    npm test
    if [ $? -ne 0 ]; then
        log_warn "前端测试未通过"
    fi
    cd ..
    
    log_info "测试完成"
}

# 启动服务
start_services() {
    local mode=$1
    log_info "启动服务..."
    
    # 启动后端服务
    cd backend
    if [ "$mode" = "dev" ]; then
        npx nodemon server.js &
    else
        node server.js &
    fi
    cd ..
    
    # 启动前端开发服务器
    cd frontend
    if [ "$mode" = "dev" ]; then
        npm run dev &
    else
        # 使用 serve 启动生产环境
        npx serve -s dist -l 3306 &
    fi
    cd ..
    
    # 等待服务启动
    sleep 3
    
    # 检查服务是否成功启动
    if ! curl -s http://localhost:3309/health > /dev/null; then
        log_error "后端服务启动失败"
        exit 1
    fi
    
    if ! curl -s http://localhost:3306 > /dev/null; then
        log_error "前端服务启动失败"
        exit 1
    fi
    
    log_info "服务启动完成"
}

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    
    mkdir -p backend/uploads/chunks
    mkdir -p backend/logs
    mkdir -p backend/exports
    mkdir -p backend/temp
    
    log_info "目录创建完成"
}

# 配置环境变量
setup_env() {
    log_info "配置环境变量..."
    
    # 后端环境变量
    if [ ! -f backend/.env ]; then
        cp backend/.env.example backend/.env
        log_warn "请配置backend/.env文件"
    fi
    
    # 前端环境变量
    if [ ! -f frontend/.env ]; then
        cp frontend/.env.example frontend/.env
        log_warn "请配置frontend/.env文件"
    fi
    
    log_info "环境变���置完成"
}

# 创��后端项目结构
setup_backend() {
    log_info "创建后端项目结构..."
    
    # 强制重新创建后端目录
    rm -rf backend
    mkdir -p backend/{routes,controllers,models,middleware,config,utils,services}
    
    # 创建健康检查路由
    cat > backend/routes/health.js << EOF
const express = require('express');
const router = express.Router();

router.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

module.exports = router;
EOF

    # 创建图书路由
    cat > backend/routes/books.js << EOF
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

router.get('/', async (req, res) => {
    try {
        res.json({ books: [] });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
EOF

    # 创建 auth 中间件
    cat > backend/middleware/auth.js << EOF
const jwt = require('jsonwebtoken');

const auth = (req, res, next) => {
    try {
        const token = req.header('Authorization')?.replace('Bearer ', '');
        if (!token) {
            throw new Error('No token provided');
        }
        
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Please authenticate' });
    }
};

module.exports = auth;
EOF

    # 创建数据库配置
    cat > backend/config/database.js << EOF
const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

module.exports = pool;
EOF

    # 创建 Redis 配置
    cat > backend/config/redis.js << EOF
const Redis = require('ioredis');
require('dotenv').config();

const redis = new Redis({
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT
});

module.exports = redis;
EOF

    # 创建环境变量文件
    cat > backend/.env << EOF
PORT=3309
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=et_book
REDIS_HOST=localhost
REDIS_PORT=6379
JWT_SECRET=your-secret-key-123
EOF

    # 创建 package.json
    cat > backend/package.json << EOF
{
  "name": "et-book-backend",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "test": "jest --passWithNoTests"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "jsonwebtoken": "^9.0.2",
    "mysql2": "^3.6.1",
    "ioredis": "^5.3.2",
    "bcryptjs": "^2.4.3"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.7.0"
  }
}
EOF

    # 创建 server.js
    cat > backend/server.js << EOF
const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

// 确保在其他导入之前加载环境变量
dotenv.config();

const healthRouter = require('./routes/health');
const booksRouter = require('./routes/books');

const app = express();

// 中间件
app.use(cors());
app.use(express.json());

// 路由
app.use('/', healthRouter);
app.use('/api/books', booksRouter);

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something broke!' });
});

const PORT = process.env.PORT || 3309;

const server = app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});

// 优雅关闭
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
});

// 处理未捕获的异常
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    server.close(() => {
        console.log('HTTP server closed due to uncaught exception');
        process.exit(1);
    });
});
EOF

    log_info "后端项目结构创建完成"
}

# 主函数
main() {
    log_info "开始部署..."
    
    # 检查锁文件
    if [ -f .deploy.lock ]; then
        if [ $(( $(date +%s) - $(stat -f %m .deploy.lock) )) -gt 1800 ]; then
            log_warn "检测到过期的锁文件，正在清理..."
            rm -f .deploy.lock
        else
            log_error "部署脚本已在运行"
            exit 1
        fi
    fi
    
    # 创建新的锁文件
    echo $$ > .deploy.lock
    
    # 确保退出时清理锁文件
    trap 'rm -f .deploy.lock; cleanup' EXIT INT TERM
    
    # 按顺序执行各个步骤，遇到错误立即退出
    check_environment || exit 1
    create_directories || exit 1
    setup_backend || exit 1
    setup_frontend || exit 1
    setup_env || exit 1
    install_dependencies || exit 1
    setup_database || exit 1
    setup_redis || exit 1
    build_frontend || exit 1
    run_tests || exit 1
    start_services $1 || exit 1
    
    log_info "部署完成!"
    log_info "后端API运行在: http://localhost:3309"
    log_info "前端页面运行在: http://localhost:3306"
}

# 清理函数
cleanup() {
    log_info "清理资源..."
    
    # 停止服务
    pkill -f "node" || true
    
    # 停止Redis（仅当Redis正在运行时）
    if redis-cli ping > /dev/null 2>&1; then
        redis-cli shutdown || true
    fi
    
    # 确保删除锁文件
    rm -f .deploy.lock
    
    log_info "清理完成"
}

# 参数处理
MODE=${1:-prod}  # 默认生产模式

# 执行部署
main $MODE