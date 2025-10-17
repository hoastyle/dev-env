#!/usr/bin/env zsh
# ===============================================
# Utility Functions
# ===============================================

# ===============================================
# 代理配置管理 - Proxy Configuration Management
# ===============================================

# 代理配置文件位置
_PROXY_CONFIG_FILE="${HOME}/.proxy_config"
_PROXY_DEFAULT_PORT=7890
_PROXY_DEFAULT_HOST="127.0.0.1"

# 初始化代理配置文件
_init_proxy_config() {
    if [[ ! -f "$_PROXY_CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$_PROXY_CONFIG_FILE")"
        cat > "$_PROXY_CONFIG_FILE" << 'EOF'
# Proxy Configuration File
# Format: PROXY_HOST:PROXY_PORT
# Example: 127.0.0.1:7890

# Default proxy address (Clash, v2ray, etc.)
PROXY_ADDRESS=127.0.0.1:7890

# No proxy list (comma-separated)
NO_PROXY_LIST=localhost,127.0.0.1,.local,*.local

# Proxy timeout (seconds)
PROXY_TIMEOUT=3
EOF
        chmod 600 "$_PROXY_CONFIG_FILE"
    fi
}

# 读取代理配置
_get_proxy_config() {
    _init_proxy_config

    local proxy_address="$_PROXY_DEFAULT_HOST:$_PROXY_DEFAULT_PORT"
    local no_proxy_list="localhost,127.0.0.1,.local,*.local"

    if [[ -f "$_PROXY_CONFIG_FILE" ]]; then
        proxy_address=$(grep -E "^PROXY_ADDRESS=" "$_PROXY_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "$proxy_address")
        no_proxy_list=$(grep -E "^NO_PROXY_LIST=" "$_PROXY_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "$no_proxy_list")
    fi

    echo "$proxy_address|$no_proxy_list"
}

# 检查代理是否启用
check_proxy() {
    local proxy_status_show="${1:---status}"

    if handle_help_param "check_proxy" "$1"; then
        return 0
    fi

    local is_enabled=false

    # 检查是否设置了代理环境变量
    if [[ -n "$http_proxy" || -n "$HTTP_PROXY" || -n "$all_proxy" || -n "$ALL_PROXY" ]]; then
        is_enabled=true
    fi

    if $is_enabled; then
        echo "✅ 代理已启用"
        if [[ "$proxy_status_show" == "--status" || "$proxy_status_show" == "-s" ]]; then
            proxy_status
        fi
        return 0
    else
        echo "❌ 代理未启用"
        return 1
    fi
}

# 显示代理状态
proxy_status() {
    if handle_help_param "proxy_status" "$1"; then
        return 0
    fi

    local config_info=$(_get_proxy_config)
    local proxy_addr="${config_info%|*}"
    local no_proxy="${config_info#*|}"

    echo ""
    echo "📊 代理状态信息："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 检查代理是否启用
    if [[ -n "$http_proxy" ]]; then
        echo "🟢 代理状态: 已启用"
        echo "   http_proxy: ${http_proxy}"
        echo "   https_proxy: ${https_proxy:-未设置}"
        echo "   all_proxy: ${all_proxy:-未设置}"
    else
        echo "🔴 代理状态: 未启用"
    fi

    echo ""
    echo "⚙️  默认配置:"
    echo "   代理地址: $proxy_addr"
    echo "   NO_PROXY: $no_proxy"

    # 检查代理服务是否可用
    echo ""
    echo "🔍 代理服务可用性检测:"
    _check_proxy_availability "$proxy_addr"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 检查代理服务是否可用
_check_proxy_availability() {
    local proxy_addr="$1"
    local host="${proxy_addr%:*}"
    local port="${proxy_addr#*:}"
    local timeout=3

    # 尝试连接到代理服务
    if command -v timeout &> /dev/null; then
        timeout $timeout bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "   ✅ $host:$port 连接正常"
        else
            echo "   ⚠️  $host:$port 连接超时或拒绝"
        fi
    else
        echo "   ⏸️  跳过可用性检测 (timeout 命令不可用)"
    fi
}

# 网络代理设置 (优化版)
proxy() {
    if handle_help_param "proxy" "$1"; then
        return 0
    fi

    # 支持自定义代理地址参数
    local proxy_target="${1:-}"
    local config_info=$(_get_proxy_config)
    local proxy_addr="${proxy_target:-${config_info%|*}}"
    local no_proxy="${config_info#*|}"

    # 验证代理地址格式
    if [[ ! "$proxy_addr" =~ ^[0-9a-zA-Z.-]+:[0-9]+$ ]]; then
        echo "❌ 错误: 代理地址格式无效: $proxy_addr"
        echo "   预期格式: host:port (例: 127.0.0.1:7890)"
        return 1
    fi

    local host="${proxy_addr%:*}"
    local port="${proxy_addr#*:}"

    # 设置代理环境变量 (统一使用http://前缀)
    export http_proxy="http://$proxy_addr"
    export https_proxy="http://$proxy_addr"
    export all_proxy="http://$proxy_addr"
    export ftp_proxy="http://$proxy_addr"

    # 大写版本
    export HTTP_PROXY="http://$proxy_addr"
    export HTTPS_PROXY="http://$proxy_addr"
    export ALL_PROXY="http://$proxy_addr"
    export FTP_PROXY="http://$proxy_addr"

    # 正确设置 NO_PROXY (排除不需要代理的域名/IP)
    export NO_PROXY="$no_proxy"
    export no_proxy="$no_proxy"

    echo "✅ 代理已启用"
    echo "   地址: http://$proxy_addr"
    echo "   NO_PROXY: $no_proxy"

    # 可选: 验证代理连接
    if [[ "$2" == "--verify" || "$2" == "-v" ]]; then
        echo ""
        _check_proxy_availability "$proxy_addr"
    fi
}

# 禁用网络代理 (优化版)
unproxy() {
    if handle_help_param "unproxy" "$1"; then
        return 0
    fi

    # 清除所有代理相关环境变量
    local proxy_vars=(
        http_proxy https_proxy all_proxy ftp_proxy
        HTTP_PROXY HTTPS_PROXY ALL_PROXY FTP_PROXY
        no_proxy NO_PROXY
    )

    for var in "${proxy_vars[@]}"; do
        unset $var
    done

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