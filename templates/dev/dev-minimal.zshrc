# ===============================================
# ZSH Configuration Template - Minimal Development Environment
# ===============================================
# Template: dev-minimal
# Description: Lightweight development environment with essential features
# Use Case: Quick development tasks, script execution, resource-constrained environments
# Startup Time: ~50-100ms
# ===============================================

# Skip instant prompt for faster startup
# Enable only if needed:
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#     source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

# ===============================================
# Minimal Theme
# ===============================================

autoload -U colors && colors
PROMPT="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ "
RPROMPT="%(?..%{$fg[red]%}%?%{$reset_color%})"

# ===============================================
# Essential Aliases
# ===============================================

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias python=python3
alias pip=pip3

# ===============================================
# Python Environment - Lazy Loading
# ===============================================

# Conda - Lazy loading
if [[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]]; then
    export CONDA_EXE="$HOME/anaconda3/bin/conda"
    export _CONDA_ROOT="$HOME/anaconda3"
    conda() {
        unset -f conda
        eval "$($HOME/anaconda3/bin/conda shell.zsh hook)"
        conda "$@"
    }
fi

# NVM - Lazy loading
export NVM_DIR="$HOME/.nvm"
nvm() {
    unset -f nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    nvm "$@"
}

# ===============================================
# FZF - Lazy Loading
# ===============================================

fzf() {
    unset -f fzf
    [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    fzf "$@"
}

export FZF_DEFAULT_COMMAND='fdfind --hidden --follow -E ".git" -E "node_modules" . /etc /home'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

# ===============================================
# Autojump - Lazy Loading
# ===============================================

typeset -g _AUTOJUMP_LAZY_LOADED=0

lazy_load_autojump() {
    [[ $_AUTOJUMP_LAZY_LOADED -eq 1 ]] && return 0
    if [[ -s "$HOME/.autojump/etc/profile.d/autojump.sh" ]]; then
        source "$HOME/.autojump/etc/profile.d/autojump.sh"
    elif command -v autojump &> /dev/null; then
        [[ -s "$(dirname $(command -v autojump))/../share/autojump/autojump.sh" ]] && \
            source "$(dirname $(command -v autojump))/../share/autojump/autojump.sh"
    fi
    _AUTOJUMP_LAZY_LOADED=1
}

j() {
    if [[ $_AUTOJUMP_LAZY_LOADED -eq 0 ]]; then
        lazy_load_autojump
        if typeset -f j | grep -q "autojump"; then
            unfunction j
            j "$@"
            return $?
        fi
    fi
    if command -v autojump &> /dev/null; then
        local target_dir="$(autojump "$@" 2>/dev/null)"
        if [[ -d "$target_dir" ]]; then
            cd "$target_dir"
        else
            echo "autojump: directory '$*' not found" >&2
            return 1
        fi
    else
        echo "autojump not installed" >&2
        return 1
    fi
}

# ===============================================
# Completion - Lazy Loading
# ===============================================

typeset -g COMPLETION_ENABLED=""

enable_completion() {
    if [[ -z "$COMPLETION_ENABLED" ]]; then
        autoload -Uz compinit
        compinit -u
        COMPLETION_ENABLED=1
        echo "Completion enabled"
    fi
}

lazy_completion() {
    enable_completion
    zle expand-or-complete
}
zle -N lazy_completion
bindkey '^I' lazy_completion

alias comp-enable='enable_completion'

# ===============================================
# Essential Functions
# ===============================================

# Quick directory navigation
cd() {
    builtin cd "$@" && ls -la
}

# Create directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ===============================================
# Environment Variables
# ===============================================

export EDITOR=${EDITOR:-vim}
export VISUAL=${VISUAL:-vim}

# Add ~/.local/bin to PATH
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# ===============================================
# Case-Insensitive Completion
# ===============================================

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
