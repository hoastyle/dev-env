#!/bin/bash
# =============================================================================
# Unit Tests: Backup and Recovery Library
# =============================================================================
# Description: Tests for lib_backup.sh functions
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library
source "$PROJECT_ROOT/scripts/lib_backup.sh"

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

assert_dir_exists() {
    local dir="$1"
    local message="$2"

    if [[ -d "$dir" ]]; then
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
TEST_BACKUP_DIR="$TEST_DIR/backups"

# Override paths for testing
export BACKUP_DIR="$TEST_BACKUP_DIR"
export PROJECT_ROOT="$TEST_DIR"

mkdir -p "$TEST_BACKUP_DIR"

# Create test files
echo "# Test ZSH config" > "$TEST_DIR/.zshrc"
export HOME="$TEST_DIR"

# Cleanup on exit
trap "rm -rf '$TEST_DIR'" EXIT

# =============================================================================
# Test Cases
# =============================================================================

test_create_backup() {
    echo "Test: create_backup"

    local backup_path=$(create_backup "Test backup" 2>/dev/null | tail -n1)

    assert_dir_exists "$backup_path" "Backup directory created"

    # Verify manifest exists
    if [[ -f "$backup_path/manifest.txt" ]]; then
        echo "  ✅ PASS: Manifest file created"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Manifest file not created"
        ((TESTS_FAILED++))
    fi

    # Verify metadata exists
    if [[ -f "$backup_path/metadata.json" ]]; then
        echo "  ✅ PASS: Metadata file created"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Metadata file not created"
        ((TESTS_FAILED++))
    fi
}

test_list_backups() {
    echo "Test: list_backups"

    create_backup "List test" > /dev/null 2>&1

    local output=$(list_backups 2>&1)

    if [[ "$output" =~ "List test" ]]; then
        echo "  ✅ PASS: Backup appears in list"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Backup not in list"
        ((TESTS_FAILED++))
    fi
}

test_get_backup_info() {
    echo "Test: get_backup_info"

    local backup_path=$(create_backup "Info test" 2>/dev/null | tail -n1)
    local backup_id=$(basename "$backup_path")

    local info=$(get_backup_info "$backup_id")

    if [[ "$info" =~ "Info test" ]]; then
        echo "  ✅ PASS: Backup info retrieved"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Backup info not found"
        ((TESTS_FAILED++))
    fi
}

test_cleanup_old_backups() {
    echo "Test: cleanup_old_backups"

    # Count initial backups
    local initial_count=$(ls "$TEST_BACKUP_DIR" 2>/dev/null | wc -l)

    create_backup "Cleanup 1" > /dev/null 2>&1
    create_backup "Cleanup 2" > /dev/null 2>&1
    create_backup "Cleanup 3" > /dev/null 2>&1

    cleanup_old_backups 2 > /dev/null

    local remaining=$(ls "$TEST_BACKUP_DIR" 2>/dev/null | wc -l)
    # Should have at most 2 + initial_count backups
    local max_allowed=$((initial_count + 2))
    if [[ $remaining -le $max_allowed ]]; then
        echo "  ✅ PASS: Old backups cleaned up (kept $remaining, max $max_allowed)"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Too many backups remaining ($remaining > $max_allowed)"
        ((TESTS_FAILED++))
    fi
}

# =============================================================================
# Run All Tests
# =============================================================================

run_all_tests() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Unit Tests: Backup and Recovery Library"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_create_backup
    echo ""

    test_list_backups
    echo ""

    test_get_backup_info
    echo ""

    test_cleanup_old_backups
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
