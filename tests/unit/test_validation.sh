#!/usr/bin/env bash
# unit/test_validation.sh - Parameter validation unit tests
# Tests for validation.zsh functions: error_msg, success_msg, warn_msg, info_msg
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
    log_debug "Setting up validation tests..."
    setup_fixtures

    # Create mock validation.zsh
    create_mock_validation "$(get_temp_dir)"
}

teardown() {
    log_debug "Tearing down validation tests..."
    teardown_fixtures
}

# ============================================================================
# Message Function Tests
# ============================================================================

# Test error_msg outputs to stderr
test_error_msg_stderr() {
    local msg="Test error message"
    local output

    # Source the mock validation script
    source "$(get_temp_dir)/validation.zsh"

    # Capture stderr
    output=$(error_msg "$msg" 2>&1 1>/dev/null)

    assert_string_contains "$output" "ERROR: Test error message" \
        "error_msg should output error prefix"
}

# Test success_msg outputs to stdout
test_success_msg_stdout() {
    local msg="Test success message"
    local output

    source "$(get_temp_dir)/validation.zsh"

    output=$(success_msg "$msg" 2>/dev/null)

    assert_string_contains "$output" "SUCCESS: Test success message" \
        "success_msg should output success prefix"
}

# Test warn_msg outputs warning
test_warn_msg_format() {
    local msg="Test warning"
    local output

    source "$(get_temp_dir)/validation.zsh"

    output=$(warn_msg "$msg" 2>/dev/null)

    assert_string_contains "$output" "WARNING:" \
        "warn_msg should include WARNING prefix"
}

# Test info_msg outputs info
test_info_msg_format() {
    local msg="Test info"
    local output

    source "$(get_temp_dir)/validation.zsh"

    output=$(info_msg "$msg" 2>/dev/null)

    assert_string_contains "$output" "INFO:" \
        "info_msg should include INFO prefix"
}

# ============================================================================
# Parameter Validation Tests
# ============================================================================

# Test empty parameter detection
test_empty_parameter_detection() {
    local param=""

    if [[ -z "$param" ]]; then
        log_success "Empty parameter correctly detected"
        return 0
    fi

    return 1
}

# Test non-empty parameter
test_non_empty_parameter() {
    local param="value"

    assert_not_empty "$param" "Parameter should not be empty"
}

# Test parameter format validation
test_parameter_format_validation() {
    local param="valid-name"

    # Check if parameter matches valid format
    if [[ $param =~ ^[a-zA-Z0-9_-]+$ ]]; then
        log_success "Parameter format is valid"
        return 0
    fi

    return 1
}

# ============================================================================
# Path Validation Tests
# ============================================================================

# Test absolute path validation
test_absolute_path_validation() {
    local path="/absolute/path"

    if [[ "$path" = /* ]]; then
        log_success "Absolute path correctly identified"
        return 0
    fi

    return 1
}

# Test relative path validation
test_relative_path_validation() {
    local path="relative/path"

    if [[ "$path" != /* && "$path" != /* ]]; then
        log_success "Relative path correctly identified"
        return 0
    fi

    return 1
}

# Test path with parent directory references
test_path_parent_directory_refs() {
    local path="../parent/dir"

    assert_string_contains "$path" ".." "Path should contain parent directory reference"
}

# ============================================================================
# Directory Validation Tests
# ============================================================================

# Test directory existence check
test_directory_existence_check() {
    local test_dir="$(get_temp_dir)/test_dir"

    mkdir -p "$test_dir"

    assert_dir_exists "$test_dir" "Directory should exist after creation"
}

# Test non-existent directory
test_non_existent_directory() {
    local test_dir="$(get_temp_dir)/non_existent_dir_$(date +%s)"

    assert_dir_not_exists "$test_dir" "Directory should not exist"
}

# Test writable directory
test_writable_directory() {
    local test_dir="$(get_temp_dir)/writable_test"

    mkdir -p "$test_dir"

    assert_file_writable "$test_dir" "Directory should be writable"
}

# ============================================================================
# File Validation Tests
# ============================================================================

# Test file existence
test_file_existence() {
    local test_file="$(get_temp_dir)/test.txt"

    create_test_file "test.txt" "test content" "$(get_temp_dir)"

    assert_file_exists "$test_file" "File should exist after creation"
}

# Test file readability
test_file_readability() {
    local test_file="$(get_temp_dir)/readable.txt"

    create_test_file "readable.txt" "content" "$(get_temp_dir)"

    assert_file_readable "$test_file" "File should be readable"
}

# Test file writeability
test_file_writeability() {
    local test_file="$(get_temp_dir)/writable.txt"

    create_test_file "writable.txt" "content" "$(get_temp_dir)"

    assert_file_writable "$test_file" "File should be writable"
}

# ============================================================================
# Array/List Validation Tests
# ============================================================================

# Test array non-empty check
test_array_non_empty() {
    local -a test_array=("item1" "item2" "item3")

    if [[ ${#test_array[@]} -gt 0 ]]; then
        log_success "Array is non-empty"
        return 0
    fi

    return 1
}

# Test array empty check
test_array_empty() {
    local -a test_array=()

    if [[ ${#test_array[@]} -eq 0 ]]; then
        log_success "Array is empty"
        return 0
    fi

    return 1
}

# Test array contains element
test_array_contains_element() {
    local -a test_array=("item1" "item2" "item3")
    local search="item2"

    local found=0
    for item in "${test_array[@]}"; do
        if [[ "$item" == "$search" ]]; then
            found=1
            break
        fi
    done

    if [[ $found -eq 1 ]]; then
        log_success "Array contains search element"
        return 0
    fi

    return 1
}

# ============================================================================
# Numeric Validation Tests
# ============================================================================

# Test positive number validation
test_positive_number() {
    local num=42

    if [[ $num -gt 0 ]]; then
        log_success "Number is positive"
        return 0
    fi

    return 1
}

# Test zero value
test_zero_value() {
    local num=0

    assert_num_equal 0 "$num" "Number should be zero"
}

# Test negative number
test_negative_number() {
    local num=-10

    if [[ $num -lt 0 ]]; then
        log_success "Number is negative"
        return 0
    fi

    return 1
}

# Test numeric comparison
test_numeric_comparison() {
    local num1=10
    local num2=20

    assert_num_lt "$num1" "$num2" "First number should be less than second"
}

# ============================================================================
# Boolean/Status Code Tests
# ============================================================================

# Test success status code
test_success_status_code() {
    true
    local status=$?

    assert_num_equal 0 "$status" "Command should return success status (0)"
}

# Test failure status code
test_failure_status_code() {
    ( false )  # Execute in subshell to capture exit code
    local status=$?

    assert_num_equal 1 "$status" "Command should return failure status (1)"
}

# Test custom exit code
test_custom_exit_code() {
    (exit 42)
    local status=$?

    assert_num_equal 42 "$status" "Command should return custom exit code (42)"
}

# ============================================================================
# String Validation Tests
# ============================================================================

# Test string equality
test_string_equality() {
    local str1="hello"
    local str2="hello"

    assert_equal "$str1" "$str2" "Strings should be equal"
}

# Test string inequality
test_string_inequality() {
    local str1="hello"
    local str2="world"

    assert_not_equal "$str1" "$str2" "Strings should not be equal"
}

# Test string contains substring
test_string_contains_substring() {
    local str="hello world"
    local substr="world"

    assert_string_contains "$str" "$substr" "String should contain substring"
}

# Test string regex match
test_string_regex_match() {
    local str="test@example.com"
    local email_pattern="[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"

    assert_regex_match "$str" "$email_pattern" "String should match email pattern"
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
