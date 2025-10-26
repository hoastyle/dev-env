#!/bin/bash
# ===============================================
# Centralized Backup Management Library
# ===============================================
# Version: 1.0
# Purpose: Unified backup system for dev-env project
# ===============================================

# Global backup configuration
BACKUP_ROOT="${XDG_DATA_HOME:-$HOME}/.dev-env-backups"
BACKUP_INDEX="$HOME/.dev-env-backup-index"

# Color definitions (if not already defined)
if [[ -z "$RED" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    NC='\033[0m'
fi

# ===============================================
# Core Backup Functions
# ===============================================

# Create backup directory with category
# Usage: create_backup_dir <category>
# Returns: backup_dir path
create_backup_dir() {
    local category="$1"

    if [[ -z "$category" ]]; then
        echo "ERROR: category is required" >&2
        return 1
    fi

    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="$BACKUP_ROOT/$category/$timestamp"

    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Update backup index and create 'latest' symlink
# Usage: update_backup_index <category> <backup_dir>
update_backup_index() {
    local category="$1"
    local backup_dir="$2"

    if [[ -z "$category" ]] || [[ -z "$backup_dir" ]]; then
        echo "ERROR: category and backup_dir are required" >&2
        return 1
    fi

    # Create/update 'latest' symlink
    local latest_link="$BACKUP_ROOT/$category/latest"
    ln -sfn "$backup_dir" "$latest_link"

    # Update index file
    local index_entry="[$category]"
    local timestamp_entry="timestamp=$(date '+%Y-%m-%d %H:%M:%S')"
    local path_entry="path=$backup_dir"

    # Create index file if it doesn't exist
    touch "$BACKUP_INDEX"

    # Remove old entry for this category (if exists)
    sed -i.bak "/^\[$category\]/,/^$/d" "$BACKUP_INDEX" 2>/dev/null || true
    rm -f "${BACKUP_INDEX}.bak" 2>/dev/null || true

    # Append new entry
    {
        echo "$index_entry"
        echo "$timestamp_entry"
        echo "$path_entry"
        echo ""
    } >> "$BACKUP_INDEX"
}

# Get latest backup directory for category
# Usage: get_latest_backup <category>
# Returns: backup_dir path or empty string
get_latest_backup() {
    local category="$1"

    if [[ -z "$category" ]]; then
        echo "ERROR: category is required" >&2
        return 1
    fi

    local latest_link="$BACKUP_ROOT/$category/latest"

    if [[ -L "$latest_link" ]]; then
        readlink "$latest_link"
    else
        echo ""
    fi
}

# List all backups for a category
# Usage: list_category_backups <category>
list_category_backups() {
    local category="$1"

    if [[ -z "$category" ]]; then
        echo "ERROR: category is required" >&2
        return 1
    fi

    local category_dir="$BACKUP_ROOT/$category"

    if [[ ! -d "$category_dir" ]]; then
        return 0
    fi

    for backup in "$category_dir"/*; do
        if [[ -d "$backup" ]] && [[ "$(basename "$backup")" != "latest" ]]; then
            local backup_name=$(basename "$backup")
            local backup_size=$(du -sh "$backup" 2>/dev/null | cut -f1)
            echo "$backup_name ($backup_size)"
        fi
    done
}

# Clean old backups, keeping only last N
# Usage: clean_old_backups <category> <keep_count>
clean_old_backups() {
    local category="$1"
    local keep_count="${2:-5}"  # Default: keep last 5

    if [[ -z "$category" ]]; then
        echo "ERROR: category is required" >&2
        return 1
    fi

    local category_dir="$BACKUP_ROOT/$category"

    if [[ ! -d "$category_dir" ]]; then
        return 0
    fi

    # Get sorted list of backups (newest first)
    local -a backups
    while IFS= read -r backup; do
        backups+=("$backup")
    done < <(find "$category_dir" -maxdepth 1 -type d -name "20*" | sort -r)

    local total_count=${#backups[@]}

    if (( total_count <= keep_count )); then
        return 0
    fi

    # Remove old backups
    local removed_count=0
    for (( i=keep_count; i<total_count; i++ )); do
        local backup_dir="${backups[$i]}"
        echo -e "${YELLOW}Removing old backup:${NC} $(basename "$backup_dir")"
        rm -rf "$backup_dir"
        ((removed_count++))
    done

    echo -e "${GREEN}Removed $removed_count old backup(s) from category '$category'${NC}"
}

# Get total backup size for category
# Usage: get_backup_size <category>
get_backup_size() {
    local category="$1"

    if [[ -z "$category" ]]; then
        echo "ERROR: category is required" >&2
        return 1
    fi

    local category_dir="$BACKUP_ROOT/$category"

    if [[ ! -d "$category_dir" ]]; then
        echo "0B"
        return 0
    fi

    du -sh "$category_dir" 2>/dev/null | cut -f1
}

# ===============================================
# Backup Operations
# ===============================================

# Standard backup function for files
# Usage: backup_files <category> <file1> <file2> ...
backup_files() {
    local category="$1"
    shift

    if [[ -z "$category" ]]; then
        echo "ERROR: category is required" >&2
        return 1
    fi

    if [[ $# -eq 0 ]]; then
        echo "ERROR: at least one file is required" >&2
        return 1
    fi

    local backup_dir=$(create_backup_dir "$category")
    local backed_up_count=0

    for file_path in "$@"; do
        if [[ -f "$file_path" ]]; then
            cp "$file_path" "$backup_dir/"
            ((backed_up_count++))
        elif [[ -d "$file_path" ]]; then
            cp -r "$file_path" "$backup_dir/"
            ((backed_up_count++))
        fi
    done

    if (( backed_up_count > 0 )); then
        update_backup_index "$category" "$backup_dir"
        echo "$backup_dir"
    else
        rm -rf "$backup_dir"
        echo ""
    fi
}

# ===============================================
# Utility Functions
# ===============================================

# Check if backup system is initialized
is_backup_initialized() {
    [[ -d "$BACKUP_ROOT" ]]
}

# Initialize backup system
init_backup_system() {
    if ! is_backup_initialized; then
        mkdir -p "$BACKUP_ROOT"
        touch "$BACKUP_INDEX"
    fi
}

# Get all backup categories
get_backup_categories() {
    if [[ ! -d "$BACKUP_ROOT" ]]; then
        return 0
    fi

    for category_dir in "$BACKUP_ROOT"/*; do
        if [[ -d "$category_dir" ]]; then
            basename "$category_dir"
        fi
    done
}

# Display backup summary
show_backup_summary() {
    echo -e "${BLUE}=== Backup Summary ===${NC}"
    echo -e "Backup Root: ${CYAN}$BACKUP_ROOT${NC}"
    echo ""

    if [[ ! -d "$BACKUP_ROOT" ]]; then
        echo "No backups found."
        return 0
    fi

    for category in $(get_backup_categories); do
        local count=$(find "$BACKUP_ROOT/$category" -maxdepth 1 -type d -name "20*" 2>/dev/null | wc -l)
        local size=$(get_backup_size "$category")
        local latest=$(get_latest_backup "$category")

        echo -e "${GREEN}[$category]${NC}"
        echo "  Backups: $count"
        echo "  Total Size: $size"
        if [[ -n "$latest" ]]; then
            echo "  Latest: $(basename "$latest")"
        fi
        echo ""
    done
}

# ===============================================
# Migration Functions
# ===============================================

# Migrate old backups to new structure
# Usage: migrate_old_backups
migrate_old_backups() {
    echo -e "${BLUE}=== Migrating Old Backups ===${NC}"

    local migrated_count=0

    # Migrate install_zsh_config.sh backups
    for old_backup in "$HOME"/zsh-backup-*; do
        if [[ -d "$old_backup" ]]; then
            local timestamp=$(basename "$old_backup" | sed 's/zsh-backup-//')
            local new_location="$BACKUP_ROOT/install/$timestamp"

            mkdir -p "$(dirname "$new_location")"
            mv "$old_backup" "$new_location"

            echo -e "${GREEN}Migrated:${NC} $(basename "$old_backup") → install/$timestamp"
            ((migrated_count++))
        fi
    done

    # Migrate zsh_optimizer.sh backups
    for old_backup in "$HOME"/zsh-optimizer-backup-*; do
        if [[ -d "$old_backup" ]]; then
            local timestamp=$(basename "$old_backup" | sed 's/zsh-optimizer-backup-//')
            local new_location="$BACKUP_ROOT/optimizer/$timestamp"

            mkdir -p "$(dirname "$new_location")"
            mv "$old_backup" "$new_location"

            echo -e "${GREEN}Migrated:${NC} $(basename "$old_backup") → optimizer/$timestamp"
            ((migrated_count++))
        fi
    done

    # Migrate zsh_launcher.sh backups
    for old_backup in "$HOME"/zsh-launcher-backup-*; do
        if [[ -d "$old_backup" ]]; then
            local timestamp=$(basename "$old_backup" | sed 's/zsh-launcher-backup-//')
            local new_location="$BACKUP_ROOT/launcher/$timestamp"

            mkdir -p "$(dirname "$new_location")"
            mv "$old_backup" "$new_location"

            echo -e "${GREEN}Migrated:${NC} $(basename "$old_backup") → launcher/$timestamp"
            ((migrated_count++))
        fi
    done

    if (( migrated_count > 0 )); then
        echo ""
        echo -e "${GREEN}Successfully migrated $migrated_count backup(s)${NC}"

        # Update latest symlinks
        for category in install optimizer launcher tools; do
            local category_dir="$BACKUP_ROOT/$category"
            if [[ -d "$category_dir" ]]; then
                local latest_backup=$(find "$category_dir" -maxdepth 1 -type d -name "20*" | sort -r | head -1)
                if [[ -n "$latest_backup" ]]; then
                    update_backup_index "$category" "$latest_backup"
                fi
            fi
        done
    else
        echo "No old backups found to migrate."
    fi
}

# ===============================================
# Initialization
# ===============================================

# Auto-initialize on source
init_backup_system
