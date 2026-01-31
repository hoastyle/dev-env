#!/bin/bash
# =============================================================================
# Migration: 001_initial
# =============================================================================
# Description: Initialize configuration lifecycle management
# Target Version: 2.0.0
# Created: 2026-01-31
# =============================================================================

# Migration version
MIGRATION_VERSION="2.0.0"

# Migration description
MIGRATION_DESCRIPTION="Initialize configuration lifecycle management"

# =============================================================================
# Migration Functions
# =============================================================================

# Apply migration (upgrade)
migrate_up() {
    echo "Applying migration: 001_initial"

    # Initialize version file if it doesn't exist
    local version_file="$HOME/.zshrc.version"

    if [[ ! -f "$version_file" ]]; then
        echo "  Creating initial version file..."

        # Use project version file as template
        local project_version="$PROJECT_ROOT/config/.zshrc.version"
        if [[ -f "$project_version" ]]; then
            cp "$project_version" "$version_file"
            echo "  ✅ Version file initialized from template"
        else
            cat > "$version_file" << 'EOF'
# ZSH Configuration Version File
VERSION="2.0.0"
BUILD_DATE="2026-01-31"
INSTALL_DATE=""
LAST_MIGRATION="001_initial"
USER_CUSTOMIZATIONS="false"
CUSTOM_CONFIG_HASH=""
EOF
            echo "  ✅ Version file created"
        fi
    else
        echo "  ℹ️  Version file already exists"
    fi

    # Create data directory structure
    local data_dir="$PROJECT_ROOT/data"
    mkdir -p "$data_dir"
    echo "  ✅ Data directory ensured"

    # Create migrations history log
    local history_file="$data_dir/migration_history.log"
    if [[ ! -f "$history_file" ]]; then
        cat > "$history_file" << 'EOF'
# Migration History Log
# Format: TIMESTAMP|MIGRATION_ID|FROM_VERSION|TO_VERSION|STATUS|DURATION

EOF
        echo "  ✅ Migration history initialized"
    fi

    echo "  ✅ Migration 001_initial completed"
    return 0
}

# Rollback migration (downgrade)
migrate_down() {
    echo "Rolling back migration: 001_initial"

    # Remove version file if it was created by this migration
    local version_file="$HOME/.zshrc.version"

    if [[ -f "$version_file" ]]; then
        # Check if we should remove it (only if it's at initial version)
        local version=$(grep "^VERSION=" "$version_file" | cut -d'"' -f2)
        if [[ "$version" == "2.0.0" ]]; then
            rm -f "$version_file"
            echo "  ✅ Version file removed"
        fi
    fi

    echo "  ✅ Migration 001_initial rolled back"
    return 0
}

# =============================================================================
# Self-test
# =============================================================================

# If run directly, execute self-test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Testing migration: 001_initial"

    # Set PROJECT_ROOT if not set
    PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

    migrate_up
fi
