# ===============================================
# ZSH Core Configuration
# ===============================================
# Version: 1.0
# Description: Powerlevel10k instant prompt, Antigen plugin manager
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

# ===============================================
# Antigen Plugin Manager
# ===============================================
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
