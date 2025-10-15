#!/usr/bin/env zsh
# ===============================================
# Search Enhancement Functions
# ===============================================

# 递归搜索文件内容 (区分大小写)
hg() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hg" "$1"
        return 0
    fi

    # 检查参数
    if [[ -z "$1" ]]; then
        echo "❌ 错误: 缺少搜索模式"
        echo "用法: hg \"pattern\" [directory]"
        echo "示例: hg \"function\" ./src"
        echo "输入 'hg --help' 查看详细帮助"
        return 1
    fi

    local search_dir="${2:-.}"
    grep -Ern "$1" --color=always "$search_dir" | less -r
}

# 递归搜索文件内容 (忽略大小写)
hig() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hig" "$1"
        return 0
    fi

    # 检查参数
    if [[ -z "$1" ]]; then
        echo "❌ 错误: 缺少搜索模式"
        echo "用法: hig \"pattern\" [directory]"
        echo "示例: hig \"TODO\" ."
        echo "输入 'hig --help' 查看详细帮助"
        return 1
    fi

    local search_dir="${2:-.}"
    grep -Eirn "$1" --color=always "$search_dir" | less -r
}

# 使用 ripgrep 搜索 (区分大小写)
hrg() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hrg" "$1"
        return 0
    fi

    # 检查 ripgrep 是否安装
    if ! command -v rg &> /dev/null; then
        echo "❌ 错误: ripgrep (rg) 未安装"
        echo "安装方法:"
        echo "  Ubuntu/Debian: sudo apt install ripgrep"
        echo "  macOS: brew install ripgrep"
        echo "输入 'hrg --help' 查看详细帮助"
        return 1
    fi

    # 检查参数
    if [[ -z "$1" ]]; then
        echo "❌ 错误: 缺少搜索模式"
        echo "用法: hrg \"pattern\" [directory]"
        echo "示例: hrg \"error\" ./logs"
        echo "输入 'hrg --help' 查看详细帮助"
        return 1
    fi

    local search_dir="${2:-.}"
    rg -e "$1" --color=always "$search_dir" | less -r
}

# 使用 ripgrep 搜索 (忽略大小写)
hirg() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hirg" "$1"
        return 0
    fi

    # 检查 ripgrep 是否安装
    if ! command -v rg &> /dev/null; then
        echo "❌ 错误: ripgrep (rg) 未安装"
        echo "安装方法:"
        echo "  Ubuntu/Debian: sudo apt install ripgrep"
        echo "  macOS: brew install ripgrep"
        echo "输入 'hirg --help' 查看详细帮助"
        return 1
    fi

    # 检查参数
    if [[ -z "$1" ]]; then
        echo "❌ 错误: 缺少搜索模式"
        echo "用法: hirg \"pattern\" [directory]"
        echo "示例: hirg \"config\" /etc"
        echo "输入 'hirg --help' 查看详细帮助"
        return 1
    fi

    local search_dir="${2:-.}"
    rg -ie "$1" --color=always "$search_dir" | less -r
}