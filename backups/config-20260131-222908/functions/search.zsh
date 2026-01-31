#!/usr/bin/env zsh
# ===============================================
# Search Enhancement Functions
# ===============================================

# 递归搜索文件内容 (区分大小写)
# Recursive search for file content (case-sensitive)
hg() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hg" "$1"
        return 0
    fi

    # 验证必需参数
    if ! assert_param "$1" "search_pattern"; then
        print_usage "hg" 'hg "pattern" [directory]' 'hg "function" ./src' 'hg "TODO" .'
        return 1
    fi

    local search_pattern="$1"
    local search_dir="${2:-.}"

    # 验证搜索目录存在
    if ! validate_directory "$search_dir"; then
        error_msg "目录不存在: $search_dir"
        return 1
    fi

    grep -Ern "$search_pattern" --color=always "$search_dir" | less -r
}

# 递归搜索文件内容 (忽略大小写)
# Recursive search for file content (case-insensitive)
hig() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hig" "$1"
        return 0
    fi

    # 验证必需参数
    if ! assert_param "$1" "search_pattern"; then
        print_usage "hig" 'hig "pattern" [directory]' 'hig "TODO" .' 'hig "error" ./logs'
        return 1
    fi

    local search_pattern="$1"
    local search_dir="${2:-.}"

    # 验证搜索目录存在
    if ! validate_directory "$search_dir"; then
        error_msg "目录不存在: $search_dir"
        return 1
    fi

    grep -Eirn "$search_pattern" --color=always "$search_dir" | less -r
}

# 使用 ripgrep 搜索 (区分大小写)
# Search using ripgrep (case-sensitive)
hrg() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hrg" "$1"
        return 0
    fi

    # 验证 ripgrep 是否安装
    if ! assert_command "rg"; then
        echo "安装方法:"
        echo "  Ubuntu/Debian: sudo apt install ripgrep"
        echo "  macOS: brew install ripgrep"
        echo "  Arch: sudo pacman -S ripgrep"
        return 1
    fi

    # 验证必需参数
    if ! assert_param "$1" "search_pattern"; then
        print_usage "hrg" 'hrg "pattern" [directory]' 'hrg "error" ./logs' 'hrg "TODO" .'
        return 1
    fi

    local search_pattern="$1"
    local search_dir="${2:-.}"

    # 验证搜索目录存在
    if ! validate_directory "$search_dir"; then
        error_msg "目录不存在: $search_dir"
        return 1
    fi

    rg -e "$search_pattern" --color=always "$search_dir" | less -r
}

# 使用 ripgrep 搜索 (忽略大小写)
# Search using ripgrep (case-insensitive)
hirg() {
    # 处理帮助参数
    if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        handle_help_param "hirg" "$1"
        return 0
    fi

    # 验证 ripgrep 是否安装
    if ! assert_command "rg"; then
        echo "安装方法:"
        echo "  Ubuntu/Debian: sudo apt install ripgrep"
        echo "  macOS: brew install ripgrep"
        echo "  Arch: sudo pacman -S ripgrep"
        return 1
    fi

    # 验证必需参数
    if ! assert_param "$1" "search_pattern"; then
        print_usage "hirg" 'hirg "pattern" [directory]' 'hirg "config" /etc' 'hirg "error" .'
        return 1
    fi

    local search_pattern="$1"
    local search_dir="${2:-.}"

    # 验证搜索目录存在
    if ! validate_directory "$search_dir"; then
        error_msg "目录不存在: $search_dir"
        return 1
    fi

    rg -ie "$search_pattern" --color=always "$search_dir" | less -r
}
