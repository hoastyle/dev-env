#!/usr/bin/env zsh
# ===============================================
# Unified Parameter Validation Module
# ===============================================
# 提供统一的参数验证和错误消息格式
# Provides unified parameter validation and error message formatting

# Color codes for consistent output
readonly _VALIDATION_COLORS=(
    error="\033[0;31m"      # Red
    success="\033[0;32m"    # Green
    warning="\033[0;33m"    # Yellow
    info="\033[0;36m"       # Cyan
    reset="\033[0m"         # Reset
)

# ===============================================
# Error Message Formatting
# ===============================================

# Print error message with consistent format
# Usage: error_msg "error_message" ["additional_info"]
error_msg() {
    local msg="$1"
    local detail="$2"
    echo "${_VALIDATION_COLORS[error]}❌ 错误${_VALIDATION_COLORS[reset]}: $msg"
    if [[ -n "$detail" ]]; then
        echo "   $detail"
    fi
}

# Print warning message with consistent format
# Usage: warning_msg "warning_message"
warning_msg() {
    local msg="$1"
    echo "${_VALIDATION_COLORS[warning]}⚠️  警告${_VALIDATION_COLORS[reset]}: $msg"
}

# Print success message with consistent format
# Usage: success_msg "success_message"
success_msg() {
    local msg="$1"
    echo "${_VALIDATION_COLORS[success]}✅ 成功${_VALIDATION_COLORS[reset]}: $msg"
}

# Print info message with consistent format
# Usage: info_msg "info_message"
info_msg() {
    local msg="$1"
    echo "${_VALIDATION_COLORS[info]}ℹ️  信息${_VALIDATION_COLORS[reset]}: $msg"
}

# ===============================================
# Parameter Validation Functions
# ===============================================

# Validate that at least N parameters are provided
# Usage: validate_param_count <count> "$@" || return
# Returns 0 if valid, 1 if not enough parameters
validate_param_count() {
    local required_count="$1"
    shift
    local actual_count=$#

    if [[ $actual_count -lt $required_count ]]; then
        return 1
    fi
    return 0
}

# Validate that a parameter is not empty
# Usage: validate_not_empty "$param" "parameter_name" || return
validate_not_empty() {
    local value="$1"
    local param_name="$2"

    if [[ -z "$value" ]]; then
        return 1
    fi
    return 0
}

# Validate that a directory exists
# Usage: validate_directory "$dir_path" || return
validate_directory() {
    local dir_path="$1"

    if [[ ! -d "$dir_path" ]]; then
        return 1
    fi
    return 0
}

# Validate that a file exists
# Usage: validate_file "$file_path" || return
validate_file() {
    local file_path="$1"

    if [[ ! -f "$file_path" ]]; then
        return 1
    fi
    return 0
}

# Validate that a command exists
# Usage: validate_command "command_name" || return
validate_command() {
    local cmd="$1"

    if ! command -v "$cmd" &> /dev/null; then
        return 1
    fi
    return 0
}

# Validate that a parameter matches a regex pattern
# Usage: validate_pattern "$value" "pattern" "pattern_name" || return
validate_pattern() {
    local value="$1"
    local pattern="$2"
    local pattern_name="$3"

    if [[ ! "$value" =~ $pattern ]]; then
        return 1
    fi
    return 0
}

# ===============================================
# Usage Help Functions
# ===============================================

# Print function usage information
# Usage: print_usage "function_name" "usage_pattern" "example_1" ["example_2"] ...
print_usage() {
    local func_name="$1"
    local usage_pattern="$2"
    shift 2
    local examples=("$@")

    echo ""
    echo "用法: $usage_pattern"
    echo ""
    if [[ ${#examples[@]} -gt 0 ]]; then
        echo "示例:"
        for example in "${examples[@]}"; do
            echo "  $example"
        done
        echo ""
    fi
    echo "输入 '$func_name --help' 查看详细帮助"
}

# ===============================================
# Assertion Functions (for strict checking)
# ===============================================

# Assert parameter is provided, exit if not
# Usage: assert_param "$param" "parameter_name"
assert_param() {
    local value="$1"
    local param_name="$2"

    if ! validate_not_empty "$value" "$param_name"; then
        error_msg "缺少必需参数: $param_name"
        return 1
    fi
}

# Assert directory exists, exit if not
# Usage: assert_directory "$dir_path" "directory_name"
assert_directory() {
    local dir_path="$1"
    local dir_name="${2:-$dir_path}"

    if ! validate_directory "$dir_path"; then
        error_msg "目录不存在: $dir_name" "路径: $dir_path"
        return 1
    fi
}

# Assert file exists, exit if not
# Usage: assert_file "$file_path" "file_name"
assert_file() {
    local file_path="$1"
    local file_name="${2:-$file_path}"

    if ! validate_file "$file_path"; then
        error_msg "文件不存在: $file_name" "路径: $file_path"
        return 1
    fi
}

# Assert command exists, exit if not
# Usage: assert_command "command_name"
assert_command() {
    local cmd="$1"

    if ! validate_command "$cmd"; then
        error_msg "命令未找到: $cmd"
        warning_msg "请确保 '$cmd' 已安装并在 PATH 中"
        return 1
    fi
}

# Assert parameter matches pattern, exit if not
# Usage: assert_pattern "$value" "pattern" "pattern_name"
assert_pattern() {
    local value="$1"
    local pattern="$2"
    local pattern_name="$3"

    if ! validate_pattern "$value" "$pattern" "$pattern_name"; then
        error_msg "参数格式无效: $pattern_name" "预期格式: $pattern"
        return 1
    fi
}

# Export all functions for use in subshells
export -f error_msg warning_msg success_msg info_msg
export -f validate_param_count validate_not_empty validate_directory validate_file validate_command validate_pattern
export -f assert_param assert_directory assert_file assert_command assert_pattern
export -f print_usage
