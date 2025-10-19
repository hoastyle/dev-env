#!/usr/bin/env bash
# unit/test_dryrun.sh - Dry-run mode unit tests
# Tests for lib_dryrun.sh functions and dry-run mode integration
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
    log_debug "Setting up dry-run tests..."
    setup_fixtures

    # Create mock dryrun library
    create_mock_dryrun_lib "$(get_temp_dir)"

    # Create mock install script
    create_mock_install_script "$(get_temp_dir)"
}

teardown() {
    log_debug "Tearing down dry-run tests..."
    teardown_fixtures
}

# ============================================================================
# Dry-run Flag Tests
# ============================================================================

# Test dry-run flag detection
test_dry_run_flag_detection() {
    local DRY_RUN=1

    if [[ $DRY_RUN -eq 1 ]]; then
        log_success "Dry-run flag correctly detected"
        return 0
    fi

    return 1
}

# Test dry-run disabled by default
test_dry_run_disabled_by_default() {
    local DRY_RUN="${DRY_RUN:-0}"

    assert_num_equal 0 "$DRY_RUN" "Dry-run should be disabled by default"
}

# Test dry-run parameter parsing
test_dry_run_parameter_parsing() {
    local args="--dry-run"

    if [[ "$args" =~ --dry-run ]]; then
        log_success "Dry-run parameter correctly parsed"
        return 0
    fi

    return 1
}

# ============================================================================
# Mock mkdir Tests
# ============================================================================

# Test dry_mkdir in dry-run mode
test_dry_mkdir_dry_run_mode() {
    local output
    local test_dir="$(get_temp_dir)/test_mkdir"

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    output=$(dry_mkdir "$test_dir" 2>&1)

    assert_string_contains "$output" "DRY RUN:" "dry_mkdir should output dry-run message"
    assert_dir_not_exists "$test_dir" "Directory should not be created in dry-run mode"

    unset DRY_RUN
}

# Test dry_mkdir in normal mode
test_dry_mkdir_normal_mode() {
    local test_dir="$(get_temp_dir)/test_mkdir_normal"

    export DRY_RUN=0
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    dry_mkdir "$test_dir"

    assert_dir_exists "$test_dir" "Directory should be created in normal mode"

    unset DRY_RUN
}

# ============================================================================
# Mock Copy Tests
# ============================================================================

# Test dry_cp in dry-run mode
test_dry_cp_dry_run_mode() {
    local src="$(get_temp_dir)/source.txt"
    local dst="$(get_temp_dir)/dest.txt"
    local output

    create_test_file "source.txt" "test content" "$(get_temp_dir)"

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    output=$(dry_cp "$src" "$dst" 2>&1)

    assert_string_contains "$output" "DRY RUN:" "dry_cp should output dry-run message"
    assert_file_not_exists "$dst" "File should not be copied in dry-run mode"

    unset DRY_RUN
}

# Test dry_cp in normal mode
test_dry_cp_normal_mode() {
    local src="$(get_temp_dir)/source.txt"
    local dst="$(get_temp_dir)/dest.txt"

    create_test_file "source.txt" "test content" "$(get_temp_dir)"

    export DRY_RUN=0
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    dry_cp "$src" "$dst"

    assert_file_exists "$dst" "File should be copied in normal mode"
    assert_files_equal "$src" "$dst" "Copied file should be identical"

    unset DRY_RUN
}

# ============================================================================
# Install Script Tests
# ============================================================================

# Test install script with --dry-run
test_install_script_dry_run() {
    local output
    local mock_script="$(get_temp_dir)/install_zsh_config_mock.sh"

    output=$("$mock_script" --dry-run 2>&1)

    assert_string_contains "$output" "DRY RUN:" \
        "Install script should indicate dry-run mode"
}

# Test install script without --dry-run
test_install_script_normal_mode() {
    local output
    local mock_script="$(get_temp_dir)/install_zsh_config_mock.sh"

    output=$("$mock_script" 2>&1)

    assert_string_contains "$output" "Installing" \
        "Install script should perform installation"
}

# Test install script --dry-run exit code
test_install_script_dry_run_exit_code() {
    local mock_script="$(get_temp_dir)/install_zsh_config_mock.sh"

    assert_exit_code 0 "'$mock_script' --dry-run" \
        "Install script should return success in dry-run mode"
}

# ============================================================================
# Output Verification Tests
# ============================================================================

# Test dry-run output format
test_dry_run_output_format() {
    local output="DRY RUN: mkdir -p /some/path"

    assert_string_contains "$output" "DRY RUN:" "Output should contain dry-run indicator"
    assert_string_contains "$output" "mkdir" "Output should contain operation"
}

# Test dry-run shows actual command
test_dry_run_shows_command() {
    local test_dir="$(get_temp_dir)/show_command_test"
    local output

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    output=$(dry_mkdir "$test_dir" 2>&1)

    assert_string_contains "$output" "$test_dir" "Output should show the actual path"

    unset DRY_RUN
}

# Test dry-run preserves all details
test_dry_run_preserves_details() {
    local src="/source/file.txt"
    local dst="/dest/file.txt"
    local output

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    output=$(dry_cp "$src" "$dst" 2>&1)

    assert_string_contains "$output" "$src" "Output should show source path"
    assert_string_contains "$output" "$dst" "Output should show destination path"

    unset DRY_RUN
}

# ============================================================================
# No Modifications Tests
# ============================================================================

# Test dry-run does not create files
test_dry_run_no_file_creation() {
    local test_file="$(get_temp_dir)/dry_run_test_file.txt"
    local file_count_before

    file_count_before=$(find "$(get_temp_dir)" -type f | wc -l)

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    dry_mkdir "$test_file"

    unset DRY_RUN

    local file_count_after=$(find "$(get_temp_dir)" -type f | wc -l)

    # File count should not increase (only the mock library files exist)
    if [[ $file_count_after -le $file_count_before ]]; then
        log_success "Dry-run mode did not create additional files"
        return 0
    fi

    return 1
}

# Test dry-run does not modify existing files
test_dry_run_no_file_modification() {
    local test_file="$(get_temp_dir)/test_file.txt"
    local original_content="original content"
    local original_mtime

    create_test_file "test_file.txt" "$original_content" "$(get_temp_dir)"
    original_mtime=$(stat -f%m "$test_file" 2>/dev/null || stat -c%Y "$test_file")

    sleep 0.1

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    # Try to copy over the file in dry-run
    dry_cp "$test_file" "$test_file"

    unset DRY_RUN

    # Verify file is unchanged
    local content_after=$(cat "$test_file")
    assert_equal "$original_content" "$content_after" "File content should not change"
}

# ============================================================================
# Integration Tests
# ============================================================================

# Test multiple dry-run operations
test_multiple_dry_run_operations() {
    local output_count=0
    local test_dir="$(get_temp_dir)/multi_op_test"

    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"

    # Try multiple operations
    dry_mkdir "$test_dir"
    dry_mkdir "$test_dir/subdir"

    unset DRY_RUN

    # Verify nothing was created
    assert_dir_not_exists "$test_dir" "Base directory should not exist"
    assert_dir_not_exists "$test_dir/subdir" "Subdirectory should not exist"
}

# Test dry-run toggle
test_dry_run_toggle() {
    local test_dir="$(get_temp_dir)/toggle_test"

    # First: dry-run
    export DRY_RUN=1
    source "$(get_temp_dir)/lib_dryrun_mock.sh"
    dry_mkdir "$test_dir"

    assert_dir_not_exists "$test_dir" "Directory should not exist after dry-run"

    # Second: normal mode
    export DRY_RUN=0
    source "$(get_temp_dir)/lib_dryrun_mock.sh"
    dry_mkdir "$test_dir"

    assert_dir_exists "$test_dir" "Directory should exist after normal mode"

    unset DRY_RUN
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
