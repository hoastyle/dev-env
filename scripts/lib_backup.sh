#!/bin/bash
# =============================================================================
# Configuration Lifecycle Management - Backup and Recovery Library
# =============================================================================
# Description: Backup and restore ZSH configuration files
# Version: 1.0
# Created: 2026-01-31
# =============================================================================

# Script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"

# Backup directory
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backups}"

# Files to backup
BACKUP_FILES=(
    "$HOME/.zshrc"
    "$HOME/.zshrc.version"
    "$HOME/.zshrc.local"
    "$HOME/.zshrc.user"
    "$PROJECT_ROOT/config/.zshrc.version"
)

# Maximum backups to keep (default: 10)
MAX_BACKUPS="${MAX_BACKUPS:-10}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# =============================================================================
# Backup Functions
# =============================================================================

# Create a new backup
# Args:
#   $1 - Optional description for the backup
# Returns: 0 on success, 1 on failure
create_backup() {
    local description="${1:-Manual backup}"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_name="config-$timestamp"
    local backup_path="$BACKUP_DIR/$backup_name"

    echo "💾 Creating backup: $backup_name"

    # Create backup directory
    mkdir -p "$backup_path"

    local files_backed=0
    local manifest_file="$backup_path/manifest.txt"

    # Create manifest header
    cat > "$manifest_file" << EOF
# Configuration Backup Manifest
# Backup ID: $backup_name
# Created: $(date '+%Y-%m-%d %H:%M:%S')
# Description: $description
# Hostname: $(hostname)
# User: $USER
#

EOF

    # Backup each file
    for file in "${BACKUP_FILES[@]}"; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local dest="$backup_path/$filename"

            # Copy file
            cp "$file" "$dest"

            # Calculate hash
            local hash=$(sha256sum "$file" 2>/dev/null | awk '{print $1}')

            # Add to manifest
            echo "FILE|$filename|$file|$hash" >> "$manifest_file"

            ((files_backed++))
        fi
    done

    # Backup custom functions if they exist
    if [[ -d "$HOME/.zsh/functions" ]]; then
        cp -r "$HOME/.zsh/functions" "$backup_path/"
        echo "DIR|functions|$HOME/.zsh/functions" >> "$manifest_file"
        ((files_backed++))
    fi

    # Create metadata
    cat > "$backup_path/metadata.json" << EOF
{
  "backup_id": "$backup_name",
  "timestamp": "$(date -Iseconds)",
  "description": "$description",
  "hostname": "$(hostname)",
  "user": "$USER",
  "files_count": $files_backed,
  "version": "$(source "$PROJECT_ROOT/scripts/lib_version.sh" 2>/dev/null && get_current_version || echo "unknown")"
}
EOF

    echo "✅ Backup created: $backup_path ($files_backed files)"
    echo "$backup_path"
}

# List all available backups
list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "No backups found"
        return 1
    fi

    echo "📋 Available Backups"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local backups=($(ls -t "$BACKUP_DIR" 2>/dev/null))

    if [[ ${#backups[@]} -eq 0 ]]; then
        echo "No backups found in $BACKUP_DIR"
        return 1
    fi

    for backup in "${backups[@]}"; do
        local backup_path="$BACKUP_DIR/$backup"
        local metadata_file="$backup_path/metadata.json"

        if [[ -f "$metadata_file" ]]; then
            local timestamp=$(grep '"timestamp":' "$metadata_file" | cut -d'"' -f4)
            local description=$(grep '"description":' "$metadata_file" | cut -d'"' -f4)
            local version=$(grep '"version":' "$metadata_file" | grep -o '[0-9.]*' | head -1)

            printf "📦 %s\n" "$backup"
            printf "   Time: %s\n" "$timestamp"
            printf "   Version: %s\n" "$version"
            printf "   Description: %s\n" "$description"
        else
            printf "📦 %s (no metadata)\n" "$backup"
        fi
        echo ""
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    return 0
}

# Restore from a backup
# Args:
#   $1 - Backup ID (e.g., "config-20260131-103000")
# Returns: 0 on success, 1 on failure
restore_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"

    if [[ -z "$backup_id" ]]; then
        echo "❌ Usage: restore_backup <backup_id>" >&2
        return 1
    fi

    if [[ ! -d "$backup_path" ]]; then
        echo "❌ Backup not found: $backup_path" >&2
        return 1
    fi

    echo "🔄 Restoring from backup: $backup_id"

    # Create a safety backup of current state
    local safety_backup=$(create_backup "Pre-restore safety backup" 2>/dev/null)
    echo "  📦 Safety backup created: $safety_backup"

    # Restore files from backup
    local files_restored=0

    for backup_file in "$backup_path"/*; do
        [[ -f "$backup_file" ]] || continue
        local filename=$(basename "$backup_file")

        # Skip metadata files
        case "$filename" in
            manifest.txt|metadata.json) continue ;;
        esac

        # Determine restore destination
        local dest=""
        case "$filename" in
            .zshrc) dest="$HOME/.zshrc" ;;
            .zshrc.version) dest="$HOME/.zshrc.version" ;;
            .zshrc.local) dest="$HOME/.zshrc.local" ;;
            .zshrc.user) dest="$HOME/.zshrc.user" ;;
        esac

        if [[ -n "$dest" ]]; then
            cp "$backup_file" "$dest"
            echo "  ✅ Restored: $filename"
            ((files_restored++))
        fi
    done

    # Restore functions directory if present
    if [[ -d "$backup_path/functions" ]]; then
        cp -r "$backup_path/functions"/* "$HOME/.zsh/functions/" 2>/dev/null
        echo "  ✅ Restored: functions/"
        ((files_restored++))
    fi

    echo "✅ Backup restored: $files_restored files"
    return 0
}

# Delete a backup
# Args:
#   $1 - Backup ID
# Returns: 0 on success, 1 on failure
delete_backup() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"

    if [[ -z "$backup_id" ]]; then
        echo "❌ Usage: delete_backup <backup_id>" >&2
        return 1
    fi

    if [[ ! -d "$backup_path" ]]; then
        echo "❌ Backup not found: $backup_path" >&2
        return 1
    fi

    echo "🗑️  Deleting backup: $backup_id"

    rm -rf "$backup_path"

    if [[ ! -d "$backup_path" ]]; then
        echo "✅ Backup deleted"
        return 0
    else
        echo "❌ Failed to delete backup" >&2
        return 1
    fi
}

# Cleanup old backups
# Keeps the most recent N backups, deletes older ones
cleanup_old_backups() {
    local keep="${1:-$MAX_BACKUPS}"

    echo "🧹 Cleaning up old backups (keeping last $keep)..."

    local backups=($(ls -t "$BACKUP_DIR" 2>/dev/null))
    local total=${#backups[@]}

    if [[ $total -le $keep ]]; then
        echo "✅ No cleanup needed ($total backups, keeping $keep)"
        return 0
    fi

    local to_delete=$((total - keep))
    local deleted=0

    for ((i = keep; i < total; i++)); do
        local backup="${backups[$i]}"
        local backup_path="$BACKUP_DIR/$backup"

        rm -rf "$backup_path"
        ((deleted++))
    done

    echo "✅ Cleaned up $deleted old backup(s)"
}

# Get backup info
# Args:
#   $1 - Backup ID
get_backup_info() {
    local backup_id="$1"
    local backup_path="$BACKUP_DIR/$backup_id"

    if [[ ! -d "$backup_path" ]]; then
        echo "❌ Backup not found: $backup_id" >&2
        return 1
    fi

    local metadata_file="$backup_path/metadata.json"

    if [[ -f "$metadata_file" ]]; then
        cat "$metadata_file"
    else
        # Generate info from manifest
        echo "Backup: $backup_id"
        echo "Path: $backup_path"
        echo ""
        echo "Files:"
        cat "$backup_path/manifest.txt" 2>/dev/null || echo "No manifest found"
    fi
}

# =============================================================================
# Test Functions
# =============================================================================

test_backup_functions() {
    echo "🧪 Testing Backup Functions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local test_dir=$(mktemp -d)
    local test_backup_dir="$test_dir/backups"

    # Setup test environment
    BACKUP_DIR="$test_backup_dir"
    mkdir -p "$test_backup_dir"

    # Create test files
    local test_zshrc="$test_dir/.zshrc"
    echo "# Test ZSH config" > "$test_zshrc"
    export HOME="$test_dir"

    # Test 1: Create backup
    echo ""
    echo "Test 1: Create backup"
    local backup_path=$(create_backup "Test backup" 2>/dev/null | tail -n1)

    if [[ -d "$backup_path" ]]; then
        echo "✅ PASS: Backup created"
    else
        echo "❌ FAIL: Backup not created"
        rm -rf "$test_dir"
        return 1
    fi

    # Test 2: List backups
    echo ""
    echo "Test 2: List backups"
    local output=$(list_backups 2>&1)

    if [[ "$output" =~ "Test backup" ]]; then
        echo "✅ PASS: Backup listed"
    else
        echo "❌ FAIL: Backup not in list"
        rm -rf "$test_dir"
        return 1
    fi

    # Test 3: Get backup info
    echo ""
    echo "Test 3: Get backup info"
    local backup_id=$(basename "$backup_path")
    local info=$(get_backup_info "$backup_id")

    if [[ "$info" =~ "Test backup" ]]; then
        echo "✅ PASS: Backup info retrieved"
    else
        echo "❌ FAIL: Backup info not found"
        rm -rf "$test_dir"
        return 1
    fi

    # Test 4: Cleanup old backups
    echo ""
    echo "Test 4: Cleanup old backups"
    create_backup "Test backup 2" > /dev/null
    create_backup "Test backup 3" > /dev/null

    cleanup_old_backups 2 > /dev/null

    local remaining=$(ls "$test_backup_dir" 2>/dev/null | wc -l)
    if [[ $remaining -le 2 ]]; then
        echo "✅ PASS: Old backups cleaned up"
    else
        echo "❌ FAIL: Cleanup didn't work"
        rm -rf "$test_dir"
        return 1
    fi

    # Cleanup
    rm -rf "$test_dir"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All backup tests passed!"
    return 0
}

# =============================================================================
# Main Entry Point
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_backup_functions
fi
