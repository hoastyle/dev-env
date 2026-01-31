#!/bin/bash
# =============================================================================
# ZSH Memory Usage Test
# =============================================================================
# Description: Memory usage measurement for different ZSH configurations
# Version: 1.0
# =============================================================================

set -e

# =============================================================================
# Test Configuration
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CONFIG_DIR="$PROJECT_ROOT/config"

# Output directory
OUTPUT_DIR="$PROJECT_ROOT/test-results/performance"
mkdir -p "$OUTPUT_DIR"

# Results file
RESULTS_FILE="$OUTPUT_DIR/memory_usage_$(date +%Y%m%d_%H%M%S).csv"
SUMMARY_FILE="$OUTPUT_DIR/memory_summary_$(date +%Y%m%d_%H%M%S).txt"

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

# =============================================================================
# Helper Functions
# =============================================================================

# Get memory usage in KB
get_memory_kb() {
    local pid="$1"

    if [[ ! -d "/proc/$pid" ]]; then
        echo "N/A"
        return 1
    fi

    # Read RSS (Resident Set Size) from status file
    local rss=$(grep -E '^VmRSS:' "/proc/$pid/status" 2>/dev/null | awk '{print $2}')

    if [[ -n "$rss" ]]; then
        echo "$rss"
    else
        # Fallback to stat
        local rss=$(grep -E '^rss:' "/proc/$pid/statm" 2>/dev/null | awk '{print $2 * 4}')  # pages to KB
        echo "${rss:-0}"
    fi
}

# Get memory usage in MB
get_memory_mb() {
    local kb=$(get_memory_kb "$1")
    if [[ "$kb" == "N/A" ]]; then
        echo "N/A"
    else
        echo "$kb" | awk '{printf "%.2f", $1 / 1024}'
    fi
}

# Measure memory usage for a config file
measure_memory_usage() {
    local config_file="$1"
    local mode="$2"

    if [[ ! -f "$config_file" ]]; then
        echo "N/A,N/A,N/A"
        return 1
    fi

    # Start ZSH in background with config
    local temp_script=$(mktemp)
    echo "#!/bin/zsh" > "$temp_script"
    echo "source '$config_file'" >> "$temp_script"
    echo "sleep 300" >> "$temp_script"
    chmod +x "$temp_script"

    # Launch ZSH
    zsh "$temp_script" &
    local zsh_pid=$!

    # Wait for initialization
    sleep 2

    # Measure memory at idle
    local idle_memory=$(get_memory_kb "$zsh_pid")

    # Trigger some activity (compinit)
    zsh -c "echo $zsh_pid | xargs kill -USR1" 2>/dev/null || true

    # Measure memory after activity
    local active_memory=$(get_memory_kb "$zsh_pid")

    # Get peak memory (VmHWM)
    local peak_memory=$(grep -E '^VmHWM:' "/proc/$zsh_pid/status" 2>/dev/null | awk '{print $2}')
    [[ -z "$peak_memory" ]] && peak_memory="0"

    # Cleanup
    kill "$zsh_pid" 2>/dev/null || true
    wait "$zsh_pid" 2>/dev/null || true
    rm -f "$temp_script"

    echo "${idle_memory:-0},${active_memory:-0},${peak_memory:-0}"
}

# Run memory test for a specific mode
test_mode_memory() {
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

    log_info "Testing memory usage for mode: $mode"

    local result=$(measure_memory_usage "$config_file" "$mode")
    IFS=',' read -r idle active peak <<< "$result"

    local idle_mb=$(echo "$idle" | awk '{printf "%.2f", $1 / 1024}')
    local active_mb=$(echo "$active" | awk '{printf "%.2f", $1 / 1024}')
    local peak_mb=$(echo "$peak" | awk '{printf "%.2f", $1 / 1024}')

    printf "  Idle Memory:   %8s MB\n" "$idle_mb"
    printf "  Active Memory: %8s MB\n" "$active_mb"
    printf "  Peak Memory:   %8s MB\n" "$peak_mb"
    echo ""

    # Write to CSV (in KB)
    echo "$mode,$idle,$active,$peak" >> "$RESULTS_FILE"

    return 0
}

# Generate summary report
generate_summary() {
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "              ZSH Memory Usage Summary"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "Date: $(date)"
        echo "Platform: $(uname -s) $(uname -m)"
        echo "ZSH Version: $(zsh --version)"
        echo ""
        echo "───────────────────────────────────────────────────────────────"
        echo "Mode       │ Idle (MB) │ Active (MB) │ Peak (MB)"
        echo "───────────────────────────────────────────────────────────────"

        # Read CSV and format
        while IFS=',' read -r mode idle active peak; do
            local idle_mb=$(echo "$idle" | awk '{printf "%.2f", $1 / 1024}')
            local active_mb=$(echo "$active" | awk '{printf "%.2f", $1 / 1024}')
            local peak_mb=$(echo "$peak" | awk '{printf "%.2f", $1 / 1024}')
            printf "%-10s │ %9s │ %10s │ %9s\n" "$mode" "$idle_mb" "$active_mb" "$peak_mb"
        done < "$RESULTS_FILE"

        echo "───────────────────────────────────────────────────────────────"
        echo ""
        echo "Results saved to: $RESULTS_FILE"
        echo "═══════════════════════════════════════════════════════════════"
    } | tee "$SUMMARY_FILE"
}

# Compare memory usage
compare_memory() {
    local normal_idle=0
    local fast_idle=0
    local minimal_idle=0

    while IFS=',' read -r mode idle active peak; do
        case "$mode" in
            "normal") normal_idle=$idle ;;
            "fast") fast_idle=$idle ;;
            "minimal") minimal_idle=$idle ;;
        esac
    done < "$RESULTS_FILE"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Memory Comparison (Idle)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [[ $minimal_idle -gt 0 && $normal_idle -gt 0 ]]; then
        local saving=$((normal_idle - minimal_idle))
        local percent=$((saving * 100 / normal_idle))
        echo "Minimal mode saves ${saving}KB (${percent}%) compared to Normal"
    fi

    if [[ $fast_idle -gt 0 && $normal_idle -gt 0 ]]; then
        local saving=$((normal_idle - fast_idle))
        local percent=$((saving * 100 / normal_idle))
        echo "Fast mode saves ${saving}KB (${percent}%) compared to Normal"
    fi

    echo ""
}

# =============================================================================
# Test Functions
# =============================================================================

test_memory_usage() {
    log_header "ZSH Memory Usage Test"

    # Check if /proc is available (Linux only)
    if [[ ! -d "/proc" ]]; then
        log_error "Memory test requires /proc filesystem (Linux only)"
        log_info "Alternative: Use 'ps' command or system monitoring tools"
        return 1
    fi

    # Create CSV header
    echo "mode,idle_kb,active_kb,peak_kb" > "$RESULTS_FILE"

    # Test each mode
    test_mode_memory "minimal"
    test_mode_memory "fast"
    test_mode_memory "normal"

    # Generate summary
    generate_summary
    compare_memory

    log_success "Memory usage test complete!"
}

test_ps_based_memory() {
    log_header "Memory Usage Test (ps-based fallback)"

    # Create CSV header
    echo "mode,rss_mb,vsz_mb" > "$RESULTS_FILE"

    for mode in minimal fast normal; do
        local config_file=""
        case "$mode" in
            "normal") config_file="$CONFIG_DIR/.zshrc" ;;
            "fast") config_file="$CONFIG_DIR/.zshrc.optimized" ;;
            "minimal") config_file="$CONFIG_DIR/.zshrc.ultra-optimized" ;;
        esac

        if [[ ! -f "$config_file" ]]; then
            continue
        fi

        log_info "Testing mode: $mode"

        # Start ZSH and measure with ps
        local temp_script=$(mktemp)
        echo "#!/bin/zsh" > "$temp_script"
        echo "source '$config_file'" >> "$temp_script"
        echo "sleep 60" >> "$temp_script"
        chmod +x "$temp_script"

        zsh "$temp_script" &
        local zsh_pid=$!
        sleep 2

        # Use ps to measure memory
        local mem_output=$(ps -p "$zsh_pid" -o rss=,vsz= 2>/dev/null || echo "0 0")
        local rss=$(echo "$mem_output" | awk '{print int($1/1024)}')  # KB to MB
        local vsz=$(echo "$mem_output" | awk '{print int($2/1024)}')  # KB to MB

        kill "$zsh_pid" 2>/dev/null || true
        wait "$zsh_pid" 2>/dev/null || true
        rm -f "$temp_script"

        echo "$mode,$rss,$vsz" >> "$RESULTS_FILE"
        printf "  RSS: %d MB, VSZ: %d MB\n" "$rss" "$vsz"
    done

    generate_summary
    log_success "Memory test complete!"
}

# =============================================================================
# Main
# =============================================================================

main() {
    local test_type="${1:-auto}"

    case "$test_type" in
        "auto"|"memory")
            if [[ -d "/proc" ]]; then
                test_memory_usage
            else
                log_warn "/proc not available, using ps-based fallback"
                test_ps_based_memory
            fi
            ;;
        "ps")
            test_ps_based_memory
            ;;
        *)
            log_error "Unknown test type: $test_type"
            echo "Usage: $0 [auto|memory|ps]"
            exit 1
            ;;
    esac
}

# =============================================================================
# Test Lifecycle
# =============================================================================

setup() {
    log_info "Setting up memory usage tests"
    mkdir -p "$OUTPUT_DIR"
}

teardown() {
    log_info "Tearing down memory usage tests"
}

# =============================================================================
# Script Entry Point
# =============================================================================

setup
main "$@"
teardown
