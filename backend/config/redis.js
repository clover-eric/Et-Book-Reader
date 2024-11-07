const Redis = require('ioredis');
require('dotenv').config();

const redisConfig = {
    host: process.env.REDIS_HOST,
    port: process.env.REDIS_PORT,
    // 添加重试策略
    retryStrategy(times) {
        const delay = Math.min(times * 50, 2000);
        return delay;
    },
    // 添加错误处理
    maxRetriesPerRequest: 3,
    // 添加超时设置
    connectTimeout: 10000,
    // 添加保活配置
    keepAlive: 10000
};

const redis = new Redis(redisConfig);

// 错误处理
redis.on('error', (error) => {
    console.error('Redis connection error:', error);
});

redis.on('connect', () => {
    console.log('Redis connected successfully');
});

// 包装 Redis 操作
const redisClient = {
    async get(key) {
        try {
            return await redis.get(key);
        } catch (error) {
            console.error('Redis get error:', error);
            throw new Error('Redis operation failed');
        }
    },
    async set(key, value, expiry = null) {
        try {
            if (expiry) {
                return await redis.set(key, value, 'EX', expiry);
            }
            return await redis.set(key, value);
        } catch (error) {
            console.error('Redis set error:', error);
            throw new Error('Redis operation failed');
        }
    }
};

module.exports = redisClient;
