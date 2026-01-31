# ===============================================
# Matrix System Status (Optional)
# ===============================================
# Description: Load additional Matrix system functions if available
# This provides process status, restart functions, and session info

# Load Matrix system status module if available
if [[ -f "$HOME/.zshrc.matrix" ]]; then
    source "$HOME/.zshrc.matrix"
fi

# ===============================================
# Case-Insensitive Completion
# ===============================================
# Enable case-insensitive tab completion for convenience
# Example: typing 'cd Doc' + Tab will complete to 'Documents'
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''
