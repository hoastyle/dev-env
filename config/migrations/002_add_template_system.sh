#!/bin/bash
# =============================================================================
# Migration: 002_add_template_system
# =============================================================================
# Description: Add configuration template system
# Target Version: 2.2.0
# Created: 2026-01-31
# =============================================================================

# Migration version
MIGRATION_VERSION="2.2.0"

# Migration description
MIGRATION_DESCRIPTION="Add configuration template and preset system"

# =============================================================================
# Migration Functions
# =============================================================================

# Apply migration (upgrade)
migrate_up() {
    echo "Applying migration: 002_add_template_system"

    # Update version file
    local version_file="$HOME/.zshrc.version"
    if [[ -f "$version_file" ]]; then
        # Update VERSION field
        local temp_file=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" =~ ^VERSION= ]]; then
                echo 'VERSION="2.2.0"'
            else
                echo "$line"
            fi
        done < "$version_file" > "$temp_file"
        mv "$temp_file" "$version_file"
        echo "  ✅ Version updated to 2.2.0"
    fi

    # Create .zshrc.user template if it doesn't exist
    local user_config="$HOME/.zshrc.user"
    if [[ ! -f "$user_config" ]]; then
        cat > "$user_config" << 'EOF'
# =============================================================================
# User Custom Configuration
# =============================================================================
# This file is preserved during configuration updates
# Add your personal aliases, functions, and customizations here
# =============================================================================

# Personal aliases
# alias ll='ls -la'
# alias la='ls -A'

# Personal functions
# function myproject() { cd ~/projects/myproject; }

# Environment variables
# export MY_VAR=value

# =============================================================================
EOF
        echo "  ✅ User config template created"
    else
        echo "  ℹ️  User config already exists"
    fi

    # Create .zshrc.local template if it doesn't exist
    local local_config="$HOME/.zshrc.local"
    if [[ ! -f "$local_config" ]]; then
        cat > "$local_config" << 'EOF'
# =============================================================================
# Local Machine Configuration
# =============================================================================
# This file contains machine-specific settings
# It is NOT tracked by version control
# =============================================================================

# Local PATH additions
# export PATH="$HOME/.local/bin:$PATH"

# Local environment variables
# export EDITOR=vim

# Machine-specific settings
# if [[ "$(hostname)" == "workstation" ]]; then
#     # Workstation specific settings
# fi

# =============================================================================
EOF
        echo "  ✅ Local config template created"
    else
        echo "  ℹ️  Local config already exists"
    fi

    echo "  ✅ Migration 002_add_template_system completed"
    return 0
}

# Rollback migration (downgrade)
migrate_down() {
    echo "Rolling back migration: 002_add_template_system"

    # Revert version file
    local version_file="$HOME/.zshrc.version"
    if [[ -f "$version_file" ]]; then
        local temp_file=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" =~ ^VERSION= ]]; then
                echo 'VERSION="2.0.0"'
            else
                echo "$line"
            fi
        done < "$version_file" > "$temp_file"
        mv "$temp_file" "$version_file"
        echo "  ✅ Version reverted to 2.0.0"
    fi

    # Note: We don't remove user-created files (.zshrc.user, .zshrc.local)
    echo "  ℹ️  User config files preserved"

    echo "  ✅ Migration 002_add_template_system rolled back"
    return 0
}

# =============================================================================
# Self-test
# =============================================================================

# If run directly, execute self-test
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Testing migration: 002_add_template_system"

    # Set PROJECT_ROOT if not set
    PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"

    migrate_up
fi
