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

# 清理无关文件
cleanup_files() {
    log_info "清理无关文件..."
    
    # 创建或更新 .gitignore
    cat > .gitignore << EOF
# 开发环境
.env
.env.*
node_modules/
dist/
coverage/
*.log

# 系统文件
.DS_Store
Thumbs.db

# 临时文件
*.tmp
*.temp
.deploy.lock
.cache/

# 数据库文件
*.sql
!backend/database/init.sql
!backend/database/seed.sql

# 日志文件
logs/
*.log
npm-debug.log*

# 测试文件
__tests__/
test/
tests/
*.test.js
*.spec.js

# 文档源文件
*.md
!README.md
!docs/*.md

# 开发工具配置
.idea/
.vscode/
*.sublime-*
*.swp
EOF

    # 删除不需要的脚本和文件
    rm -f fix-issues.sh
    rm -f generate-docs.sh
    
    log_info "文件清理完成"
}

# 初始化Git仓库
init_git() {
    log_info "初始化Git仓库..."
    
    if [ ! -d .git ]; then
        git init
        git remote add origin https://github.com/clover-eric/Et-Book-Reader.git
    fi
}

# 提交更改
commit_changes() {
    log_info "提交更改..."
    
    git add .
    git status
    
    # 获取提交信息
    echo "请输入提交信息 (默认: Update project files):"
    read commit_message
    if [ -z "$commit_message" ]; then
        commit_message="Update project files"
    fi
    
    git commit -m "$commit_message"
}

# 推送到GitHub
push_to_github() {
    log_info "推送到GitHub..."
    
    # 检查是否有未提交的更改
    if ! git diff-index --quiet HEAD --; then
        log_warn "有未提交的更改"
        commit_changes
    fi
    
    # 获取远程分支信息
    git fetch origin
    
    # 创建一个新的孤立分支
    git checkout --orphan temp_branch
    
    # 添加所有文件
    git add .
    
    # 提交更改
    git commit -m "Initial commit"
    
    # 删除main分支
    git branch -D main || true
    
    # 将临时分支重命名为main
    git branch -m main
    
    # 强制推送到远程仓库
    if git push -f origin main; then
        log_info "成功推送到GitHub!"
    else
        log_error "推送失败，请检查GitHub访问权限"
        exit 1
    fi
}

# 主函数
main() {
    log_info "开始处理..."
    
    cleanup_files
    init_git
    commit_changes
    push_to_github
    
    log_info "所有操作完成!"
}

# 执行主函数
main