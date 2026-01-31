#!/bin/bash
# =============================================================================
# Unit Tests: Version Management Library
# =============================================================================
# Description: Tests for lib_version.sh functions
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library
source "$PROJECT_ROOT/scripts/lib_version.sh"

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

assert_success() {
    local message="$1"
    if [[ $? -eq 0 ]]; then
        echo "  ✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: $message"
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
TEST_VERSION_FILE="$TEST_DIR/.zshrc.version"
export VERSION_FILE="$TEST_VERSION_FILE"

# Cleanup on exit
trap "rm -rf '$TEST_DIR'" EXIT

# =============================================================================
# Test Cases
# =============================================================================

test_get_current_version() {
    echo "Test: get_current_version"

    # Test with no version file
    local version=$(get_current_version)
    assert_equals "0.0.0" "$version" "Returns 0.0.0 when no file exists"

    # Create version file and test
    set_version "2.2.0" > /dev/null
    version=$(get_current_version)
    assert_equals "2.2.0" "$version" "Returns correct version"
}

test_set_version() {
    echo "Test: set_version"

    # Test basic version setting
    set_version "2.2.0" "2026-01-31" > /dev/null
    assert_file_exists "$TEST_VERSION_FILE" "Version file created"

    # Verify version was set
    local version=$(get_current_version)
    assert_equals "2.2.0" "$version" "Version correctly set"

    # Test version validation
    set_version "invalid" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "  ✅ PASS: Invalid version rejected"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Invalid version should be rejected"
        ((TESTS_FAILED++))
    fi
}

test_compare_versions() {
    echo "Test: compare_versions"

    # Test greater than
    if compare_versions "2.2.0" "2.1.0"; then
        echo "  ✅ PASS: 2.2.0 >= 2.1.0"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: 2.2.0 >= 2.1.0"
        ((TESTS_FAILED++))
    fi

    # Test less than
    if ! compare_versions "2.0.0" "2.1.0"; then
        echo "  ✅ PASS: 2.0.0 < 2.1.0"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: 2.0.0 < 2.1.0"
        ((TESTS_FAILED++))
    fi

    # Test equal
    if compare_versions "2.2.0" "2.2.0"; then
        echo "  ✅ PASS: 2.2.0 == 2.2.0"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: 2.2.0 == 2.2.0"
        ((TESTS_FAILED++))
    fi
}

test_needs_migration() {
    echo "Test: needs_migration"

    # Set initial version
    set_version "2.2.0" > /dev/null

    # Test migration needed
    if needs_migration "2.3.0" > /dev/null; then
        echo "  ✅ PASS: Migration needed detected"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Should need migration"
        ((TESTS_FAILED++))
    fi

    # Test no migration needed
    if ! needs_migration "2.1.0" > /dev/null; then
        echo "  ✅ PASS: No migration needed when current > target"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Should not need migration"
        ((TESTS_FAILED++))
    fi
}

test_update_last_migration() {
    echo "Test: update_last_migration"

    set_version "2.2.0" > /dev/null
    update_last_migration "001_initial" > /dev/null

    local last_migration=$(grep "^LAST_MIGRATION=" "$TEST_VERSION_FILE" | cut -d'"' -f2)
    assert_equals "001_initial" "$last_migration" "Last migration updated"
}

test_mark_user_customizations() {
    echo "Test: mark_user_customizations"

    set_version "2.2.0" > /dev/null

    # Create a user config file
    local user_config="$TEST_DIR/.zshrc.user"
    echo "# User customizations" > "$user_config"

    # Mark customizations (using HOME override)
    local old_home="$HOME"
    HOME="$TEST_DIR"
    mark_user_customizations > /dev/null
    HOME="$old_home"

    local user_custom=$(grep "^USER_CUSTOMIZATIONS=" "$TEST_VERSION_FILE" | cut -d'"' -f2)
    assert_equals "true" "$user_custom" "User customizations marked"
}

test_generate_version_report() {
    echo "Test: generate_version_report"

    set_version "2.2.0" "2026-01-31" > /dev/null
    update_last_migration "001_initial" > /dev/null

    local output=$(generate_version_report)
    if [[ "$output" =~ "2.2.0" ]]; then
        echo "  ✅ PASS: Version report contains version"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Version report missing version"
        ((TESTS_FAILED++))
    fi
}

test_get_version_json() {
    echo "Test: get_version_json"

    set_version "2.2.0" > /dev/null

    local json=$(get_version_json)
    if [[ "$json" =~ "version" ]] && [[ "$json" =~ "2.2.0" ]]; then
        echo "  ✅ PASS: JSON contains version"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: JSON missing version"
        ((TESTS_FAILED++))
    fi
}

# =============================================================================
# Run All Tests
# =============================================================================

run_all_tests() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Unit Tests: Version Management Library"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_get_current_version
    echo ""

    test_set_version
    echo ""

    test_compare_versions
    echo ""

    test_needs_migration
    echo ""

    test_update_last_migration
    echo ""

    test_mark_user_customizations
    echo ""

    test_generate_version_report
    echo ""

    test_get_version_json
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
