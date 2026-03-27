#!/usr/bin/env bash
# test_runner.sh - Test execution orchestrator
# Discovers, executes, and reports on test suites
# Version: 1.0
# Created: 2025-10-19

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
UNIT_DIR="$SCRIPT_DIR/unit"
INTEGRATION_DIR="$SCRIPT_DIR/integration"

# Test execution options
VERBOSE=0
DEBUG=0
FILTER=""
RUN_UNIT=1
RUN_INTEGRATION=1
STOP_ON_FAILURE=0

# Aggregated file-level test state
declare -g TOTAL_TESTS=0
declare -g PASSED_TESTS=0
declare -g FAILED_TESTS=0
declare -g SKIPPED_TESTS=0
declare -a FAILED_TEST_LIST=()

# ============================================================================
# Utility Functions
# ============================================================================

# Print usage
usage() {
    cat << EOF_USAGE
Usage: test_runner.sh [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose output
    -d, --debug             Enable debug output
    -f, --filter PATTERN    Only run tests matching PATTERN
    --unit-only             Run only unit tests
    --integration-only      Run only integration tests
    --stop-on-failure       Stop on first failure
    -x, --exclude DIR       Exclude directory from tests

EXAMPLES:
    # Run all tests
    ./test_runner.sh

    # Run with verbose output
    ./test_runner.sh --verbose

    # Run only validation tests
    ./test_runner.sh --filter validation

    # Run unit tests only and stop on first failure
    ./test_runner.sh --unit-only --stop-on-failure

EOF_USAGE
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=1
                ;;
            -d|--debug)
                DEBUG=1
                VERBOSE=1
                export DEBUG=1
                ;;
            -f|--filter)
                FILTER="$2"
                shift
                ;;
            --unit-only)
                RUN_INTEGRATION=0
                ;;
            --integration-only)
                RUN_UNIT=0
                ;;
            --stop-on-failure)
                STOP_ON_FAILURE=1
                ;;
            -x|--exclude)
                # Not yet implemented
                shift
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
        shift
    done
}

# ============================================================================
# Library Loading
# ============================================================================

# Load test libraries
load_libraries() {
    echo "Loading test libraries..."

    # Check library files exist
    if [[ ! -f "$LIB_DIR/test_utils.sh" ]]; then
        echo "ERROR: test_utils.sh not found at $LIB_DIR/test_utils.sh" >&2
        return 1
    fi

    if [[ ! -f "$LIB_DIR/assertions.sh" ]]; then
        echo "ERROR: assertions.sh not found at $LIB_DIR/assertions.sh" >&2
        return 1
    fi

    if [[ ! -f "$LIB_DIR/fixtures.sh" ]]; then
        echo "ERROR: fixtures.sh not found at $LIB_DIR/fixtures.sh" >&2
        return 1
    fi

    # Source libraries
    source "$LIB_DIR/test_utils.sh" || return 1
    source "$LIB_DIR/assertions.sh" || return 1
    source "$LIB_DIR/fixtures.sh" || return 1

    echo "✓ Libraries loaded successfully"
    return 0
}

# ============================================================================
# Test Discovery and Execution
# ============================================================================

# Discover test files
discover_tests() {
    local test_dir="$1"
    local pattern="$2"

    if [[ ! -d "$test_dir" ]]; then
        return 0
    fi

    for test_file in "$test_dir"/test_*.sh; do
        if [[ ! -f "$test_file" ]]; then
            continue
        fi

        # Apply filter if specified
        if [[ -n "$pattern" ]] && [[ ! "$test_file" =~ $pattern ]]; then
            continue
        fi

        echo "$test_file"
    done

    return 0
}

# Execute a single test file
execute_test_file() {
    local test_file="$1"
    local test_name
    local output=""

    test_name=$(basename "$test_file" .sh)
    print_test_header "$test_name"

    ((TOTAL_TESTS += 1))

    # Execute each test file in an isolated process to avoid function/global-state leakage.
    if output=$(bash "$test_file" 2>&1); then
        if [[ -n "$output" ]]; then
            printf "%s\n" "$output"
        fi
        ((PASSED_TESTS += 1))
        return 0
    fi

    if [[ -n "$output" ]]; then
        printf "%s\n" "$output"
    fi

    ((FAILED_TESTS += 1))
    FAILED_TEST_LIST+=("$test_file")
    log_error "Test file failed: $test_file"
    return 1
}

# Execute all unit tests
execute_unit_tests() {
    if [[ $RUN_UNIT -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo -e "\033[1m\033[34m========== UNIT TESTS ==========\033[0m"

    if [[ ! -d "$UNIT_DIR" ]]; then
        log_warn "Unit tests directory not found: $UNIT_DIR"
        return 0
    fi

    local failed=0
    local test_files
    test_files=$(discover_tests "$UNIT_DIR" "$FILTER")

    if [[ -z "$test_files" ]]; then
        log_warn "No unit test files found"
        return 0
    fi

    while IFS= read -r test_file; do
        if [[ -f "$test_file" ]]; then
            if ! execute_test_file "$test_file"; then
                failed=1
                if [[ $STOP_ON_FAILURE -eq 1 ]]; then
                    return 1
                fi
            fi
        fi
    done <<< "$test_files"

    return $failed
}

# Execute all integration tests
execute_integration_tests() {
    if [[ $RUN_INTEGRATION -eq 0 ]]; then
        return 0
    fi

    echo ""
    echo -e "\033[1m\033[34m========== INTEGRATION TESTS ==========\033[0m"

    if [[ ! -d "$INTEGRATION_DIR" ]]; then
        log_warn "Integration tests directory not found: $INTEGRATION_DIR"
        return 0
    fi

    local failed=0
    local test_files
    test_files=$(discover_tests "$INTEGRATION_DIR" "$FILTER")

    if [[ -z "$test_files" ]]; then
        log_warn "No integration test files found"
        return 0
    fi

    while IFS= read -r test_file; do
        if [[ -f "$test_file" ]]; then
            if ! execute_test_file "$test_file"; then
                failed=1
                if [[ $STOP_ON_FAILURE -eq 1 ]]; then
                    return 1
                fi
            fi
        fi
    done <<< "$test_files"

    return $failed
}

# ============================================================================
# Report Generation
# ============================================================================

# Generate test report
generate_report() {
    local file_pass_rate=0

    echo ""
    echo -e "\033[1m\033[36mFile-level Summary\033[0m"
    echo -e "\033[36m────────────────────────────────────────\033[0m"

    if ((TOTAL_TESTS > 0)); then
        file_pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    fi

    print_summary "Total Test Files" "$TOTAL_TESTS"
    print_summary "Passed Files" "$PASSED_TESTS" "$COLOR_GREEN"
    print_summary "Failed Files" "$FAILED_TESTS" "$COLOR_RED"
    print_summary "Skipped Files" "$SKIPPED_TESTS" "$COLOR_YELLOW"
    print_summary "Pass Rate" "${file_pass_rate}%"

    if ((FAILED_TESTS > 0)); then
        echo ""
        echo -e "\033[1m\033[31mFailed Files:\033[0m"
        for failed_file in "${FAILED_TEST_LIST[@]}"; do
            echo "  - $failed_file"
        done
    fi

    # Print configuration summary
    echo ""
    echo -e "\033[1m\033[34mConfiguration\033[0m"
    echo "  Verbose: $VERBOSE"
    echo "  Debug: $DEBUG"
    echo "  Unit Tests: $RUN_UNIT"
    echo "  Integration Tests: $RUN_INTEGRATION"

    # Print test directory info
    echo ""
    echo -e "\033[1m\033[34mTest Directories\033[0m"
    echo "  Unit: $UNIT_DIR"
    echo "  Integration: $INTEGRATION_DIR"
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Parse arguments
    parse_arguments "$@"

    # Print header
    echo ""
    echo -e "\033[1m\033[34m╔════════════════════════════════════════╗\033[0m"
    echo -e "\033[1m\033[34m║  dev-env Test Suite Execution Engine  ║\033[0m"
    echo -e "\033[1m\033[34m╚════════════════════════════════════════╝\033[0m"
    echo ""

    # Load libraries first (before using their functions)
    if ! load_libraries; then
        echo "ERROR: Failed to load test libraries" >&2
        return 1
    fi

    # Initialize test state
    init_test_state
    TOTAL_TESTS=0
    PASSED_TESTS=0
    FAILED_TESTS=0
    SKIPPED_TESTS=0
    FAILED_TEST_LIST=()

    # Execute tests
    local overall_status=0

    if ! execute_unit_tests; then
        overall_status=1
    fi

    if ! execute_integration_tests; then
        overall_status=1
    fi

    # Generate report
    generate_report

    # Exit with appropriate code
    if [[ $overall_status -eq 0 ]]; then
        echo ""
        log_success "All tests passed! ✓"
        return 0
    else
        echo ""
        log_error "Some tests failed! ✗"
        return 1
    fi
}

# ============================================================================
# Execution
# ============================================================================

main "$@"
exit $?
