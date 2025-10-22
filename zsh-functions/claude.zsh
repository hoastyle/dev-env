#!/usr/bin/env zsh
# ===============================================
# Claude CLI Configuration Management Module
# ===============================================
# 功能: Claude CLI 多模型配置管理
# 特性: 动态别名生成、配置创建、热重载、生命周期管理
#
# 使用:
#   cc-create <name>     - 创建新配置
#   cc-edit <name>       - 编辑配置（热重载）
#   cc-validate <name>   - 验证配置
#   cc-list              - 列出所有配置
#   cc-copy <src> <dst>  - 复制配置
#   cc-delete <name>     - 删除配置
#   cc-refresh           - 刷新别名
#   cc-current           - 显示版本信息
#
# 配置文件命名: settings.json.<name> → 别名: cc-<name>

# ============================================
# 配置常量
# ============================================
typeset -g CLAUDE_CONFIG_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
typeset -g CLAUDE_TEMPLATE_FILE="${CLAUDE_CONFIG_DIR}/settings.json"
typeset -g CLAUDE_EDITOR="${EDITOR:-vim}"

# ============================================
# 核心函数：通用配置切换
# ============================================
_claude_with_config() {
    local config_name="$1"
    shift  # 移除第一个参数，剩余的传给 claude

    local config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        error_msg "Claude 配置文件不存在: $config_file"
        info_msg "可用配置: $(cc-list 2>/dev/null | grep 'cc-' | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//')"
        info_msg "创建新配置: cc-create $config_name"
        return 1
    fi

    # 启动 Claude CLI
    claude --settings "$config_file" "$@"
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
# 配置创建功能
# ============================================
cc-create() {
    if handle_help_param "cc-create" "$1"; then
        return 0
    fi

    local config_name="$1"

    # 参数检查
    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: cc-create <config_name>"
        info_msg "示例: cc-create mymodel"
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

        # 创建默认模板
        cat > "$CLAUDE_TEMPLATE_FILE" <<'EOF'
{
  "api_key": "YOUR_API_KEY_HERE",
  "base_url": "https://api.anthropic.com",
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 8096,
  "temperature": 0.7,
  "timeout": 60
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
    echo "  1. 编辑配置文件: cc-edit $config_name"
    echo "  2. 配置 API Key 和 Base URL"
    echo "  3. 保存后自动生效: cc-${config_name:l}"
    echo ""

    # 询问是否立即编辑
    echo -n "是否立即编辑配置? [Y/n]: "
    read -r response
    if [[ ! "$response" =~ ^[Nn]$ ]]; then
        cc-edit "$config_name"
    else
        # 不立即编辑，但刷新别名
        _setup_claude_aliases
        info_msg "别名已刷新，使用 cc-${config_name:l} 启动"
    fi
}

# ============================================
# 配置编辑功能（支持热重载）
# ============================================
cc-edit() {
    if handle_help_param "cc-edit" "$1"; then
        return 0
    fi

    local config_name="$1"

    # 参数检查
    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: cc-edit <config_name>"
        info_msg "可用配置:"
        cc-list 2>/dev/null | grep 'cc-' | sed 's/  cc-/  - /' | head -10
        return 1
    fi

    local config_file="${CLAUDE_CONFIG_DIR}/settings.json.${config_name}"

    # 检查配置文件是否存在
    if [[ ! -f "$config_file" ]]; then
        error_msg "配置文件不存在: $config_file"
        info_msg "创建新配置: cc-create $config_name"
        return 1
    fi

    # 显示编辑提示
    info_msg "正在编辑配置: $config_file"
    info_msg "编辑器: $CLAUDE_EDITOR"
    echo ""
    warning_msg "⚠️  请确保配置以下字段:"
    echo "  - api_key: 你的 API 密钥"
    echo "  - base_url: API 服务器地址"
    echo "  - model: 模型名称"
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
                info_msg "重新编辑: cc-edit $config_name"
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
# 配置验证功能
# ============================================
cc-validate() {
    if handle_help_param "cc-validate" "$1"; then
        return 0
    fi

    local config_name="$1"

    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: cc-validate <config_name>"
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

        # 检查必需字段
        local has_api_key=$(jq -r '.api_key // empty' "$config_file")
        local has_base_url=$(jq -r '.base_url // empty' "$config_file")
        local has_model=$(jq -r '.model // empty' "$config_file")

        echo ""
        info_msg "配置字段检查:"

        if [[ -n "$has_api_key" && "$has_api_key" != "YOUR_API_KEY_HERE" ]]; then
            success_msg "✓ api_key: 已配置"
        else
            warning_msg "⚠ api_key: 未配置或使用默认值"
        fi

        if [[ -n "$has_base_url" ]]; then
            success_msg "✓ base_url: $has_base_url"
        else
            warning_msg "⚠ base_url: 未配置"
        fi

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
# 配置复制功能
# ============================================
cc-copy() {
    if handle_help_param "cc-copy" "$1"; then
        return 0
    fi

    local source_config="$1"
    local target_config="$2"

    if [[ -z "$source_config" || -z "$target_config" ]]; then
        error_msg "缺少参数"
        info_msg "使用方法: cc-copy <source_config> <target_config>"
        info_msg "示例: cc-copy glm myglm"
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
# 配置删除功能
# ============================================
cc-delete() {
    if handle_help_param "cc-delete" "$1"; then
        return 0
    fi

    local config_name="$1"

    if [[ -z "$config_name" ]]; then
        error_msg "缺少配置名称参数"
        info_msg "使用方法: cc-delete <config_name>"
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
# 辅助命令
# ============================================

# 列出所有可用配置
cc-list() {
    if handle_help_param "cc-list" "$1"; then
        return 0
    fi

    if [[ ! -d "$CLAUDE_CONFIG_DIR" ]]; then
        warning_msg "Claude 配置目录不存在: $CLAUDE_CONFIG_DIR"
        info_msg "创建第一个配置: cc-create mymodel"
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
            local model=$(jq -r '.model // "未配置"' "$config_file" 2>/dev/null)
            local base_url=$(jq -r '.base_url // "未配置"' "$config_file" 2>/dev/null)
            echo "    模型: $model"
            echo "    服务器: $base_url"
        fi

        echo ""
        ((count++))
    done

    if [[ $count -eq 0 ]]; then
        warning_msg "未找到任何配置文件"
        info_msg "创建第一个配置: cc-create mymodel"
    else
        success_msg "共找到 ${count} 个配置"
        echo ""
        info_msg "管理命令:"
        echo "  cc-create <name>    - 创建新配置"
        echo "  cc-edit <name>      - 编辑配置（热重载）"
        echo "  cc-validate <name>  - 验证配置"
        echo "  cc-copy <src> <dst> - 复制配置"
        echo "  cc-delete <name>    - 删除配置"
    fi
}

# 刷新别名
cc-refresh() {
    if handle_help_param "cc-refresh" "$1"; then
        return 0
    fi

    info_msg "正在刷新 Claude CLI 别名..."
    _setup_claude_aliases
    success_msg "别名刷新完成"
    cc-list
}

# 显示当前配置
cc-current() {
    if handle_help_param "cc-current" "$1"; then
        return 0
    fi

    info_msg "当前 Claude CLI 信息:"
    if command -v claude &>/dev/null; then
        claude --version 2>/dev/null || warning_msg "无法获取版本信息"
    else
        warning_msg "Claude CLI 未安装"
        info_msg "安装方式: npm install -g @anthropic-ai/claude-cli"
    fi
}

# ============================================
# 帮助系统注册（集成到 help.zsh）
# ============================================
_register_claude_help() {
    # 仅在 help.zsh 已加载时注册
    if ! typeset -f init_help_database >/dev/null 2>&1; then
        return 0
    fi

    # Claude CLI 配置管理命令
    COMMAND_CATEGORIES[cc-create]="AI工具"
    COMMAND_CATEGORIES[cc-edit]="AI工具"
    COMMAND_CATEGORIES[cc-validate]="AI工具"
    COMMAND_CATEGORIES[cc-list]="AI工具"
    COMMAND_CATEGORIES[cc-copy]="AI工具"
    COMMAND_CATEGORIES[cc-delete]="AI工具"
    COMMAND_CATEGORIES[cc-refresh]="AI工具"
    COMMAND_CATEGORIES[cc-current]="AI工具"

    COMMAND_DESCRIPTIONS[cc-create]="创建新的 Claude 配置"
    COMMAND_DESCRIPTIONS[cc-edit]="编辑配置（热重载）"
    COMMAND_DESCRIPTIONS[cc-validate]="验证配置格式和字段"
    COMMAND_DESCRIPTIONS[cc-list]="列出所有可用配置"
    COMMAND_DESCRIPTIONS[cc-copy]="复制现有配置"
    COMMAND_DESCRIPTIONS[cc-delete]="删除配置"
    COMMAND_DESCRIPTIONS[cc-refresh]="刷新别名"
    COMMAND_DESCRIPTIONS[cc-current]="显示 Claude CLI 版本信息"

    COMMAND_USAGES[cc-create]="cc-create <config_name>"
    COMMAND_USAGES[cc-edit]="cc-edit <config_name>"
    COMMAND_USAGES[cc-validate]="cc-validate <config_name>"
    COMMAND_USAGES[cc-list]="cc-list"
    COMMAND_USAGES[cc-copy]="cc-copy <source> <target>"
    COMMAND_USAGES[cc-delete]="cc-delete <config_name>"
    COMMAND_USAGES[cc-refresh]="cc-refresh"
    COMMAND_USAGES[cc-current]="cc-current"

    COMMAND_EXAMPLES[cc-create]="cc-create mymodel"
    COMMAND_EXAMPLES[cc-edit]="cc-edit glm-4"
    COMMAND_EXAMPLES[cc-validate]="cc-validate mymodel"
    COMMAND_EXAMPLES[cc-list]="cc-list"
    COMMAND_EXAMPLES[cc-copy]="cc-copy glm-4 glm-test"
    COMMAND_EXAMPLES[cc-delete]="cc-delete oldconfig"
    COMMAND_EXAMPLES[cc-refresh]="cc-refresh"
    COMMAND_EXAMPLES[cc-current]="cc-current"

    # 将所有命令添加到主数据库
    for cmd in cc-create cc-edit cc-validate cc-list cc-copy cc-delete cc-refresh cc-current; do
        ZSH_COMMANDS[$cmd]=1
    done
}

# 注册帮助信息
_register_claude_help
