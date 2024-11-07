# Et-Book 项目

## 项目简介
Et-Book是一个现代化的图书管理系统，提供图书的浏览、管理等功能。

## 技术栈
### 前端
- Vue 3
- Vuex 4
- Vue Router 4
- Element Plus
- Axios
- Vite

### 后端
- Node.js
- Express
- MySQL
- Redis
- JWT认证

## 功能特性
- 图书列表展示
- 用户认证
- 数据缓存
- RESTful API
- 响应式设计

## 快速开始

### 环境要求
- Node.js >= 14
- MySQL >= 8.0
- Redis >= 6.0

### 安装步骤

### 一键部署命令
```bash
# 克隆项目后执行
./deploy-docker.sh

# 或者直接使用curl执行（推荐）
curl -fsSL https://raw.githubusercontent.com/clover-eric/Et-Book-Reader/main/deploy-docker.sh | bash
```

1. 克隆项目
```bash
git clone <repository-url>
cd et-book
```

2. 安装依赖
```bash
# 安装后端依赖
cd backend
npm install

# 安装前端依赖
cd ../frontend
npm install
```

3. 配置环境变量
```bash
# 后端配置
cp backend/.env.example backend/.env

# 前端配置
cp frontend/.env.example frontend/.env
```

4. 初始化数据库
```bash
mysql -u root < backend/database/init.sql
```

5. 启动服务
```bash
# 开发模式
./deploy.sh dev

# 生产模式
./deploy.sh prod
```

## 项目结构
```
et-book/
├── frontend/           # 前端项目
│   ├── src/
│   │   ├── components/  # 组件
│   │   ├── views/       # 页面
│   │   ├── store/       # 状态管理
│   │   ├── router/      # 路由配置
│   │   └── services/    # API服务
│   └── public/
├── backend/            # 后端项目
│   ├── routes/         # 路由
│   ├── controllers/    # 控制器
│   ├── models/         # 数据模型
│   ├── middleware/     # 中间件
│   ├── config/         # 配置文件
│   └── utils/          # 工具函数
└── deploy.sh          # 部署脚本
```

## API文档
详见 [API文档](./docs/api.md)

## 开发文档
详见 [开发文档](./docs/development.md)

## 部署文档
详见 [部署文档](./docs/deployment.md)

## 贡献指南
1. Fork 项目
2. 创建特性分支
3. 提交改动
4. 推送到分支
5. 创建 Pull Request

## 许可证
MIT
