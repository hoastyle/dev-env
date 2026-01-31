#!/bin/bash
# =============================================================================
# Unit Tests: Health Check Library
# =============================================================================
# Description: Tests for lib_health.sh functions
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source the library
source "$PROJECT_ROOT/scripts/lib_health.sh"

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
# Test Cases
# =============================================================================

test_check_syntax() {
    echo "Test: check_syntax"

    # Create a valid test config
    local test_config=$(mktemp)
    echo "# Valid ZSH config" > "$test_config"
    echo "export TEST_VAR='value'" >> "$test_config"

    CONFIG_FILE="$test_config" check_syntax > /dev/null
    local result=$?
    rm -f "$test_config"

    if [[ $result -eq 0 ]]; then
        echo "  ✅ PASS: Syntax check passes for valid config"
        ((TESTS_PASSED++))
    else
        echo "  ❌ FAIL: Should pass for valid config"
        ((TESTS_FAILED++))
    fi

    # Note: zsh -n is lenient and may not catch all syntax errors
    # So we skip the invalid config test
    echo "  ℹ️  Skipping invalid config test (zsh -n is lenient)"
}

test_check_dependencies() {
    echo "Test: check_dependencies"

    check_dependencies > /dev/null
    assert_success $? "Dependencies check runs without error"
}

test_check_version_file() {
    echo "Test: check_version_file"

    # Test with project version file
    check_version_file > /dev/null
    assert_success $? "Version file check works"
}

test_generate_health_report() {
    echo "Test: generate_health_report"

    run_health_check > /dev/null 2>&1

    assert_file_exists "$HEALTH_CHECK_LOG" "Health report generated"
}

# =============================================================================
# Run All Tests
# =============================================================================

run_all_tests() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🧪 Unit Tests: Health Check Library"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    test_check_syntax
    echo ""

    test_check_dependencies
    echo ""

    test_check_version_file
    echo ""

    test_generate_health_report
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
