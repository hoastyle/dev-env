# ===============================================
# ZSH Configuration - Development Environment
# ===============================================
# Version: 1.0
# Maintainer: dev-env project
# ===============================================

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
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
antigen apply

# Ensure theme loads properly
sleep 0.5

# Fallback theme loading
if [[ -z "$PROMPT" ]]; then
    echo "🎨 重新加载 Antigen 主题..."
    antigen theme romkatv/powerlevel10k
    antigen apply
fi

# ===============================================
# Python Environment
# ===============================================

# Use Python 3 by default
alias python=python3
alias pip=pip3

# Conda Environment
__conda_setup="$(CONDA_REPORT_ERRORS=false '/home/hao/anaconda3/bin/conda' shell.bash hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "/home/hao/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/hao/anaconda3/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="/home/hao/anaconda3/bin:$PATH"
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

# Autojump
[[ -s /home/hao/.autojump/etc/profile.d/autojump.sh ]] && source /home/hao/.autojump/etc/profile.d/autojump.sh

# ===============================================
# Custom Functions
# ===============================================

# Load custom functions from ~/.zsh/functions
if [[ -d "$HOME/.zsh/functions" ]]; then
    for function_file in "$HOME/.zsh/functions"/*.zsh; do
        if [[ -f "$function_file" ]]; then
            source "$function_file"
        fi
    done
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

# ZSH Completion
autoload -U compinit && compinit -u

# ===============================================
# Powerlevel10k Configuration
# ===============================================

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===============================================
# Configuration Complete
# ===============================================
echo "🎉 Development Environment ZSH Configuration Loaded"
