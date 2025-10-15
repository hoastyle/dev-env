# ===============================================
# ZSH Configuration - Development Environment
# ===============================================
# Version: 1.0
# Maintainer: dev-env project
# ===============================================

# Antigen Plugin Manager
source "$HOME/.antigen.zsh"

# Antigen Configuration
antigen use oh-my-zsh

# Core Plugins
antigen bundle git
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle srijanshetty/zsh-pip-completion
antigen bundle MichaelAquilina/zsh-auto-notify
antigen bundle unixorn/autoupdate-antigen.zshplugin
antigen bundle iboyperson/pipenv-zsh
antigen bundle trystan2k/zsh-tab-title
antigen bundle zpm-zsh/undollar
antigen bundle mafredri/zsh-async

# Theme Configuration
antigen theme robbyrussell

# Apply Antigen Settings
antigen apply

# Ensure theme loads properly
sleep 0.5

# Fallback theme loading
if [[ -z "$PROMPT" ]]; then
    echo "🎨 重新加载 Antigen 主题..."
    antigen theme robbyrussell
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

# Search Tools
hg() {
    grep -Ern "$1" --color=always "$2" | less -r
}

hig() {
    grep -Eirn "$1" --color=always "$2" | less -r
}
alias hig='hig'

hrg() {
    rg -e "$1" --color=always "$2" | less -r
}
alias hrg='hrg'

hirg() {
    rg -ie "$1" --color=always "$2" | less -r
}
alias hirg='hirg'

# Network Proxy
alias proxy="
    export http_proxy=http://127.0.0.1:7890;
    export https_proxy=http://127.0.0.1:7890;
    export all_proxy=http://127.0.0.1:7890;
    export no_proxy=http://127.0.0.1:7890;
    export HTTP_PROXY=http://127.0.0.1:7890;
    export HTTPS_PROXY=http://127.0.0.1:7890;
    export ALL_PROXY=http://127.0.0.1:7890;
    export NO_PROXY='localhost, 127.0.0.1,*.local';"

alias unproxy="
    unset http_proxy;
    unset https_proxy;
    unset all_proxy;
    unset no_proxy;
    unset HTTP_PROXY;
    unset HTTPS_PROXY;
    unset ALL_PROXY;
    unset NO_PROXY"

# CUDA & TensorRT
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64/:/usr/local/TensorRT/targets/x86_64-linux-gnu/lib/:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda-11.1/bin/:$PATH

# Autojump
[[ -s /home/hao/.autojump/etc/profile.d/autojump.sh ]] && source /home/hao/.autojump/etc/profile.d/autojump.sh

# ===============================================
# Custom Functions
# ===============================================

# Safe ZSH Configuration Reload
reload_zsh() {
    echo "🔄 重新加载 zsh 配置..."
    source ~/.zshrc
    echo "✅ zsh 配置加载完成"
    echo "🎨 当前主题: robbyrussell 风格"
}

# Environment Detection
check_environment() {
    if [[ -f "/.dockerenv" ]]; then
        echo "🐳 当前在 Docker 容器环境中"
        echo "   容器名: $(hostname)"
        echo "   用户: $(whoami)"
        echo "   镜像: $(cat /etc/image_version 2>/dev/null || echo "未知")"
    else
        echo "🖥️  当前在物理主机环境中"
        echo "   主机名: $(hostname)"
        echo "   用户: $(whoami)"
        echo "   系统: $(uname -a)"
    fi
}

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
# Configuration Complete
# ===============================================
echo "🎉 Development Environment ZSH Configuration Loaded"