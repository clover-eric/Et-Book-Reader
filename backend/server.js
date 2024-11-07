const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const helmet = require('helmet');

// 确保在其他导入之前加载环境变量
dotenv.config();

const healthRouter = require('./routes/health');
const booksRouter = require('./routes/books');

const app = express();

// 安全中间件
app.use(helmet());

// CORS 配置
app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:3306',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// 请求体解析
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// 基础中间件
app.use((req, res, next) => {
    // 请求日志
    console.log(`${new Date().toISOString()} ${req.method} ${req.url}`);
    next();
});

// 路由
app.use('/', healthRouter);
app.use('/api/books', booksRouter);

// 404处理
app.use((req, res) => {
    res.status(404).json({ 
        error: 'Not Found',
        code: 'NOT_FOUND'
    });
});

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ 
        error: 'Internal Server Error',
        code: 'SERVER_ERROR',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

const PORT = process.env.PORT || 3309;

const server = app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});

// 优雅关闭
const gracefulShutdown = async () => {
    console.log('Received shutdown signal');
    
    server.close(async () => {
        console.log('HTTP server closed');
        
        try {
            // 关闭数据库连接
            await require('./config/database').pool.end();
            console.log('Database connections closed');
            
            // 关闭Redis连接
            await require('./config/redis').quit();
            console.log('Redis connection closed');
            
            process.exit(0);
        } catch (error) {
            console.error('Error during shutdown:', error);
            process.exit(1);
        }
    });
    
    // 如果15秒内没有完成关闭，强制退出
    setTimeout(() => {
        console.error('Could not close connections in time, forcefully shutting down');
        process.exit(1);
    }, 15000);
};

process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// 处理未捕获的异常
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    gracefulShutdown();
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});
