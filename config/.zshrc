# ===============================================
# ZSH Configuration - Development Environment
# ===============================================
# Version: 1.0
# Maintainer: dev-env project
# ===============================================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#
# Note: Use quiet mode in tmux to suppress warnings about console output
if [[ -n "$TMUX" ]]; then
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
fi

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Collapse nested launcher shells by exiting the previous instance when reopened.
if [[ -n "$ZSH_LAUNCHER_ACTIVE" ]]; then
    trap 'builtin exit' USR1
    if [[ -n "$ZSH_LAUNCHER_PREV_PID" && "$ZSH_LAUNCHER_PREV_PID" != "$$" ]]; then
        if kill -0 "$ZSH_LAUNCHER_PREV_PID" 2>/dev/null; then
            kill -USR1 "$ZSH_LAUNCHER_PREV_PID" 2>/dev/null || true
        fi
        unset ZSH_LAUNCHER_PREV_PID
    fi
fi

# Antigen Plugin Manager
source "$HOME/.antigen.zsh"

# Antigen Configuration
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

# Theme Configuration
antigen theme romkatv/powerlevel10k

# Apply Antigen Settings
# Note: Suppress output to prevent instant prompt warnings
antigen apply &>/dev/null

# Fallback theme loading (without sleep to support instant prompt)
if [[ -z "$PROMPT" ]]; then
    antigen theme romkatv/powerlevel10k
    antigen apply &>/dev/null
fi

# ===============================================
# Python Environment
# ===============================================

# Use Python 3 by default
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
# Development Tools
# ===============================================

# Search Tools and Network Proxy functions are loaded from ~/.zsh/functions/

# CUDA & TensorRT
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64/:/usr/local/TensorRT/targets/x86_64-linux-gnu/lib/:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda-11.1/bin/:$PATH

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

# ===============================================
# Custom Functions
# ===============================================

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

# ===============================================
# Additional Aliases
# ===============================================

# ROS (commented out, enable if needed)
# source /opt/ros/noetic/setup.zsh

# Point Cloud Tools
alias pm="pcl_viewer -use_point_picking -ax 4 -multiview 1"
alias pa="pcl_viewer -ax 4 -use_point_picking"

# ===============================================
# Environment Variables
# ===============================================

# Google Cloud Project
export GOOGLE_CLOUD_PROJECT="gen-lang-client-0165913056"

# ZSH Completion (cached)
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

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===============================================
# Environment Context Indicators
# ===============================================
# Environment indicators are loaded from ~/.zsh/functions/context.zsh
# and integrated into Powerlevel10k via the prompt_env_indicators segment
#
# To enable: Run: ./scripts/setup-p10k-env-indicators.sh
# Or manually edit ~/.p10k.zsh and add 'env_indicators' to RIGHT_PROMPT_ELEMENTS
#
# See: docs/P10K_ENV_INDICATORS_SETUP.md for detailed setup instructions

# ===============================================
# Configuration Complete
# ===============================================

# Welcome message disabled to support Powerlevel10k instant prompt
# The theme provides its own visual feedback
# To re-enable, uncomment the following line:
# echo "🎉 Development Environment ZSH Configuration Loaded"

# ===============================================
# User-Local Binary PATH (~/.local/bin)
# ===============================================
# Add ~/.local/bin to PATH for user-installed tools (e.g., uv, pipx, etc.)
# This script uses intelligent PATH management to avoid duplicate entries
# Source: uv installer and XDG Base Directory Specification
if [[ -f "$HOME/.local/bin/env" ]]; then
    source "$HOME/.local/bin/env"
fi
