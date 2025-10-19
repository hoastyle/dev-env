#!/usr/bin/env bash
# test_utils.sh - Test utility functions library
# Provides logging, timing, and state management for test suite
# Version: 1.0
# Created: 2025-10-19

set -e

# ============================================================================
# Color and Formatting Constants
# ============================================================================

# Color definitions
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_DIM='\033[2m'

# ============================================================================
# Logging Functions
# ============================================================================

# Log informational message
log_info() {
    local message="$1"
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} ${message}"
}

# Log success message
log_success() {
    local message="$1"
    echo -e "${COLOR_GREEN}[✓]${COLOR_RESET} ${message}"
}

# Log warning message
log_warn() {
    local message="$1"
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} ${message}"
}

# Log error message
log_error() {
    local message="$1"
    echo -e "${COLOR_RED}[✗]${COLOR_RESET} ${message}" >&2
}

# Log debug message (only if DEBUG enabled)
log_debug() {
    local message="$1"
    if [[ "${DEBUG:-0}" == "1" ]]; then
        echo -e "${COLOR_DIM}[DEBUG]${COLOR_RESET} ${message}"
    fi
}

# Print test header
print_test_header() {
    local test_name="$1"
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
    echo -e "${COLOR_BOLD}Testing: ${test_name}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${COLOR_RESET}"
}

# Print section header
print_section() {
    local section_name="$1"
    echo ""
    echo -e "${COLOR_BOLD}${section_name}${COLOR_RESET}"
    echo -e "${COLOR_DIM}────────────────────────────────────────${COLOR_RESET}"
}

# Print summary line
print_summary() {
    local label="$1"
    local value="$2"
    local color="${3:-}"

    if [[ -n "$color" ]]; then
        printf "  %-30s: ${color}%s${COLOR_RESET}\n" "$label" "$value"
    else
        printf "  %-30s: %s\n" "$label" "$value"
    fi
}

# ============================================================================
# Timing Functions
# ============================================================================

# Start timer
start_timer() {
    # Return milliseconds since epoch
    if command -v date &>/dev/null; then
        date +%s%N | cut -b1-13
    else
        echo $(($(date +%s) * 1000))
    fi
}

# Calculate elapsed time in milliseconds
get_elapsed_time() {
    local start_time="$1"
    local end_time="$2"
    echo $((end_time - start_time))
}

# Format milliseconds to human-readable format
format_time() {
    local ms="$1"

    if ((ms < 1000)); then
        echo "${ms}ms"
    elif ((ms < 60000)); then
        local seconds=$((ms / 1000))
        local remainder=$((ms % 1000))
        printf "%d.%03ds\n" "$seconds" "$remainder"
    else
        local minutes=$((ms / 60000))
        local remainder=$((ms % 60000))
        local seconds=$((remainder / 1000))
        printf "%dm%ds\n" "$minutes" "$seconds"
    fi
}

# ============================================================================
# State Management Functions
# ============================================================================

# Global test state variables
declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g TEST_SKIPPED=0
declare -a TEST_FAILURES=()

# Initialize test state
init_test_state() {
    TEST_TOTAL=0
    TEST_PASSED=0
    TEST_FAILED=0
    TEST_SKIPPED=0
    TEST_FAILURES=()
}

# Record a passed test
record_pass() {
    ((TEST_TOTAL++))
    ((TEST_PASSED++))
}

# Record a failed test
record_fail() {
    local test_name="$1"
    local reason="${2:-Unknown reason}"

    ((TEST_TOTAL++))
    ((TEST_FAILED++))
    TEST_FAILURES+=("$test_name: $reason")
}

# Record a skipped test
record_skip() {
    ((TEST_TOTAL++))
    ((TEST_SKIPPED++))
}

# Get test statistics
get_test_stats() {
    echo "$TEST_TOTAL:$TEST_PASSED:$TEST_FAILED:$TEST_SKIPPED"
}

# Print test summary
print_test_summary() {
    echo ""
    echo -e "${COLOR_BOLD}${COLOR_CYAN}Test Summary${COLOR_RESET}"
    echo -e "${COLOR_CYAN}────────────────────────────────────────${COLOR_RESET}"

    local pass_color="${COLOR_GREEN}"
    local fail_color="${COLOR_RED}"
    local skip_color="${COLOR_YELLOW}"

    # Calculate percentages
    local pass_pct=0
    if ((TEST_TOTAL > 0)); then
        pass_pct=$((TEST_PASSED * 100 / TEST_TOTAL))
    fi

    print_summary "Total Tests" "$TEST_TOTAL"
    print_summary "Passed" "$TEST_PASSED" "$pass_color"
    print_summary "Failed" "$TEST_FAILED" "$fail_color"
    print_summary "Skipped" "$TEST_SKIPPED" "$skip_color"
    print_summary "Pass Rate" "${pass_pct}%"

    # Print failures if any
    if ((TEST_FAILED > 0)); then
        echo ""
        echo -e "${COLOR_BOLD}${COLOR_RED}Failures:${COLOR_RESET}"
        for failure in "${TEST_FAILURES[@]}"; do
            echo -e "  ${COLOR_RED}✗${COLOR_RESET} $failure"
        done
    fi

    echo ""
}

# ============================================================================
# Temporary File/Directory Management
# ============================================================================

# Global cleanup list
declare -a CLEANUP_LIST=()

# Create a temporary directory and track for cleanup
create_temp_dir() {
    local temp_dir
    temp_dir=$(mktemp -d) || {
        log_error "Failed to create temporary directory"
        return 1
    }
    CLEANUP_LIST+=("$temp_dir")
    echo "$temp_dir"
}

# Create a temporary file and track for cleanup
create_temp_file() {
    local temp_file
    temp_file=$(mktemp) || {
        log_error "Failed to create temporary file"
        return 1
    }
    CLEANUP_LIST+=("$temp_file")
    echo "$temp_file"
}

# Cleanup all temporary files and directories
cleanup_temps() {
    for item in "${CLEANUP_LIST[@]}"; do
        if [[ -d "$item" ]]; then
            rm -rf "$item" 2>/dev/null || log_warn "Failed to cleanup directory: $item"
        elif [[ -f "$item" ]]; then
            rm -f "$item" 2>/dev/null || log_warn "Failed to cleanup file: $item"
        fi
    done
    CLEANUP_LIST=()
}

# ============================================================================
# Process and Command Execution
# ============================================================================

# Run a command and capture output
run_command() {
    local cmd="$1"
    local output
    local exit_code

    log_debug "Executing: $cmd"

    output=$(eval "$cmd" 2>&1) || exit_code=$?

    echo "$output"
    return "${exit_code:-0}"
}

# Run a command silently
run_silent() {
    local cmd="$1"
    eval "$cmd" &>/dev/null
}

# Check if a command exists
command_exists() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null
}

# ============================================================================
# Assertion Helper Functions
# ============================================================================

# Assert that a file exists
assert_file_exists() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    return 0
}

# Assert that a directory exists
assert_dir_exists() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        return 1
    fi
    return 0
}

# Assert that a file is readable
assert_file_readable() {
    local file="$1"
    if [[ ! -r "$file" ]]; then
        return 1
    fi
    return 0
}

# Assert that a file is writable
assert_file_writable() {
    local file="$1"
    if [[ ! -w "$file" ]]; then
        return 1
    fi
    return 0
}

# Assert that a file contains text
assert_file_contains() {
    local file="$1"
    local text="$2"
    if ! grep -q "$text" "$file"; then
        return 1
    fi
    return 0
}

# ============================================================================
# Environment Setup/Teardown
# ============================================================================

# Save original environment variables
save_env() {
    # Save PATH for restoration
    export ORIGINAL_PATH="$PATH"
    export ORIGINAL_HOME="$HOME"
}

# Restore original environment
restore_env() {
    PATH="$ORIGINAL_PATH"
    HOME="$ORIGINAL_HOME"
}

# ============================================================================
# Exports for use in other scripts
# ============================================================================

export -f log_info log_success log_warn log_error log_debug
export -f print_test_header print_section print_summary print_test_summary
export -f start_timer get_elapsed_time format_time
export -f init_test_state record_pass record_fail record_skip get_test_stats
export -f create_temp_dir create_temp_file cleanup_temps
export -f run_command run_silent command_exists
export -f assert_file_exists assert_dir_exists assert_file_readable assert_file_writable assert_file_contains
export -f save_env restore_env
