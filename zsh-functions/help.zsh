#!/usr/bin/env zsh
# ===============================================
# Help System Functions
# ===============================================
# Optimized with singleton pattern to prevent
# redundant database initialization on every call

# 命令帮助数据库
typeset -A ZSH_COMMANDS
typeset -A COMMAND_CATEGORIES
typeset -A COMMAND_DESCRIPTIONS
typeset -A COMMAND_USAGES
typeset -A COMMAND_EXAMPLES

# 数据库初始化标志 (singleton pattern)
typeset -g ZSH_HELP_INITIALIZED=0

# 初始化命令数据库 (仅执行一次)
init_help_database() {
    # 如果已初始化，直接返回
    if [[ $ZSH_HELP_INITIALIZED -eq 1 ]]; then
        return 0
    fi
    # 环境检测命令
    COMMAND_CATEGORIES[check_environment]="环境检测"
    COMMAND_CATEGORIES[reload_zsh]="环境检测"
    COMMAND_CATEGORIES[env_status]="环境检测"

    COMMAND_DESCRIPTIONS[check_environment]="检测当前运行环境（Docker容器/物理主机）"
    COMMAND_DESCRIPTIONS[reload_zsh]="安全地重新加载ZSH配置"
    COMMAND_DESCRIPTIONS[env_status]="显示当前环境上下文（容器、SSH、代理状态）"

    COMMAND_USAGES[check_environment]="check_environment"
    COMMAND_USAGES[reload_zsh]="reload_zsh"
    COMMAND_USAGES[env_status]="env_status"

    COMMAND_EXAMPLES[check_environment]="check_environment"
    COMMAND_EXAMPLES[reload_zsh]="reload_zsh"
    COMMAND_EXAMPLES[env_status]="env_status"

    # 搜索增强命令
    COMMAND_CATEGORIES[hg]="搜索增强"
    COMMAND_CATEGORIES[hig]="搜索增强"
    COMMAND_CATEGORIES[hrg]="搜索增强"
    COMMAND_CATEGORIES[hirg]="搜索增强"

    COMMAND_DESCRIPTIONS[hg]="递归搜索文件内容（区分大小写）"
    COMMAND_DESCRIPTIONS[hig]="递归搜索文件内容（忽略大小写）"
    COMMAND_DESCRIPTIONS[hrg]="使用ripgrep搜索文件内容（区分大小写）"
    COMMAND_DESCRIPTIONS[hirg]="使用ripgrep搜索文件内容（忽略大小写）"

    COMMAND_USAGES[hg]="hg \"pattern\" [directory]"
    COMMAND_USAGES[hig]="hig \"pattern\" [directory]"
    COMMAND_USAGES[hrg]="hrg \"pattern\" [directory]"
    COMMAND_USAGES[hirg]="hirg \"pattern\" [directory]"

    COMMAND_EXAMPLES[hg]="hg \"function\" ./src"
    COMMAND_EXAMPLES[hig]="hig \"TODO\" ."
    COMMAND_EXAMPLES[hrg]="hrg \"error\" ./logs"
    COMMAND_EXAMPLES[hirg]="hirg \"config\" /etc"

    # AI 工具命令
    COMMAND_CATEGORIES[claude-config]="AI工具"
    COMMAND_CATEGORIES[ccfg]="AI工具"
    COMMAND_CATEGORIES[cc-proxy]="AI工具"

    COMMAND_DESCRIPTIONS[claude-config]="Claude CLI 配置管理（主命令）"
    COMMAND_DESCRIPTIONS[ccfg]="claude-config 的简短别名"
    COMMAND_DESCRIPTIONS[cc-proxy]="Claude CLI 代理支持（配置级和运行时）"

    COMMAND_USAGES[claude-config]="claude-config <subcommand> [args]"
    COMMAND_USAGES[ccfg]="ccfg <subcommand> [args]"
    COMMAND_USAGES[cc-proxy]="cc-<name> --proxy [地址] | cc-<name> --no-proxy"

    COMMAND_EXAMPLES[claude-config]="claude-config create mymodel\nclaude-config list\nclaude-config edit glm"
    COMMAND_EXAMPLES[ccfg]="ccfg create mymodel  # 创建配置\nccfg edit glm  # 编辑配置\nccfg list  # 列出所有配置"
    COMMAND_EXAMPLES[cc-proxy]="cc-glm --proxy  # 使用默认代理\ncc-glm --proxy 192.168.1.1:8080  # 指定代理\ncc-glm --no-proxy  # 禁用代理"

    # 实用工具命令
    COMMAND_CATEGORIES[proxy]="实用工具"
    COMMAND_CATEGORIES[unproxy]="实用工具"
    COMMAND_CATEGORIES[check_proxy]="实用工具"
    COMMAND_CATEGORIES[proxy_status]="实用工具"
    COMMAND_CATEGORIES[comp-enable]="实用工具"
    COMMAND_CATEGORIES[autojump-lazy]="实用工具"
    COMMAND_CATEGORIES[nvm-lazy]="实用工具"
    COMMAND_CATEGORIES[conda-init]="实用工具"
    COMMAND_CATEGORIES[jdev]="实用工具"

    COMMAND_DESCRIPTIONS[proxy]="启用网络代理（支持自定义地址和验证）"
    COMMAND_DESCRIPTIONS[unproxy]="禁用网络代理"
    COMMAND_DESCRIPTIONS[check_proxy]="检查代理是否已启用"
    COMMAND_DESCRIPTIONS[proxy_status]="显示详细的代理状态和可用性"
    COMMAND_DESCRIPTIONS[comp-enable]="启用按需补全系统（fast/minimal 模式）"
    COMMAND_DESCRIPTIONS[autojump-lazy]="加载 Autojump（minimal 模式先执行以恢复 j/jdev）"
    COMMAND_DESCRIPTIONS[nvm-lazy]="按需加载 NVM 及补全（minimal 模式）"
    COMMAND_DESCRIPTIONS[conda-init]="按需激活 Conda 基础环境（minimal 模式）"
    COMMAND_DESCRIPTIONS[jdev]="快速跳转到开发目录（需要autojump；minimal 模式先执行 autojump-lazy）"

    COMMAND_USAGES[proxy]="proxy [host:port] [--verify]"
    COMMAND_USAGES[unproxy]="unproxy"
    COMMAND_USAGES[check_proxy]="check_proxy [--status|-s]"
    COMMAND_USAGES[proxy_status]="proxy_status"
    COMMAND_USAGES[comp-enable]="comp-enable"
    COMMAND_USAGES[autojump-lazy]="autojump-lazy"
    COMMAND_USAGES[nvm-lazy]="nvm-lazy"
    COMMAND_USAGES[conda-init]="conda-init"
    COMMAND_USAGES[jdev]="jdev [directory_name]"

    COMMAND_EXAMPLES[proxy]="proxy 127.0.0.1:7890 --verify"
    COMMAND_EXAMPLES[unproxy]="unproxy"
    COMMAND_EXAMPLES[check_proxy]="check_proxy --status"
    COMMAND_EXAMPLES[proxy_status]="proxy_status"
    COMMAND_EXAMPLES[comp-enable]="comp-enable"
    COMMAND_EXAMPLES[autojump-lazy]="autojump-lazy && jdev workspace"
    COMMAND_EXAMPLES[nvm-lazy]="nvm-lazy && node -v"
    COMMAND_EXAMPLES[conda-init]="conda-init && conda info"
    COMMAND_EXAMPLES[jdev]="autojump-lazy && jdev workspace"

    # 将所有命令添加到主数据库
    for cmd in "${(@k)COMMAND_CATEGORIES}"; do
        ZSH_COMMANDS[$cmd]=1
    done

    # 标记初始化完成 (singleton pattern)
    ZSH_HELP_INITIALIZED=1
}

# 统一帮助命令
zsh_help() {
    local topic="$1"

    # 初始化数据库
    init_help_database

    # 如果没有参数，显示所有命令概览
    if [[ -z "$topic" ]]; then
        show_help_overview
        return 0
    fi

    # 如果参数是 --help 或 -h，显示帮助信息
    if [[ "$topic" == "--help" ]] || [[ "$topic" == "-h" ]]; then
        show_help_usage
        return 0
    fi

    # 如果参数是具体命令，显示该命令的详细帮助
    if [[ -n "${ZSH_COMMANDS[(I)$topic]}" ]]; then
        show_command_help "$topic"
        return 0
    fi

    # 如果参数是类别，显示该类别的所有命令
    if [[ "$topic" == "环境检测" ]] || [[ "$topic" == "搜索增强" ]] || [[ "$topic" == "实用工具" ]] || [[ "$topic" == "AI工具" ]]; then
        show_category_help "$topic"
        return 0
    fi

    # 未知参数，显示错误信息
    echo "❌ 未知主题或命令: $topic"
    echo ""
    echo "可用主题:"
    echo "  环境检测    - 环境检测相关命令"
    echo "  搜索增强    - 文件搜索相关命令"
    echo "  实用工具    - 实用工具命令"
    echo "  AI工具      - Claude CLI 配置管理命令"
    echo ""
    echo "可用命令 (输入 'zsh_help <命令名>' 查看详细信息):"

    # 按类别显示命令
    local categories=("环境检测" "搜索增强" "实用工具" "AI工具")
    for category in "${categories[@]}"; do
        echo ""
        echo "  $category:"
        for cmd in "${(@k)COMMAND_CATEGORIES}"; do
            if [[ "${COMMAND_CATEGORIES[$cmd]}" == "$category" ]]; then
                echo "    $cmd - ${COMMAND_DESCRIPTIONS[$cmd]}"
            fi
        done
    done
}

# 显示帮助概览
show_help_overview() {
    echo "🔧 ZSH 自定义命令帮助系统"
    echo "=========================="
    echo ""
    echo "可用命令类别:"
    echo ""

    # 统计各类别命令数量
    local env_count=0 search_count=0 util_count=0 ai_count=0
    for cmd in "${(@k)COMMAND_CATEGORIES}"; do
        case "${COMMAND_CATEGORIES[$cmd]}" in
            "环境检测") ((env_count++)) ;;
            "搜索增强") ((search_count++)) ;;
            "实用工具") ((util_count++)) ;;
            "AI工具") ((ai_count++)) ;;
        esac
    done

    echo "🌍 环境检测 ($env_count 个命令)"
    echo "   check_environment - 检测当前运行环境"
    echo "   reload_zsh       - 重新加载ZSH配置"
    echo "   env_status       - 显示环境上下文状态"
    echo ""

    echo "🔍 搜索增强 ($search_count 个命令)"
    echo "   hg               - 递归搜索（区分大小写）"
    echo "   hig              - 递归搜索（忽略大小写）"
    echo "   hrg              - ripgrep搜索（区分大小写）"
    echo "   hirg             - ripgrep搜索（忽略大小写）"
    echo ""

    echo "🤖 AI工具 ($ai_count 个命令)"
    echo "   claude-config    - Claude CLI 配置管理（主命令）"
    echo "   ccfg             - claude-config 的简短别名"
    echo "   cc-proxy         - 代理支持说明和示例"
    echo ""

    local minimal_hint=""
    if [[ "$ZSH_LAUNCHER_MODE" == "minimal" ]]; then
        minimal_hint="（Minimal 模式按需启用功能）"
    fi

    echo "🛠️  实用工具 ($util_count 个命令) $minimal_hint"
    echo "   proxy            - 启用网络代理"
    echo "   unproxy          - 禁用网络代理"
    echo "   check_proxy      - 检查代理状态"
    echo "   proxy_status     - 显示代理详细信息"
    echo "   comp-enable      - 启用按需补全系统"
    echo "   autojump-lazy    - 加载 Autojump 并恢复 j/jdev"
    echo "   nvm-lazy         - 加载 NVM 及补全"
    echo "   conda-init       - 启动 Conda 基础环境"
    local autojump_note=""
    if ! command -v autojump &> /dev/null; then
        autojump_note="（当前未检测到 autojump，可先运行 autojump-lazy）"
    fi
    echo "   jdev             - 快速目录跳转${autojump_note}"
    echo ""

    echo "💡 使用方法:"
    echo "   zsh_help <类别>    - 查看某类别的所有命令"
    echo "   zsh_help <命令>    - 查看具体命令的详细帮助"
    echo "   zsh_help --help    - 显示此帮助信息"
    echo ""
    echo "📚 示例:"
    echo "   zsh_help 搜索增强  # 查看所有搜索命令"
    echo "   zsh_help hg        # 查看 hg 命令详细帮助"
}

# 显示帮助使用方法
show_help_usage() {
    echo "🔧 ZSH 帮助系统使用指南"
    echo "======================"
    echo ""
    echo "用法: zsh_help [主题|命令]"
    echo ""
    echo "参数:"
    echo "  无参数        显示所有命令概览"
    echo "  类别名称      显示该类别的所有命令"
    echo "  具体命令      显示该命令的详细帮助"
    echo "  --help, -h    显示此帮助信息"
    echo ""
    echo "可用类别:"
    echo "  环境检测    - 环境检测和配置管理命令"
    echo "  搜索增强    - 文件内容搜索命令"
    echo "  实用工具    - 实用工具命令"
    echo "  AI工具      - Claude CLI 配置管理命令"
    echo ""
    echo "示例:"
    echo "  zsh_help              # 显示概览"
    echo "  zsh_help 搜索增强     # 显示搜索命令"
    echo "  zsh_help hg           # 显示 hg 命令帮助"
}

# 显示类别帮助
show_category_help() {
    local category="$1"
    local category_key=""

    # 映射中文类别到英文关键词
    case "$category" in
        "环境检测") category_key="环境检测" ;;
        "搜索增强") category_key="搜索增强" ;;
        "实用工具") category_key="实用工具" ;;
        "AI工具") category_key="AI工具" ;;
        *) category_key="$category" ;;
    esac

    echo "📂 $category 类别命令"
    echo "=================="
    echo ""

    local found=false
    for cmd in "${(@k)COMMAND_CATEGORIES}"; do
        if [[ "${COMMAND_CATEGORIES[$cmd]}" == "$category_key" ]]; then
            found=true
            echo "🔹 $cmd"
            echo "   描述: ${COMMAND_DESCRIPTIONS[$cmd]}"
            echo "   用法: ${COMMAND_USAGES[$cmd]}"
            echo "   示例: ${COMMAND_EXAMPLES[$cmd]}"
            echo ""
        fi
    done

    if [[ "$found" == false ]]; then
        echo "❌ 未找到类别: $category"
        echo ""
        echo "可用类别: 环境检测, 搜索增强, 实用工具, AI工具"
    fi
}

# 显示具体命令帮助
show_command_help() {
    local cmd="$1"

    echo "📖 命令帮助: $cmd"
    echo "================"
    echo ""
    echo "📝 描述: ${COMMAND_DESCRIPTIONS[$cmd]}"
    echo ""
    echo "🎯 用法: ${COMMAND_USAGES[$cmd]}"
    echo ""
    echo "💡 示例: ${COMMAND_EXAMPLES[$cmd]}"
    echo ""

    # 如果有相关工具，显示工具信息
    case "$cmd" in
        claude-config|ccfg)
            echo "🤖 功能: Claude CLI 多模型配置管理系统"
            echo ""
            echo "📋 管理子命令:"
            echo "    create <name>       - 创建新配置"
            echo "    edit <name>         - 编辑配置（热重载）"
            echo "    validate <name>     - 验证配置格式和字段"
            echo "    list                - 列出所有可用配置"
            echo "    copy <src> <dst>    - 复制现有配置"
            echo "    delete <name>       - 删除配置"
            echo "    refresh             - 刷新别名"
            echo "    current             - 显示 Claude CLI 版本"
            echo "    help                - 显示帮助信息"
            echo ""
            echo "🤖 使用模型:"
            echo "    cc-<model> \"prompt\"  - 使用指定配置的 AI 模型"
            echo ""
            echo "💡 命令示例:"
            echo "    ccfg create mymodel          # 创建新配置"
            echo "    ccfg edit glm                # 编辑 GLM 配置"
            echo "    ccfg list                    # 列出所有配置"
            echo "    cc-glm \"你好，请帮我写代码\"  # 使用 GLM 模型"
            echo ""
            echo "🌐 代理支持 (两种方式):"
            echo "    1. 配置级代理（持久化）:"
            echo "       ccfg edit <name>"
            echo "       # 在 env 字段添加:"
            echo "       # \"http_proxy\": \"http://127.0.0.1:7890\""
            echo "       # \"https_proxy\": \"http://127.0.0.1:7890\""
            echo ""
            echo "    2. 运行时代理（临时）:"
            echo "       cc-<model> --proxy \"prompt\"              # 使用默认代理"
            echo "       cc-<model> --proxy 192.168.1.1:8080 \"prompt\"  # 指定代理"
            echo "       cc-<model> --no-proxy \"prompt\"           # 禁用代理"
            ;;
        cc-proxy)
            echo "🌐 功能: Claude CLI 代理支持说明"
            echo ""
            echo "📋 两种代理配置方式:"
            echo ""
            echo "1️⃣ 配置级代理（持久化，每次生效）:"
            echo "    使用 'ccfg edit <配置名>' 编辑配置文件"
            echo "    在 env 字段中添加代理环境变量:"
            echo "    {"
            echo "      \"env\": {"
            echo "        \"http_proxy\": \"http://127.0.0.1:7890\","
            echo "        \"https_proxy\": \"http://127.0.0.1:7890\","
            echo "        \"all_proxy\": \"http://127.0.0.1:7890\""
            echo "      }"
            echo "    }"
            echo ""
            echo "2️⃣ 运行时代理（临时，仅当次生效）:"
            echo "    cc-glm --proxy \"prompt\"              # 使用默认代理 (127.0.0.1:7890)"
            echo "    cc-glm --proxy 10.0.0.1:8080 \"prompt\" # 使用指定代理"
            echo "    cc-glm --no-proxy \"prompt\"           # 明确禁用代理"
            echo ""
            echo "🎯 优先级规则:"
            echo "    --no-proxy 参数 > --proxy 参数 > 配置文件 env 字段"
            echo ""
            echo "💡 使用场景:"
            echo "    - 配置级: 适合该模型总是需要代理的情况"
            echo "    - 运行时: 适合临时测试、切换代理地址"
            ;;
        hg|hig)
            echo "🔧 相关工具: grep (系统自带)"
            echo "⚠️  注意: 在大型项目中搜索可能较慢"
            ;;
        hrg|hirg)
            if command -v rg &> /dev/null; then
                echo "✅ 相关工具: ripgrep (已安装)"
                echo "⚡ 性能: 比grep快很多倍"
            else
                echo "❌ 相关工具: ripgrep (未安装)"
                echo "📦 安装: apt install ripgrep / brew install ripgrep"
            fi
            ;;
        proxy)
            echo "🌐 功能: 启用网络代理，支持自定义地址"
            echo "📁 配置文件: ~/.proxy_config"
            echo "⚙️  选项:"
            echo "    <host:port>  - 指定自定义代理地址"
            echo "    --verify,-v  - 验证代理连接可用性"
            echo ""
            echo "📋 示例:"
            echo "    proxy                           # 使用默认配置启用"
            echo "    proxy 192.168.1.1:1080          # 指定自定义代理"
            echo "    proxy 127.0.0.1:7890 --verify   # 启用并验证"
            ;;
        unproxy)
            echo "🌐 功能: 清除所有代理环境变量"
            echo "📝 清除变量: http_proxy, https_proxy, all_proxy 等"
            echo "   支持大小写版本: HTTP_PROXY, HTTPS_PROXY 等"
            ;;
        check_proxy)
            echo "🔍 功能: 快速检查代理是否已启用"
            echo "📋 选项:"
            echo "    --status,-s  - 显示详细状态信息"
            echo ""
            echo "📝 输出: ✅ 代理已启用 / ❌ 代理未启用"
            echo "         (可选) 显示当前代理配置"
            ;;
        proxy_status)
            echo "📊 功能: 显示完整的代理配置和状态"
            echo "📋 信息包括:"
            echo "    - 当前代理状态 (已启用/未启用)"
            echo "    - 代理地址信息"
            echo "    - 默认配置信息"
            echo "    - 代理服务可用性检测"
            ;;
        jdev)
            if command -v autojump &> /dev/null; then
                echo "✅ 相关工具: autojump (已安装)"
            else
                echo "❌ 相关工具: autojump (未安装)"
                echo "📦 安装: apt install autojump / brew install autojump"
            fi
            ;;
    esac
    echo ""

    echo "🔗 相关命令:"
    local current_category="${COMMAND_CATEGORIES[$cmd]}"
    for related_cmd in "${(@k)COMMAND_CATEGORIES}"; do
        if [[ "${COMMAND_CATEGORIES[$related_cmd]}" == "$current_category" ]] && [[ "$related_cmd" != "$cmd" ]]; then
            echo "   $related_cmd - ${COMMAND_DESCRIPTIONS[$related_cmd]}"
        fi
    done
}

# 通用帮助参数处理函数
handle_help_param() {
    local cmd_name="$1"
    local param="$2"

    if [[ "$param" == "--help" ]] || [[ "$param" == "-h" ]]; then
        init_help_database
        show_command_help "$cmd_name"
        return 0
    fi

    return 1  # 不是帮助参数，继续正常执行
}

# 初始化帮助数据库（在模块加载时执行）
init_help_database
