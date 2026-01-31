#!/bin/bash
# =============================================================================
# Configuration Validation Unit Tests
# =============================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../lib/test_utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assertions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixtures.sh"

# =============================================================================
# 测试函数
# =============================================================================

# 测试主 ZSH 配置文件存在性
test_main_zshrc_exists() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    assert_file_exists "$config_file" "Main .zshrc should exist"
}

# 测试主配置文件语法
test_main_zshrc_syntax() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    local syntax_check
    syntax_check=$(zsh -n "$config_file" 2>&1)
    local exit_code=$?

    assert_equal 0 $exit_code ".zshrc should have valid syntax"
}

# 测试优化配置文件存在性
test_optimized_zshrc_exists() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.optimized"

    assert_file_exists "$config_file" "Optimized .zshrc should exist"
}

# 测试优化配置文件语法
test_optimized_zshrc_syntax() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.optimized"

    local syntax_check
    syntax_check=$(zsh -n "$config_file" 2>&1)
    local exit_code=$?

    assert_equal 0 $exit_code ".zshrc.optimized should have valid syntax"
}

# 测试超优化配置文件存在性
test_ultra_optimized_zshrc_exists() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.ultra-optimized"

    assert_file_exists "$config_file" "Ultra-optimized .zshrc should exist"
}

# 测试超优化配置文件语法
test_ultra_optimized_zshrc_syntax() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.ultra-optimized"

    local syntax_check
    syntax_check=$(zsh -n "$config_file" 2>&1)
    local exit_code=$?

    assert_equal 0 $exit_code ".zshrc.ultra-optimized should have valid syntax"
}

# 测试模块化配置存在性
test_modular_zshrc_exists() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.modular"

    assert_file_exists "$config_file" "Modular .zshrc should exist"
}

# 测试配置文件包含 Antigen
test_zshrc_contains_antigen() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    assert_file_contains "$config_file" "antigen" ".zshrc should use antigen"
}

# 测试配置文件设置主题
test_zshrc_contains_theme() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    assert_file_contains "$config_file" "theme\|prompt" ".zshrc should set theme"
}

# 测试配置文件没有硬编码路径
test_zshrc_no_hardcoded_paths() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    # 检查不应该有硬编码的用户路径
    assert_file_not_contains "$config_file" "/home/[a-zA-Z0-9]" "Should not contain hardcoded user paths"
}

# 测试模块化配置源文件目录
test_zshrc_sources_directory() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.modular"

    assert_file_contains "$config_file" ".zshrc.d" "Modular config should source .zshrc.d directory"
}

# 测试 .zshrc.d 目录结构
test_zshrcd_directory_structure() {
    local zshrcd_dir
    zshrcd_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.d"

    assert_dir_exists "$zshrcd_dir" ".zshrc.d directory should exist"
}

# 测试模块文件命名规范
test_zshrcd_module_naming() {
    local zshrcd_dir
    zshrcd_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.d"

    # 检查模块文件是否按数字顺序命名
    local modules
    modules=$(ls "$zshd_dir"/[0-9]*.zsh 2>/dev/null || true)

    if [[ -n "$modules" ]]; then
        # 验证文件名以数字开头
        for module in $modules; do
            local filename=$(basename "$module")
            [[ "$filename" =~ ^[0-9] ]] || assert_fail "Module should start with number: $filename"
        done
    fi
}

# 测试模块文件语法
test_zshrcd_modules_syntax() {
    local zshrcd_dir
    zshrcd_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.d"

    for module in "$zshrcd_dir"/*.zsh; do
        if [[ -f "$module" ]]; then
            local syntax_check
            syntax_check=$(zsh -n "$module" 2>&1)
            local exit_code=$?

            if [[ $exit_code -ne 0 ]]; then
                log_error "Syntax error in $module: $syntax_check"
            fi

            assert_equal 0 $exit_code "$module should have valid syntax"
        fi
    done
}

# 测试NVM优化配置存在性
test_nvm_optimized_config_exists() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc.nvm-optimized"

    # 这个文件是可选的
    if [[ -f "$config_file" ]]; then
        assert_file_readable "$config_file" "NVM optimized config should be readable"
    else
        log_info "NVM optimized config not found (optional)"
        record_skip
    fi
}

# 测试配置文件完整性
test_config_completeness() {
    local project_root
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    # 检查关键配置文件
    assert_file_exists "$project_root/config/.zshrc" "Main config required"
    assert_file_exists "$project_root/config/.zshrc.optimized" "Optimized config required"
    assert_file_exists "$project_root/config/.zshrc.ultra-optimized" "Ultra-optimized config required"
}

# 测试配置文件之间的差异
test_config_mode_differences() {
    local project_root
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    local main_size=$(get_file_size "$project_root/config/.zshrc")
    local optimized_size=$(get_file_size "$project_root/config/.zshrc.optimized")

    # 优化版本应该更小（更少插件）
    log_info "Main config size: $main_size bytes"
    log_info "Optimized config size: $optimized_size bytes"

    # 优化版本应该明显更小
    if [[ $main_size -gt 0 ]]; then
        assert_num_lt $optimized_size $main_size "Optimized config should be smaller than main config"
    fi
}

# 测试配置文件可读性
test_config_files_readable() {
    local project_root
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

    assert_file_readable "$project_root/config/.zshrc" "Main config should be readable"
    assert_file_readable "$project_root/config/.zshrc.optimized" "Optimized config should be readable"
    assert_file_readable "$project_root/config/.zshrc.ultra-optimized" "Ultra-optimized config should be readable"
}

# 测试配置文件变量导出
test_config_exports_variables() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    # 检查是否导出关键变量
    assert_file_contains "$config_file" "export PATH" "Should export PATH"
    assert_file_contains "$config_file" "export EDITOR\|export VISUAL" "Should export editor"
}

# 测试配置文件的插件设置
test_config_plugin_settings() {
    local config_file
    config_file="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)/.zshrc"

    # 检查 Antigen 插件设置
    assert_file_contains "$config_file" "antigen bundle" "Should have antigen bundles"
    assert_file_contains "$config_file" "antigen theme\|antigen apply" "Should apply antigen theme"
}

# =============================================================================
# 生命周期函数
# =============================================================================

setup() {
    log_info "Setting up config validation tests"
    setup_fixtures
}

teardown() {
    log_info "Tearing down config validation tests"
    teardown_fixtures
}

# =============================================================================
# 主执行
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_test_suite "$@"
fi
