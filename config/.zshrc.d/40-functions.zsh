# ===============================================
# Custom Functions
# ===============================================
# Description: Load custom functions from ~/.zsh/functions

# Load custom functions from ~/.zsh/functions
if [[ -d "$HOME/.zsh/functions" ]]; then
    # Load validation module first (required by other functions)
    if [[ -f "$HOME/.zsh/functions/validation.zsh" ]]; then
        source "$HOME/.zsh/functions/validation.zsh"
    fi

    # Load all other function modules using autoload for lazy loading
    # This improves startup time by loading functions on-demand
    for function_file in "$HOME/.zsh/functions"/*.zsh; do
        if [[ -f "$function_file" ]] && [[ "$(basename "$function_file")" != "validation.zsh" ]]; then
            # Source for backward compatibility (immediate loading)
            # Uncomment the autoload line below for lazy loading (experimental)
            source "$function_file"
        fi
    done

    # Optional: Enable lazy loading with autoload -Uz
    # Uncomment the lines below to enable lazy loading
    # fpath=("$HOME/.zsh/functions" $fpath)
    # autoload -Uz $HOME/.zsh/functions/*(:t:r)
fi
