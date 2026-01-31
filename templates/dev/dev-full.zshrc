# ===============================================
# ZSH Configuration Template - Full Development Environment
# ===============================================
# Template: dev-full
# Description: Complete development environment with all features enabled
# Use Case: Daily development work with maximum productivity features
# Startup Time: ~1.5s
# ===============================================

# Enable Powerlevel10k instant prompt
if [[ -n "$TMUX" ]]; then
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Collapse nested launcher shells
if [[ -n "$ZSH_LAUNCHER_ACTIVE" ]]; then
    trap 'builtin exit' USR1
    if [[ -n "$ZSH_LAUNCHER_PREV_PID" && "$ZSH_LAUNCHER_PREV_PID" != "$$" ]]; then
        if kill -0 "$ZSH_LAUNCHER_PREV_PID" 2>/dev/null; then
            kill -USR1 "$ZSH_LAUNCHER_PREV_PID" 2>/dev/null || true
        fi
        unset ZSH_LAUNCHER_PREV_PID
    fi
fi

# ===============================================
# Antigen Plugin Manager
# ===============================================

source "$HOME/.antigen.zsh"
antigen use oh-my-zsh

# Core Plugins
antigen bundle git
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle srijanshetty/zsh-pip-completion
antigen bundle MichaelAquilina/zsh-auto-notify
antigen bundle unixorn/autoupdate-antigen.zshplugin
antigen bundle iboyperson/pipenv-zsh
antigen bundle trystan2k/zsh-tab-title
antigen bundle zpm-zsh/undollar
antigen bundle mafredri/zsh-async

# Theme
antigen theme romkatv/powerlevel10k
antigen apply &>/dev/null

# Fallback theme loading
if [[ -z "$PROMPT" ]]; then
    antigen theme romkatv/powerlevel10k
    antigen apply &>/dev/null
fi

# ===============================================
# Python Environment
# ===============================================

alias python=python3
alias pip=pip3

# Conda Environment
__conda_setup="$(CONDA_REPORT_ERRORS=false "$HOME/anaconda3/bin/conda" shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]; then
        . "$HOME/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="$HOME/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ===============================================
# FZF Configuration
# ===============================================

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export FZF_DEFAULT_COMMAND='fdfind --hidden --follow -E ".git" -E "node_modules" . /etc /home'
export FZF_DEFAULT_OPTS='--height 90% --layout=reverse --bind=alt-j:down,alt-k:up,alt-i:toggle+down --border --preview "echo {} | ~/.fzf/fzf_preview.py" --preview-window=down'

_fzf_compgen_path() {
  fdfind --hidden --follow -E ".git" -E "node_modules" . /etc /home
}

_fzf_compgen_dir() {
  fdfind --type d --hidden --follow -E ".git" -E "node_modules" . /etc /home
}

# ===============================================
# Development Tools
# ===============================================

# CUDA & TensorRT (comment out if not needed)
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64/:/usr/local/TensorRT/targets/x86_64-linux-gnu/lib/:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda-11.1/bin/:$PATH

# Autojump
if [[ -s "$HOME/.autojump/etc/profile.d/autojump.sh" ]]; then
    source "$HOME/.autojump/etc/profile.d/autojump.sh"
elif command -v autojump &> /dev/null; then
    [[ -s "$(dirname $(command -v autojump))/../share/autojump/autojump.sh" ]] && \
        source "$(dirname $(command -v autojump))/../share/autojump/autojump.sh"
fi

# ===============================================
# Custom Functions
# ===============================================

if [[ -d "$HOME/.zsh/functions" ]]; then
    if [[ -f "$HOME/.zsh/functions/validation.zsh" ]]; then
        source "$HOME/.zsh/functions/validation.zsh"
    fi
    for function_file in "$HOME/.zsh/functions"/*.zsh; do
        if [[ -f "$function_file" ]] && [[ "$(basename "$function_file")" != "validation.zsh" ]]; then
            source "$function_file"
        fi
    done
fi

# ===============================================
# Aliases
# ===============================================

if command -v dircolors &> /dev/null; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Point Cloud Tools
alias pm="pcl_viewer -use_point_picking -ax 4 -multiview 1"
alias pa="pcl_viewer -ax 4 -use_point_picking"

# ===============================================
# Environment Variables
# ===============================================

export GOOGLE_CLOUD_PROJECT="gen-lang-client-0165913056"

# ===============================================
# Completion System
# ===============================================

_dev_env_init_completion() {
    setopt LOCAL_OPTIONS EXTENDED_GLOB
    autoload -Uz compinit
    zmodload zsh/stat 2>/dev/null || true

    local cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/dev-env"
    local dump_file="${cache_root}/zcompdump-${HOST}-${ZSH_VERSION}"
    local dump_ttl=${ZSH_COMPDUMP_TTL:-86400}

    [[ -d "${cache_root}" ]] || mkdir -p "${cache_root}"

    local -a compinit_args
    compinit_args=(-d "${dump_file}")

    if [[ -s "${dump_file}" ]]; then
        local -a dump_stat
        if zstat -A dump_stat +mtime -- "${dump_file}" 2>/dev/null; then
            if (( EPOCHSECONDS - dump_stat[1] < dump_ttl )); then
                compinit_args=(-C "${compinit_args[@]}")
            fi
        fi
    fi

    if [[ "${compinit_args[1]}" != "-C" ]]; then
        local -a insecure_dirs
        insecure_dirs=(${(@f)$(compaudit 2>/dev/null)})
        if (( ${#insecure_dirs} )); then
            compinit_args=(-i "${compinit_args[@]}")
        fi
    fi

    compinit "${compinit_args[@]}"
}

_dev_env_init_completion
unset -f _dev_env_init_completion

# ===============================================
# Powerlevel10k Configuration
# ===============================================

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===============================================
# User-Local Binary PATH
# ===============================================

if [[ -f "$HOME/.local/bin/env" ]]; then
    source "$HOME/.local/bin/env"
fi

# ===============================================
# Case-Insensitive Completion
# ===============================================

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''
