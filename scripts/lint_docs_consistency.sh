#!/usr/bin/env bash
# lint_docs_consistency.sh
# Validate critical documentation metadata and command consistency.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

declare -i ERROR_COUNT=0

pass() {
    echo "  [OK] $1"
}

fail() {
    echo "  [ERROR] $1" >&2
    ((ERROR_COUNT += 1))
}

check_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        pass "Found file: $file"
    else
        fail "Missing file: $file"
    fi
}

check_metadata_field() {
    local file="$1"
    local label="$2"
    local pattern="$3"
    local line

    line="$(grep -E "^\\*\\*${label}\\*\\*:" "$file" | head -n1 || true)"

    if [[ -z "$line" ]]; then
        fail "$file missing field: **${label}**"
        return
    fi

    if [[ ! "$line" =~ $pattern ]]; then
        fail "$file field format invalid: $line"
        return
    fi

    pass "$file field valid: **${label}**"
}

validate_launcher_subcommand() {
    local cmd="$1"
    case "$cmd" in
        help|normal|fast|minimal|benchmark|benchmark-all|enable-completion|switch-mode|restore|quick-restore|-h|--help)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

validate_tools_subcommand() {
    local cmd="$1"
    case "$cmd" in
        help|validate|backup|restore|update|clean|benchmark|benchmark-detailed|doctor|-h|--help)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

check_readme_command_paths() {
    local readme_file="README.md"
    local path
    local command_paths
    local line
    local cmd
    local had_launcher=0
    local had_tools=0

    mapfile -t command_paths < <(grep -oE '\./scripts/[[:alnum:]_.-]+\.sh' "$readme_file" | sort -u)
    if [[ ${#command_paths[@]} -eq 0 ]]; then
        fail "No ./scripts/*.sh commands found in README.md"
        return
    fi

    for path in "${command_paths[@]}"; do
        local rel_path="${path#./}"
        if [[ ! -f "$rel_path" ]]; then
            fail "README references missing script: $path"
            continue
        fi
        if [[ ! -x "$rel_path" ]]; then
            fail "README references non-executable script: $path"
            continue
        fi
        pass "README script path valid: $path"
    done

    while IFS= read -r line; do
        if [[ "$line" =~ \./scripts/zsh_launcher\.sh[[:space:]]+([[:alnum:]_-]+) ]]; then
            cmd="${BASH_REMATCH[1]}"
            had_launcher=1
            if ! validate_launcher_subcommand "$cmd"; then
                fail "README invalid zsh_launcher subcommand: $cmd"
            fi
        fi

        if [[ "$line" =~ \./scripts/zsh_tools\.sh[[:space:]]+([[:alnum:]_-]+) ]]; then
            cmd="${BASH_REMATCH[1]}"
            had_tools=1
            if ! validate_tools_subcommand "$cmd"; then
                fail "README invalid zsh_tools subcommand: $cmd"
            fi
        fi
    done < "$readme_file"

    if [[ "$had_launcher" -eq 1 ]]; then
        pass "README zsh_launcher subcommands validated"
    else
        fail "README does not contain zsh_launcher command examples"
    fi

    if [[ "$had_tools" -eq 1 ]]; then
        pass "README zsh_tools subcommands validated"
    else
        fail "README does not contain zsh_tools command examples"
    fi
}

check_test_entrypoints() {
    local readme_file="README.md"

    if grep -qE './run_tests\.sh[[:space:]]+quick' "$readme_file"; then
        pass "README contains quick test entrypoint"
    else
        fail "README missing quick test entrypoint: ./run_tests.sh quick"
    fi

    if grep -qE './run_tests\.sh[[:space:]]+full' "$readme_file"; then
        pass "README contains full test entrypoint"
    else
        fail "README missing full test entrypoint: ./run_tests.sh full"
    fi
}

main() {
    echo "Running documentation consistency checks..."

    # Critical docs must exist.
    check_file_exists "README.md"
    check_file_exists "docs/README.md"
    check_file_exists "docs/management/TASK.md"
    check_file_exists "docs/management/CONTEXT.md"
    check_file_exists "docs/management/KNOWLEDGE.md"
    check_file_exists "scripts/zsh_launcher.sh"
    check_file_exists "scripts/zsh_tools.sh"
    check_file_exists "tests/run_tests.sh"

    # Metadata format checks.
    check_metadata_field "README.md" "项目版本" '.+'
    check_metadata_field "README.md" "最后更新" '[0-9]{4}-[0-9]{2}-[0-9]{2}'
    check_metadata_field "docs/management/TASK.md" "版本" '.+'
    check_metadata_field "docs/management/TASK.md" "最后更新" '[0-9]{4}-[0-9]{2}-[0-9]{2}'
    check_metadata_field "docs/management/CONTEXT.md" "版本" '.+'
    check_metadata_field "docs/management/CONTEXT.md" "最后更新" '[0-9]{4}-[0-9]{2}-[0-9]{2}'

    # Command consistency checks.
    check_readme_command_paths
    check_test_entrypoints

    if [[ "$ERROR_COUNT" -gt 0 ]]; then
        echo "Documentation consistency checks failed: $ERROR_COUNT error(s)." >&2
        exit 1
    fi

    echo "Documentation consistency checks passed."
}

main "$@"
