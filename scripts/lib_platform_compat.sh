#!/bin/bash
# =============================================================================
# dev-env Platform Compatibility Library
# =============================================================================
# 版本: 1.0
# 描述: 跨平台兼容性处理 (macOS/Linux)
# =============================================================================

# =============================================================================
# 操作系统检测
# =============================================================================

# 检测操作系统
get_os_type() {
    local os_type
    os_type=$(uname -s)
    echo "$os_type"
}

# 检测是否为 macOS
is_macos() {
    [[ "$(uname -s)" == "Darwin" ]]
}

# 检测是否为 Linux
is_linux() {
    [[ "$(uname -s)" == "Linux" ]]
}

# 获取操作系统版本
get_os_version() {
    if is_macos; then
        sw_vers -productVersion
    elif is_linux; then
        lsb_release -d 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME
    else
        echo "Unknown"
    fi
}

# =============================================================================
# 文件系统操作兼容层
# =============================================================================

# 获取文件大小（跨平台）
get_file_size() {
    local file=$1
    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi

    if is_macos; then
        stat -f%z "$file" 2>/dev/null || echo "0"
    else
        stat -c%s "$file" 2>/dev/null || echo "0"
    fi
}

# 获取文件权限（跨平台）
get_file_perms() {
    local file=$1
    if is_macos; then
        stat -f%Lp "$file" 2>/dev/null
    else
        stat -c%a "$file" 2>/dev/null
    fi
}

# 获取文件修改时间（跨平台）
get_file_mtime() {
    local file=$1
    if is_macos; then
        stat -f%m "$file" 2>/dev/null
    else
        stat -c%Y "$file" 2>/dev/null
    fi
}

# realpath 替代（macOS 旧版本没有 realpath）
realpath_compat() {
    local path=$1
    if command -v realpath &> /dev/null; then
        realpath "$path"
    elif is_macos; then
        # macOS 使用 python 或 perl
        python -c "import os; print(os.path.realpath('$path'))" 2>/dev/null || \
        perl -MCwd -e 'print Cwd::abs_path(shift)' "$path"
    else
        readlink -f "$path"
    fi
}

# =============================================================================
# 时间处理兼容层
# =============================================================================

# 获取时间戳（毫秒级，跨平台）
get_timestamp_ms() {
    if is_macos; then
        # macOS: 使用 python 或 perl 获取毫秒
        python -c 'import time; print(int(time.time()*1000))' 2>/dev/null || \
        perl -MTime::HiRes -e 'printf("%d",Time::HiRes::time()*1000)' 2>/dev/null || \
        date +%s000
    else
        # Linux: 直接使用 date
        date +%s%3N 2>/dev/null || date +%s000
    fi
}

# 获取格式化时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 获取相对于现在的日期时间
get_date_relative() {
    local days=$1
    if is_macos; then
        date -v-${days}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null || \
        date -d "$days days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null
    else
        date -d "$days days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null
    fi
}

# =============================================================================
# 进程处理兼容层
# =============================================================================

# 获取进程内存使用（KB）
get_process_memory() {
    local pid=$1
    if is_macos; then
        ps -o rss= -p "$pid" 2>/dev/null || echo "0"
    else
        ps -o rss= -p "$pid" 2>/dev/null || echo "0"
    fi
}

# 获取进程 CPU 使用率
get_process_cpu() {
    local pid=$1
    if is_macos; then
        ps -o %cpu= -p "$pid" 2>/dev/null || echo "0"
    else
        ps -o %cpu= -p "$pid" 2>/dev/null || echo "0"
    fi
}

# =============================================================================
# 工具检测和兼容性
# =============================================================================

# 检测命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# 获取 GNU 工具（macOS 可能需要安装 coreutils）
get_gnu_tool() {
    local tool=$1
    local gnu_tool="g$tool"

    if is_macos; then
        if command_exists "$gnu_tool"; then
            echo "$gnu_tool"
        else
            echo "$tool"
        fi
    else
        echo "$tool"
    fi
}

# 检测并设置兼容的 sed
get_compat_sed() {
    if is_macos; then
        # macOS 的 sed 需要 '' 空字符串处理
        echo "sed"
    else
        echo "sed"
    fi
}

# =============================================================================
# 终端兼容性
# =============================================================================

# 检测是否支持颜色
supports_color() {
    # 检查是否在交互式终端中
    [[ -t 1 ]] || return 1

    # 检查 TERM 环境变量
    case "$TERM" in
        xterm*|rxvt*|screen*|tmux*) return 0 ;;
    esac

    # 检查 COLORTERM 环境变量
    [[ -n "$COLORTERM" ]] && return 1

    return 1
}

# 设置或取消颜色
set_color_support() {
    if ! supports_color; then
        # 禁用所有颜色
        readonly LOG_COLOR_DEBUG=""
        readonly LOG_COLOR_INFO=""
        readonly LOG_COLOR_WARN=""
        readonly LOG_COLOR_ERROR=""
        readonly LOG_COLOR_SUCCESS=""
        readonly LOG_COLOR_RESET=""
    fi
}

# =============================================================================
# 包管理器检测
# =============================================================================

# 检测包管理器
detect_package_manager() {
    if command_exists brew; then
        echo "brew"
    elif command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists dnf; then
        echo "dnf"
    elif command_exists pacman; then
        echo "pacman"
    elif command_exists zypper; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# 安装包（跨平台）
install_package() {
    local pkg=$1
    local pm=$(detect_package_manager)

    case "$pm" in
        brew)
            brew install "$pkg"
            ;;
        apt)
            sudo apt-get install -y "$pkg"
            ;;
        yum|dnf)
            sudo "$pm" install -y "$pkg"
            ;;
        pacman)
            sudo pacman -S --noconfirm "$pkg"
            ;;
        zypper)
            sudo zypper install -y "$pkg"
            ;;
        *)
            echo "Error: Unknown package manager" >&2
            return 1
            ;;
    esac
}

# =============================================================================
# 路径兼容性
# =============================================================================

# 获取用户 bin 目录
get_user_bin_dir() {
    local bin_dir="$HOME/.local/bin"
    if [[ ! -d "$bin_dir" ]]; then
        mkdir -p "$bin_dir" 2>/dev/null
    fi
    echo "$bin_dir"
}

# 获取配置目录
get_config_dir() {
    local config_dir
    if is_macos; then
        config_dir="$HOME/Library/Application Support/dev-env"
    else
        config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dev-env"
    fi

    if [[ ! -d "$config_dir" ]]; then
        mkdir -p "$config_dir" 2>/dev/null
    fi

    echo "$config_dir"
}

# =============================================================================
# Shell 兼容性
# =============================================================================

# 检测当前 shell
get_current_shell() {
    if [[ -n "$ZSH_VERSION" ]]; then
        echo "zsh"
    elif [[ -n "$BASH_VERSION" ]]; then
        echo "bash"
    else
        echo "unknown"
    fi
}

# 检测 shell 版本
get_shell_version() {
    local shell=$(get_current_shell)
    case "$shell" in
        zsh)
            echo "$ZSH_VERSION"
            ;;
        bash)
            echo "$BASH_VERSION"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# =============================================================================
# 性能工具兼容性
# =============================================================================

# 获取 time 命令（跨平台）
get_time_command() {
    if is_macos; then
        # macOS 的 time 命令在 shell 内置
        echo "time"
    else
        # Linux 可以使用 /usr/bin/time 获取更详细信息
        if command_exists /usr/bin/time; then
            echo "/usr/bin/time"
        else
            echo "time"
        fi
    fi
}

# =============================================================================
# 初始化（自动设置颜色支持）
# =============================================================================

# 根据终端能力自动设置颜色支持
if ! supports_color; then
    export NO_COLOR=1
fi

# 注意：��数定义后，通过 source 此文件即可使用
# 如果需要在子shell中使用，请在 .zshrc 中 source 此文件
