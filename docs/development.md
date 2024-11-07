# 开发文档

## 开发环境设置

### 前端开发
1. 安装依赖
```bash
cd frontend
npm install
```

2. 启动开发服务器
```bash
npm run dev
```

3. 构建
```bash
npm run build
```

### 后端开发
1. 安装依赖
```bash
cd backend
npm install
```

2. 启动开发服务器
```bash
npm run dev
```

## 代码规范
- 使用ESLint进行代码检查
- 使用Prettier进行代码格式化
- 遵循Vue3组件命名规范
- 使用TypeScript类型注解

## 开发流程
1. 从main分支创建新分支
2. 开发新功能
3. 编写测试
4. 提交代码
5. 创建Pull Request

## 测试
- 单元测试使用Jest
- API测试使用Supertest
- E2E测试使用Cypress

## 调试
- 前端使用Vue DevTools
- 后端使用Node.js调试器
- 使用Postman测试API

## 性能优化
- 使用Redis缓存
- 图片懒加载
- 路由懒加载
- 组件按需加载
