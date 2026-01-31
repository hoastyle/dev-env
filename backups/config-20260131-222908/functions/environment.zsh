#!/usr/bin/env zsh
# ===============================================
# Environment Detection Functions
# ===============================================

# 检查当前环境是否在 Docker 容器中
check_environment() {
    # 处理帮助参数
    if handle_help_param "check_environment" "$1"; then
        return 0
    fi

    if [[ -f "/.dockerenv" ]]; then
        echo "🐳 当前在 Docker 容器环境中"
        echo "   容器名: $(hostname)"
        echo "   用户: $(whoami)"
        echo "   镜像: $(cat /etc/image_version 2>/dev/null || echo "未知")"
    else
        echo "🖥️  当前在物理主机环境中"
        echo "   主机名: $(hostname)"
        echo "   用户: $(whoami)"
        echo "   系统: $(uname -a)"
    fi
}

# 安全重载 zsh 配置
reload_zsh() {
    # 处理帮助参数
    if handle_help_param "reload_zsh" "$1"; then
        return 0
    fi

    echo "🔄 重新加载 zsh 配置..."
    source ~/.zshrc
    echo "✅ zsh 配置加载完成"
    # 确保主题颜色正常显示
    echo "🎨 当前主题: robbyrussell 风格"
}
