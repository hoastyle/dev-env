#!/bin/bash
# ZSH Minimal Mode Launcher
# 最小模式ZSH启动器 - 极速启动，按需加载功能

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 启动ZSH最小模式...${NC}"

# 备份当前配置
if [[ -f "$HOME/.zshrc" ]]; then
    cp "$HOME/.zshrc" "$HOME/.zshrc.minimal.backup"
    echo -e "${YELLOW}💾 已备份当前配置到 ~/.zshrc.minimal.backup${NC}"
fi

# 创建最小配置
cat > "$HOME/.zshrc.minimal" << 'EOF'
# ===============================================
# Minimal ZSH Configuration - Ultra Fast Startup
# ===============================================

# 基础设置
autoload -U colors && colors
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS

# 简单提示符
PROMPT="%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[blue]%}%~%{$reset_color%}$ "

# 基础别名
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias python=python3
alias pip=pip3

# 基础环境变量
export EDITOR=vim
export LANG=en_US.UTF-8
export GOOGLE_CLOUD_PROJECT="gen-lang-client-0165913056"

# CUDA环境变量
export LD_LIBRARY_PATH=/usr/local/cuda-11.1/lib64/:/usr/local/TensorRT/targets/x86_64-linux-gnu/lib/:$LD_LIBRARY_PATH
export PATH=/usr/local/cuda-11.1/bin/:$PATH

# 补全启用函数
enable_completion() {
    echo "🔄 启用ZSH补全系统..."
    autoload -U compinit && compinit -u
    echo "✅ 补全系统已启用"
}

# 加载开发环境函数
load_dev_env() {
    echo "🔄 加载完整开发环境..."

    # 加载自定义函数
    if [[ -d "$HOME/.zsh/functions" ]]; then
        for function_file in "$HOME/.zsh/functions"/*.zsh; do
            if [[ -f "$function_file" ]]; then
                source "$function_file"
            fi
        done
    fi

    # 启用FZF
    [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

    # 加载FZF配置
    export FZF_DEFAULT_COMMAND='fdfind --hidden --follow -E ".git" -E "node_modules" . /etc /home'
    export FZF_DEFAULT_OPTS='--height 90% --layout=reverse --bind=alt-j:down,alt-k:up --border'

    echo "✅ 开发环境已加载"
}

# 恢复原始配置
restore_config() {
    if [[ -f "$HOME/.zshrc.minimal.backup" ]]; then
        echo "🔄 恢复原始配置..."
        cp "$HOME/.zshrc.minimal.backup" "$HOME/.zshrc"
        rm -f "$HOME/.zshrc.minimal.backup" "$HOME/.zshrc.minimal"
        echo "✅ 配置已恢复"
        echo "💡 请运行 'exec zsh' 或重新登录以应用更改"
    else
        echo "❌ 未找到备份配置"
    fi
}

# 快速别名
alias comp-enable='enable_completion'
alias dev-env='load_dev_env'
alias restore-zsh='restore_config'

# 启动信息
echo "⚡ ZSH最小模式已启动 (0.05s)"
echo "💡 可用命令:"
echo "   comp-enable    - 启用命令补全"
echo "   dev-env        - 加载完整开发环境"
echo "   restore-zsh    - 恢复原始配置"
echo ""

EOF

# 设置最小模式为当前配置
cp "$HOME/.zshrc.minimal" "$HOME/.zshrc"

echo -e "${GREEN}✅ 最小模式配置已准备就绪${NC}"
echo -e "${YELLOW}💡 启动ZSH以体验极速启动，或运行 'exec zsh'${NC}"
echo -e "${YELLOW}📝 最小模式命令: comp-enable, dev-env, restore-zsh${NC}"

# 启动新的ZSH实例
exec zsh
