#!/bin/bash
# =============================================================================
# ZSH Configuration Manager - Main CLI Tool
# =============================================================================
# Description: Configuration Lifecycle Management CLI
# Version: 1.0
# Created: 2026-01-31
# =============================================================================

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Source library dependencies
source "$PROJECT_ROOT/scripts/lib_version.sh"
source "$PROJECT_ROOT/scripts/lib_migration.sh"
source "$PROJECT_ROOT/scripts/lib_health.sh"
source "$PROJECT_ROOT/scripts/lib_backup.sh"

# =============================================================================
# CLI Functions
# =============================================================================

# Show help message
show_help() {
    cat << 'EOF'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                        ZSH Configuration Manager
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

A configuration lifecycle management system for ZSH.

USAGE:
    zsh_config_manager.sh <command> [options]

COMMANDS:
    version         Show current configuration version
    migrate         Run pending migrations
    health          Run health checks
    backup          Create a backup
    list-backups    List available backups
    restore         Restore from a backup
    rollback        Rollback a migration
    history         Show migration history
    validate        Validate configuration
    help            Show this help message

OPTIONS:
    --verbose, -v   Enable verbose output
    --quiet, -q     Suppress non-error output
    --force, -f     Skip confirmation prompts

EXAMPLES:
    zsh_config_manager.sh version
    zsh_config_manager.sh migrate
    zsh_config_manager.sh health
    zsh_config_manager.sh backup "Before upgrade"
    zsh_config_manager.sh restore config-20260131-103000
    zsh_config_manager.sh rollback 001_initial

For more information, see docs/design/README.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
}

# Command: version
cmd_version() {
    echo "📊 Configuration Version Information"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    generate_version_report
}

# Command: migrate
cmd_migrate() {
    echo "🔄 Configuration Migration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local current_version=$(get_current_version)
    echo "Current version: $current_version"
    echo ""

    run_migrations
}

# Command: health
cmd_health() {
    run_health_check
}

# Command: backup
cmd_backup() {
    local description="${1:-Manual backup}"

    echo "💾 Creating Configuration Backup"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    create_backup "$description"
}

# Command: list-backups
cmd_list_backups() {
    list_backups
}

# Command: restore
cmd_restore() {
    local backup_id="$1"

    if [[ -z "$backup_id" ]]; then
        echo "❌ Error: Backup ID required"
        echo ""
        echo "Usage: $0 restore <backup_id>"
        echo ""
        echo "Available backups:"
        list_backups
        return 1
    fi

    echo "🔄 Restoring Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    restore_backup "$backup_id"
}

# Command: rollback
cmd_rollback() {
    local migration_id="$1"

    if [[ -z "$migration_id" ]]; then
        echo "❌ Error: Migration ID required"
        echo ""
        echo "Usage: $0 rollback <migration_id>"
        echo ""
        echo "Recent migrations:"
        get_migration_history
        return 1
    fi

    echo "⏪ Rolling Back Migration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    rollback_migration "$migration_id"
}

# Command: history
cmd_history() {
    get_migration_history
}

# Command: validate
cmd_validate() {
    echo "✓ Validating Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local all_valid=0

    # Check syntax
    if check_syntax; then
        echo "  ✅ Syntax check passed"
    else
        echo "  ❌ Syntax check failed"
        ((all_valid++))
    fi

    # Check version file
    if check_version_file; then
        echo "  ✅ Version file valid"
    else
        echo "  ⚠️  Version file needs initialization"
        ((all_valid++))
    fi

    echo ""
    if [[ $all_valid -eq 0 ]]; then
        echo "✅ Configuration is valid"
        return 0
    else
        echo "⚠️  Configuration has issues"
        return 1
    fi
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
    local command="${1:-help}"
    shift || true

    case "$command" in
        "version")
            cmd_version
            ;;
        "migrate")
            cmd_migrate "$@"
            ;;
        "health")
            cmd_health
            ;;
        "backup")
            cmd_backup "$@"
            ;;
        "list-backups")
            cmd_list_backups
            ;;
        "restore")
            cmd_restore "$@"
            ;;
        "rollback")
            cmd_rollback "$@"
            ;;
        "history")
            cmd_history
            ;;
        "validate")
            cmd_validate
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo "❌ Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
