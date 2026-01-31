#!/bin/bash
# =============================================================================
# Unit Tests: Migration Management Library
# =============================================================================
# Description: Tests for lib_migration.sh functions
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library
source "$PROJECT_ROOT/scripts/lib_migration.sh"

# =============================================================================
# Test Framework
# =============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"

    if [[ "$expected" == "$actual" ]]; then
        echo "  ✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: $message"
        echo "     Expected: '$expected'"
        echo "     Actual:   '$actual'"
        ((TESTS_FAILED++))
    fi
}

assert_file_exists() {
    local file="$1"
    local message="$2"

    if [[ -f "$file" ]]; then
        echo "  ✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: $message"
        ((TESTS_FAILED++))
    fi
}

# =============================================================================
# Test Setup
# =============================================================================

TEST_DIR=$(mktemp -d)
TEST_MIGRATIONS_DIR="$TEST_DIR/migrations"
TEST_HISTORY="$TEST_DIR/migration_history.log"

# Override paths for testing
export MIGRATIONS_DIR="$TEST_MIGRATIONS_DIR"
export MIGRATION_HISTORY="$TEST_HISTORY"
export PROJECT_ROOT="$TEST_DIR"

mkdir -p "$TEST_MIGRATIONS_DIR"

# Cleanup on exit
trap "rm -rf '$TEST_DIR'" EXIT

# =============================================================================
# Test Cases
# =============================================================================

test_create_migration() {
    echo "Test: create_migration"

    create_migration "001_test" "2.0.0" "Test migration" > /dev/null

    assert_file_exists "$TEST_MIGRATIONS_DIR/001_test.sh" "Migration file created"

    # Verify migration file has required content
    if grep -q "migrate_up" "$TEST_MIGRATIONS_DIR/001_test.sh"; then
        echo "  ✅ PASS: Migration has migrate_up function"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Migration missing migrate_up function"
        ((TESTS_FAILED++))
    fi
}

test_get_pending_migrations() {
    echo "Test: get_pending_migrations"

    create_migration "002_pending" "2.1.0" "Pending test" > /dev/null

    local pending=$(get_pending_migrations)

    if [[ "$pending" =~ "002_pending" ]]; then
        echo "  ✅ PASS: Pending migration detected"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Pending migration not detected"
        ((TESTS_FAILED++))
    fi
}

test_migration_was_executed() {
    echo "Test: migration_was_executed"

    create_migration "003_executed" "2.2.0" "Executed test" > /dev/null

    # Should not be executed yet
    if ! migration_was_executed "003_executed"; then
        echo "  ✅ PASS: Migration not yet executed"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Migration should not be executed"
        ((TESTS_FAILED++))
    fi

    # Mark as executed
    log_migration "003_executed" "SUCCESS" "1" > /dev/null

    # Should now be executed
    if migration_was_executed "003_executed"; then
        echo "  ✅ PASS: Migration marked as executed"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Migration should be executed"
        ((TESTS_FAILED++))
    fi
}

test_log_migration() {
    echo "Test: log_migration"

    log_migration "004_test" "SUCCESS" "2" > /dev/null

    if [[ -f "$TEST_HISTORY" ]]; then
        echo "  ✅ PASS: Migration history created"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Migration history not created"
        ((TESTS_FAILED++))
    fi

    # Verify log content
    if grep -q "004_test" "$TEST_HISTORY"; then
        echo "  ✅ PASS: Migration logged correctly"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Migration not in history"
        ((TESTS_FAILED++))
    fi
}

test_get_migration_version() {
    echo "Test: get_migration_version"

    create_migration "005_version_test" "3.0.0" "Version test" > /dev/null

    local version=$(get_migration_version "005_version_test")

    assert_equals "3.0.0" "$version" "Migration version extracted"
}

# =============================================================================
# Run All Tests
# =============================================================================

run_all_tests() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Unit Tests: Migration Management Library"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_create_migration
    echo ""

    test_get_pending_migrations
    echo ""

    test_migration_was_executed
    echo ""

    test_log_migration
    echo ""

    test_get_migration_version
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "✅ All tests passed!"
        return 0
    else
        echo "❌ Some tests failed"
        return 1
    fi
}

# =============================================================================
# Main
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests
fi
