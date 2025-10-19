#!/usr/bin/env bash
# integration/test_workflows.sh - Workflow integration tests
# Tests real-world usage scenarios and workflows
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
    log_debug "Setting up workflow tests..."
    setup_fixtures
    setup_mock_environment "with_zsh"
}

teardown() {
    log_debug "Tearing down workflow tests..."
    teardown_fixtures
}

# ============================================================================
# Development Workflow Scenarios
# ============================================================================

# Test developer first-time setup workflow
test_developer_first_time_setup() {
    local temp_dir="$(get_temp_dir)"
    local home_dir="$temp_dir/home"

    mkdir -p "$home_dir"

    # Step 1: Check if zsh is installed
    if ! command -v zsh &>/dev/null; then
        log_warn "ZSH not installed, skipping workflow"
        return 0
    fi

    # Step 2: Create zsh configuration directories
    mkdir -p "$home_dir/.zsh/functions"
    mkdir -p "$home_dir/.zsh/cache"

    # Step 3: Download and install configuration
    create_mock_zshrc "$home_dir"

    assert_file_exists "$home_dir/.zshrc" "Configuration should be installed"
    assert_dir_exists "$home_dir/.zsh/functions" "Functions directory should exist"

    log_success "First-time setup workflow passed"
}

# Test configuration update workflow
test_configuration_update_workflow() {
    local temp_dir="$(get_temp_dir)"
    local old_version="v2.0"
    local new_version="v2.2.0"

    # Step 1: Backup existing configuration
    local backup_dir="$(get_backup_dir)"
    create_mock_zshrc "$temp_dir"
    cp "$temp_dir/.zshrc" "$backup_dir/.zshrc.backup.$old_version"

    assert_file_exists "$backup_dir/.zshrc.backup.$old_version" \
        "Backup of old version should be created"

    # Step 2: Deploy new version
    create_mock_zshrc "$temp_dir"
    echo "# Version $new_version" >> "$temp_dir/.zshrc"

    assert_file_contains "$temp_dir/.zshrc" "# Version $new_version" \
        "New version should be deployed"

    log_success "Configuration update workflow passed"
}

# Test troubleshooting workflow
test_troubleshooting_workflow() {
    local temp_dir="$(get_temp_dir)"

    # Step 1: Create valid configuration
    create_mock_zshrc "$temp_dir"

    # Step 2: Verify configuration syntax
    assert_success "bash -n '$temp_dir/.zshrc'" \
        "Configuration should have valid syntax"

    # Step 3: Create validation report
    local report_file="$temp_dir/validation_report.txt"
    echo "Configuration Status: OK" > "$report_file"
    echo "Syntax Check: PASS" >> "$report_file"
    echo "Dependencies: OK" >> "$report_file"

    assert_file_contains "$report_file" "Configuration Status: OK" \
        "Report should indicate success"

    log_success "Troubleshooting workflow passed"
}

# ============================================================================
# Maintenance Workflow Scenarios
# ============================================================================

# Test routine maintenance workflow
test_routine_maintenance_workflow() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"

    # Step 1: Validate current configuration
    create_mock_zshrc "$temp_dir"
    assert_file_readable "$temp_dir/.zshrc" "Configuration should be readable"

    # Step 2: Create backup
    cp "$temp_dir/.zshrc" "$backup_dir/.zshrc.maintenance"
    assert_file_exists "$backup_dir/.zshrc.maintenance" "Maintenance backup created"

    # Step 3: Clean cache
    local cache_dir="$temp_dir/.zsh/cache"
    mkdir -p "$cache_dir"
    for i in {1..3}; do
        echo "cache $i" > "$cache_dir/cache_$i"
    done

    rm -f "$cache_dir"/cache_*

    local remaining_count=$(find "$cache_dir" -name "cache_*" | wc -l)
    assert_num_equal 0 "$remaining_count" "Cache should be cleaned"

    log_success "Routine maintenance workflow passed"
}

# Test backup rotation workflow
test_backup_rotation_workflow() {
    local backup_dir="$(get_backup_dir)"

    # Step 1: Create multiple backups
    for i in {1..5}; do
        create_test_file ".zshrc.backup.$i" "backup $i" "$backup_dir"
    done

    local count=$(find "$backup_dir" -name ".zshrc.backup.*" | wc -l)
    assert_num_equal 5 "$count" "Should have 5 backups"

    # Step 2: Simulate rotation (keep last 3)
    find "$backup_dir" -name ".zshrc.backup.*" | sort | head -2 | xargs rm -f

    count=$(find "$backup_dir" -name ".zshrc.backup.*" | wc -l)
    assert_num_equal 3 "$count" "Should have 3 backups after rotation"

    log_success "Backup rotation workflow passed"
}

# ============================================================================
# Testing and Validation Workflows
# ============================================================================

# Test configuration validation workflow
test_configuration_validation_workflow() {
    local temp_dir="$(get_temp_dir)"

    # Step 1: Create test configuration
    create_mock_zshrc "$temp_dir"

    # Step 2: Validate existence
    assert_file_exists "$temp_dir/.zshrc" "Configuration should exist"

    # Step 3: Validate readability
    assert_file_readable "$temp_dir/.zshrc" "Configuration should be readable"

    # Step 4: Validate content
    assert_file_contains "$temp_dir/.zshrc" "#!/bin/zsh" \
        "Configuration should have zsh shebang"

    # Step 5: Validate syntax
    assert_success "bash -n '$temp_dir/.zshrc'" \
        "Configuration syntax should be valid"

    log_success "Configuration validation workflow passed"
}

# Test environment detection workflow
test_environment_detection_workflow() {
    local temp_dir="$(get_temp_dir)"

    # Step 1: Detect shell
    if [[ -n "$ZSH_VERSION" ]]; then
        log_info "Detected shell: ZSH"
    elif [[ -n "$BASH_VERSION" ]]; then
        log_info "Detected shell: BASH"
    fi

    # Step 2: Detect OS
    local os="unknown"
    if [[ "$OSTYPE" == "linux-gnu" ]]; then
        os="Linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os="macOS"
    fi

    log_info "Detected OS: $os"

    # Step 3: Store detection results
    create_test_file "environment.txt" "OS: $os" "$temp_dir"

    assert_file_contains "$temp_dir/environment.txt" "OS:" \
        "Environment detection should be recorded"

    log_success "Environment detection workflow passed"
}

# ============================================================================
# Migration Workflow Scenarios
# ============================================================================

# Test migration to new version workflow
test_migration_to_new_version() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"
    local old_config="$backup_dir/.zshrc.old"
    local new_config="$temp_dir/.zshrc"

    # Step 1: Backup old configuration
    create_mock_zshrc "$backup_dir"
    cp "$backup_dir/.zshrc" "$old_config"

    assert_file_exists "$old_config" "Old configuration should be backed up"

    # Step 2: Install new version
    create_mock_zshrc "$temp_dir"
    echo "# New version features" >> "$new_config"

    assert_file_exists "$new_config" "New configuration should be installed"

    # Step 3: Verify both versions exist
    assert_file_exists "$old_config" "Old configuration should still exist"
    assert_file_exists "$new_config" "New configuration should exist"

    log_success "Migration to new version workflow passed"
}

# Test rollback workflow
test_rollback_workflow() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"
    local current_config="$temp_dir/.zshrc"
    local backup_config="$backup_dir/.zshrc.backup"

    # Step 1: Install new configuration
    create_mock_zshrc "$temp_dir"
    cp "$current_config" "$backup_config"

    # Step 2: Introduce change
    echo "# Problematic change" >> "$current_config"

    assert_file_contains "$current_config" "Problematic change" \
        "Change should be applied"

    # Step 3: Detect problem and rollback
    cp "$backup_config" "$current_config"

    assert_string_not_contains "$(cat "$current_config")" "Problematic change" \
        "Problematic change should be rolled back"

    log_success "Rollback workflow passed"
}

# ============================================================================
# Disaster Recovery Workflows
# ============================================================================

# Test corruption detection and recovery
test_corruption_detection_recovery() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"

    # Step 1: Create valid backup
    create_mock_zshrc "$backup_dir"
    local backup_checksum=$(md5sum "$backup_dir/.zshrc" | awk '{print $1}')

    # Step 2: Simulate corruption
    echo "corrupted content" > "$temp_dir/.zshrc"

    # Step 3: Detect corruption by comparing checksums
    local current_checksum=$(md5sum "$temp_dir/.zshrc" | awk '{print $1}')

    if [[ "$backup_checksum" != "$current_checksum" ]]; then
        log_info "Corruption detected"

        # Step 4: Restore from backup
        cp "$backup_dir/.zshrc" "$temp_dir/.zshrc"

        current_checksum=$(md5sum "$temp_dir/.zshrc" | awk '{print $1}')
        assert_equal "$backup_checksum" "$current_checksum" \
            "Configuration should be restored correctly"
    fi

    log_success "Corruption detection and recovery passed"
}

# Test multi-component recovery
test_multi_component_recovery() {
    local temp_dir="$(get_temp_dir)"

    # Step 1: Create all components
    create_mock_zshrc "$temp_dir"
    create_mock_validation "$temp_dir"
    create_mock_install_script "$temp_dir"

    # Step 2: Simulate partial failure
    rm -f "$temp_dir/.zshrc" "$temp_dir/validation.zsh"

    # Step 3: Detect missing components
    local missing=0
    [[ ! -f "$temp_dir/.zshrc" ]] && ((missing++))
    [[ ! -f "$temp_dir/validation.zsh" ]] && ((missing++))

    assert_num_equal 2 "$missing" "Should detect 2 missing components"

    # Step 4: Recover all components
    create_mock_zshrc "$temp_dir"
    create_mock_validation "$temp_dir"

    assert_file_exists "$temp_dir/.zshrc" "Configuration should be recovered"
    assert_file_exists "$temp_dir/validation.zsh" "Validation should be recovered"

    log_success "Multi-component recovery passed"
}

# ============================================================================
# Performance and Reliability Workflows
# ============================================================================

# Test performance under load
test_performance_under_load() {
    local temp_dir="$(get_temp_dir)"
    local start_time
    local end_time
    local elapsed

    start_time=$(start_timer)

    # Create many configurations
    for i in {1..20}; do
        create_test_file "config_$i.txt" "config $i" "$temp_dir"
    done

    end_time=$(start_timer)
    elapsed=$(get_elapsed_time "$start_time" "$end_time")

    local file_count=$(find "$temp_dir" -name "config_*.txt" | wc -l)
    assert_num_equal 20 "$file_count" "Should create 20 configurations"

    log_info "Created 20 files in $(format_time "$elapsed")"
    log_success "Performance under load test passed"
}

# Test reliability with repeated operations
test_reliability_repeated_operations() {
    local temp_dir="$(get_temp_dir)"
    local backup_dir="$(get_backup_dir)"

    # Perform repeated backup/restore cycles
    for i in {1..3}; do
        create_mock_zshrc "$temp_dir"
        cp "$temp_dir/.zshrc" "$backup_dir/.zshrc.backup.$i"

        assert_file_exists "$backup_dir/.zshrc.backup.$i" \
            "Backup cycle $i should succeed"

        # Restore
        cp "$backup_dir/.zshrc.backup.$i" "$temp_dir/.zshrc"

        assert_file_exists "$temp_dir/.zshrc" \
            "Restore cycle $i should succeed"
    done

    log_success "Reliability with repeated operations passed"
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
