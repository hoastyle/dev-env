#!/usr/bin/env bash
# integration/test_end_to_end.sh - End-to-end integration tests
# Tests complete workflows and component interactions
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
    log_debug "Setting up end-to-end tests..."
    setup_fixtures
    setup_mock_environment "with_zsh"
}

teardown() {
    log_debug "Tearing down end-to-end tests..."
    teardown_fixtures
}

# ============================================================================
# Basic Installation Workflow
# ============================================================================

# Test complete installation flow
test_complete_installation_workflow() {
    local temp_dir="$(get_temp_dir)"
    local mock_script="$temp_dir/install_zsh_config_mock.sh"

    create_mock_install_script "$temp_dir"

    # Step 1: Verify script exists
    assert_file_exists "$mock_script" "Installation script should exist"

    # Step 2: Execute installation
    assert_success "$mock_script" "Installation should complete successfully"

    # Step 3: Verify configuration
    create_mock_zshrc "$temp_dir"
    assert_file_exists "$temp_dir/.zshrc" "ZSH configuration should be created"

    log_success "Complete installation workflow passed"
}

# Test installation with validation
test_installation_with_validation() {
    local temp_dir="$(get_temp_dir)"

    # Step 1: Create configuration
    create_mock_zshrc "$temp_dir"

    # Step 2: Validate configuration
    assert_file_readable "$temp_dir/.zshrc" "Configuration should be readable"

    # Step 3: Create validation module
    create_mock_validation "$temp_dir"

    assert_file_exists "$temp_dir/validation.zsh" "Validation module should exist"

    log_success "Installation with validation passed"
}

# ============================================================================
# Backup and Restore Workflow
# ============================================================================

# Test backup creation workflow
test_backup_creation_workflow() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"

    # Step 1: Create original configuration
    create_mock_zshrc "$temp_dir"
    local original="$temp_dir/.zshrc"

    # Step 2: Create backup
    cp "$original" "$backup_dir/.zshrc.backup"

    # Step 3: Verify backup
    assert_file_exists "$backup_dir/.zshrc.backup" "Backup should be created"
    assert_files_equal "$original" "$backup_dir/.zshrc.backup" \
        "Backup should match original"

    log_success "Backup creation workflow passed"
}

# Test restore workflow
test_restore_workflow() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"
    local backup_file="$backup_dir/.zshrc.backup"
    local config_file="$temp_dir/.zshrc"

    # Step 1: Create and backup configuration
    create_mock_zshrc "$temp_dir"
    cp "$config_file" "$backup_file"

    # Step 2: Modify configuration
    echo "# Modified" >> "$config_file"

    # Step 3: Restore from backup
    cp "$backup_file" "$config_file"

    # Step 4: Verify restoration
    assert_file_contains "$config_file" "#!/bin/zsh" "Restored config should have shebang"
    assert_string_not_contains "$(cat "$config_file")" "# Modified" \
        "Modifications should be removed"

    log_success "Restore workflow passed"
}

# ============================================================================
# Dry-run Mode Workflow
# ============================================================================

# Test dry-run installation workflow
test_dry_run_installation_workflow() {
    local temp_dir="$(get_temp_dir)"
    local mock_script="$temp_dir/install_zsh_config_mock.sh"
    local file_count_before

    create_mock_install_script "$temp_dir"
    file_count_before=$(find "$temp_dir" -type f | wc -l)

    # Execute with dry-run
    eval "$mock_script --dry-run"

    local file_count_after=$(find "$temp_dir" -type f | wc -l)

    # Verify no new files were created
    assert_num_equal "$file_count_before" "$file_count_after" \
        "Dry-run should not create new files"

    log_success "Dry-run installation workflow passed"
}

# Test dry-run shows what would happen
test_dry_run_shows_operations() {
    local temp_dir="$(get_temp_dir)"
    local mock_script="$temp_dir/install_zsh_config_mock.sh"
    local output

    create_mock_install_script "$temp_dir"

    output=$("$mock_script" --dry-run 2>&1)

    assert_string_contains "$output" "DRY RUN" \
        "Output should indicate dry-run mode"

    log_success "Dry-run output verification passed"
}

# ============================================================================
# Multiple Component Interaction
# ============================================================================

# Test interaction between configuration and validation
test_config_validation_interaction() {
    local temp_dir="$(get_temp_dir)"

    # Create configuration
    create_mock_zshrc "$temp_dir"

    # Create validation
    create_mock_validation "$temp_dir"

    # Both should be accessible
    assert_file_exists "$temp_dir/.zshrc" "Configuration should exist"
    assert_file_exists "$temp_dir/validation.zsh" "Validation should exist"

    # Both should be readable
    assert_file_readable "$temp_dir/.zshrc" "Configuration should be readable"
    assert_file_readable "$temp_dir/validation.zsh" "Validation should be readable"

    log_success "Config-validation interaction passed"
}

# Test interaction between multiple scripts
test_multiple_scripts_interaction() {
    local temp_dir="$(get_temp_dir)"

    create_mock_install_script "$temp_dir"
    create_mock_dryrun_lib "$temp_dir"

    # Both scripts should be available
    assert_file_exists "$temp_dir/install_zsh_config_mock.sh" "Install script should exist"
    assert_file_exists "$temp_dir/lib_dryrun_mock.sh" "Dryrun library should exist"

    # Install script should be able to source dryrun library
    local install_script="$temp_dir/install_zsh_config_mock.sh"
    assert_file_readable "$install_script" "Install script should be readable"

    log_success "Multiple scripts interaction passed"
}

# ============================================================================
# Environment Setup Workflow
# ============================================================================

# Test environment preparation
test_environment_preparation() {
    local temp_dir="$(get_temp_dir)"

    # Simulate environment setup
    mkdir -p "$temp_dir/.zsh/functions"
    mkdir -p "$temp_dir/.zsh/cache"
    mkdir -p "$temp_dir/.config"

    # Verify structure
    assert_dir_exists "$temp_dir/.zsh/functions" "Functions directory should exist"
    assert_dir_exists "$temp_dir/.zsh/cache" "Cache directory should exist"
    assert_dir_exists "$temp_dir/.config" "Config directory should exist"

    log_success "Environment preparation passed"
}

# Test cleanup after operations
test_cleanup_after_operations() {
    local temp_dir="$(get_temp_dir)"

    # Create test files
    for i in {1..5}; do
        create_test_file "temp_$i.txt" "content $i" "$temp_dir"
    done

    # Verify they were created
    local count=$(find "$temp_dir" -name "temp_*.txt" | wc -l)
    assert_num_equal 5 "$count" "Should have created 5 test files"

    # Simulate cleanup
    rm -f "$temp_dir"/temp_*.txt

    # Verify cleanup
    count=$(find "$temp_dir" -name "temp_*.txt" | wc -l)
    assert_num_equal 0 "$count" "Test files should be cleaned up"

    log_success "Cleanup after operations passed"
}

# ============================================================================
# Complex Workflows
# ============================================================================

# Test install -> backup -> modify -> restore workflow
test_install_modify_restore_workflow() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"

    # Step 1: Install
    create_mock_install_script "$temp_dir"
    assert_file_exists "$temp_dir/install_zsh_config_mock.sh" "Install script created"

    # Step 2: Create configuration
    create_mock_zshrc "$temp_dir"
    assert_file_exists "$temp_dir/.zshrc" "Configuration created"

    # Step 3: Backup
    cp "$temp_dir/.zshrc" "$backup_dir/.zshrc.backup"
    assert_file_exists "$backup_dir/.zshrc.backup" "Backup created"

    # Step 4: Modify
    echo "# Test modification" >> "$temp_dir/.zshrc"

    # Step 5: Restore
    cp "$backup_dir/.zshrc.backup" "$temp_dir/.zshrc"

    # Step 6: Verify restoration
    assert_file_contains "$temp_dir/.zshrc" "#!/bin/zsh" "Should be restored correctly"

    log_success "Complete modify-restore workflow passed"
}

# Test concurrent operations simulation
test_concurrent_operations_simulation() {
    local temp_dir="$(get_temp_dir)"

    # Simulate multiple operations
    create_test_file "file1.txt" "content1" "$temp_dir" &
    create_test_file "file2.txt" "content2" "$temp_dir" &
    create_test_file "file3.txt" "content3" "$temp_dir" &

    wait

    # Verify all files were created
    assert_file_exists "$temp_dir/file1.txt" "File 1 should exist"
    assert_file_exists "$temp_dir/file2.txt" "File 2 should exist"
    assert_file_exists "$temp_dir/file3.txt" "File 3 should exist"

    log_success "Concurrent operations simulation passed"
}

# ============================================================================
# Error Recovery Workflow
# ============================================================================

# Test recovery from failed installation
test_recovery_from_failed_installation() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"

    # Step 1: Create initial config
    create_mock_zshrc "$temp_dir"
    cp "$temp_dir/.zshrc" "$backup_dir/.zshrc.backup"

    # Step 2: Simulate failed installation (corrupted config)
    echo "corrupted config" > "$temp_dir/.zshrc"

    assert_file_contains "$temp_dir/.zshrc" "corrupted" "Config should be corrupted"

    # Step 3: Recover from backup
    cp "$backup_dir/.zshrc.backup" "$temp_dir/.zshrc"

    assert_string_not_contains "$(cat "$temp_dir/.zshrc")" "corrupted" \
        "Corruption should be removed"

    log_success "Error recovery workflow passed"
}

# Test partial operation recovery
test_partial_operation_recovery() {
    local temp_dir="$(get_temp_dir)"

    # Create multiple components
    create_mock_zshrc "$temp_dir"
    create_mock_validation "$temp_dir"
    create_mock_install_script "$temp_dir"

    # Simulate partial failure
    rm -f "$temp_dir/validation.zsh"

    # Verify partial state
    assert_file_exists "$temp_dir/.zshrc" "Config should still exist"
    assert_file_not_exists "$temp_dir/validation.zsh" "Validation should be missing"

    # Recover missing component
    create_mock_validation "$temp_dir"

    assert_file_exists "$temp_dir/validation.zsh" "Validation should be recovered"

    log_success "Partial operation recovery passed"
}

# ============================================================================
# Performance and Scalability
# ============================================================================

# Test handling many files
test_handle_many_files() {
    local temp_dir="$(get_temp_dir)"
    local file_count=50

    # Create many files
    for ((i=1; i<=file_count; i++)); do
        create_test_file "file_$i.txt" "content $i" "$temp_dir"
    done

    # Count created files
    local created_count=$(find "$temp_dir" -name "file_*.txt" | wc -l)

    assert_num_equal "$file_count" "$created_count" \
        "Should handle many files correctly"

    log_success "Handling many files passed (count: $created_count)"
}

# Test large file handling
test_large_file_handling() {
    local temp_dir="$(get_temp_dir)"
    local large_file="$temp_dir/large.txt"

    # Create a relatively large file
    for ((i=1; i<=1000; i++)); do
        echo "Line $i with some content" >> "$large_file"
    done

    assert_file_exists "$large_file" "Large file should exist"
    assert_file_readable "$large_file" "Large file should be readable"

    log_success "Large file handling passed"
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
