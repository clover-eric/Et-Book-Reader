const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { query } = require('../config/database');
const redis = require('../config/redis');

// 获取图书列表
router.get('/', async (req, res) => {
    try {
        // 尝试从缓存获取
        const cachedBooks = await redis.get('books:all');
        if (cachedBooks) {
            return res.json({
                code: 'SUCCESS',
                books: JSON.parse(cachedBooks)
            });
        }

        // 从数据库获取
        const books = await query(
            'SELECT id, title, author, description FROM books WHERE status = ?', 
            ['active']
        );
        
        // 设置缓存
        await redis.set('books:all', JSON.stringify(books), 300);
        
        res.json({
            code: 'SUCCESS',
            books
        });
    } catch (error) {
        console.error('Error fetching books:', error);
        res.status(500).json({
            code: 'FETCH_ERROR',
            error: 'Failed to fetch books',
            message: process.env.NODE_ENV === 'development' ? error.message : undefined
        });
    }
});

module.exports = router;
