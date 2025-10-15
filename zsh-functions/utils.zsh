#!/usr/bin/env zsh
# ===============================================
# Utility Functions
# ===============================================

# 网络代理设置
proxy() {
    # 处理帮助参数
    if handle_help_param "proxy" "$1"; then
        return 0
    fi

    export http_proxy=http://127.0.0.1:7890
    export https_proxy=http://127.0.0.1:7890
    export all_proxy=http://127.0.0.1:7890
    export no_proxy=http://127.0.0.1:7890
    export HTTP_PROXY=http://127.0.0.1:7890
    export HTTPS_PROXY=http://127.0.0.1:7890
    export ALL_PROXY=http://127.0.0.1:7890
    export NO_PROXY='localhost, 127.0.0.1,*.local'
    echo "✅ 代理已启用 (http://127.0.0.1:7890)"
}

# 禁用网络代理
unproxy() {
    # 处理帮助参数
    if handle_help_param "unproxy" "$1"; then
        return 0
    fi

    unset http_proxy
    unset https_proxy
    unset all_proxy
    unset no_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    unset NO_PROXY
    echo "❌ 代理已禁用"
}

# 快速目录跳转函数 (需要 autojump 支持)
if command -v autojump &> /dev/null; then
    # 快速跳转到常用目录
    jdev() {
        # 处理帮助参数
        if handle_help_param "jdev" "$1"; then
            return 0
        fi

        # 检查参数
        if [[ -z "$1" ]]; then
            echo "❌ 错误: 缺少目录名称"
            echo "用法: jdev <directory_name>"
            echo "示例: jdev workspace"
            echo "输入 'jdev --help' 查看详细帮助"
            echo ""
            echo "💡 提示: 首先需要使用 autojump 访问目录以建立记忆"
            return 1
        fi

        local target_dir=$(autojump "$1" 2>/dev/null || echo "$HOME/Workspace")
        if [[ "$target_dir" != "$HOME/Workspace" ]]; then
            cd "$target_dir"
            echo "✅ 已跳转到: $target_dir"
        else
            echo "⚠️  未找到 '$1' 的记录，跳转到默认工作目录: $target_dir"
            cd "$target_dir"
        fi
    }
fi