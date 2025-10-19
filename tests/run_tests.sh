#!/usr/bin/env bash
# run_tests.sh - Local test runner wrapper
# Convenience script for running tests with common options
# Version: 1.0
# Created: 2025-10-19

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_RUNNER="$SCRIPT_DIR/test_runner.sh"

# ============================================================================
# Color definitions
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# Help text
# ============================================================================

show_help() {
    cat << EOF
Usage: run_tests.sh [MODE] [OPTIONS]

MODES:
    quick               Run quick tests (unit tests only)
    full                Run all tests (default)
    unit                Run unit tests only
    integration         Run integration tests only
    debug               Run tests with debug output
    watch               Watch mode (rerun on changes - requires inotify-tools)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output
    -f, --filter PATTERN Filter tests by pattern
    --stop-on-failure   Stop on first failure
    --no-cleanup        Keep temporary files for debugging

EXAMPLES:
    # Run all tests
    ./run_tests.sh

    # Run quick test suite
    ./run_tests.sh quick

    # Run with verbose output and stop on failure
    ./run_tests.sh full --verbose --stop-on-failure

    # Run only validation tests
    ./run_tests.sh unit --filter validation

    # Debug mode with detailed output
    ./run_tests.sh debug

EOF
}

# ============================================================================
# Test execution functions
# ============================================================================

run_quick_tests() {
    echo -e "${BLUE}Running quick test suite (unit tests only)...${NC}"
    "$TEST_RUNNER" --unit-only "$@"
}

run_full_tests() {
    echo -e "${BLUE}Running full test suite (all tests)...${NC}"
    "$TEST_RUNNER" "$@"
}

run_unit_tests() {
    echo -e "${BLUE}Running unit tests only...${NC}"
    "$TEST_RUNNER" --unit-only "$@"
}

run_integration_tests() {
    echo -e "${BLUE}Running integration tests only...${NC}"
    "$TEST_RUNNER" --integration-only "$@"
}

run_debug_tests() {
    echo -e "${BLUE}Running tests in debug mode...${NC}"
    "$TEST_RUNNER" --debug --verbose "$@"
}

watch_tests() {
    echo -e "${YELLOW}Watch mode enabled. Rerunning on changes...${NC}"

    if ! command -v inotifywait &>/dev/null; then
        echo -e "${RED}Error: inotify-tools not installed${NC}"
        echo "Install with: sudo apt-get install inotify-tools"
        return 1
    fi

    # Initial run
    run_full_tests

    # Watch for changes
    while inotifywait -r -e modify \
        "$SCRIPT_DIR/lib" \
        "$SCRIPT_DIR/unit" \
        "$SCRIPT_DIR/integration" \
        "$SCRIPT_DIR/test_runner.sh" \
        2>/dev/null; do
        clear
        echo -e "${YELLOW}File changed, rerunning tests...${NC}"
        run_full_tests || true
    done
}

# ============================================================================
# Results reporting
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     dev-env Test Suite Runner        ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_footer() {
    local exit_code=$1
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}✓ All tests completed successfully${NC}"
    else
        echo -e "${RED}✗ Some tests failed (exit code: $exit_code)${NC}"
    fi
    echo ""
}

# ============================================================================
# Main
# ============================================================================

main() {
    local mode="full"
    local test_args=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            quick)
                mode="quick"
                ;;
            full)
                mode="full"
                ;;
            unit)
                mode="unit"
                ;;
            integration)
                mode="integration"
                ;;
            debug)
                mode="debug"
                ;;
            watch)
                mode="watch"
                ;;
            -v|--verbose|--stop-on-failure|-f|--filter)
                test_args+=("$1")
                if [[ "$1" == "-f" || "$1" == "--filter" ]]; then
                    test_args+=("$2")
                    shift
                fi
                ;;
            --no-cleanup)
                export NO_CLEANUP=1
                ;;
            *)
                echo "Unknown option: $1" >&2
                show_help
                exit 1
                ;;
        esac
        shift
    done

    # Print header
    print_header

    # Check if test runner exists
    if [[ ! -f "$TEST_RUNNER" ]]; then
        echo -e "${RED}Error: test_runner.sh not found at $TEST_RUNNER${NC}"
        exit 1
    fi

    # Run tests based on mode
    local exit_code=0
    case "$mode" in
        quick)
            run_quick_tests "${test_args[@]}" || exit_code=$?
            ;;
        full)
            run_full_tests "${test_args[@]}" || exit_code=$?
            ;;
        unit)
            run_unit_tests "${test_args[@]}" || exit_code=$?
            ;;
        integration)
            run_integration_tests "${test_args[@]}" || exit_code=$?
            ;;
        debug)
            run_debug_tests "${test_args[@]}" || exit_code=$?
            ;;
        watch)
            watch_tests "${test_args[@]}" || exit_code=$?
            ;;
        *)
            echo "Unknown mode: $mode" >&2
            show_help
            exit 1
            ;;
    esac

    # Print footer
    print_footer $exit_code

    return $exit_code
}

# ============================================================================
# Execution
# ============================================================================

main "$@"
exit $?
