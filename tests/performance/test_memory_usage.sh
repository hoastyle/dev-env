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
# Local Helper Functions
# =============================================================================

# Print section header (local definition for performance tests)
print_section() {
    local section_name="$1"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$section_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Load test utilities for print_section function
if [[ -f "$SCRIPT_DIR/../lib/test_utils.sh" ]]; then
    source "$SCRIPT_DIR/../lib/test_utils.sh"
fi

# =============================================================================
# Helper Functions
# =============================================================================

# Get memory usage in KB
get_memory_kb() {
    local pid="$1"

    # Check if process exists
    if [[ ! -d "/proc/$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
        echo "0"
        return 1
    fi

    # Read RSS (Resident Set Size) from status file
    local rss=$(grep -E '^VmRSS:' "/proc/$pid/status" 2>/dev/null | awk '{print $2}')

    # Validate RSS is numeric
    if [[ -n "$rss" && "$rss" =~ ^[0-9]+$ ]]; then
        echo "$rss"
        return 0
    fi

    # Fallback: use statm if available
    local statm_data=$(cat "/proc/$pid/statm" 2>/dev/null)
    if [[ -n "$statm_data" ]]; then
        local rss=$(echo "$statm_data" | awk '{print $2 * 4}')  # pages to KB
        echo "${rss:-0}"
        return 0
    fi

    echo "0"
    return 1
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

    # Start ZSH in background with config (isolated from user config)
    local temp_script=$(mktemp)
    cat > "$temp_script" << 'TEMPEOF'
#!/bin/zsh
# Isolate from all user configuration
ZDOTDIR=/dev/null
setopt NO_GLOBAL_RCS
setopt NO_RCS

# Source the test config file
source '$config_file'
sleep 5
TEMPEOF
    chmod +x "$temp_script"

    # Launch ZSH - using -Z and -o NO_RCS for isolation
    zsh -Z -o NO_RCS -o NO_GLOBAL_RCS "$temp_script" &
    local zsh_pid=$!

    # Wait for initialization and check process is still running
    sleep 3
    if ! kill -0 "$zsh_pid" 2>/dev/null; then
        log_warn "ZSH process exited early, using default values"
        echo "0,0,0"
        return 1
    fi

    # Measure memory at idle
    local idle_memory=$(get_memory_kb "$zsh_pid")

    # Check process still exists before second measurement
    if ! kill -0 "$zsh_pid" 2>/dev/null; then
        log_warn "ZSH process exited during measurement"
        echo "${idle_memory:-0},0,0"
        return 1
    fi

    # Measure memory after activity
    local active_memory=$(get_memory_kb "$zsh_pid")

    # Get peak memory (VmHWM)
    local peak_memory=$(grep -E '^VmHWM:' "/proc/$zsh_pid/status" 2>/dev/null | awk '{print $2}')
    [[ -z "$peak_memory" ]] && peak_memory="0"

    # Cleanup: Kill the background ZSH process
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

    # Convert to integers for comparison (remove decimal points)
    local normal_idle_int=${normal_idle%.*}
    local fast_idle_int=${fast_idle%.*}
    local minimal_idle_int=${minimal_idle%.*}

    if [[ $minimal_idle_int -gt 0 && $normal_idle_int -gt 0 ]]; then
        local saving=$((normal_idle_int - minimal_idle_int))
        local percent=$((saving * 100 / normal_idle_int))
        echo "Minimal mode saves ${saving}KB (${percent}%) compared to Normal"
    fi

    if [[ $fast_idle_int -gt 0 && $normal_idle_int -gt 0 ]]; then
        local saving=$((normal_idle_int - fast_idle_int))
        local percent=$((saving * 100 / normal_idle_int))
        echo "Fast mode saves ${saving}KB (${percent}%) compared to Normal"
    fi

    echo ""
}

# =============================================================================
# Test Functions
# =============================================================================

test_memory_usage() {
    print_section "ZSH Memory Usage Test"

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
    print_section "Memory Usage Test (ps-based fallback)"

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

        # Start ZSH and measure with ps (isolated from user config)
        local temp_script=$(mktemp)
        cat > "$temp_script" << 'TEMPEOF'
#!/bin/zsh
ZDOTDIR=/dev/null
setopt NO_GLOBAL_RCS
setopt NO_RCS
source '$config_file'
sleep 3
TEMPEOF
        chmod +x "$temp_script"

        # Launch ZSH with isolation
        zsh -Z -o NO_RCS -o NO_GLOBAL_RCS "$temp_script" &
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
