# ===============================================
# Development Tools Configuration
# ===============================================
# Description: FZF, CUDA, TensorRT, Autojump

# ===============================================
# FZF Configuration
# ===============================================

# Enable FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# FZF Configuration
export FZF_DEFAULT_COMMAND='fdfind --hidden --follow -E ".git" -E "node_modules" . /etc /home'
export FZF_DEFAULT_OPTS='--height 90% --layout=reverse --bind=alt-j:down,alt-k:up,alt-i:toggle+down --border --preview "echo {} | ~/.fzf/fzf_preview.py" --preview-window=down'

# FZF Completion Functions
_fzf_compgen_path() {
  fdfind --hidden --follow -E ".git" -E "node_modules" . /etc /home
}

_fzf_compgen_dir() {
  fdfind --type d --hidden --follow -E ".git" -E "node_modules" . /etc /home
}

# ===============================================
# CUDA & TensorRT
# ===============================================
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64/:/usr/local/TensorRT/targets/x86_64-linux-gnu/lib/:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda-11.1/bin/:$PATH

# ===============================================
# Autojump Configuration
# ===============================================
# Fast directory jumping with autojump
# Install: apt-get install autojump OR brew install autojump
# NOTE: Do NOT create aliases j='autojump' as they override autojump.zsh function definitions!
#       The autojump.sh script provides the j() function with proper cd integration.
if [[ -s "$HOME/.autojump/etc/profile.d/autojump.sh" ]]; then
    source "$HOME/.autojump/etc/profile.d/autojump.sh"
    # Note: autojump.zsh defines j() function with cd integration
    # No need to create aliases - the function handles all j commands
elif command -v autojump &> /dev/null; then
    # Fallback: autojump installed but not in expected location
    # Try to find autojump from PATH
    if [[ -n "$(command -v autojump)" ]]; then
        # Source autojump shell integration if available
        [[ -s "$(dirname $(command -v autojump))/../share/autojump/autojump.sh" ]] && \
            source "$(dirname $(command -v autojump))/../share/autojump/autojump.sh"
        # If autojump shell integration failed, provide fallback
        if ! command -v j &> /dev/null; then
            alias j='autojump'
            alias jhistory='autojump -s'
        fi
    fi
else
    # Autojump not installed - provide helpful message
    j() {
        echo "❌ autojump is not installed" >&2
        echo "Install with: apt-get install autojump (Ubuntu/Debian) or brew install autojump (macOS)" >&2
        echo "After installation, restart your shell with: exec zsh" >&2
        return 1
    }
    jhistory() {
        echo "❌ autojump is not installed" >&2
        echo "Install autojump to use this feature" >&2
        return 1
    }
fi
