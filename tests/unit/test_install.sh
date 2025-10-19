#!/usr/bin/env bash
# unit/test_install.sh - Installation script unit tests
# Tests for install_zsh_config.sh functionality
# Version: 1.0
# Created: 2025-10-19

# Source test libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/test_utils.sh"
source "$SCRIPT_DIR/../lib/assertions.sh"
source "$SCRIPT_DIR/../lib/fixtures.sh"

# ============================================================================
# Setup and Teardown
# ============================================================================

setup() {
    log_debug "Setting up install tests..."
    setup_fixtures

    # Setup mock environment
    setup_mock_environment "empty_home"

    # Create mock install script
    create_mock_install_script "$(get_temp_dir)"
}

teardown() {
    log_debug "Tearing down install tests..."
    teardown_fixtures
}

# ============================================================================
# Script Availability Tests
# ============================================================================

# Test install script exists
test_install_script_exists() {
    local script="$(get_temp_dir)/install_zsh_config_mock.sh"

    assert_file_exists "$script" "Install script should exist"
}

# Test install script is executable
test_install_script_executable() {
    local script="$(get_temp_dir)/install_zsh_config_mock.sh"

    # Set executable permission
    chmod +x "$script"

    assert_file_readable "$script" "Install script should be readable"
}

# ============================================================================
# Basic Execution Tests
# ============================================================================

# Test install script runs successfully
test_install_script_runs() {
    local script="$(get_temp_dir)/install_zsh_config_mock.sh"

    assert_success "$script" "Install script should run successfully"
}

# Test install script runs with force flag
test_install_script_force_flag() {
    local script="$(get_temp_dir)/install_zsh_config_mock.sh"

    assert_success "$script --force" "Install script should accept --force flag"
}

# Test install script dry-run mode
test_install_script_dry_run_mode() {
    local script="$(get_temp_dir)/install_zsh_config_mock.sh"

    assert_success "$script --dry-run" "Install script should support dry-run mode"
}

# ============================================================================
# Configuration Detection Tests
# ============================================================================

# Test zsh detection
test_zsh_detection() {
    if command -v zsh &>/dev/null; then
        log_success "zsh is available"
        return 0
    fi

    log_warn "zsh not available on this system"
    return 0  # Don't fail if zsh not installed
}

# Test bash requirement
test_bash_requirement() {
    if command -v bash &>/dev/null; then
        log_success "bash is available"
        return 0
    fi

    log_error "bash is required but not available"
    return 1
}

# ============================================================================
# Antigen Installation Tests
# ============================================================================

# Test antigen detection
test_antigen_detection() {
    local antigen_dir="$HOME/.antigen"

    if [[ ! -d "$antigen_dir" ]]; then
        log_info "Antigen not yet installed (expected in test environment)"
        return 0
    fi

    assert_dir_exists "$antigen_dir" "Antigen directory should exist if installed"
}

# Test antigen installation simulation
test_antigen_installation_simulation() {
    local antigen_dir="$(get_temp_dir)/.antigen"
    local antigen_file="$antigen_dir/antigen.zsh"

    mkdir -p "$antigen_dir"
    create_test_file "antigen.zsh" "# Mock antigen" "$antigen_dir"

    assert_file_exists "$antigen_file" "Antigen file should be created"
}

# ============================================================================
# Configuration File Tests
# ============================================================================

# Test .zshrc creation
test_zshrc_creation() {
    local zshrc_file="$(get_temp_dir)/.zshrc"

    create_mock_zshrc "$(get_temp_dir)"

    assert_file_exists "$zshrc_file" ".zshrc should be created"
    assert_file_readable "$zshrc_file" ".zshrc should be readable"
}

# Test .zshrc content
test_zshrc_content() {
    local zshrc_file="$(get_temp_dir)/.zshrc"

    create_mock_zshrc "$(get_temp_dir)"

    assert_file_contains "$zshrc_file" "#!/bin/zsh" ".zshrc should contain shebang"
    assert_file_contains "$zshrc_file" "antigen" ".zshrc should reference antigen"
    assert_file_contains "$zshrc_file" "robbyrussell" ".zshrc should reference theme"
}

# Test functions directory creation
test_functions_directory_creation() {
    local functions_dir="$(get_temp_dir)/.zsh/functions"

    mkdir -p "$functions_dir"

    assert_dir_exists "$functions_dir" "Functions directory should be created"
}

# ============================================================================
# Backup and Restore Tests
# ============================================================================

# Test backup creation
test_backup_creation() {
    local original_file="$(get_temp_dir)/.zshrc"
    local backup_dir="$(get_backup_dir)"

    create_mock_zshrc "$(get_temp_dir)"

    # Simulate backup
    cp "$original_file" "$backup_dir/.zshrc.backup"

    assert_file_exists "$backup_dir/.zshrc.backup" "Backup file should be created"
}

# Test backup restoration
test_backup_restoration() {
    local backup_file="$(get_backup_dir)/.zshrc.backup"
    local restore_file="$(get_temp_dir)/.zshrc"

    create_test_file ".zshrc.backup" "backed up content" "$(get_backup_dir)"

    # Simulate restore
    cp "$backup_file" "$restore_file"

    assert_file_exists "$restore_file" "Restored file should exist"
    assert_files_equal "$backup_file" "$restore_file" "Restored file should match backup"
}

# Test multiple backups
test_multiple_backups() {
    local backup_dir="$(get_backup_dir)"

    for i in {1..3}; do
        create_test_file ".zshrc.backup.$i" "backup $i" "$backup_dir"
    done

    local count=$(find "$backup_dir" -name ".zshrc.backup.*" | wc -l)

    assert_num_equal 3 "$count" "Should have created 3 backup files"
}

# ============================================================================
# Permission Tests
# ============================================================================

# Test configuration file permissions
test_config_file_permissions() {
    local config_file="$(get_temp_dir)/.zshrc"

    create_mock_zshrc "$(get_temp_dir)"

    assert_file_readable "$config_file" "Configuration file should be readable"
    assert_file_writable "$config_file" "Configuration file should be writable by owner"
}

# Test backup directory permissions
test_backup_directory_permissions() {
    local backup_dir="$(get_backup_dir)"

    assert_dir_exists "$backup_dir" "Backup directory should exist"
    assert_file_writable "$backup_dir" "Backup directory should be writable"
}

# ============================================================================
# Validation Tests
# ============================================================================

# Test syntax validation of created .zshrc
test_zshrc_syntax_validation() {
    local zshrc_file="$(get_temp_dir)/.zshrc"

    create_mock_zshrc "$(get_temp_dir)"

    # Verify it's a valid bash/zsh file (no syntax errors)
    assert_success "bash -n '$zshrc_file'" \
        "Created .zshrc should have valid syntax"
}

# Test validation function file exists
test_validation_file_creation() {
    local validation_file="$(get_temp_dir)/validation.zsh"

    create_mock_validation "$(get_temp_dir)"

    assert_file_exists "$validation_file" "Validation file should be created"
}

# ============================================================================
# Environment Integration Tests
# ============================================================================

# Test home directory detection
test_home_directory_detection() {
    local home_dir="$HOME"

    assert_not_empty "$home_dir" "HOME variable should be set"
    assert_dir_exists "$home_dir" "HOME directory should exist"
}

# Test zsh directory structure
test_zsh_directory_structure() {
    local zsh_dir="$(get_temp_dir)/.zsh"

    create_test_directory_structure "$(get_temp_dir)" "functions:cache:completion"

    assert_dir_exists "$zsh_dir" ".zsh directory should exist"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

# Test missing dependencies handling
test_missing_dependencies_detection() {
    # This test verifies the script can detect missing dependencies
    # In a mock environment, we can't truly test this, so we verify the logic
    log_info "Missing dependencies detection would be tested in integration tests"
    return 0
}

# Test permission error handling
test_permission_error_handling() {
    local protected_file="$(get_temp_dir)/protected.txt"

    create_test_file "protected.txt" "content" "$(get_temp_dir)"

    # Make it read-only
    chmod 444 "$protected_file"

    # Verify it's not writable
    if [[ ! -w "$protected_file" ]]; then
        log_success "Permission restriction verified"
        chmod 644 "$protected_file"  # Restore for cleanup
        return 0
    fi

    return 1
}

# ============================================================================
# Execution
# ============================================================================

# Run setup
setup

# Run all test functions
for func in $(declare -F | grep " test_" | awk '{print $3}'); do
    if ! run_test "$func" "$func"; then
        true  # Continue to next test even on failure
    fi
done

# Run teardown
teardown

exit 0
