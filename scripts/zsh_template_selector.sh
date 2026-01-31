#!/bin/bash
# =============================================================================
# ZSH Template Selector
# =============================================================================
# Description: Interactive template selection and application tool
# Version: 1.0
# =============================================================================

set -e

# =============================================================================
# Script Directory
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$PROJECT_ROOT/templates"

# =============================================================================
# Load Libraries
# =============================================================================

# Load logging library if available
if [[ -f "$SCRIPT_DIR/lib_logging.sh" ]]; then
    source "$SCRIPT_DIR/lib_logging.sh"
    init_logging 2>/dev/null || true
else
    # Basic logging fallback
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*"; }
    log_error() { echo "[ERROR] $*"; }
fi

# Load platform compatibility library if available
if [[ -f "$SCRIPT_DIR/lib_platform_compat.sh" ]]; then
    source "$SCRIPT_DIR/lib_platform_compat.sh"
fi

# =============================================================================
# Template Information
# =============================================================================

# Template metadata
declare -A TEMPLATE_NAMES=(
    ["dev-full"]="Full Development Environment"
    ["dev-minimal"]="Minimal Development Environment"
    ["server"]="Server/Production Environment"
    ["docker"]="Docker Container Environment"
)

declare -A TEMPLATE_DESCRIPTIONS=(
    ["dev-full"]="Complete development environment with all features enabled (~1.5s startup)"
    ["dev-minimal"]="Lightweight development environment with essential features (~50-100ms startup)"
    ["server"]="Production server environment with stability and security focus (~20-50ms startup)"
    ["docker"]="Docker container optimized with minimal overhead (~5-20ms startup)"
)

declare -A TEMPLATE_CATEGORIES=(
    ["dev-full"]="development"
    ["dev-minimal"]="development"
    ["server"]="server"
    ["docker"]="docker"
)

declare -A TEMPLATE_STARTUP_TIMES=(
    ["dev-full"]="~1.5s"
    ["dev-minimal"]="~50-100ms"
    ["server"]="~20-50ms"
    ["docker"]="~5-20ms"
)

# =============================================================================
# Helper Functions
# =============================================================================

# Get all available templates
get_templates() {
    local templates=()

    # Add built-in templates
    for template in "${!TEMPLATE_NAMES[@]}"; do
        templates+=("$template")
    done

    # Add custom templates
    if [[ -d "$TEMPLATES_DIR/custom" ]]; then
        while IFS= read -r -d '' file; do
            local basename=$(basename "$file" .zshrc)
            templates+=("custom:$basename")
        done < <(find "$TEMPLATES_DIR/custom" -name "*.zshrc" -print0 2>/dev/null)
    fi

    printf '%s\n' "${templates[@]}"
}

# Get template file path
get_template_path() {
    local template="$1"

    if [[ "$template" == custom:* ]]; then
        local basename="${template#custom:}"
        echo "$TEMPLATES_DIR/custom/${basename}.zshrc"
    else
        case "$template" in
            "dev-full")
                echo "$TEMPLATES_DIR/dev/dev-full.zshrc"
                ;;
            "dev-minimal")
                echo "$TEMPLATES_DIR/dev/dev-minimal.zshrc"
                ;;
            "server")
                echo "$TEMPLATES_DIR/server/server.zshrc"
                ;;
            "docker")
                echo "$TEMPLATES_DIR/docker/docker.zshrc"
                ;;
            *)
                echo ""
                ;;
        esac
    fi
}

# Get template name (for display)
get_template_display_name() {
    local template="$1"

    if [[ "$template" == custom:* ]]; then
        local basename="${template#custom:}"
        echo "Custom: $basename"
    else
        echo "${TEMPLATE_NAMES[$template]:-$template}"
    fi
}

# Get template description
get_template_description() {
    local template="$1"

    if [[ "$template" == custom:* ]]; then
        echo "(Custom template)"
    else
        echo "${TEMPLATE_DESCRIPTIONS[$template]:-No description available}"
    fi
}

# Check if template exists
template_exists() {
    local template="$1"
    local path=$(get_template_path "$template")
    [[ -n "$path" && -f "$path" ]]
}

# =============================================================================
# Interactive Template Selection
# =============================================================================

# Display template menu
show_template_menu() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           ZSH Configuration Template Selector                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Available Templates:"
    echo ""

    local index=1
    local templates=($(get_templates))

    for template in "${templates[@]}"; do
        local name=$(get_template_display_name "$template")
        local desc=$(get_template_description "$template")
        local startup_time="${TEMPLATE_STARTUP_TIMES[$template]:-Unknown}"

        printf "  [%d] %s\n" "$index" "$name"
        printf "      %s\n" "$desc"
        printf "      Startup: %s\n" "$startup_time"
        echo ""

        ((index++))
    done

    echo "  [q] Quit"
    echo ""
}

# Interactive selection
select_template_interactive() {
    local templates=($(get_templates))

    while true; do
        show_template_menu
        read -r "choice?Select a template (1-${#templates[@]} or q): " choice

        case "$choice" in
            q|Q|quit)
                log_info "Template selection cancelled"
                return 1
                ;;
            [0-9]*)
                local index=$((choice - 1))
                if [[ $index -ge 0 && $index -lt ${#templates[@]} ]]; then
                    echo "${templates[$index]}"
                    return 0
                else
                    log_error "Invalid selection. Please try again."
                fi
                ;;
            *)
                log_error "Invalid input. Please enter a number or 'q' to quit."
                ;;
        esac
    done
}

# =============================================================================
# Template Application
# =============================================================================

# Backup existing configuration
backup_config() {
    local backup_dir="$HOME/zsh-template-backup-$(date +%Y%m%d-%H%M%S)"

    if [[ -f "$HOME/.zshrc" ]]; then
        mkdir -p "$backup_dir"
        cp "$HOME/.zshrc" "$backup_dir/.zshrc"
        echo "$backup_dir" > "$HOME/.zsh_template_last_backup"
        log_info "Backed up current .zshrc to: $backup_dir"
        echo "$backup_dir"
    else
        log_info "No existing .zshrc to backup"
        echo ""
    fi
}

# Apply template
apply_template() {
    local template="$1"
    local backup_location="$2"

    local template_path=$(get_template_path "$template")

    if [[ ! -f "$template_path" ]]; then
        log_error "Template not found: $template"
        return 1
    fi

    log_info "Applying template: $template"

    # Copy template to .zshrc
    cp "$template_path" "$HOME/.zshrc"

    # Add template marker comment
    local marker="# Generated from template: $template"
    if ! grep -q "Generated from template" "$HOME/.zshrc" 2>/dev/null; then
        sed -i "1i $marker" "$HOME/.zshrc" 2>/dev/null || \
            (echo "$marker" | cat - "$HOME/.zshrc" > "$HOME/.zshrc.tmp" && mv "$HOME/.zshrc.tmp" "$HOME/.zshrc")
    fi

    log_success "Template applied successfully!"
    echo ""
    echo "Configuration files:"
    echo "  Template:  $template_path"
    echo "  Installed: $HOME/.zshrc"

    if [[ -n "$backup_location" ]]; then
        echo "  Backup:    $backup_location"
    fi

    echo ""
    log_info "Run 'exec zsh' or 'source ~/.zshrc' to apply the new configuration"
}

# =============================================================================
# Template Preview
# =============================================================================

preview_template() {
    local template="$1"
    local template_path=$(get_template_path "$template")

    if [[ ! -f "$template_path" ]]; then
        log_error "Template not found: $template"
        return 1
    fi

    local name=$(get_template_display_name "$template")
    local desc=$(get_template_description "$template")

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Template: $name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$desc"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    head -50 "$template_path"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "(Showing first 50 lines. Full template has $(wc -l < "$template_path") lines)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# =============================================================================
# Template Comparison
# =============================================================================

compare_templates() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║              Template Comparison Matrix                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "┌─────────────────────┬──────────┬──────────┬─────────────┬─────────┐"
    echo "│ Template            │ Startup  │ Features │ Use Case    │ Memory  │"
    echo "├─────────────────────┼──────────┼──────────┼─────────────┼─────────┤"

    printf "│ %-19s │ %-8s │ %-8s │ %-11s │ %-7s │\n" \
        "dev-full" "~1.5s" "Full" "Daily Dev" "~35MB"

    printf "│ %-19s │ %-8s │ %-8s │ %-11s │ %-7s │\n" \
        "dev-minimal" "~100ms" "Essential" "Quick Tasks" "~20MB"

    printf "│ %-19s │ %-8s │ %-8s │ %-11s │ %-7s │\n" \
        "server" "~50ms" "Minimal" "Production" "~15MB"

    printf "│ %-19s │ %-8s │ %-8s │ %-11s │ %-7s │\n" \
        "docker" "~20ms" "None" "Containers" "~10MB"

    echo "└─────────────────────┴──────────┴──────────┴─────────────┴─────────┘"
    echo ""

    echo "Feature Comparison:"
    echo ""
    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "Feature" "dev-full" "dev-minimal" "server" "docker"
    printf "%-15s-+-%-10s-+-%-10s-+-%-10s-+-%-10s\n" \
        "---------------" "----------" "----------" "----------" "----------"

    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "Powerlevel10k" "✓" "✗" "✗" "✗"

    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "Completion" "✓" "Lazy" "Basic" "✗"

    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "FZF" "✓" "Lazy" "✗" "✗"

    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "Autojump" "✓" "Lazy" "✗" "✗"

    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "Python Env" "✓" "Lazy" "✗" "✗"

    printf "%-15s | %-10s | %-10s | %-10s | %-10s\n" \
        "Custom Funcs" "✓" "✓" "✓" "Optional"

    echo ""
}

# =============================================================================
# Template Benchmarking
# =============================================================================

benchmark_templates() {
    log_info "Benchmarking template startup times..."
    echo ""

    local templates=("dev-minimal" "server" "docker" "dev-full")
    declare -A results

    for template in "${templates[@]}"; do
        local template_path=$(get_template_path "$template")

        if [[ ! -f "$template_path" ]]; then
            log_warn "Template not found: $template"
            continue
        fi

        # Measure startup time (3 iterations)
        local total_time=0
        local iterations=3

        for ((i=1; i<=iterations; i++)); do
            local start_time end_time
            if command -v python &>/dev/null; then
                start_time=$(python -c 'import time; print(int(time.time()*1000))' 2>/dev/null)
                zsh -c "source $template_path && exit" 2>/dev/null || true
                end_time=$(python -c 'import time; print(int(time.time()*1000))' 2>/dev/null)
            else
                start_time=$(date +%s)000
                zsh -c "source $template_path && exit" 2>/dev/null || true
                end_time=$(date +%s)000
            fi

            total_time=$((total_time + end_time - start_time))
        done

        local avg_time=$((total_time / iterations))
        results["$template"]=$avg_time
    done

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Template Startup Time Benchmark (Average of $iterations runs)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    for template in "${templates[@]}"; do
        local time=${results[$template]:-0}
        printf "  %-20s %5d ms\n" "$template:" "$time"
    done

    echo ""
    echo "Note: Actual startup times may vary based on system performance"
    echo "      and loaded plugins/dependencies."
}

# =============================================================================
# Help and Usage
# =============================================================================

show_help() {
    cat << 'EOF'
ZSH Template Selector - Interactive template selection and application tool

USAGE:
    zsh_template_selector.sh [COMMAND] [OPTIONS]

COMMANDS:
    interactive, select
        Interactively select and apply a template (default)

    apply <template>
        Apply a specific template without interactive selection

    preview <template>
        Preview a template's content

    list
        List all available templates

    compare
        Show template comparison matrix

    benchmark
        Benchmark template startup times

    help, -h, --help
        Show this help message

TEMPLATES:
    dev-full          Full development environment
    dev-minimal       Minimal development environment
    server            Server/production environment
    docker            Docker container environment
    custom:<name>     Custom template from templates/custom/

EXAMPLES:
    # Interactive selection
    zsh_template_selector.sh

    # Apply specific template
    zsh_template_selector.sh apply dev-minimal

    # Preview template
    zsh_template_selector.sh preview server

    # Compare all templates
    zsh_template_selector.sh compare

    # Benchmark startup times
    zsh_template_selector.sh benchmark

OPTIONS:
    --no-backup       Skip creating a backup before applying
    --force           Apply template without confirmation

FILES:
    templates/dev/dev-full.zshrc
        Full development environment template

    templates/dev/dev-minimal.zshrc
        Minimal development environment template

    templates/server/server.zshrc
        Server/production environment template

    templates/docker/docker.zshrc
        Docker container environment template

    templates/custom/*.zshrc
        Custom user templates

SEE ALSO:
    zsh_launcher.sh    Multi-mode ZSH launcher
    templates/README.md  Template documentation

EOF
}

# =============================================================================
# Main Function
# =============================================================================

main() {
    local command="${1:-interactive}"
    shift || true

    local no_backup=false
    local force=false

    # Parse options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-backup)
                no_backup=true
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    case "$command" in
        interactive|select)
            local template=$(select_template_interactive)
            if [[ $? -eq 0 && -n "$template" ]]; then
                echo ""
                local backup_location=""
                if [[ "$no_backup" == false ]]; then
                    backup_location=$(backup_config)
                fi

                if [[ "$force" == false ]]; then
                    read "confirm?Apply template '$template'? (y/N): "
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        log_info "Cancelled"
                        return 0
                    fi
                fi

                apply_template "$template" "$backup_location"
            fi
            ;;

        apply)
            if [[ -z "$1" ]]; then
                log_error "Please specify a template to apply"
                echo ""
                echo "Available templates:"
                get_templates
                return 1
            fi

            local template="$1"
            if ! template_exists "$template"; then
                log_error "Template not found: $template"
                echo ""
                echo "Available templates:"
                get_templates
                return 1
            fi

            local backup_location=""
            if [[ "$no_backup" == false ]]; then
                backup_location=$(backup_config)
            fi

            if [[ "$force" == false ]]; then
                read "confirm?Apply template '$template'? (y/N): "
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    log_info "Cancelled"
                    return 0
                fi
            fi

            apply_template "$template" "$backup_location"
            ;;

        preview)
            if [[ -z "$1" ]]; then
                log_error "Please specify a template to preview"
                return 1
            fi
            preview_template "$1"
            ;;

        list)
            echo ""
            echo "Available Templates:"
            echo ""
            get_templates | while read -r template; do
                local name=$(get_template_display_name "$template")
                local desc=$(get_template_description "$template")
                echo "  [$template] $name"
                echo "      $desc"
                echo ""
            done
            ;;

        compare)
            compare_templates
            ;;

        benchmark)
            benchmark_templates
            ;;

        help|-h|--help)
            show_help
            ;;

        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            return 1
            ;;
    esac
}

# =============================================================================
# Script Entry Point
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
