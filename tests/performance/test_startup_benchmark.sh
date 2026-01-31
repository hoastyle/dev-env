#!/bin/bash
# =============================================================================
# ZSH Startup Performance Benchmark Test
# =============================================================================
# Description: Comprehensive startup time measurement for different ZSH modes
# Version: 1.0
# =============================================================================

set -e

# =============================================================================
# Test Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config"

# Test iterations
ITERATIONS=${ITERATIONS:-5}

# Output directory
OUTPUT_DIR="$PROJECT_ROOT/test-results/performance"
mkdir -p "$OUTPUT_DIR"

# Results file
RESULTS_FILE="$OUTPUT_DIR/startup_benchmark_$(date +%Y%m%d_%H%M%S).csv"
SUMMARY_FILE="$OUTPUT_DIR/startup_summary_$(date +%Y%m%d_%H%M%S).txt"

# =============================================================================
# Load Libraries
# =============================================================================

if [[ -f "$PROJECT_ROOT/scripts/lib_logging.sh" ]]; then
    source "$PROJECT_ROOT/scripts/lib_logging.sh"
    init_logging 2>/dev/null || true
else
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*"; }
fi

if [[ -f "$PROJECT_ROOT/scripts/lib_platform_compat.sh" ]]; then
    source "$PROJECT_ROOT/scripts/lib_platform_compat.sh"
fi

# =============================================================================
# Helper Functions
# =============================================================================

# Get current timestamp in milliseconds
get_timestamp_ms() {
    if command -v python &>/dev/null; then
        python -c 'import time; print(int(time.time()*1000))' 2>/dev/null
    elif command -v perl &>/dev/null; then
        perl -MTime::HiRes -e 'printf("%d",Time::HiRes::time()*1000)' 2>/dev/null
    else
        echo $(($(date +%s) * 1000))
    fi
}

# Measure ZSH startup time for a config file
measure_startup_time() {
    local config_file="$1"
    local mode="$2"
    local iteration="$3"

    if [[ ! -f "$config_file" ]]; then
        echo "SKIP"
        return 1
    fi

    local start_time=$(get_timestamp_ms)
    zsh -c "source $config_file && exit" 2>/dev/null || true
    local end_time=$(get_timestamp_ms)

    echo $((end_time - start_time))
}

# Run benchmark for a specific mode
benchmark_mode() {
    local mode="$1"
    local config_file=""

    case "$mode" in
        "normal")
            config_file="$CONFIG_DIR/.zshrc"
            ;;
        "fast")
            config_file="$CONFIG_DIR/.zshrc.optimized"
            ;;
        "minimal")
            config_file="$CONFIG_DIR/.zshrc.ultra-optimized"
            ;;
        *)
            log_error "Unknown mode: $mode"
            return 1
            ;;
    esac

    if [[ ! -f "$config_file" ]]; then
        log_warn "Config file not found: $config_file"
        return 1
    fi

    log_info "Benchmarking mode: $mode"
    local total_time=0
    local times=()

    for ((i=1; i<=ITERATIONS; i++)); do
        local time=$(measure_startup_time "$config_file" "$mode" "$i")
        if [[ "$time" == "SKIP" ]]; then
            continue
        fi
        times+=("$time")
        total_time=$((total_time + time))
        printf "  Iteration %d: %d ms\n" "$i" "$time"
    done

    if [[ ${#times[@]} -eq 0 ]]; then
        log_error "No valid measurements for mode: $mode"
        return 1
    fi

    local avg_time=$((total_time / ${#times[@]}))

    # Calculate min and max
    local min_time=${times[0]}
    local max_time=${times[0]}
    for time in "${times[@]}"; do
        [[ $time -lt $min_time ]] && min_time=$time
        [[ $time -gt $max_time ]] && max_time=$time
    done

    # Calculate standard deviation
    local variance=0
    for time in "${times[@]}"; do
        local diff=$((time - avg_time))
        variance=$((variance + diff * diff))
    done
    local stddev=0
    if [[ ${#times[@]} -gt 1 ]]; then
        stddev=$(echo "scale=2; sqrt($variance / ${#times[@]})" | bc 2>/dev/null || echo "0")
    fi

    printf "  Average: %d ms\n" "$avg_time"
    printf "  Min: %d ms\n" "$min_time"
    printf "  Max: %d ms\n" "$max_time"
    printf "  StdDev: %s\n" "$stddev"
    echo ""

    # Write to CSV
    echo "$mode,$avg_time,$min_time,$max_time,$stddev" >> "$RESULTS_FILE"

    return 0
}

# Generate summary report
generate_summary() {
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "         ZSH Startup Performance Benchmark Summary"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Date: $(date)"
        echo "Iterations per mode: $ITERATIONS"
        echo "Platform: $(uname -s) $(uname -m)"
        echo "ZSH Version: $(zsh --version)"
        echo ""
        echo "───────────────────────────────────────────────────────────────"
        echo "Mode       │ Avg (ms) │ Min (ms) │ Max (ms) │ StdDev"
        echo "───────────────────────────────────────────────────────────────"

        # Read CSV and format
        while IFS=',' read -r mode avg min max stddev; do
            printf "%-10s │ %8s │ %8s │ %8s │ %s\n" "$mode" "$avg" "$min" "$max" "$stddev"
        done < "$RESULTS_FILE"

        echo "───────────────────────────────────────────────────────────────"
        echo ""
        echo "Results saved to: $RESULTS_FILE"
        echo "═══════════════════════════════════════════════════════════════"
    } | tee "$SUMMARY_FILE"
}

# Compare modes
compare_modes() {
    local normal_avg=0
    local fast_avg=0
    local minimal_avg=0

    while IFS=',' read -r mode avg min max stddev; do
        case "$mode" in
            "normal") normal_avg=$avg ;;
            "fast") fast_avg=$avg ;;
            "minimal") minimal_avg=$avg ;;
        esac
    done < "$RESULTS_FILE"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Performance Comparison"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ $minimal_avg -gt 0 && $normal_avg -gt 0 ]]; then
        local improvement=$((100 - (minimal_avg * 100 / normal_avg)))
        echo "Minimal mode is ${improvement}% faster than Normal mode"
    fi

    if [[ $fast_avg -gt 0 && $normal_avg -gt 0 ]]; then
        local improvement=$((100 - (fast_avg * 100 / normal_avg)))
        echo "Fast mode is ${improvement}% faster than Normal mode"
    fi

    if [[ $minimal_avg -gt 0 && $fast_avg -gt 0 ]]; then
        local improvement=$((100 - (minimal_avg * 100 / fast_avg)))
        echo "Minimal mode is ${improvement}% faster than Fast mode"
    fi

    echo ""
}

# =============================================================================
# Test Functions
# =============================================================================

test_startup_benchmark() {
    log_header "ZSH Startup Performance Benchmark"

    # Create CSV header
    echo "mode,average_ms,min_ms,max_ms,stddev" > "$RESULTS_FILE"

    # Benchmark each mode
    benchmark_mode "minimal"
    benchmark_mode "fast"
    benchmark_mode "normal"

    # Generate summary
    generate_summary
    compare_modes

    log_success "Benchmark complete!"
}

test_warm_startup() {
    log_header "Warm Startup Benchmark (with cache)"

    # Pre-load compinit cache
    zsh -c "autoload -Uz compinit && compinit && exit" 2>/dev/null || true

    # Create CSV header
    echo "mode,average_ms,min_ms,max_ms,stddev" > "$RESULTS_FILE"

    benchmark_mode "minimal"
    benchmark_mode "fast"
    benchmark_mode "normal"

    generate_summary

    log_success "Warm startup benchmark complete!"
}

test_cold_startup() {
    log_header "Cold Startup Benchmark (clear cache)"

    # Clear cache
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/dev-env"
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/p10k"
    rm -f "${ZDOTDIR:-$HOME}/.zcompdump"* 2>/dev/null || true

    # Create CSV header
    echo "mode,average_ms,min_ms,max_ms,stddev" > "$RESULTS_FILE"

    benchmark_mode "minimal"
    benchmark_mode "fast"
    benchmark_mode "normal"

    generate_summary

    log_success "Cold startup benchmark complete!"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local test_type="${1:-all}"

    case "$test_type" in
        "all"|"benchmark")
            test_startup_benchmark
            ;;
        "warm")
            test_warm_startup
            ;;
        "cold")
            test_cold_startup
            ;;
        *)
            log_error "Unknown test type: $test_type"
            echo "Usage: $0 [all|warm|cold]"
            exit 1
            ;;
    esac
}

# =============================================================================
# Test Lifecycle
# =============================================================================

setup() {
    log_info "Setting up startup benchmark tests"
    mkdir -p "$OUTPUT_DIR"
}

teardown() {
    log_info "Tearing down startup benchmark tests"
}

# =============================================================================
# Script Entry Point
# =============================================================================

setup
main "$@"
teardown
