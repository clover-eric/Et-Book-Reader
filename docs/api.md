# API文档

## 基础信息
- 基础URL: `http://localhost:3309`
- 所有请求都应包含 `Content-Type: application/json`
- 认证请求需要在header中包含 `Authorization: Bearer <token>`

## 接口列表

### 健康检查
```
GET /health
```

### 图书相关

#### 获取图书列表
```
GET /api/books

Response:
{
    "code": "SUCCESS",
    "books": [
        {
            "id": 1,
            "title": "书名",
            "author": "作者",
            "description": "描述"
        }
    ]
}
```

## 错误码说明
- SUCCESS: 操作成功
- AUTH_REQUIRED: 需要认证
- INVALID_TOKEN: 无效的token
- TOKEN_EXPIRED: token已过期
- NOT_FOUND: 资源不存在
- SERVER_ERROR: 服务器错误
