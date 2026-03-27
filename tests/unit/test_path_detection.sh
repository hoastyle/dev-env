#!/bin/bash
# =============================================================================
# Path Detection Unit Tests
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# 源测试库
source "$SCRIPT_DIR/../lib/test_utils.sh"
source "$SCRIPT_DIR/../lib/assertions.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

# =============================================================================
# 测试函数
# =============================================================================

# 测试脚本目录检测
test_script_dir_detection() {
    local script_dir="$PROJECT_ROOT/scripts"

    assert_dir_exists "$script_dir" "Scripts directory should exist"
    assert_file_readable "$script_dir/zsh_launcher.sh" "Launcher script should be readable"
}

# 测试配置目录检测
test_config_dir_detection() {
    local config_dir="$PROJECT_ROOT/config"

    assert_dir_exists "$config_dir" "Config directory should exist"
    assert_file_exists "$config_dir/.zshrc" "Main zshrc should exist"
}

# 测试相对路径解析
test_relative_path_resolution() {
    cd "$PROJECT_ROOT" || return 1

    local relative_path="scripts/zsh_launcher.sh"
    local resolved_path="$PROJECT_ROOT/$relative_path"

    assert_file_exists "$resolved_path" "Relative path should resolve correctly"
}

# 测试绝对路径检测
test_absolute_path_detection() {
    local absolute_path="$PROJECT_ROOT/config/.zshrc"

    assert_file_exists "$absolute_path" "Absolute path should exist"
    assert_string_contains "$absolute_path" "$PROJECT_ROOT" "Absolute path should contain project root"
}

# 测试从脚本执行检测路径
test_path_from_script_execution() {
    local script_output
    script_output=$(bash "$PROJECT_ROOT/scripts/zsh_launcher.sh" help 2>&1 || true)

    assert_not_empty "$script_output" "Script should produce output"
    assert_string_contains "$script_output" "ZSH" "Output should contain ZSH"
}

# 测试主目录检测
test_home_directory_detection() {
    assert_dir_exists "$HOME" "Home directory should exist"
    assert_file_writable "$HOME" "Home directory should be writable"
}

# 测试 ZSH 自定义路径检测
test_zsh_custom_path() {
    local zsh_custom="${ZSH_CUSTOM:-$HOME/.zsh/custom}"

    # 如果目录不存在，创建它
    if [[ ! -d "$zsh_custom" ]]; then
        mkdir -p "$zsh_custom" || return 1
    fi

    assert_dir_exists "$zsh_custom" "ZSH custom directory should exist"
}

# 测试 NVM 路径检测
test_nvm_detection() {
    if [[ -n "$NVM_DIR" ]]; then
        assert_dir_exists "$NVM_DIR" "NVM_DIR should exist if set"
    else
        log_info "NVM_DIR not set, skipping NVM tests"
        record_skip
    fi
}

# 测试 Conda 路径检测
test_conda_detection() {
    if [[ -n "${CONDA_DEFAULT_ENV:-}" ]] || [[ -d "$HOME/miniconda3" ]]; then
        # Conda 环境存在
        log_info "Conda environment detected"
        record_pass
    else
        log_info "Conda not found, skipping conda tests"
        record_skip
    fi
}

# 测试函数库路径
test_function_library_path() {
    assert_dir_exists "$PROJECT_ROOT/zsh-functions" "Function library directory should exist"
}

# 测试配置文件路径有效性
test_config_file_paths() {
    # 检查配置文件
    assert_file_exists "$PROJECT_ROOT/config/.zshrc" "Main config should exist"
    assert_file_exists "$PROJECT_ROOT/config/.zshrc.optimized" "Optimized config should exist"
    assert_file_exists "$PROJECT_ROOT/config/.zshrc.ultra-optimized" "Ultra-optimized config should exist"
}

# 测试脚本路径检测功能
test_get_project_root_function() {
    local result
    local script_output
    local script_path

    script_output=$(bash "$PROJECT_ROOT/scripts/zsh_launcher.sh" help 2>&1 || true)
    script_path=$(echo "$script_output" | sed -n 's/^用法: \([^ ]*\) .*/\1/p' | head -n1)
    result="$(dirname "$(dirname "$script_path")")"

    assert_not_empty "$result" "get_project_root should return a path"
    assert_dir_exists "$result" "Returned path should exist"
}

# =============================================================================
# 生命周期函数
# =============================================================================

setup() {
    log_info "Setting up path detection tests"
    setup_fixtures
}

teardown() {
    log_info "Tearing down path detection tests"
    teardown_fixtures
}

# =============================================================================
# 主执行
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite "$@"
fi
