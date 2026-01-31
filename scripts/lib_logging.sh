#!/bin/bash
# =============================================================================
# dev-env Logging Library
# =============================================================================
# 版本: 1.1
# 描述: 提供统一的日志记录功能（跨平台兼容）
# =============================================================================

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载跨平台兼容性库
if [[ -f "$SCRIPT_DIR/lib_platform_compat.sh" ]]; then
    source "$SCRIPT_DIR/lib_platform_compat.sh"
else
    # 如果兼容性库不存在，使用最小兼容函数
    is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }
    is_linux() { [[ "$(uname -s)" == "Linux" ]]; }
    get_file_size() {
        local file=$1
        if is_macos; then
            stat -f%z "$file" 2>/dev/null || echo "0"
        else
            stat -c%s "$file" 2>/dev/null || echo "0"
        fi
    }
fi

# =============================================================================
# 常量定义
# =============================================================================

# 日志级别定义
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# 日志级别名称映射
declare -A LOG_LEVEL_NAMES=(
    [$LOG_LEVEL_DEBUG]="DEBUG"
    [$LOG_LEVEL_INFO]="INFO"
    [$LOG_LEVEL_WARN]="WARN"
    [$LOG_LEVEL_ERROR]="ERROR"
)

# 日��颜色定义
readonly LOG_COLOR_DEBUG="\033[0;36m"    # 青色
readonly LOG_COLOR_INFO="\033[0;32m"     # 绿色
readonly LOG_COLOR_WARN="\033[0;33m"     # 黄色
readonly LOG_COLOR_ERROR="\033[0;31m"    # 红色
readonly LOG_COLOR_SUCCESS="\033[0;32m"  # 绿色
readonly LOG_COLOR_RESET="\033[0m"       # 重置

# 当前日志级别 (从环境变量读取，默认 INFO)
CURRENT_LOG_LEVEL="${LOG_LEVEL:-$LOG_LEVEL_INFO}"

# 日志目录和文件
LOG_DIR="${LOG_DIR:-$HOME/.zsh/logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/dev-env.log}"
LOG_MAX_SIZE="${LOG_MAX_SIZE:-10485760}"  # 10MB
LOG_MAX_FILES="${LOG_MAX_FILES:-5}"

# =============================================================================
# 初始化和目录管理
# =============================================================================

# 确保日志目录存在
ensure_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "Warning: Cannot create log directory: $LOG_DIR" >&2
            return 1
        }
    fi
    return 0
}

# 初始化日志系统
init_logging() {
    ensure_log_dir

    # 创建日志文件（如果不存在）
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" 2>/dev/null || {
            echo "Warning: Cannot create log file: $LOG_FILE" >&2
            return 1
        }
    fi

    # 执行日志轮转
    log_rotate

    return 0
}

# =============================================================================
# 日志轮转
# =============================================================================

# 日志文件轮转
log_rotate() {
    if [[ ! -f "$LOG_FILE" ]]; then
        return 0
    fi

    # 检查日志文件大小（使用跨平台方法）
    local file_size=$(get_file_size "$LOG_FILE")

    # 如果文件超过最大大小，进行轮转
    if [[ $file_size -gt $LOG_MAX_SIZE ]]; then
        # 删除最老的日志文件
        if [[ -f "$LOG_FILE.$LOG_MAX_FILES" ]]; then
            rm -f "$LOG_FILE.$LOG_MAX_FILES"
        fi

        # 轮转现有的日志文件
        for ((i=$LOG_MAX_FILES-1; i>=1; i--)); do
            if [[ -f "$LOG_FILE.$i" ]]; then
                mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))" 2>/dev/null
            fi
        done

        # 轮转当前日志文件
        mv "$LOG_FILE" "$LOG_FILE.1" 2>/dev/null

        # 创建新的日志文件
        touch "$LOG_FILE" 2>/dev/null
    fi

    return 0
}

# =============================================================================
# 时间戳函数
# =============================================================================

# 获取格式化的时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 获取调用者信息
get_caller_info() {
    local line=${2:-}
    local func=${1:-}
    if [[ -n "$func" ]]; then
        echo "${func}:${line}"
    else
        echo "unknown:${line}"
    fi
}

# =============================================================================
# 核心日志函数
# =============================================================================

# 内部日志记录函数
_log() {
    local level=$1
    shift
    local message="$*"
    local level_name="${LOG_LEVEL_NAMES[$level]}"
    local timestamp=$(get_timestamp)
    local log_entry="[$timestamp] [$level_name] $message"

    # 确定输出颜色
    local color=""
    case $level in
        $LOG_LEVEL_DEBUG) color="$LOG_COLOR_DEBUG" ;;
        $LOG_LEVEL_INFO)  color="$LOG_COLOR_INFO" ;;
        $LOG_LEVEL_WARN)  color="$LOG_COLOR_WARN" ;;
        $LOG_LEVEL_ERROR) color="$LOG_COLOR_ERROR" ;;
    esac

    # 检查是否应该输出
    if [[ $level -ge $CURRENT_LOG_LEVEL ]]; then
        # 控制台输出（带颜色）
        if [[ -t 2 ]]; then
            echo -e "${color}${log_entry}${LOG_COLOR_RESET}" >&2
        else
            echo "${log_entry}" >&2
        fi

        # 文件输出（无颜色）
        if [[ -w "$LOG_FILE" ]]; then
            echo "${log_entry}" >> "$LOG_FILE"
        fi
    fi

    return 0
}

# =============================================================================
# 公共日志接口
# =============================================================================

# DEBUG 级别日志
log_debug() {
    _log $LOG_LEVEL_DEBUG "$@"
}

# INFO 级别日志
log_info() {
    _log $LOG_LEVEL_INFO "$@"
}

# WARN 级别日志
log_warn() {
    _log $LOG_LEVEL_WARN "$@"
}

# ERROR 级别日志
log_error() {
    _log $LOG_LEVEL_ERROR "$@"
}

# SUCCESS 日志（带绿色标记）
log_success() {
    local message="$*"
    local timestamp=$(get_timestamp)
    local log_entry="[SUCCESS] [$timestamp] $message"

    echo -e "${LOG_COLOR_SUCCESS}${log_entry}${LOG_COLOR_RESET}"

    ensure_log_dir
    if [[ -w "$LOG_FILE" ]]; then
        echo "${log_entry}" >> "$LOG_FILE"
    fi
}

# =============================================================================
# 便捷日志函数
# =============================================================================

# 段落分隔
log_section() {
    local title="$*"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))

    echo ""
    printf '%*s' "$padding" | tr ' ' '='
    echo " $title "
    printf '%*s' "$padding" | tr ' ' '='
    echo ""
}

# 开始标记
log_start() {
    log_info "========== START: $* =========="
}

# 结束标记
log_end() {
    local exit_code=${1:-0}
    if [[ $exit_code -eq 0 ]]; then
        log_info "========== END: SUCCESS =========="
    else
        log_error "========== END: FAILED (exit code: $exit_code) =========="
    fi
}

# 命令执行日志
log_cmd() {
    log_info "Executing: $*"
}

# =============================================================================
# 日志查看和清理
# =============================================================================

# 查看日志
view_logs() {
    local lines=${1:-50}
    if [[ -f "$LOG_FILE" ]]; then
        tail -n "$lines" "$LOG_FILE"
    else
        echo "Log file not found: $LOG_FILE"
        return 1
    fi
}

# 实时查看日志
tail_logs() {
    if [[ -f "$LOG_FILE" ]]; then
        tail -f "$LOG_FILE"
    else
        echo "Log file not found: $LOG_FILE"
        return 1
    fi
}

# 清理旧日志
clean_old_logs() {
    local days=${1:-7}
    ensure_log_dir

    # 删除超过指定天数的日志文件
    find "$LOG_DIR" -name "*.log.*" -type f -mtime +$days -delete 2>/dev/null
    log_info "Cleaned logs older than $days days"

    return 0
}

# 清理所有日志
clean_all_logs() {
    ensure_log_dir

    # 保留当前日志文件，删除所有轮转的日志
    rm -f "$LOG_FILE".* 2>/dev/null
    log_info "Cleaned all archived logs"

    return 0
}

# =============================================================================
# 调试支持函数
# =============================================================================

# 调试变量值
log_debug_vars() {
    log_debug "=== Variables Debug ==="
    for var in "$@"; do
        local value="${!var}"
        log_debug "$var = ${value:-<empty>}"
    done
}

# 调试环境信息
log_debug_env() {
    log_debug "=== Environment Debug ==="
    log_debug "PWD = $PWD"
    log_debug "USER = $USER"
    log_debug "HOME = $HOME"
    log_debug "SHELL = $SHELL"
    log_debug "LOG_LEVEL = $CURRENT_LOG_LEVEL"
    log_debug "LOG_FILE = $LOG_FILE"
}

# =============================================================================
# 错误处理增强
# =============================================================================

# 记录错误并退出
log_error_with_exit() {
    local exit_code=${2:-1}
    log_error "$1"
    exit $exit_code
}

# =============================================================================
# 初始化（自动执行）
# =============================================================================

# 自动初始化日志系统
ensure_log_dir

# =============================================================================
# 函数已定义，source 此文件后即可使用
# =============================================================================

# 注意：在子shell中使用这些函数时，需要先 source 此文件
# 或者定义在 .zshrc 中使其全局可用
