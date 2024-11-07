const express = require('express');
const router = express.Router();
const { pool } = require('../config/database');
const redis = require('../config/redis');

router.get('/health', async (req, res) => {
    try {
        // 检查数据库连接
        await pool.query('SELECT 1');
        
        // 检查Redis连接
        await redis.set('health_check', 'ok');
        await redis.get('health_check');
        
        res.json({
            status: 'healthy',
            services: {
                database: 'connected',
                redis: 'connected'
            }
        });
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(503).json({
            status: 'unhealthy',
            error: error.message
        });
    }
});

module.exports = router;
