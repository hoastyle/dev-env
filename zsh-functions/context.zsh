#!/usr/bin/env zsh
# ===============================================
# Environment Context Detection Functions
# ===============================================
# Purpose: Detect and display current environment context
#          (Docker container, SSH session, proxy status)
# ===============================================

# 检测是否在 Docker 容器中
_is_in_container() {
    [[ -f "/.dockerenv" ]] && return 0
    return 1
}

# 检测是否在 SSH 会话中
_is_in_ssh() {
    [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]
    return $?
}

# 检测是否使用了代理
_is_using_proxy() {
    [[ -n "$HTTP_PROXY$HTTPS_PROXY$http_proxy$https_proxy$SOCKS_PROXY$socks_proxy" ]]
    return $?
}

# 生成环境指示符字符串（显示所有环境状态）
# 返回值格式: "🖥️ 物理 🏠 本地 ✗ 无代理" （常态显示所有信息）
_get_env_indicators() {
    local indicators=""

    # 容器状态
    if _is_in_container; then
        indicators+="🐳 Docker"
    else
        indicators+="🖥️ 物理"
    fi

    # 连接方式
    if _is_in_ssh; then
        indicators+=" 🌐 SSH"
    else
        indicators+=" 🏠 本地"
    fi

    # 代理状态
    if _is_using_proxy; then
        indicators+=" ✓ 代理"
    else
        indicators+=" ✗ 无代理"
    fi

    echo "$indicators"
}

# 为 LPROMPT 生成环境指示符段（在提示符第一行显示）
_get_env_indicators_prompt_segment() {
    local indicators=$(_get_env_indicators)
    # 添加颜色和间距
    echo "%F{cyan}[${indicators}]%f "
}

# 查询命令：显示详细的环境状态
env_status() {
    # Handle help parameter
    if handle_help_param "env_status" "$1"; then
        cat << 'HELP'
Show current environment context (container, SSH, proxy status)

Usage:
  env_status          Show environment status
  env_status --help   Show this help message
  env_status -h       Show this help message

Description:
  Displays detailed information about the current environment context,
  including whether you are in a Docker container, SSH session, or
  using a proxy.

Example:
  $ env_status
  ┌─ Environment Context ──────────────────────────┐
  │ 🐳 Docker:    In container (container_name)   │
  │ 🌐 SSH:       SSH session (user@1.2.3.4)      │
  │ 🔐 Proxy:     Active - http://proxy:8080      │
  └────────────────────────────────────────────────┘

See Also:
  zsh_help - Show help for all available commands
HELP
        return 0
    fi

    echo ""
    echo "┌─ Environment Context ──────────────────────────┐"

    # Docker 状态
    if _is_in_container; then
        printf "│ 🐳 Docker:    %-34s │\n" "In container ($(hostname))"
    else
        printf "│ 🐳 Docker:    %-34s │\n" "Physical machine"
    fi

    # SSH 状态
    if _is_in_ssh; then
        local ssh_client="${SSH_CLIENT%% *}"
        if [[ -z "$ssh_client" && -n "$SSH_CONNECTION" ]]; then
            ssh_client="${SSH_CONNECTION%% *}"
        fi
        printf "│ 🌐 SSH:       %-34s │\n" "SSH session from $ssh_client"
    else
        printf "│ 🌐 SSH:       %-34s │\n" "Local session"
    fi

    # 代理状态
    if _is_using_proxy; then
        local proxy_addr="${HTTP_PROXY:-$HTTPS_PROXY:-$http_proxy:-$https_proxy:-$SOCKS_PROXY:-$socks_proxy}"
        # 截断代理地址以适应行宽
        proxy_addr="${proxy_addr:0:30}"
        printf "│ 🔐 Proxy:     %-34s │\n" "Active - $proxy_addr"
    else
        printf "│ 🔐 Proxy:     %-34s │\n" "Not configured"
    fi

    echo "└────────────────────────────────────────────────┘"
    echo ""
}
