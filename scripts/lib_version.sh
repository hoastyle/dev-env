#!/bin/bash
# =============================================================================
# Configuration Lifecycle Management - Version Management Library
# =============================================================================
# Description: Manages configuration version tracking, comparison, and reporting
# Version: 1.0
# Created: 2026-01-31
# =============================================================================

# Version file path (can be overridden for testing)
VERSION_FILE="${VERSION_FILE:-$HOME/.zshrc.version}"

# Project root detection
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Default version file in project config
DEFAULT_VERSION_FILE="$PROJECT_ROOT/config/.zshrc.version"

# Use default if home version doesn't exist
if [[ ! -f "$VERSION_FILE" && -f "$DEFAULT_VERSION_FILE" ]]; then
    VERSION_FILE="$DEFAULT_VERSION_FILE"
fi

# =============================================================================
# Version Management Functions
# =============================================================================

# Get current configuration version
# Returns: Version string (e.g., "2.2.0") or "0.0.0" if not found
get_current_version() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "0.0.0"
        return 1
    fi

    local version=$(grep "^VERSION=" "$VERSION_FILE" 2>/dev/null | cut -d'"' -f2)
    if [[ -z "$version" ]]; then
        echo "0.0.0"
        return 1
    fi

    echo "$version"
    return 0
}

# Set configuration version
# Args:
#   $1 - New version string (e.g., "2.2.0")
#   $2 - Optional build date (defaults to today)
set_version() {
    local new_version="$1"
    local build_date="${2:-$(date +%Y-%m-%d)}"

    if [[ -z "$new_version" ]]; then
        echo "Error: Version cannot be empty" >&2
        return 1
    fi

    # Validate version format (MAJOR.MINOR.PATCH)
    if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format '$new_version'. Expected MAJOR.MINOR.PATCH" >&2
        return 1
    fi

    # Read existing values to preserve them
    local install_date=""
    local last_migration=""
    local user_customizations="false"
    local custom_config_hash=""

    if [[ -f "$VERSION_FILE" ]]; then
        install_date=$(grep "^INSTALL_DATE=" "$VERSION_FILE" 2>/dev/null | cut -d'"' -f2)
        last_migration=$(grep "^LAST_MIGRATION=" "$VERSION_FILE" 2>/dev/null | cut -d'"' -f2)
        user_customizations=$(grep "^USER_CUSTOMIZATIONS=" "$VERSION_FILE" 2>/dev/null | cut -d'"' -f2)
        custom_config_hash=$(grep "^CUSTOM_CONFIG_HASH=" "$VERSION_FILE" 2>/dev/null | cut -d'"' -f2)
    fi

    # Set install date if not set
    if [[ -z "$install_date" || "$install_date" == '""' ]]; then
        install_date="$(date '+%Y-%m-%d %H:%M:%S')"
    fi

    # Create or update version file
    cat > "$VERSION_FILE" << EOF
# ZSH Configuration Version File
# Auto-generated - DO NOT EDIT MANUALLY
# This file tracks the configuration version and metadata

VERSION="$new_version"
BUILD_DATE="$build_date"
INSTALL_DATE="$install_date"
LAST_MIGRATION="$last_migration"
USER_CUSTOMIZATIONS="$user_customizations"
CUSTOM_CONFIG_HASH="$custom_config_hash"
EOF

    echo "✅ Version set to: $new_version"
    return 0
}

# Compare two version strings
# Args:
#   $1 - First version (e.g., "2.2.0")
#   $2 - Second version (e.g., "2.1.0")
# Returns: 0 if $1 >= $2, 1 if $1 < $2
compare_versions() {
    local version1="$1"
    local version2="$2"

    # Use sort -V for version comparison
    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version2" ]]; then
        return 0  # version1 >= version2
    else
        return 1  # version1 < version2
    fi
}

# Check if migration is needed
# Args:
#   $1 - Target version (e.g., "2.3.0")
# Returns: 0 if migration needed, 1 if already at or above target
needs_migration() {
    local target_version="$1"
    local current_version=$(get_current_version)

    echo "Checking migration: $current_version -> $target_version"

    if ! compare_versions "$current_version" "$target_version"; then
        echo "⚠️  Migration needed: $current_version -> $target_version"
        return 0
    else
        echo "✅ Current version $current_version is already at or above $target_version"
        return 1
    fi
}

# Generate version report
# Displays all version information in a formatted way
generate_version_report() {
    echo "📊 Configuration Version Report"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "❌ Version file not found: $VERSION_FILE"
        echo "   Run 'set_version X.Y.Z' to initialize"
        return 1
    fi

    # Display current version
    local version=$(get_current_version)
    echo "Current Version: $version"

    # Display all fields
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue

        # Remove quotes and format display
        value=$(echo "$value" | tr -d '"')
        local display_key=$(echo "$key" | sed 's/_/ /g' | tr '[:upper:]' '[:lower:]' | sed 's/\b\(.\)/\u\1/g')

        # Skip VERSION (already displayed)
        [[ "$key" == "VERSION" ]] && continue

        printf "  %-25s: %s\n" "$display_key" "$value"
    done < "$VERSION_FILE"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Version File: $VERSION_FILE"

    return 0
}

# Get version file path
# Returns: Path to the version file
get_version_file_path() {
    echo "$VERSION_FILE"
}

# Update last migration record
# Args:
#   $1 - Migration ID (e.g., "001_initial")
update_last_migration() {
    local migration_id="$1"

    if [[ -z "$migration_id" ]]; then
        echo "Error: Migration ID cannot be empty" >&2
        return 1
    fi

    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "Error: Version file not found" >&2
        return 1
    fi

    # Update LAST_MIGRATION field
    local temp_file=$(mktemp)
    while IFS= read -r line; do
        if [[ "$line" =~ ^LAST_MIGRATION= ]]; then
            echo "LAST_MIGRATION=\"$migration_id\""
        else
            echo "$line"
        fi
    done < "$VERSION_FILE" > "$temp_file"

    mv "$temp_file" "$VERSION_FILE"
    echo "✅ Last migration updated: $migration_id"
    return 0
}

# Mark user customizations as present
mark_user_customizations() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "Error: Version file not found" >&2
        return 1
    fi

    local temp_file=$(mktemp)
    local hash=""

    # Calculate hash of .zshrc.user if it exists
    if [[ -f "$HOME/.zshrc.user" ]]; then
        hash=$(sha256sum "$HOME/.zshrc.user" 2>/dev/null | awk '{print $1}')
    fi

    while IFS= read -r line; do
        if [[ "$line" =~ ^USER_CUSTOMIZATIONS= ]]; then
            echo "USER_CUSTOMIZATIONS=\"true\""
        elif [[ "$line" =~ ^CUSTOM_CONFIG_HASH= ]]; then
            echo "CUSTOM_CONFIG_HASH=\"$hash\""
        else
            echo "$line"
        fi
    done < "$VERSION_FILE" > "$temp_file"

    mv "$temp_file" "$VERSION_FILE"
    echo "✅ User customizations marked"
    return 0
}

# Get version info as JSON (for integration with other tools)
# Returns: JSON string with version information
get_version_json() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo '{"error":"Version file not found"}'
        return 1
    fi

    local version=$(get_current_version)
    local build_date=$(grep "^BUILD_DATE=" "$VERSION_FILE" | cut -d'"' -f2)
    local install_date=$(grep "^INSTALL_DATE=" "$VERSION_FILE" | cut -d'"' -f2)
    local last_migration=$(grep "^LAST_MIGRATION=" "$VERSION_FILE" | cut -d'"' -f2)
    local user_custom=$(grep "^USER_CUSTOMIZATIONS=" "$VERSION_FILE" | cut -d'"' -f2)

    cat << EOF
{
  "version": "$version",
  "build_date": "$build_date",
  "install_date": "$install_date",
  "last_migration": "$last_migration",
  "user_customizations": $user_custom,
  "version_file": "$VERSION_FILE"
}
EOF
}

# =============================================================================
# Test Functions
# =============================================================================

# Run version management tests
test_version_functions() {
    echo "🧪 Testing Version Management Functions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local test_dir=$(mktemp -d)
    local test_version_file="$test_dir/.zshrc.version"

    # Test 1: Create new version file
    echo ""
    echo "Test 1: Create new version file"
    VERSION_FILE="$test_version_file" set_version "2.2.0" "2026-01-31"
    if [[ -f "$test_version_file" ]]; then
        echo "✅ PASS: Version file created"
    else
        echo "❌ FAIL: Version file not created"
        return 1
    fi

    # Test 2: Read version
    echo ""
    echo "Test 2: Read current version"
    local version=$(VERSION_FILE="$test_version_file" get_current_version)
    if [[ "$version" == "2.2.0" ]]; then
        echo "✅ PASS: Version read correctly: $version"
    else
        echo "❌ FAIL: Expected 2.2.0, got: $version"
        return 1
    fi

    # Test 3: Compare versions
    echo ""
    echo "Test 3: Compare versions"
    if compare_versions "2.2.0" "2.1.0"; then
        echo "✅ PASS: 2.2.0 >= 2.1.0"
    else
        echo "❌ FAIL: Version comparison failed"
        return 1
    fi

    if ! compare_versions "2.0.0" "2.1.0"; then
        echo "✅ PASS: 2.0.0 < 2.1.0"
    else
        echo "❌ FAIL: Version comparison failed"
        return 1
    fi

    # Test 4: Migration check
    echo ""
    echo "Test 4: Migration needed check"
    if VERSION_FILE="$test_version_file" needs_migration "2.3.0"; then
        echo "✅ PASS: Migration needed detected"
    else
        echo "❌ FAIL: Migration check failed"
        return 1
    fi

    # Test 5: Update last migration
    echo ""
    echo "Test 5: Update last migration"
    VERSION_FILE="$test_version_file" update_last_migration "001_initial"
    local last_migration=$(grep "^LAST_MIGRATION=" "$test_version_file" | cut -d'"' -f2)
    if [[ "$last_migration" == "001_initial" ]]; then
        echo "✅ PASS: Last migration updated"
    else
        echo "❌ FAIL: Last migration not updated: $last_migration"
        return 1
    fi

    # Cleanup
    rm -rf "$test_dir"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All version management tests passed!"
    return 0
}

# =============================================================================
# Main Entry Point
# =============================================================================

# If run directly, execute tests
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_version_functions
fi
