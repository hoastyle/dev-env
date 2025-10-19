#!/usr/bin/env bash
# fixtures.sh - Test fixtures and test data management
# Provides test data, temporary environments, and setup/teardown utilities
# Version: 1.0
# Created: 2025-10-19

set -e

# ============================================================================
# Global Fixture State
# ============================================================================

declare -g FIXTURE_TEMP_DIR=""
declare -g FIXTURE_BACKUP_DIR=""
declare -a FIXTURE_CLEANUP_QUEUE=()

# ============================================================================
# Setup and Teardown
# ============================================================================

# Initialize test fixtures
setup_fixtures() {
    log_info "Setting up test fixtures..."

    # Create temporary directories
    FIXTURE_TEMP_DIR=$(mktemp -d) || {
        log_error "Failed to create temp directory"
        return 1
    }

    FIXTURE_BACKUP_DIR=$(mktemp -d) || {
        log_error "Failed to create backup directory"
        rm -rf "$FIXTURE_TEMP_DIR"
        return 1
    }

    log_success "Test fixtures initialized"
    log_debug "Temp dir: $FIXTURE_TEMP_DIR"
    log_debug "Backup dir: $FIXTURE_BACKUP_DIR"

    return 0
}

# Cleanup test fixtures
teardown_fixtures() {
    log_info "Tearing down test fixtures..."

    # Process cleanup queue in reverse order
    for ((i = ${#FIXTURE_CLEANUP_QUEUE[@]} - 1; i >= 0; i--)); do
        local cleanup_cmd="${FIXTURE_CLEANUP_QUEUE[i]}"
        eval "$cleanup_cmd" 2>/dev/null || log_warn "Cleanup failed: $cleanup_cmd"
    done

    # Remove temporary directories
    if [[ -d "$FIXTURE_TEMP_DIR" ]]; then
        rm -rf "$FIXTURE_TEMP_DIR" || log_warn "Failed to remove temp dir"
    fi

    if [[ -d "$FIXTURE_BACKUP_DIR" ]]; then
        rm -rf "$FIXTURE_BACKUP_DIR" || log_warn "Failed to remove backup dir"
    fi

    FIXTURE_CLEANUP_QUEUE=()
    log_success "Test fixtures cleaned up"

    return 0
}

# Register a cleanup function to run during teardown
register_cleanup() {
    local cleanup_cmd="$1"
    FIXTURE_CLEANUP_QUEUE+=("$cleanup_cmd")
}

# ============================================================================
# Test File Creation
# ============================================================================

# Create a test file with content
create_test_file() {
    local filename="$1"
    local content="$2"
    local location="${3:-$FIXTURE_TEMP_DIR}"

    local filepath="$location/$filename"
    local dir_path=$(dirname "$filepath")

    # Create parent directories if needed
    mkdir -p "$dir_path" || {
        log_error "Failed to create directory: $dir_path"
        return 1
    }

    # Write content to file
    echo "$content" > "$filepath" || {
        log_error "Failed to create file: $filepath"
        return 1
    }

    log_debug "Created test file: $filepath"
    echo "$filepath"
}

# Create a test directory structure
create_test_directory_structure() {
    local base_dir="${1:-$FIXTURE_TEMP_DIR}"
    local structure="$2"

    log_debug "Creating directory structure: $structure"

    # Parse and create directory structure
    # Expected format: "dir1:dir2:dir3" or "dir1/subdir1:dir2"
    local IFS=":"
    for dir in $structure; do
        mkdir -p "$base_dir/$dir" || {
            log_error "Failed to create directory: $base_dir/$dir"
            return 1
        }
    done

    return 0
}

# ============================================================================
# Environment Setup
# ============================================================================

# Create a mock environment
setup_mock_environment() {
    local env_name="$1"

    log_debug "Setting up mock environment: $env_name"

    case "$env_name" in
        "empty_home")
            export HOME="$FIXTURE_TEMP_DIR/home"
            mkdir -p "$HOME"
            export PATH="/usr/bin:/bin"
            ;;
        "with_zsh")
            export HOME="$FIXTURE_TEMP_DIR/home"
            mkdir -p "$HOME/.zsh/functions"
            export SHELL="/bin/zsh"
            ;;
        "docker_env")
            export DOCKER_HOST="unix:///var/run/docker.sock"
            export IS_DOCKER_ENV="1"
            ;;
        *)
            log_warn "Unknown environment type: $env_name"
            return 1
            ;;
    esac

    return 0
}

# Restore original environment
restore_original_environment() {
    # This should be done by the caller using trap or finally blocks
    log_debug "Environment restoration should be handled by caller"
    return 0
}

# ============================================================================
# Configuration File Fixtures
# ============================================================================

# Create a mock .zshrc file
create_mock_zshrc() {
    local target_dir="${1:-$FIXTURE_TEMP_DIR}"

    local content='#!/bin/zsh
# Mock .zshrc for testing

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Antigen initialization
source ~/.antigen/antigen.zsh

# Plugins
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

# Theme
antigen theme robbyrussell

# Apply
antigen apply

# Functions
if [[ -d ~/.zsh/functions ]]; then
    for func in ~/.zsh/functions/*.zsh; do
        source "$func"
    done
fi
'

    echo "$content" > "$target_dir/.zshrc" || {
        log_error "Failed to create mock .zshrc"
        return 1
    }

    log_debug "Created mock .zshrc at $target_dir/.zshrc"
    echo "$target_dir/.zshrc"
}

# Create a mock validation.zsh
create_mock_validation() {
    local target_dir="${1:-$FIXTURE_TEMP_DIR}"

    local content='#!/bin/zsh
# Mock validation.zsh for testing

error_msg() {
    echo "ERROR: $1" >&2
}

success_msg() {
    echo "SUCCESS: $1"
}

warn_msg() {
    echo "WARNING: $1"
}

info_msg() {
    echo "INFO: $1"
}
'

    echo "$content" > "$target_dir/validation.zsh" || {
        log_error "Failed to create mock validation.zsh"
        return 1
    }

    log_debug "Created mock validation.zsh at $target_dir/validation.zsh"
    echo "$target_dir/validation.zsh"
}

# ============================================================================
# Script Fixtures
# ============================================================================

# Create a mock install script
create_mock_install_script() {
    local target_dir="${1:-$FIXTURE_TEMP_DIR}"

    local content='#!/bin/bash
# Mock install_zsh_config.sh for testing

DRY_RUN=0
FORCE=0

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        --force) FORCE=1 ;;
    esac
    shift
done

if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: Would install ZSH configuration"
    exit 0
fi

echo "Installing ZSH configuration..."
exit 0
'

    echo "$content" > "$target_dir/install_zsh_config_mock.sh" || {
        log_error "Failed to create mock install script"
        return 1
    }

    chmod +x "$target_dir/install_zsh_config_mock.sh"
    log_debug "Created mock install script at $target_dir/install_zsh_config_mock.sh"
    echo "$target_dir/install_zsh_config_mock.sh"
}

# Create a mock dryrun library
create_mock_dryrun_lib() {
    local target_dir="${1:-$FIXTURE_TEMP_DIR}"

    local content='#!/bin/bash
# Mock lib_dryrun.sh for testing

DRY_RUN=${DRY_RUN:-0}

dry_mkdir() {
    local path="$1"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "DRY RUN: mkdir -p \"$path\""
        return 0
    fi
    mkdir -p "$path"
}

dry_cp() {
    local src="$1"
    local dst="$2"
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "DRY RUN: cp \"$src\" \"$dst\""
        return 0
    fi
    cp "$src" "$dst"
}

export DRY_RUN
export -f dry_mkdir dry_cp
'

    echo "$content" > "$target_dir/lib_dryrun_mock.sh" || {
        log_error "Failed to create mock dryrun library"
        return 1
    }

    log_debug "Created mock dryrun library at $target_dir/lib_dryrun_mock.sh"
    echo "$target_dir/lib_dryrun_mock.sh"
}

# ============================================================================
# Test Data Fixtures
# ============================================================================

# Create sample test data
create_sample_test_data() {
    local target_dir="${1:-$FIXTURE_TEMP_DIR}"

    # Create sample configuration
    create_test_file "config.sample.txt" "# Sample Configuration
key1=value1
key2=value2
key3=value3" "$target_dir"

    # Create sample log file
    create_test_file "sample.log" "[2025-10-19 10:00:00] INFO: Application started
[2025-10-19 10:00:01] INFO: Initialization complete
[2025-10-19 10:00:02] WARN: Low memory condition
[2025-10-19 10:00:03] ERROR: Connection failed" "$target_dir"

    # Create sample shell script
    create_test_file "sample_script.sh" "#!/bin/bash
# Sample test script

echo 'Hello, World!'
exit 0" "$target_dir"

    log_debug "Created sample test data in $target_dir"
    return 0
}

# ============================================================================
# Assertion Helpers for Fixtures
# ============================================================================

# Get the temp directory path
get_temp_dir() {
    echo "$FIXTURE_TEMP_DIR"
}

# Get the backup directory path
get_backup_dir() {
    echo "$FIXTURE_BACKUP_DIR"
}

# List files in fixture directory
list_fixture_files() {
    local dir="${1:-$FIXTURE_TEMP_DIR}"
    find "$dir" -type f 2>/dev/null || log_warn "Failed to list files in $dir"
}

# Dump file contents for debugging
dump_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "=== Contents of $file ==="
        cat "$file"
        echo "=== End of file ==="
    else
        log_warn "File not found: $file"
    fi
}

# ============================================================================
# Exports
# ============================================================================

export -f setup_fixtures teardown_fixtures register_cleanup
export -f create_test_file create_test_directory_structure
export -f setup_mock_environment restore_original_environment
export -f create_mock_zshrc create_mock_validation
export -f create_mock_install_script create_mock_dryrun_lib
export -f create_sample_test_data
export -f get_temp_dir get_backup_dir list_fixture_files dump_file
