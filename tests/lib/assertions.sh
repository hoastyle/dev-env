#!/usr/bin/env bash
# assertions.sh - Test assertions library
# Provides 20+ assertion functions for unit and integration testing
# Version: 1.0
# Created: 2025-10-19

set -euo pipefail

# Source test_utils if not already sourced
if [[ ! -v TEST_UTILS_LOADED ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/test_utils.sh"
    readonly TEST_UTILS_LOADED=1
fi

# ============================================================================
# Equality Assertions
# ============================================================================

# Assert two values are equal
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$expected" != "$actual" ]]; then
        log_error "Assertion failed: Expected '$expected' but got '$actual'"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert two values are not equal
assert_not_equal() {
    local not_expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ "$not_expected" == "$actual" ]]; then
        log_error "Assertion failed: Got unexpected value '$actual'"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# String Assertions
# ============================================================================

# Assert string contains substring
assert_string_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-}"

    if [[ ! "$string" =~ $substring ]]; then
        log_error "Assertion failed: String does not contain '$substring'"
        log_error "  String: '$string'"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert string does not contain substring
assert_string_not_contains() {
    local string="$1"
    local substring="$2"
    local message="${3:-}"

    if [[ "$string" =~ $substring ]]; then
        log_error "Assertion failed: String unexpectedly contains '$substring'"
        log_error "  String: '$string'"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert string matches regex
assert_regex_match() {
    local string="$1"
    local pattern="$2"
    local message="${3:-}"

    if [[ ! "$string" =~ $pattern ]]; then
        log_error "Assertion failed: String does not match pattern '$pattern'"
        log_error "  String: '$string'"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert string is empty
assert_empty() {
    local string="$1"
    local message="${2:-}"

    if [[ -n "$string" ]]; then
        log_error "Assertion failed: Expected empty string but got '$string'"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert string is not empty
assert_not_empty() {
    local string="$1"
    local message="${2:-}"

    if [[ -z "$string" ]]; then
        log_error "Assertion failed: Expected non-empty string but got empty"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# Boolean/Status Assertions
# ============================================================================

# Assert command succeeds (exit code 0)
assert_success() {
    local cmd="$1"
    local message="${2:-}"

    if ! eval "$cmd" &>/dev/null; then
        log_error "Assertion failed: Command did not succeed"
        log_error "  Command: $cmd"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert command fails (non-zero exit code)
assert_failure() {
    local cmd="$1"
    local message="${2:-}"

    if eval "$cmd" &>/dev/null; then
        log_error "Assertion failed: Command unexpectedly succeeded"
        log_error "  Command: $cmd"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert command has specific exit code
assert_exit_code() {
    local expected_code="$1"
    local cmd="$2"
    local message="${3:-}"

    local actual_code
    eval "$cmd" &>/dev/null || actual_code=$?

    if [[ "${actual_code:-0}" != "$expected_code" ]]; then
        log_error "Assertion failed: Expected exit code $expected_code but got $actual_code"
        log_error "  Command: $cmd"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# Numeric Assertions
# ============================================================================

# Assert two numbers are equal
assert_num_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"

    if [[ $expected -ne $actual ]]; then
        log_error "Assertion failed: Expected $expected but got $actual"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert first number is greater than second
assert_num_gt() {
    local actual="$1"
    local threshold="$2"
    local message="${3:-}"

    if [[ $actual -le $threshold ]]; then
        log_error "Assertion failed: Expected $actual > $threshold"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert first number is less than second
assert_num_lt() {
    local actual="$1"
    local threshold="$2"
    local message="${3:-}"

    if [[ $actual -ge $threshold ]]; then
        log_error "Assertion failed: Expected $actual < $threshold"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# File and Directory Assertions
# ============================================================================

# Assert file exists
assert_file_exists() {
    local file="$1"
    local message="${2:-}"

    if [[ ! -f "$file" ]]; then
        log_error "Assertion failed: File does not exist"
        log_error "  File: $file"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert file does not exist
assert_file_not_exists() {
    local file="$1"
    local message="${2:-}"

    if [[ -f "$file" ]]; then
        log_error "Assertion failed: File unexpectedly exists"
        log_error "  File: $file"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert directory exists
assert_dir_exists() {
    local dir="$1"
    local message="${2:-}"

    if [[ ! -d "$dir" ]]; then
        log_error "Assertion failed: Directory does not exist"
        log_error "  Directory: $dir"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert directory does not exist
assert_dir_not_exists() {
    local dir="$1"
    local message="${2:-}"

    if [[ -d "$dir" ]]; then
        log_error "Assertion failed: Directory unexpectedly exists"
        log_error "  Directory: $dir"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert file is readable
assert_file_readable() {
    local file="$1"
    local message="${2:-}"

    if [[ ! -r "$file" ]]; then
        log_error "Assertion failed: File is not readable"
        log_error "  File: $file"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert file is writable
assert_file_writable() {
    local file="$1"
    local message="${2:-}"

    if [[ ! -w "$file" ]]; then
        log_error "Assertion failed: File is not writable"
        log_error "  File: $file"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# Content Assertions
# ============================================================================

# Assert file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    local message="${3:-}"

    if ! grep -q "$text" "$file" 2>/dev/null; then
        log_error "Assertion failed: File does not contain text"
        log_error "  File: $file"
        log_error "  Text: $text"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert file does not contain text
assert_file_not_contains() {
    local file="$1"
    local text="$2"
    local message="${3:-}"

    if grep -q "$text" "$file" 2>/dev/null; then
        log_error "Assertion failed: File unexpectedly contains text"
        log_error "  File: $file"
        log_error "  Text: $text"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# Assert two files are identical
assert_files_equal() {
    local file1="$1"
    local file2="$2"
    local message="${3:-}"

    if ! cmp -s "$file1" "$file2"; then
        log_error "Assertion failed: Files are not identical"
        log_error "  File 1: $file1"
        log_error "  File 2: $file2"
        if [[ -n "$message" ]]; then
            log_error "  Details: $message"
        fi
        return 1
    fi
    return 0
}

# ============================================================================
# Test Execution Framework
# ============================================================================

# Run a test case
run_test() {
    local test_name="$1"
    local test_func="$2"

    log_info "Running: $test_name"

    if eval "$test_func"; then
        log_success "$test_name"
        record_pass
        return 0
    else
        log_error "$test_name failed"
        record_fail "$test_name" "Assertion failed"
        return 1
    fi
}

# Skip a test
skip_test() {
    local test_name="$1"
    local reason="${2:-No reason given}"

    log_warn "Skipping: $test_name ($reason)"
    record_skip
}

# ============================================================================
# Exports
# ============================================================================

export -f assert_equal assert_not_equal
export -f assert_string_contains assert_string_not_contains
export -f assert_regex_match assert_empty assert_not_empty
export -f assert_success assert_failure assert_exit_code
export -f assert_num_equal assert_num_gt assert_num_lt
export -f assert_file_exists assert_file_not_exists
export -f assert_dir_exists assert_dir_not_exists
export -f assert_file_readable assert_file_writable
export -f assert_file_contains assert_file_not_contains
export -f assert_files_equal
export -f run_test skip_test
