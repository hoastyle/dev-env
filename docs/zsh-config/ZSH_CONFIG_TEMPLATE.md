# ZSH 配置模板与使用指南

**模板版本**: 1.0
**适用人群**: 开发者、DevOps 工程师
**环境要求**: Linux/macOS, Zsh 5.0+

---

## 1. 快速开始

### 📦 **一键安装**
```bash
# 克隆配置仓库
git clone <repository-url> ~/.zsh-config
cd ~/.zsh-config

# 运行安装脚本
./install.sh

# 重新加载配置
source ~/.zshrc
```

### 🔧 **手动安装**
```bash
# 1. 安装 Antigen
curl -L git.io/antigen > ~/.antigen.zsh

# 2. 复制配置文件
cp .zshrc ~/.zshrc

# 3. 安装依赖工具
# Ubuntu/Debian:
sudo apt-get install fzf fd-find ripgrep

# macOS:
brew install fzf fd ripgrep

# 4. 重新加载
source ~/.zshrc
```

## 2. 配置文件模板

### 📋 **基础配置模板**
```bash
# ===============================
# ZSH Configuration Template
# ===============================

# Antigen 插件管理器
source "$HOME/.antigen.zsh"

# Antigen 配置
antigen use oh-my-zsh

# 核心插件
antigen bundle git
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting

# 可选插件 (根据需要启用)
antigen bundle MichaelAquilina/zsh-auto-notify
antigen bundle srijanshetty/zsh-pip-completion
antigen bundle trystan2k/zsh-tab-title

# 主题设置
antigen theme robbyrussell

# 应用配置
antigen apply

# ===============================
# 开发工具配置
# ===============================

# FZF 配置
export FZF_DEFAULT_COMMAND='fdfind --hidden --follow -E ".git" -E "node_modules" .'
export FZF_DEFAULT_OPTS='--height 90% --layout=reverse --border'

# 启用 FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ===============================
# 环境管理
# ===============================

# Conda (Python)
if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
    . "/opt/conda/etc/profile.d/conda.sh"
fi

# NVM (Node.js)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# ===============================
# 自定义函数
# ===============================

# 环境检测
check_environment() {
    if [[ -f "/.dockerenv" ]]; then
        echo "🐳 Docker 容器环境"
    else
        echo "🖥️  物理主机环境"
    fi
}

# 安全重载
reload_zsh() {
    echo "🔄 重新加载 ZSH 配置..."
    source ~/.zshrc
    echo "✅ 配置加载完成"
}

# ===============================
# 实用别名
# ===============================

# 搜索增强
alias hg='grep -Ern --color=always'
alias hig='grep -Eirn --color=always'

# 网络代理
alias proxy='export http_proxy=http://127.0.0.1:7890; export https_proxy=http://127.0.0.1:7890'
alias unproxy='unset http_proxy https_proxy'

# Python 环境
alias python='python3'
alias pip='pip3'

# ===============================
# 路径配置
# ===============================

# CUDA 支持 (可选)
# export PATH=/usr/local/cuda/bin:$PATH
# export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
```

### 🎯 **轻量级模板** (适合服务器环境)
```bash
# Minimal ZSH Configuration
source "$HOME/.antigen.zsh"

antigen use oh-my-zsh
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme robbyrussell
antigen apply

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
```

### 🚀 **开发增强模板** (适合开发机器)
```bash
# Enhanced Development Configuration
source "$HOME/.antigen.zsh"

# 核心插件
antigen use oh-my-zsh
antigen bundle git
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-autosuggestions

# 开发工具
antigen bundle docker
antigen bundle kubectl
antigen bundle gradle
antigen bundle mvn
antigen bundle node
antigen bundle npm

# 实用工具
antigen bundle extract
antigen bundle web-search
antigen bundle colored-man-pages

# 主题
antigen theme robbyrussell
antigen apply

# 高级 FZF 配置
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"

# Git 增强配置
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWUNTRACKEDFILES=1
export GIT_PS1_SHOWSTASHSTATE=1
```

## 3. 环境适配

### 🐳 **Docker 环境配置**
```bash
# Docker 环境专用配置
if [[ -f "/.dockerenv" ]]; then
    # 禁用不必要的通知
    AUTO_NOTIFY_IGNORE_EXCLUDES="all"

    # 简化主题
    antigen theme minimal

    # 容器内专用别名
    alias exit='echo "使用 Ctrl+D 退出容器"'
fi
```

### 🖥️ **服务器环境配置**
```bash
# 服务器环境优化
if [[ $(uname -s) == "Linux" ]] && [[ -z "$DISPLAY" ]]; then
    # 禁用图形界面相关插件
    antigen bundle autoupdate-antigen --disable

    # 优化性能
    setopt NO_BEEP
    setopt NO_GLOBAL_RCS

    # 简化提示符
    PROMPT='%n@%m:%~$ '
fi
```

### 💻 **MacOS 环境配置**
```bash
# MacOS 专用配置
if [[ $(uname -s) == "Darwin" ]]; then
    # Homebrew 路径
    export PATH="/opt/homebrew/bin:$PATH"

    # MacOS 特定插件
    antigen bundle brew
    antigen bundle osx

    # 文件大小显示
    alias du='du -h'
    alias df='df -h'
fi
```

## 4. 插件选择指南

### 📊 **插件分类**

#### 🎯 **核心插件** (推荐安装)
| 插件 | 功能 | 性能影响 |
|------|------|---------|
| `git` | Git 命令增强 | 低 |
| `zsh-syntax-highlighting` | 语法高亮 | 中 |
| `zsh-completions` | 命令补全 | 低 |
| `zsh-autosuggestions` | 自动建议 | 中 |

#### 🛠️ **开发工具插件** (按需选择)
| 插件 | 功能 | 适用场景 |
|------|------|---------|
| `docker` | Docker 命令补全 | 容器化开发 |
| `kubectl` | Kubernetes 支持 | 云原生开发 |
| `npm` | Node.js 包管理 | 前端开发 |
| `python` | Python 环境管理 | Python 开发 |

#### ⚡ **性能优化插件**
| 插件 | 功能 | 注意事项 |
|------|------|---------|
| `zsh-autosuggestions` | 自动建议 | 可能影响历史记录 |
| `zsh-syntax-highlighting` | 语法高亮 | 大文件可能卡顿 |
| `zsh-completions` | 增强补全 | 增加启动时间 |

### 🎯 **推荐配置组合**

#### 💻 **开发者配置**
```bash
# 开发者推荐插件组合
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle docker
antigen bundle npm
antigen bundle pip
```

#### 🖥️ **运维工程师配置**
```bash
# 运维工程师推荐插件组合
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle kubectl
antigen bundle systemd
antigen bundle docker
```

#### 🐧 **服务器管理员配置**
```bash
# 服务器管理员推荐插件组合
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen bundle colored-man-pages
antigen bundle extract
```

## 5. 主题配置

### 🎨 **主题选择**

#### 🏃‍♂️ **轻量级主题**
```bash
# 简洁主题
antigen theme minimal     # 极简主题
antigen theme pure        # Pure 主题
antigen theme lambda      # Lambda 主题
```

#### 🎯 **功能丰富主题**
```bash
# 功能主题
antigen theme robbyrussell    # 经典主题 (推荐)
antigen theme agnoster        # Git 信息丰富
antigen theme bureau          # 现代 UI 风格
```

#### 🌈 **彩色主题**
```bash
# 彩色主题
antigen theme gallois         # 彩色箭头
antigen theme fishy           # Fish Shell 风格
antigen theme refined         # 优雅配色
```

### 🎯 **自定义主题示例**
```bash
# 自定义主题函数
custom_theme() {
    # Git 状态
    local git_prompt='$(git_prompt_info)'

    # 路径显示
    local path_prompt='%{$fg_bold[blue]%}%~%{$reset_color%}'

    # 时间显示
    local time_prompt='%{$fg[gray]%}%T%{$reset_color%}'

    # 主提示符
    PROMPT='%{$fg_bold[green]%}➜ %{$reset_color%}${path_prompt}${git_prompt}
%{$fg_bold[green]%}❯%{$reset_color%} '

    # 右侧提示符
    RPROMPT='${time_prompt}'
}

# 应用自定义主题
antigen theme custom_theme
```

## 6. 性能优化

### ⚡ **启动时间优化**

#### 🔧 **插件延迟加载**
```bash
# 延迟加载函数
_lazy_load() {
    local command=$1
    local init_command=$2
    local bundle=$3

    eval "
    $command() {
        unfunction $command
        $init_command
        antigen bundle $bundle
        antigen apply
        $command \"\$@\"
    }
    "
}

# 延迟加载 NVM
_lazy_load nvm 'source ~/.nvm/nvm.sh' 'lukechilds/zsh-nvm'

# 延迟加载 Docker
_lazy_load docker 'echo "Docker commands loading..."' 'docker'
```

#### 🚀 **条件加载**
```bash
# 根据环境条件加载插件
if command -v docker &> /dev/null; then
    antigen bundle docker
fi

if [[ -d "$HOME/.nvm" ]]; then
    antigen bundle lukechilds/zsh-nvm
fi

if [[ $(uname -s) == "Darwin" ]]; then
    antigen bundle brew
fi
```

### 📊 **性能监控**
```bash
# 启动时间监控
zsh_load_time() {
    local start_time=$(date +%s.%N)
    source ~/.zshrc
    local end_time=$(date +%s.%N)
    local load_time=$(echo "$end_time - $start_time" | bc)
    echo "⏱️  ZSH 启动时间: ${load_time}s"
}

# 内存使用监控
zsh_memory_usage() {
    local memory=$(ps -o rss= -p $$)
    echo "💾 ZSH 内存使用: ${memory}KB"
}
```

## 7. 故障排除

### 🔧 **常见问题解决**

#### ❌ **问题: 主题不显示**
```bash
# 解决方案: 强制重新加载主题
antigen theme robbyrussell
antigen apply
exec zsh
```

#### ⚠️ **问题: 插件加载失败**
```bash
# 检查插件状态
antigen list

# 重新安装插件
antigen purge
antigen update
antigen apply
```

#### 🐌 **问题: 启动速度慢**
```bash
# 检查启动时间
zsh -i -c 'echo $(( $(date +%s%N) - $(date +%s%N) ))'

# 禁用不必要的插件
antigen bundle <plugin-name> --disable
```

### 🔍 **调试模式**
```bash
# 启用详细输出
setopt XTRACE
zsh -x

# 检查配置语法
zsh -n ~/.zshrc

# 查看加载顺序
zsh -i -c 'echo $fpath'
```

## 8. 备份与恢复

### 💾 **配置备份**
```bash
#!/bin/bash
# backup_zsh.sh

BACKUP_DIR="$HOME/zsh-backup-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# 备份配置文件
cp ~/.zshrc "$BACKUP_DIR/"
cp ~/.antigen.zsh "$BACKUP_DIR/" 2>/dev/null || true

# 备份 Antigen 数据
cp -r ~/.antigen "$BACKUP_DIR/" 2>/dev/null || true

# 备份自定义脚本
cp -r ~/.zsh "$BACKUP_DIR/" 2>/dev/null || true

echo "✅ ZSH 配置已备份到: $BACKUP_DIR"
```

### 🔄 **配置恢复**
```bash
#!/bin/bash
# restore_zsh.sh

BACKUP_DIR="$1"

if [[ -z "$BACKUP_DIR" ]]; then
    echo "用法: $0 <备份目录>"
    exit 1
fi

# 恢复配置文件
cp "$BACKUP_DIR/.zshrc" ~/.zshrc
cp "$BACKUP_DIR/.antigen.zsh" ~/.antigen.zsh 2>/dev/null || true

# 恢复 Antigen 数据
cp -r "$BACKUP_DIR/.antigen" ~/ 2>/dev/null || true

# 重新加载
source ~/.zshrc

echo "✅ ZSH 配置已恢复"
```

## 9. 安装脚本

### 📦 **自动安装脚本**
```bash
#!/bin/bash
# install_zsh_config.sh

set -e

echo "🚀 开始安装 ZSH 配置..."

# 检查依赖
check_dependencies() {
    local deps=("zsh" "curl" "git")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "❌ 依赖 $dep 未安装"
            exit 1
        fi
    done
    echo "✅ 依赖检查通过"
}

# 安装 Antigen
install_antigen() {
    if [[ ! -f "$HOME/.antigen.zsh" ]]; then
        echo "📦 安装 Antigen..."
        curl -L git.io/antigen > "$HOME/.antigen.zsh"
        echo "✅ Antigen 安装完成"
    else
        echo "✅ Antigen 已存在，跳过安装"
    fi
}

# 安装依赖工具
install_tools() {
    echo "🛠️  安装依赖工具..."

    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Ubuntu/Debian
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y fzf fd-find ripgrep
        # Fedora
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y fzf fd-find ripgrep
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install fzf fd ripgrep
        fi
    fi

    echo "✅ 依赖工具安装完成"
}

# 安装配置文件
install_config() {
    echo "📝 安装配置文件..."

    # 备份现有配置
    if [[ -f "$HOME/.zshrc" ]]; then
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d)"
        echo "📦 现有配置已备份"
    fi

    # 复制新配置
    cp .zshrc "$HOME/.zshrc"

    echo "✅ 配置文件安装完成"
}

# 设置默认 Shell
set_default_shell() {
    if [[ "$SHELL" != "$(which zsh)" ]]; then
        echo "🔧 设置 ZSH 为默认 Shell..."
        chsh -s "$(which zsh)"
        echo "✅ 默认 Shell 设置完成"
        echo "⚠️  请重新登录或运行 'exec zsh' 以应用更改"
    fi
}

# 主函数
main() {
    check_dependencies
    install_antigen
    install_tools
    install_config
    set_default_shell

    echo ""
    echo "🎉 ZSH 配置安装完成!"
    echo "💡 使用 'exec zsh' 启动新的 ZSH 环境"
    echo "📚 使用 'check_environment' 检查环境"
    echo "🔄 使用 'reload_zsh' 重新加载配置"
}

# 执行安装
main "$@"
```

## 10. 使用示例

### 💻 **日常使用**
```bash
# 检查当前环境
check_environment

# 重新加载配置
reload_zsh

# 搜索文件内容
hg "function_name" src/

# 模糊搜索文件
fzf

# Git 操作
git status
git add .
git commit -m "update config"
```

### 🛠️ **开发工作流**
```bash
# 激活 Python 环境
conda activate myenv

# 切换 Node.js 版本
nvm use 16

# 启用代理
proxy

# Docker 操作
docker ps
docker run -it ubuntu bash
```

### 📊 **性能监控**
```bash
# 检查启动时间
zsh_load_time

# 检查内存使用
zsh_memory_usage

# 验证配置
validate_zsh_config
```

---

**文档维护**: 定期更新模板和文档
**社区贡献**: 欢迎提交 PR 和 Issue
**技术支持**: 查看 GitHub Wiki 或提交 Issue