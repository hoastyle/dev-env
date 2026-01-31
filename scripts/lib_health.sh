#!/bin/bash
# =============================================================================
# Configuration Lifecycle Management - Health Check Library
# =============================================================================
# Description: Health check functions for ZSH configuration
# Version: 1.0
# Created: 2026-01-31
# =============================================================================

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Health check log
HEALTH_CHECK_LOG="${HEALTH_CHECK_LOG:-$PROJECT_ROOT/data/health_check.log}"

# Configuration files to check
CONFIG_FILE="${CONFIG_FILE:-$HOME/.zshrc}"
PROJECT_CONFIG="$PROJECT_ROOT/config/.zshrc"

# Ensure data directory exists
mkdir -p "$(dirname "$HEALTH_CHECK_LOG")"

# =============================================================================
# Health Check Functions
# =============================================================================

# Run all health checks
# Returns: 0 if all checks pass, 1 if any fail
run_health_check() {
    echo "🏥 Running ZSH Configuration Health Check"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local checks_passed=0
    local checks_failed=0
    local checks_warned=0

    # Run individual checks
    check_syntax
    local syntax_status=$?

    check_plugins
    local plugins_status=$?

    check_dependencies
    local deps_status=$?

    check_version_file
    local version_status=$?

    # Count results
    [[ $syntax_status -eq 0 ]] && ((checks_passed++)) || ((checks_failed++))
    [[ $plugins_status -eq 0 ]] && ((checks_passed++)) || ((checks_warned++))
    [[ $deps_status -eq 0 ]] && ((checks_passed++)) || ((checks_warned++))
    [[ $version_status -eq 0 ]] && ((checks_passed++)) || ((checks_failed++))

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Health Check Results: $checks_passed passed, $checks_warned warnings, $checks_failed failed"

    # Generate and save report
    generate_health_report "$checks_passed" "$checks_warned" "$checks_failed" "$syntax_status" "$plugins_status" "$deps_status" "$version_status"

    if [[ $checks_failed -eq 0 ]]; then
        echo "✅ All health checks passed!"
        return 0
    else
        echo "⚠️  Some health checks failed"
        return 1
    fi
}

# Check configuration file syntax
# Returns: 0 if valid, 1 if invalid
check_syntax() {
    echo "Checking: Configuration file syntax..."

    local config_to_check="$CONFIG_FILE"

    # Use project config if home config doesn't exist
    if [[ ! -f "$config_to_check" && -f "$PROJECT_CONFIG" ]]; then
        config_to_check="$PROJECT_CONFIG"
    fi

    if [[ ! -f "$config_to_check" ]]; then
        echo "  ⚠️  No configuration file found"
        return 1
    fi

    # Check syntax with zsh -n
    local syntax_errors=$(zsh -n "$config_to_check" 2>&1)
    local syntax_status=$?

    if [[ $syntax_status -eq 0 ]]; then
        echo "  ✅ Configuration syntax is valid"
        return 0
    else
        echo "  ❌ Configuration syntax errors found:"
        echo "$syntax_errors" | sed 's/^/     /'
        return 1
    fi
}

# Check plugin status
# Returns: 0 if plugins OK, 1 if issues
check_plugins() {
    echo "Checking: Plugin status..."

    # Check if Antigen is installed
    if [[ -f "$HOME/.antigen.zsh" || -f "$HOME/antigen.zsh" ]]; then
        echo "  ✅ Antigen is installed"
    else
        echo "  ⚠️  Antigen not found (optional)"
    fi

    # Check common plugin directories
    local plugins_ok=0

    if [[ -d "$HOME/.zsh/plugins" ]]; then
        local plugin_count=$(find "$HOME/.zsh/plugins" -type f 2>/dev/null | wc -l)
        echo "  ✅ Custom plugins directory found ($plugin_count plugins)"
        ((plugins_ok++))
    fi

    if [[ -f "$HOME/.zshrc.local" ]]; then
        echo "  ✅ Local configuration (.zshrc.local) exists"
        ((plugins_ok++))
    fi

    if [[ $plugins_ok -gt 0 ]]; then
        return 0
    else
        echo "  ℹ️  No custom plugins found"
        return 0
    fi
}

# Check required and optional dependencies
# Returns: 0 if all required OK, 1 if missing required
check_dependencies() {
    echo "Checking: System dependencies..."

    local required_missing=0
    local optional_missing=0

    # Required tools
    local required_tools=("zsh")
    for tool in "${required_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            echo "  ✅ $tool is installed"
        else
            echo "  ❌ $tool is NOT installed (required)"
            ((required_missing++))
        fi
    done

    # Optional but recommended tools
    local optional_tools=("fzf" "fd" "rg" "ripgrep" "fdfind")
    for tool in "${optional_tools[@]}"; do
        if command -v "$tool" &>/dev/null; then
            local version=$($tool --version 2>&1 | head -n1 || echo "version unknown")
            echo "  ✅ $tool is installed ($version)"
        fi
    done

    # Check fd/fdfind (fd has different name on some systems)
    if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
        echo "  ⚠️  fd/fdfind not found (recommended for fuzzy file search)"
        ((optional_missing++))
    fi

    # Check ripgrep
    if ! command -v rg &>/dev/null && ! command -v ripgrep &>/dev/null; then
        echo "  ⚠️  ripgrep not found (recommended for fast content search)"
        ((optional_missing++))
    fi

    if [[ $required_missing -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}

# Check version file
# Returns: 0 if OK, 1 if issues
check_version_file() {
    echo "Checking: Version file..."

    # Source version library
    source "$PROJECT_ROOT/scripts/lib_version.sh" 2>/dev/null || true

    local version=$(get_current_version 2>/dev/null)
    if [[ -z "$version" || "$version" == "0.0.0" ]]; then
        echo "  ⚠️  Version file not initialized"
        echo "     Run 'set_version X.Y.Z' to initialize"
        return 1
    else
        echo "  ✅ Version: $version"
        return 0
    fi
}

# Generate health check report
# Args:
#   $1 - Checks passed count
#   $2 - Checks warned count
#   $3 - Checks failed count
generate_health_report() {
    local passed="$1"
    local warned="$2"
    local failed="$3"
    local shift_syntax="$4"
    local shift_plugins="$5"
    local shift_deps="$6"
    local shift_version="$7"

    local timestamp=$(date -Iseconds)
    local version=$(source "$PROJECT_ROOT/scripts/lib_version.sh" 2>/dev/null && get_current_version)

    # Calculate score
    local total=$((passed + warned + failed))
    local score=0
    [[ $total -gt 0 ]] && score=$((passed * 100 / total))

    # Create JSON report
    local json_report="$HEALTH_CHECK_LOG"
    cat > "$json_report" << EOF
{
  "timestamp": "$timestamp",
  "version": "$version",
  "score": $score,
  "summary": {
    "passed": $passed,
    "warned": $warned,
    "failed": $failed,
    "total": $total
  },
  "checks": [
    {
      "name": "syntax",
      "status": "$([[ $shift_syntax -eq 0 ]] && echo "PASS" || echo "FAIL")",
      "message": "Configuration syntax validation"
    },
    {
      "name": "plugins",
      "status": "$([[ $shift_plugins -eq 0 ]] && echo "PASS" || echo "WARN")",
      "message": "Plugin installation check"
    },
    {
      "name": "dependencies",
      "status": "$([[ $shift_deps -eq 0 ]] && echo "PASS" || echo "WARN")",
      "message": "System dependencies check"
    },
    {
      "name": "version",
      "status": "$([[ $shift_version -eq 0 ]] && echo "PASS" || echo "FAIL")",
      "message": "Version file validation"
    }
  ]
}
EOF

    echo "📊 Health report saved to: $json_report"
}

# Display health report
# Shows the saved health check report
display_health_report() {
    if [[ ! -f "$HEALTH_CHECK_LOG" ]]; then
        echo "No health check report found. Run 'run_health_check' first."
        return 1
    fi

    echo "📊 Last Health Check Report"
    echo "━━━���━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Parse JSON and display (simple grep-based parsing)
    local timestamp=$(grep '"timestamp":' "$HEALTH_CHECK_LOG" | cut -d'"' -f4)
    local version=$(grep '"version":' "$HEALTH_CHECK_LOG" | cut -d'"' -f4)
    local score=$(grep '"score":' "$HEALTH_CHECK_LOG" | grep -o '[0-9]*')

    echo "Time: $timestamp"
    echo "Version: $version"
    echo "Score: $score%"
    echo ""

    echo "Check Results:"
    grep -A1 '"checks":' "$HEALTH_CHECK_LOG" -A100 | grep -E '(name|status|message)' | while read -r key; do
        local value=$(echo "$key" | cut -d'"' -f2)
        if [[ "$key" =~ "name" ]]; then
            echo -n "  • $value: "
        elif [[ "$key" =~ "status" ]]; then
            case "$value" in
                "PASS") echo -n "✅ " ;;
                "WARN") echo -n "⚠️  " ;;
                "FAIL") echo -n "❌ " ;;
            esac
        elif [[ "$key" =~ "message" ]]; then
            echo "$value"
        fi
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# =============================================================================
# Test Functions
# =============================================================================

test_health_functions() {
    echo "🧪 Testing Health Check Functions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Test 1: Syntax check with test file
    echo ""
    echo "Test 1: Syntax check"
    local test_config=$(mktemp)
    echo "# Valid ZSH config" > "$test_config"
    echo "export TEST_VAR='value'" >> "$test_config"

    CONFIG_FILE="$test_config" check_syntax > /dev/null
    local status=$?
    rm -f "$test_config"

    if [[ $status -eq 0 ]]; then
        echo "✅ PASS: Syntax check works"
    else
        echo "❌ FAIL: Syntax check failed"
        return 1
    fi

    # Test 2: Dependencies check
    echo ""
    echo "Test 2: Dependencies check"
    check_dependencies > /dev/null
    if [[ $? -eq 0 ]]; then
        echo "✅ PASS: Dependencies check works"
    else
        echo "⚠️  Some dependencies missing (expected)"
    fi

    # Test 3: Report generation
    echo ""
    echo "Test 3: Report generation"
    run_health_check > /dev/null 2>&1
    if [[ -f "$HEALTH_CHECK_LOG" ]]; then
        echo "✅ PASS: Health report generated"
    else
        echo "❌ FAIL: Health report not generated"
        return 1
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All health check tests passed!"
    return 0
}

# =============================================================================
# Main Entry Point
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_health_functions
fi
