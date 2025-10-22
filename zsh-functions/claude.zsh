#!/usr/bin/env zsh
# ===============================================
# Claude CLI Configuration Management Module
# ===============================================
# 功能: Claude CLI 多模型配置管理 + 代理支持
# 特性: 动态别名生成、配置创建、热重载、生命周期管理、运行时代理控制
#
# 主命令（推荐）:
#   claude-config <cmd>  或  ccfg <cmd>   - 统一管理入口
#
# 管理子命令:
#   ccfg create <name>     - 创建新配置
#   ccfg edit <name>       - 编辑配置（热重载）
#   ccfg validate <name>   - 验证配置
#   ccfg list              - 列出所有配置
#   ccfg copy <src> <dst>  - 复制配置
#   ccfg delete <name>     - 删除配置
#   ccfg refresh           - 刷新别名
#   ccfg current           - 显示版本信息
#   ccfg help              - 显示帮助
#
# 快速命令（向后兼容）:
#   cc-create <name>       - 创建新配置（等同于 ccfg create）
#   cc-edit <name>         - 编辑配置（等同于 ccfg edit）
#   ... 其他管理命令保持兼容
#
# 使用模型:
#   cc-<name> "prompt"     - 使用指定配置的模型
#   示例: cc-glm "你好"
#
# 代理支持:
#   方式1 (配置级) - 在 settings.json 的 env 字段中添加:
#     "http_proxy": "http://127.0.0.1:7890",
#     "https_proxy": "http://127.0.0.1:7890"
#
#   方式2 (运行时) - 使用命令行参数:
#     cc-<name> --proxy [地址]           # 启用代理（默认 127.0.0.1:7890）
#     cc-<name> --proxy 192.168.1.1:8080  # 使用指定代理
#     cc-<name> --no-proxy               # 明确禁用代理
#
# 配置文件命名: settings.json.<name> → 别名: cc-<name>


# ============================================
# 配置常量
# ============================================
typeset -g CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
typeset -g CLAUDE_TEMPLATE_FILE="${CLAUDE_CONFIG_DIR}/settings.json"
typeset -g CLAUDE_EDITOR="${EDITOR:-vim}"

# ============================================
# 核心函数：通用配置切换（支持运行时代理参数）
# ============================================
_claude_with_config() {
    local config_name="$1"
    shift  # 移除第一个参数，剩余的传给 claude

    local config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        error_msg "Claude 配置文件不存在: $config_file"
        info_msg "可用配置: $(_cc_list 2>/dev/null | grep 'cc-' | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')"
        info_msg "创建新配置: ccfg create $config_name"
        return 1
    fi

    # 处理运行时代理参数
    local proxy_enabled=false
    local proxy_url=""
    local remaining_args=()

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --proxy)
                proxy_enabled=true
                if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                    proxy_url="$2"
                    shift 2
                else
                    # 使用默认代理地址
                    proxy_url="http://127.0.0.1:7890"
                    shift
                fi
                ;;
            --no-proxy)
                # 明确禁用代理
                proxy_enabled=false
                unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy
                shift
                ;;
            *)
                remaining_args+=("$1")
                shift
                ;;
        esac
    done

    # 如果启用了运行时代理，设置环境变量
    if [[ "$proxy_enabled" == "true" ]]; then
        # 如果 proxy_url 不包含协议，添加 http://
        if [[ ! "$proxy_url" =~ ^https?:// ]]; then
            proxy_url="http://${proxy_url}"
        fi

        info_msg "🌐 运行时代理已启用: $proxy_url"
        export http_proxy="$proxy_url"
        export https_proxy="$proxy_url"
        export HTTP_PROXY="$proxy_url"
        export HTTPS_PROXY="$proxy_url"
        export all_proxy="$proxy_url"
    fi

    # 启动 Claude CLI
    claude --settings "$config_file" "${remaining_args[@]}"

    # 清理临时代理环境变量（如果是运行时设置的）
    if [[ "$proxy_enabled" == "true" ]]; then
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY all_proxy
    fi
}

# ============================================
# 动态别名生成
# ============================================
_setup_claude_aliases() {
    # 默认别名
    alias cc="claude"

    # 扫描配置目录，自动生成别名
    if [[ -d "$CLAUDE_CONFIG_DIR" ]]; then
        # 遍历所有 settings.json.* 文件
        for config_file in "${CLAUDE_CONFIG_DIR}"/settings.json.*; do
            # 检查文件是否存在（避免通配符无匹配时的问题）
            [[ -f "$config_file" ]] || continue

            # 提取配置名称（去掉路径和 settings.json. 前缀）
            local config_name="${config_file##*/settings.json.}"

            # 转换为小写（保持别名一致性）
            local alias_name="cc-${config_name:l}"  # :l 是 ZSH 的小写转换

            # 生成别名
            alias "${alias_name}"="_claude_with_config ${config_name}"
        done
    fi
}

# 执行别名生成（模块加载时）
_setup_claude_aliases

# ============================================
# 内部函数：配置创建（被 claude-config create 调用）
# ============================================
_cc_create() {
    local config_name="$1"

    # 参数检查
    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: ccfg create <config_name>"
        info_msg "示例: ccfg create mymodel"
        return 1
    fi

    # 检查配置目录是否存在
    if [[ ! -d "$CLAUDE_CONFIG_DIR" ]]; then
        info_msg "创建 Claude 配置目录: $CLAUDE_CONFIG_DIR"
        mkdir -p "$CLAUDE_CONFIG_DIR"
    fi

    local new_config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    # 检查配置是否已存在
    if [[ -f "$new_config_file" ]]; then
        warning_msg "配置已存在: $new_config_file"

        # 询问是否覆盖
        echo -n "是否覆盖现有配置? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info_msg "取消创建"
            return 0
        fi
    fi

    # 检查模板文件是否存在
    if [[ ! -f "$CLAUDE_TEMPLATE_FILE" ]]; then
        warning_msg "模板文件不存在: $CLAUDE_TEMPLATE_FILE"
        info_msg "正在创建默认模板..."

        # 创建默认模板（Claude Code CLI 格式，包含代理配置说明）
        cat > "$CLAUDE_TEMPLATE_FILE" <<'EOF'
{
  "_comment_proxy": "代理配置（可选）：如需使用代理访问 API，请在 env 中添加 http_proxy, https_proxy, all_proxy 字段，例如: \"http_proxy\": \"http://127.0.0.1:7890\"",
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "YOUR_AUTH_TOKEN_HERE",
    "ANTHROPIC_BASE_URL": "https://api.anthropic.com"
  },
  "model": "sonnet",
  "statusLine": {
    "type": "command",
    "command": "~/.claude/ccline/ccline",
    "padding": 0
  },
  "alwaysThinkingEnabled": false
}
EOF
        success_msg "已创建默认模板: $CLAUDE_TEMPLATE_FILE"
    fi

    # 复制模板创建新配置
    cp "$CLAUDE_TEMPLATE_FILE" "$new_config_file"
    success_msg "已创建配置文件: $new_config_file"

    # 显示提示信息
    echo ""
    info_msg "📝 下一步操作:"
    echo "  1. 编辑配置文件: ccfg edit $config_name"
    echo "  2. 配置 API Key 和 Base URL"
    echo "  3. 保存后自动生效: cc-${config_name:l}"
    echo ""

    # 询问是否立即编辑
    echo -n "是否立即编辑配置? [Y/n]: "
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        _cc_edit "$config_name"
    else
        # 不立即编辑，但刷新别名
        _setup_claude_aliases
        info_msg "别名已刷新，使用 cc-${config_name:l} 启动"
    fi
}

# ============================================
# 内部函数：配置编辑（支持热重载）
# ============================================
_cc_edit() {
    local config_name="$1"

    # 参数检查
    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: ccfg edit <config_name>"
        info_msg "可用配置:"
        _cc_list 2>/dev/null | grep 'cc-' | sed 's/  cc-/  - /' | head -10
        return 1
    fi

    local config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        error_msg "配置文件不存在: $config_file"
        info_msg "创建新配置: ccfg create $config_name"
        return 1
    fi

    # 显示编辑提示
    info_msg "正在编辑配置: $config_file"
    info_msg "编辑器: $CLAUDE_EDITOR"
    echo ""
    warning_msg "⚠️  请确保配置以下字段 (在 env 中):"
    echo "  - ANTHROPIC_AUTH_TOKEN: 你的 API 密钥"
    echo "  - ANTHROPIC_BASE_URL: API 服务器地址"
    echo ""
    info_msg "💡 可选字段 - 代理配置 (在 env 中):"
    echo "  - http_proxy: \"http://127.0.0.1:7890\""
    echo "  - https_proxy: \"http://127.0.0.1:7890\""
    echo "  - all_proxy: \"http://127.0.0.1:7890\""
    echo ""

    # 记录修改前的时间戳（兼容 Linux 和 macOS）
    local mtime_before=$(stat -c %Y "$config_file" 2>/dev/null || stat -f %m "$config_file" 2>/dev/null)

    # 打开编辑器
    $CLAUDE_EDITOR "$config_file"

    # 记录修改后的时间戳
    local mtime_after=$(stat -c %Y "$config_file" 2>/dev/null || stat -f %m "$config_file" 2>/dev/null)

    # 检查文件是否被修改
    if [[ "$mtime_before" != "$mtime_after" ]]; then
        success_msg "配置已保存: $config_file"

        # 验证 JSON 格式（如果有 jq）
        if command -v jq &>/dev/null; then
            if jq empty "$config_file" 2>/dev/null; then
                success_msg "✓ JSON 格式验证通过"
            else
                error_msg "✗ JSON 格式错误，请检查配置文件"
                info_msg "重新编辑: ccfg edit $config_name"
                return 1
            fi
        fi

        # 自动刷新别名（热重载）
        info_msg "正在刷新配置别名..."
        _setup_claude_aliases
        success_msg "✓ 配置已生效，可以使用 cc-${config_name:l} 命令"

        # 显示使用提示
        echo ""
        info_msg "🚀 快速测试:"
        echo "  cc-${config_name:l} --version"

    else
        info_msg "配置未修改"
    fi
}

# ============================================
# 内部函数：配置验证
# ============================================
_cc_validate() {
    local config_name="$1"

    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: ccfg validate <config_name>"
        return 1
    fi

    local config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    if [[ ! -f "$config_file" ]]; then
        error_msg "配置文件不存在: $config_file"
        return 1
    fi

    info_msg "正在验证配置: $config_file"

    # JSON 格式验证
    if command -v jq &>/dev/null; then
        if ! jq empty "$config_file" 2>/dev/null; then
            error_msg "✗ JSON 格式错误"
            return 1
        fi
        success_msg "✓ JSON 格式正确"

        # 检查必需字段（兼容两种格式）
        # 格式1: env.ANTHROPIC_AUTH_TOKEN (Claude Code CLI)
        # 格式2: api_key (Anthropic API)
        local has_auth_token=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$config_file")
        local has_api_key=$(jq -r '.api_key // empty' "$config_file")

        # Base URL 可能在 env.ANTHROPIC_BASE_URL 或顶层 base_url
        local has_base_url=$(jq -r '(.env.ANTHROPIC_BASE_URL // .base_url) // empty' "$config_file")

        # 模型字段
        local has_model=$(jq -r '.model // empty' "$config_file")

        echo ""
        info_msg "配置字段检查:"

        # 检查认证信息
        if [[ -n "$has_auth_token" && "$has_auth_token" != "YOUR_AUTH_TOKEN_HERE" ]]; then
            success_msg "✓ ANTHROPIC_AUTH_TOKEN: 已配置"
        elif [[ -n "$has_api_key" && "$has_api_key" != "YOUR_API_KEY_HERE" ]]; then
            success_msg "✓ api_key: 已配置"
        else
            warning_msg "⚠ 认证信息: 未配置或使用默认值"
            info_msg "  请配置 env.ANTHROPIC_AUTH_TOKEN 或 api_key"
        fi

        # 检查 Base URL
        if [[ -n "$has_base_url" ]]; then
            success_msg "✓ base_url: $has_base_url"
        else
            warning_msg "⚠ base_url: 未配置"
        fi

        # 检查模型
        if [[ -n "$has_model" ]]; then
            success_msg "✓ model: $has_model"
        else
            warning_msg "⚠ model: 未配置"
        fi

    else
        warning_msg "jq 未安装，跳过 JSON 验证"
        info_msg "安装 jq: sudo apt install jq  # Ubuntu/Debian"
    fi
}

# ============================================
# 内部函数：配置复制
# ============================================
_cc_copy() {
    local source_config="$1"
    local target_config="$2"

    if [[ -z "$source_config" || -z "$target_config" ]]; then
        error_msg "缺少参数"
        info_msg "使用方法: ccfg copy <source_config> <target_config>"
        info_msg "示例: ccfg copy glm myglm"
        return 1
    fi

    local source_file="${CLAUDE_CONFIG_DIR}/settings.json.${source_config}"
    local target_file="${CLAUDE_CONFIG_DIR}/settings.json.${target_config}"

    if [[ ! -f "$source_file" ]]; then
        error_msg "源配置不存在: $source_file"
        return 1
    fi

    if [[ -f "$target_file" ]]; then
        warning_msg "目标配置已存在: $target_file"
        echo -n "是否覆盖? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            info_msg "取消复制"
            return 0
        fi
    fi

    cp "$source_file" "$target_file"
    success_msg "已复制配置: $source_config → $target_config"

    _setup_claude_aliases
    info_msg "别名已刷新: cc-${target_config:l}"
}

# ============================================
# 内部函数：配置删除
# ============================================
_cc_delete() {
    local config_name="$1"

    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: ccfg delete <config_name>"
        return 1
    fi

    local config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    if [[ ! -f "$config_file" ]]; then
        error_msg "配置文件不存在: $config_file"
        return 1
    fi

    warning_msg "即将删除配置: $config_file"
    echo -n "确认删除? [y/N]: "
    read -r response

    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -f "$config_file"
        success_msg "已删除配置: $config_name"

        # 刷新别名
        _setup_claude_aliases
        info_msg "别名已刷新"
    else
        info_msg "取消删除"
    fi
}

# ============================================
# 内部函数：列出所有可用配置
# ============================================
_cc_list() {
    if [[ ! -d "$CLAUDE_CONFIG_DIR" ]]; then
        warning_msg "Claude 配置目录不存在: $CLAUDE_CONFIG_DIR"
        info_msg "创建第一个配置: ccfg create mymodel"
        return 1
    fi

    local count=0
    info_msg "可用的 Claude 配置:"
    echo ""

    for config_file in "${CLAUDE_CONFIG_DIR}"/settings.json.*; do
        [[ -f "$config_file" ]] || continue

        local config_name="${config_file##*/settings.json.}"
        local alias_name="cc-${config_name:l}"

        # 显示别名和路径
        echo "  ${alias_name}"

        # 如果有 jq，显示配置详情
        if command -v jq &>/dev/null; then
            # 查询模型（顶层字段）
            local model=$(jq -r '.model // "未配置"' "$config_file" 2>/dev/null)

            # 查询 Base URL（可能在 env.ANTHROPIC_BASE_URL 或顶层 base_url）
            local base_url=$(jq -r '(.env.ANTHROPIC_BASE_URL // .base_url) // "未配置"' "$config_file" 2>/dev/null)

            # 查询 Auth Token（检查是否已配置）
            local auth_token=$(jq -r '.env.ANTHROPIC_AUTH_TOKEN // empty' "$config_file" 2>/dev/null)
            local auth_status="未配置"
            if [[ -n "$auth_token" && "$auth_token" != "YOUR_AUTH_TOKEN_HERE" ]]; then
                auth_status="已配置"
            fi

            echo "    模型: $model"
            echo "    服务器: $base_url"
            echo "    认证: $auth_status"
        fi

        echo ""
        ((count++))
    done

    if [[ $count -eq 0 ]]; then
        warning_msg "未找到任何配置文件"
        info_msg "创建第一个配置: ccfg create mymodel"
    else
        success_msg "共找到 ${count} 个配置"
        echo ""
        info_msg "管理命令:"
        echo "  ccfg create <name>    - 创建新配置"
        echo "  ccfg edit <name>      - 编辑配置（热重载）"
        echo "  ccfg validate <name>  - 验证配置"
        echo "  ccfg copy <src> <dst> - 复制配置"
        echo "  ccfg delete <name>    - 删除配置"
    fi
}

# ============================================
# 内部函数：刷新别名
# ============================================
_cc_refresh() {
    info_msg "正在刷新 Claude CLI 别名..."
    _setup_claude_aliases
    success_msg "别名刷新完成"
    _cc_list
}

# ============================================
# 内部函数：显示当前配置
# ============================================
_cc_current() {
    info_msg "当前 Claude CLI 信息:"
    if command -v claude &>/dev/null; then
        claude --version 2>/dev/null || warning_msg "无法获取版本信息"
    else
        warning_msg "Claude CLI 未安装"
        info_msg "安装方式: npm install -g @anthropic-ai/claude-cli"
    fi
}

# ============================================
# 主管理命令：claude-config (别名 ccfg)
# ============================================
claude-config() {
    local cmd="${1:-help}"
    shift

    case "$cmd" in
        create)
            _cc_create "$@"
            ;;
        edit)
            _cc_edit "$@"
            ;;
        validate)
            _cc_validate "$@"
            ;;
        list)
            _cc_list "$@"
            ;;
        copy)
            _cc_copy "$@"
            ;;
        delete)
            _cc_delete "$@"
            ;;
        refresh)
            _cc_refresh "$@"
            ;;
        current)
            _cc_current "$@"
            ;;
        help|--help|-h)
            cat <<'EOF'
┌─────────────────────────────────────────────────────────┐
│      Claude CLI 配置管理系统 (v2.1.9)                   │
└─────────────────────────────────────────────────────────┘

📋 管理命令 (Configuration Management):
  create <name>       创建新配置
  edit <name>         编辑配置（热重载）
  validate <name>     验证配置格式和字段
  list                列出所有可用配置
  copy <src> <dst>    复制现有配置
  delete <name>       删除配置
  refresh             刷新别名
  current             显示 Claude CLI 版本信息
  help                显示此帮助信息

🤖 使用模型 (Using AI Models):
  cc-<model> "prompt"  - 使用指定配置的 AI 模型

  可用模型列表：
    运行 'ccfg list' 查看所有已配置的模型

💡 命令示例:
  # 管理配置
  ccfg create mymodel           # 创建新配置
  ccfg edit glm                 # 编辑 GLM 配置
  ccfg list                     # 列出所有配置

  # 使用模型
  cc-glm "你好，请帮我写代码"   # 使用 GLM 模型
  cc-yhlxj "翻译这段话"         # 使用 yhlxj 模型

🌐 代理支持 (Proxy Support):
  配置级代理（持久化）:
    ccfg edit <name>
    # 在 env 字段添加:
    # "http_proxy": "http://127.0.0.1:7890"
    # "https_proxy": "http://127.0.0.1:7890"

  运行时代理（临时）:
    cc-<model> --proxy "prompt"              # 使用默认代理
    cc-<model> --proxy 192.168.1.1:8080 "prompt"  # 指定代理
    cc-<model> --no-proxy "prompt"           # 禁用代理

📚 详细帮助:
  ccfg <command> --help    查看具体命令的详细帮助

  示例:
    ccfg create --help
    ccfg edit --help

🔗 快捷命令（向后兼容）:
  cc-create <name>      等同于 ccfg create <name>
  cc-edit <name>        等同于 ccfg edit <name>
  ... 其他管理命令同理

EOF
            ;;
        *)
            error_msg "未知命令: $cmd"
            info_msg "使用 'ccfg help' 查看可用命令"
            echo ""
            info_msg "常用命令:"
            echo "  ccfg list      - 列出所有配置"
            echo "  ccfg create    - 创建新配置"
            echo "  ccfg edit      - 编辑配置"
            return 1
            ;;
    esac
}

# 简短别名
alias ccfg='claude-config'

# ============================================
# Tab 补全：claude-config/ccfg 子命令
# ============================================
_ccfg_completion() {
    local -a cmds
    cmds=(
        'create:创建新配置'
        'edit:编辑配置（热重载）'
        'validate:验证配置格式和字段'
        'list:列出所有可用配置'
        'copy:复制现有配置'
        'delete:删除配置'
        'refresh:刷新别名'
        'current:显示 Claude CLI 版本'
        'help:显示帮助信息'
    )
    _describe 'claude-config 管理命令' cmds
}

compdef _ccfg_completion claude-config ccfg
