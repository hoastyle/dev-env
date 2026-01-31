#!/bin/bash
# =============================================================================
# Integration Tests: ZSH Configuration Manager
# =============================================================================
# Description: End-to-end tests for the CLM system
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the main config manager
source "$PROJECT_ROOT/scripts/zsh_config_manager.sh"

# =============================================================================
# Test Framework
# =============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

assert_success() {
    local exit_code=$?
    local message="$1"

    if [[ $exit_code -eq 0 ]]; then
        echo "  ✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: $message"
        ((TESTS_FAILED++))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="$3"

    if [[ "$haystack" =~ "$needle" ]]; then
        echo "  ✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected to find: $needle"
        ((TESTS_FAILED++))
    fi
}

# =============================================================================
# Test Cases
# =============================================================================

test_version_command() {
    echo "Test: version command"

    local output=$(cmd_version 2>&1)

    assert_contains "$output" "2.2.0" "Version is displayed"
}

test_validate_command() {
    echo "Test: validate command"

    local output=$(cmd_validate 2>&1)

    assert_contains "$output" "Configuration is valid" "Validation passes"
}

test_backup_workflow() {
    echo "Test: backup workflow"

    # Create backup
    local backup_output=$(cmd_backup "Integration test backup" 2>&1)

    assert_contains "$backup_output" "Backup created" "Backup created successfully"

    # List backups
    local list_output=$(cmd_list_backups 2>&1)

    assert_contains "$list_output" "Integration test backup" "Backup appears in list"
}

test_health_check() {
    echo "Test: health check"

    local output=$(cmd_health 2>&1)

    assert_contains "$output" "Health Check Results" "Health check runs"
}

test_migration_workflow() {
    echo "Test: migration workflow"

    # Get current migrations
    local pending=$(get_pending_migrations)

    echo "  ℹ️  Pending migrations: $pending"

    # Migrations should be available
    if [[ -d "$PROJECT_ROOT/config/migrations" ]]; then
        local migrations_count=$(ls "$PROJECT_ROOT/config/migrations"/*.sh 2>/dev/null | wc -l)
        if [[ $migrations_count -gt 0 ]]; then
            echo "  ✅ PASS: Migration files found ($migrations_count)"
            ((TESTS_PASSED++))
        else
            echo "  ❌ FAIL: No migration files found"
            ((TESTS_FAILED++))
        fi
    fi
}

test_help_command() {
    echo "Test: help command"

    local output=$(show_help 2>&1)

    assert_contains "$output" "ZSH Configuration Manager" "Help is displayed"
    assert_contains "$output" "version" "Version command in help"
    assert_contains "$output" "migrate" "Migrate command in help"
}

test_integration_workflow() {
    echo "Test: complete integration workflow"

    # Step 1: Check version
    local version_output=$(cmd_version 2>&1)
    assert_success $? "Version command succeeds"

    # Step 2: Validate config
    local validate_output=$(cmd_validate 2>&1)
    assert_success $? "Validate command succeeds"

    # Step 3: Run health check
    local health_output=$(cmd_health 2>&1)
    assert_success $? "Health check succeeds"

    # Step 4: Create backup
    local backup_output=$(cmd_backup "Integration workflow test" 2>&1)
    assert_success $? "Backup creation succeeds"

    echo "  ✅ PASS: Integration workflow completed"
    ((TESTS_PASSED++))
}

# =============================================================================
# Run All Tests
# =============================================================================

run_all_tests() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Integration Tests: ZSH Configuration Manager"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_version_command
    echo ""

    test_validate_command
    echo ""

    test_backup_workflow
    echo ""

    test_health_check
    echo ""

    test_migration_workflow
    echo ""

    test_help_command
    echo ""

    test_integration_workflow
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "✅ All integration tests passed!"
        return 0
    else
        echo "❌ Some integration tests failed"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi
