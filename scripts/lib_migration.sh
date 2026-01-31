#!/bin/bash
# =============================================================================
# Configuration Lifecycle Management - Migration Management Library
# =============================================================================
# Description: Manages configuration migration scripts and execution
# Version: 1.0
# Created: 2026-01-31
# =============================================================================

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Source dependencies
source "$PROJECT_ROOT/scripts/lib_version.sh"

# Migration directories
MIGRATIONS_DIR="${MIGRATIONS_DIR:-$PROJECT_ROOT/config/migrations}"
MIGRATION_HISTORY="${MIGRATION_HISTORY:-$PROJECT_ROOT/data/migration_history.log}"

# Ensure directories exist
mkdir -p "$MIGRATIONS_DIR"
mkdir -p "$(dirname "$MIGRATION_HISTORY")"

# =============================================================================
# Migration Management Functions
# =============================================================================

# Get list of pending migrations
# Returns: List of migration IDs that need to be executed
get_pending_migrations() {
    local current_version=$(get_current_version)
    local pending=()

    # Get all migration files
    for migration_file in "$MIGRATIONS_DIR"/*.sh; do
        [[ -f "$migration_file" ]] || continue

        local migration_id=$(basename "$migration_file" .sh)

        # Check if already executed
        if ! migration_was_executed "$migration_id"; then
            pending+=("$migration_id")
        fi
    done

    # Sort by migration ID
    IFS=$'\n' pending=($(sort -n <<<"${pending[*]}"))
    unset IFS

    echo "${pending[@]}"
}

# Check if a migration was already executed
# Args:
#   $1 - Migration ID (e.g., "001_initial")
# Returns: 0 if executed, 1 if not
migration_was_executed() {
    local migration_id="$1"

    if [[ ! -f "$MIGRATION_HISTORY" ]]; then
        return 1
    fi

    grep -q "|$migration_id|" "$MIGRATION_HISTORY"
    return $?
}

# Get migration version from migration ID
# Args:
#   $1 - Migration ID (e.g., "001_initial")
# Returns: Target version (e.g., "2.0.0")
get_migration_version() {
    local migration_id="$1"
    local migration_file="$MIGRATIONS_DIR/${migration_id}.sh"

    if [[ ! -f "$migration_file" ]]; then
        echo ""
        return 1
    fi

    # Extract MIGRATION_VERSION variable
    grep "^MIGRATION_VERSION=" "$migration_file" | cut -d'"' -f2
}

# Execute a single migration script
# Args:
#   $1 - Migration ID (e.g., "001_initial")
# Returns: 0 on success, 1 on failure
execute_migration() {
    local migration_id="$1"
    local migration_file="$MIGRATIONS_DIR/${migration_id}.sh"

    if [[ ! -f "$migration_file" ]]; then
        echo "❌ Migration file not found: $migration_file" >&2
        return 1
    fi

    echo "🔄 Executing migration: $migration_id"

    # Source the migration file
    source "$migration_file"

    # Check for required migration function
    if declare -f migrate_up > /dev/null; then
        local start_time=$(date +%s)

        # Execute migration
        if migrate_up; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))

            # Log successful migration
            log_migration "$migration_id" "SUCCESS" "$duration"
            update_last_migration "$migration_id"

            echo "✅ Migration $migration_id completed successfully (${duration}s)"
            return 0
        else
            log_migration "$migration_id" "FAILED" "0"
            echo "❌ Migration $migration_id failed" >&2
            return 1
        fi
    else
        echo "❌ Migration file missing migrate_up() function: $migration_file" >&2
        return 1
    fi
}

# Rollback a migration
# Args:
#   $1 - Migration ID (e.g., "001_initial")
# Returns: 0 on success, 1 on failure
rollback_migration() {
    local migration_id="$1"
    local migration_file="$MIGRATIONS_DIR/${migration_id}.sh"

    if [[ ! -f "$migration_file" ]]; then
        echo "❌ Migration file not found: $migration_file" >&2
        return 1
    fi

    echo "⏪ Rolling back migration: $migration_id"

    # Source the migration file
    source "$migration_file"

    # Check for rollback function
    if declare -f migrate_down > /dev/null; then
        if migrate_down; then
            # Remove from history
            local temp_file=$(mktemp)
            grep -v "|$migration_id|" "$MIGRATION_HISTORY" > "$temp_file" 2>/dev/null || true
            mv "$temp_file" "$MIGRATION_HISTORY"

            echo "✅ Migration $migration_id rolled back successfully"
            return 0
        else
            echo "❌ Migration rollback $migration_id failed" >&2
            return 1
        fi
    else
        echo "❌ Migration does not support rollback: $migration_id" >&2
        return 1
    fi
}

# Run all pending migrations
# Returns: 0 if all successful, 1 if any failed
run_migrations() {
    local pending=($(get_pending_migrations))

    if [[ ${#pending[@]} -eq 0 ]]; then
        echo "✅ No pending migrations"
        return 0
    fi

    echo "🚀 Running ${#pending[@]} pending migration(s)..."
    echo ""

    local failed=0

    for migration_id in "${pending[@]}"; do
        if ! execute_migration "$migration_id"; then
            ((failed++))
        fi
        echo ""
    done

    if [[ $failed -eq 0 ]]; then
        echo "✅ All migrations completed successfully"
        return 0
    else
        echo "⚠️  $failed migration(s) failed" >&2
        return 1
    fi
}

# Log migration execution
# Args:
#   $1 - Migration ID
#   $2 - Status (SUCCESS/FAILED)
#   $3 - Duration in seconds
log_migration() {
    local migration_id="$1"
    local status="$2"
    local duration="${3:-0}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local from_version=$(get_current_version)
    local to_version=$(get_migration_version "$migration_id")

    # Create history file if not exists
    if [[ ! -f "$MIGRATION_HISTORY" ]]; then
        echo "# Migration History Log" > "$MIGRATION_HISTORY"
        echo "# Format: TIMESTAMP|MIGRATION_ID|FROM_VERSION|TO_VERSION|STATUS|DURATION" >> "$MIGRATION_HISTORY"
        echo "" >> "$MIGRATION_HISTORY"
    fi

    echo "$timestamp|$migration_id|$from_version|$to_version|$status|${duration}s" >> "$MIGRATION_HISTORY"
}

# Get migration history
# Returns: Formatted migration history
get_migration_history() {
    if [[ ! -f "$MIGRATION_HISTORY" ]]; then
        echo "No migration history found"
        return 0
    fi

    echo "📋 Migration History"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Skip header and empty lines
    grep -v '^#' "$MIGRATION_HISTORY" | grep -v '^$' | while IFS='|' read -r timestamp migration_id from_version to_version status duration; do
        local status_icon=""
        case "$status" in
            "SUCCESS") status_icon="✅" ;;
            "FAILED") status_icon="❌" ;;
            *) status_icon="⚠️ " ;;
        esac

        printf "%s %s | %s -> %s | %s | %s\n" "$status_icon" "$migration_id" "$from_version" "$to_version" "$timestamp" "$duration"
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Create a new migration file
# Args:
#   $1 - Migration ID (e.g., "003_new_feature")
#   $2 - Target version (e.g., "2.3.0")
#   $3 - Description (e.g., "Add new feature X")
create_migration() {
    local migration_id="$1"
    local target_version="$2"
    local description="$3"
    local migration_file="$MIGRATIONS_DIR/${migration_id}.sh"

    if [[ -z "$migration_id" || -z "$target_version" ]]; then
        echo "❌ Usage: create_migration <id> <version> [description]" >&2
        return 1
    fi

    if [[ -f "$migration_file" ]]; then
        echo "❌ Migration already exists: $migration_file" >&2
        return 1
    fi

    cat > "$migration_file" << EOF
#!/bin/bash
# =============================================================================
# Migration: $migration_id
# =============================================================================
# Description: ${description:-"No description"}
# Target Version: $target_version
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# =============================================================================

# Migration version
MIGRATION_VERSION="$target_version"

# Migration description
MIGRATION_DESCRIPTION="${description:-"No description"}"

# =============================================================================
# Migration Functions
# =============================================================================

# Apply migration (upgrade)
migrate_up() {
    echo "Applying migration: $migration_id"

    # TODO: Add migration logic here

    return 0
}

# Rollback migration (downgrade)
migrate_down() {
    echo "Rolling back migration: $migration_id"

    # TODO: Add rollback logic here

    return 0
}

# =============================================================================
# Self-test (optional)
# =============================================================================

# If run directly, execute self-test
if [[ "\${BASH_SOURCE[0]}" == "\${0}" ]]; then
    echo "Testing migration: $migration_id"
    migrate_up
fi
EOF

    chmod +x "$migration_file"
    echo "✅ Migration created: $migration_file"
    return 0
}

# =============================================================================
# Test Functions
# =============================================================================

test_migration_functions() {
    echo "🧪 Testing Migration Management Functions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local test_dir=$(mktemp -d)
    local test_migrations_dir="$test_dir/migrations"
    local test_history="$test_dir/migration_history.log"

    # Override paths for testing
    MIGRATIONS_DIR="$test_migrations_dir"
    MIGRATION_HISTORY="$test_history"

    mkdir -p "$test_migrations_dir"

    # Test 1: Create migration
    echo ""
    echo "Test 1: Create migration"
    create_migration "001_test" "2.0.0" "Test migration" > /dev/null
    if [[ -f "$test_migrations_dir/001_test.sh" ]]; then
        echo "✅ PASS: Migration file created"
    else
        echo "❌ FAIL: Migration file not created"
        return 1
    fi

    # Test 2: Get pending migrations
    echo ""
    echo "Test 2: Get pending migrations"
    local pending=$(get_pending_migrations)
    if [[ "$pending" =~ "001_test" ]]; then
        echo "✅ PASS: Pending migration detected"
    else
        echo "❌ FAIL: Pending migration not detected"
        return 1
    fi

    # Test 3: Check migration executed status
    echo ""
    echo "Test 3: Migration executed status"
    if ! migration_was_executed "001_test"; then
        echo "✅ PASS: Migration not yet executed"
    else
        echo "❌ FAIL: Migration should not be executed yet"
        return 1
    fi

    # Test 4: Migration history
    echo ""
    echo "Test 4: Migration history"
    log_migration "001_test" "SUCCESS" "1" > /dev/null
    if [[ -f "$test_history" ]]; then
        echo "✅ PASS: Migration logged"
    else
        echo "❌ FAIL: Migration not logged"
        return 1
    fi

    # Cleanup
    rm -rf "$test_dir"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All migration tests passed!"
    return 0
}

# =============================================================================
# Main Entry Point
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_migration_functions
fi
