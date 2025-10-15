#!/usr/bin/env zsh
# ===============================================
# Help System Functions
# ===============================================

# 命令帮助数据库
typeset -A ZSH_COMMANDS
typeset -A COMMAND_CATEGORIES
typeset -A COMMAND_DESCRIPTIONS
typeset -A COMMAND_USAGES
typeset -A COMMAND_EXAMPLES

# 初始化命令数据库
init_help_database() {
    # 环境检测命令
    COMMAND_CATEGORIES[check_environment]="环境检测"
    COMMAND_CATEGORIES[reload_zsh]="环境检测"

    COMMAND_DESCRIPTIONS[check_environment]="检测当前运行环境（Docker容器/物理主机）"
    COMMAND_DESCRIPTIONS[reload_zsh]="安全地重新加载ZSH配置"

    COMMAND_USAGES[check_environment]="check_environment"
    COMMAND_USAGES[reload_zsh]="reload_zsh"

    COMMAND_EXAMPLES[check_environment]="check_environment"
    COMMAND_EXAMPLES[reload_zsh]="reload_zsh"

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

    # 实用工具命令
    COMMAND_CATEGORIES[proxy]="实用工具"
    COMMAND_CATEGORIES[unproxy]="实用工具"
    COMMAND_CATEGORIES[jdev]="实用工具"

    COMMAND_DESCRIPTIONS[proxy]="启用网络代理"
    COMMAND_DESCRIPTIONS[unproxy]="禁用网络代理"
    COMMAND_DESCRIPTIONS[jdev]="快速跳转到开发目录（需要autojump）"

    COMMAND_USAGES[proxy]="proxy"
    COMMAND_USAGES[unproxy]="unproxy"
    COMMAND_USAGES[jdev]="jdev [directory_name]"

    COMMAND_EXAMPLES[proxy]="proxy"
    COMMAND_EXAMPLES[unproxy]="unproxy"
    COMMAND_EXAMPLES[jdev]="jdev workspace"

    # 将所有命令添加到主数据库
    for cmd in "${(@k)COMMAND_CATEGORIES}"; do
        ZSH_COMMANDS[$cmd]=1
    done
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
    if [[ "$topic" == "环境检测" ]] || [[ "$topic" == "搜索增强" ]] || [[ "$topic" == "实用工具" ]]; then
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
    echo ""
    echo "可用命令 (输入 'zsh_help <命令名>' 查看详细信息):"

    # 按类别显示命令
    local categories=("环境检测" "搜索增强" "实用工具")
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
    local env_count=0 search_count=0 util_count=0
    for cmd in "${(@k)COMMAND_CATEGORIES}"; do
        case "${COMMAND_CATEGORIES[$cmd]}" in
            "环境检测") ((env_count++)) ;;
            "搜索增强") ((search_count++)) ;;
            "实用工具") ((util_count++)) ;;
        esac
    done

    echo "🌍 环境检测 ($env_count 个命令)"
    echo "   check_environment - 检测当前运行环境"
    echo "   reload_zsh       - 重新加载ZSH配置"
    echo ""

    echo "🔍 搜索增强 ($search_count 个命令)"
    echo "   hg               - 递归搜索（区分大小写）"
    echo "   hig              - 递归搜索（忽略大小写）"
    echo "   hrg              - ripgrep搜索（区分大小写）"
    echo "   hirg             - ripgrep搜索（忽略大小写）"
    echo ""

    echo "🛠️  实用工具 ($util_count 个命令)"
    echo "   proxy            - 启用网络代理"
    echo "   unproxy          - 禁用网络代理"
    if command -v autojump &> /dev/null; then
        echo "   jdev             - 快速目录跳转"
    fi
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
        echo "可用类别: 环境检测, 搜索增强, 实用工具"
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
        proxy|unproxy)
            echo "🌐 代理设置: http://127.0.0.1:7890"
            echo "⚙️  可在 utils.zsh 中修改代理地址"
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