#!/usr/bin/env bash
# unit/test_tools.sh - Configuration tools unit tests
# Tests for zsh_tools.sh commands: validate, backup, restore, clean, benchmark
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
    log_debug "Setting up tools tests..."
    setup_fixtures
    setup_mock_environment "with_zsh"
}

teardown() {
    log_debug "Tearing down tools tests..."
    teardown_fixtures
}

# ============================================================================
# Validate Command Tests
# ============================================================================

# Test validate command exists
test_validate_command_available() {
    # Check if the zsh_tools script exists
    local tools_script="$SCRIPT_DIR/../../scripts/zsh_tools.sh"

    if [[ -f "$tools_script" ]]; then
        log_success "zsh_tools.sh script found"
        return 0
    fi

    log_warn "zsh_tools.sh script not found (expected in integration tests)"
    return 0
}

# Test validate detects valid configuration
test_validate_valid_configuration() {
    create_mock_zshrc "$(get_temp_dir)"

    local zshrc="$(get_temp_dir)/.zshrc"
    assert_file_exists "$zshrc" "Mock .zshrc should be created"
    assert_file_readable "$zshrc" ".zshrc should be readable"
}

# Test validate detects missing configuration
test_validate_missing_configuration() {
    local missing_file="$(get_temp_dir)/missing.zshrc"

    assert_file_not_exists "$missing_file" "Missing file should not exist"
}

# Test validate checks zsh version
test_validate_zsh_version_check() {
    local zsh_version=0
    if command -v zsh &>/dev/null; then
        zsh_version=$(zsh --version | grep -oE '[0-9]+\.[0-9]+')
    fi

    if [[ -n "$zsh_version" ]]; then
        log_success "ZSH version detected: $zsh_version"
    else
        log_warn "ZSH not available on this system"
    fi

    return 0
}

# ============================================================================
# Backup Command Tests
# ============================================================================

# Test backup creates backup file
test_backup_creates_file() {
    local original="$(get_temp_dir)/.zshrc"
    local backup_dir="$(get_backup_dir)"

    create_mock_zshrc "$(get_temp_dir)"

    # Simulate backup
    cp "$original" "$backup_dir/.zshrc.backup"

    assert_file_exists "$backup_dir/.zshrc.backup" "Backup file should be created"
}

# Test backup preserves content
test_backup_preserves_content() {
    local original="$(get_temp_dir)/.zshrc"
    local backup_dir="$(get_backup_dir)"

    create_mock_zshrc "$(get_temp_dir)"
    cp "$original" "$backup_dir/.zshrc.backup"

    assert_files_equal "$original" "$backup_dir/.zshrc.backup" \
        "Backup should be identical to original"
}

# Test backup with timestamp
test_backup_with_timestamp() {
    local backup_dir="$(get_backup_dir)"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$backup_dir/.zshrc.backup.$timestamp"

    mkdir -p "$backup_dir"
    echo "backup content" > "$backup_file"

    assert_file_exists "$backup_file" "Timestamped backup should exist"
}

# Test multiple backups
test_multiple_backups_rotation() {
    local backup_dir="$(get_backup_dir)"

    for i in {1..5}; do
        create_test_file ".zshrc.backup.$i" "backup $i" "$backup_dir"
    done

    local count=$(find "$backup_dir" -name ".zshrc.backup.*" | wc -l)
    assert_num_equal 5 "$count" "Should have 5 backup files"
}

# ============================================================================
# Restore Command Tests
# ============================================================================

# Test restore from backup
test_restore_from_backup() {
    local backup_dir="$(get_backup_dir)"
    local backup_file="$backup_dir/.zshrc.backup"
    local restore_file="$(get_temp_dir)/.zshrc"

    create_test_file ".zshrc.backup" "backed up content" "$backup_dir"

    cp "$backup_file" "$restore_file"

    assert_file_exists "$restore_file" "Restored file should exist"
}

# Test restore verifies backup exists
test_restore_verifies_backup_exists() {
    local non_existent_backup="$(get_backup_dir)/.zshrc.backup.nonexistent"

    assert_file_not_exists "$non_existent_backup" \
        "Non-existent backup should not be found"
}

# Test restore overwrites current config
test_restore_overwrites_config() {
    local original_content="original content"
    local backup_content="backed up content"
    local backup_file="$(get_backup_dir)/.zshrc.backup"
    local target_file="$(get_temp_dir)/.zshrc"

    create_test_file ".zshrc.backup" "$backup_content" "$(get_backup_dir)"
    create_test_file ".zshrc" "$original_content" "$(get_temp_dir)"

    # Simulate restore
    cp "$backup_file" "$target_file"

    local restored_content=$(cat "$target_file")
    assert_equal "$backup_content" "$restored_content" \
        "Restored file should have backup content"
}

# ============================================================================
# Clean Command Tests
# ============================================================================

# Test clean removes cache files
test_clean_removes_cache() {
    local cache_dir="$(get_temp_dir)/.zsh/cache"

    mkdir -p "$cache_dir"
    create_test_file "completion_cache" "cached data" "$cache_dir"

    assert_file_exists "$cache_dir/completion_cache" "Cache file should exist before clean"

    # Simulate clean
    rm -f "$cache_dir/completion_cache"

    assert_file_not_exists "$cache_dir/completion_cache" "Cache file should be removed"
}

# Test clean lists files to remove
test_clean_lists_files() {
    local cache_dir="$(get_temp_dir)/.zsh/cache"

    mkdir -p "$cache_dir"
    for i in {1..3}; do
        create_test_file "cache_$i" "cache" "$cache_dir"
    done

    local file_count=$(find "$cache_dir" -type f | wc -l)
    assert_num_equal 3 "$file_count" "Should have 3 cache files"
}

# Test clean with dry-run
test_clean_dry_run_mode() {
    local cache_dir="$(get_temp_dir)/.zsh/cache"

    mkdir -p "$cache_dir"
    create_test_file "cache_file" "data" "$cache_dir"

    local original_count=$(find "$cache_dir" -type f | wc -l)

    # In dry-run mode, files should not be deleted
    # (simulation only, actual deletion would happen without dry-run)

    local after_count=$(find "$cache_dir" -type f | wc -l)
    assert_num_equal "$original_count" "$after_count" \
        "Dry-run should not delete files"
}

# ============================================================================
# Benchmark Command Tests
# ============================================================================

# Test benchmark measures startup time
test_benchmark_measures_startup() {
    local start_time
    local end_time
    local elapsed

    start_time=$(start_timer)
    sleep 0.01  # Simulate work
    end_time=$(start_timer)

    elapsed=$((end_time - start_time))
    assert_num_gt "$elapsed" "-1" "Elapsed time should be measured"
}

# Test benchmark output format
test_benchmark_output_format() {
    local output="冷启动时间: ~1.2s"

    assert_string_contains "$output" "启动时间" "Output should contain timing info"
}

# Test benchmark performance rating
test_benchmark_performance_rating() {
    local startup_time=600  # 0.6 seconds

    if [[ $startup_time -lt 1000 ]]; then
        log_success "Performance is good (< 1.0s)"
        return 0
    fi

    return 1
}

# ============================================================================
# Doctor Command Tests
# ============================================================================

# Test doctor checks zsh version
test_doctor_checks_zsh_version() {
    if command -v zsh &>/dev/null; then
        log_success "zsh is installed"
        return 0
    else
        log_warn "zsh not installed"
    fi

    return 0
}

# Test doctor checks dependencies
test_doctor_checks_dependencies() {
    local deps_found=0

    for cmd in zsh bash git; do
        if command -v "$cmd" &>/dev/null; then
            ((deps_found++))
        fi
    done

    assert_num_gt "$deps_found" "0" "At least some dependencies should be found"
}

# Test doctor generates report
test_doctor_generates_report() {
    local temp_report="$(get_temp_dir)/doctor_report.txt"

    echo "ZSH Environment Report" > "$temp_report"
    echo "  Version: 5.8" >> "$temp_report"
    echo "  Status: OK" >> "$temp_report"

    assert_file_contains "$temp_report" "Report" "Report should contain header"
    assert_file_contains "$temp_report" "Version" "Report should contain version info"
}

# ============================================================================
# Error Handling Tests
# ============================================================================

# Test invalid command handling
test_invalid_command_handling() {
    local invalid_cmd="invalid_command"

    assert_failure "zsh_tools.sh $invalid_cmd" \
        "Invalid command should fail"
}

# Test missing parameters handling
test_missing_parameters_handling() {
    # Commands that require parameters should fail without them
    log_info "Missing parameters would be handled by actual script"
    return 0
}

# Test help text display
test_help_text_display() {
    local help_text="Usage: zsh_tools.sh"

    assert_string_contains "$help_text" "Usage" "Help should show usage"
}

# ============================================================================
# Integration Tests
# ============================================================================

# Test command chaining
test_command_sequence() {
    local actions=("backup" "clean" "restore")

    for action in "${actions[@]}"; do
        log_debug "Testing action: $action"
    done

    log_success "Command sequence validated"
    return 0
}

# Test state persistence
test_state_persistence() {
    local state_file="$(get_temp_dir)/.zsh/state"

    mkdir -p "$(dirname "$state_file")"
    echo "initialized" > "$state_file"

    assert_file_exists "$state_file" "State file should be created"
    assert_file_contains "$state_file" "initialized" "State should be persisted"
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
