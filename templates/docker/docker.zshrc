# ===============================================
# ZSH Configuration Template - Docker Container Environment
# ===============================================
# Template: docker
# Description: Optimized for Docker containers with minimal overhead
# Use Case: Docker containers, CI/CD pipelines, ephemeral environments
# Startup Time: ~5-20ms
# ===============================================

# ===============================================
# Docker Environment Detection
# ===============================================

# Set environment marker
export DOCKER_ENV=true

# Detect if running in container
if [[ -f /.dockerenv ]] || grep -q 'docker\|lxc' /proc/1/cgroup 2>/dev/null; then
    export IN_CONTAINER=true
else
    export IN_CONTAINER=false
fi

# ===============================================
# Ultra-Minimal Prompt
# ===============================================

# Absolute minimal prompt for containers
PROMPT="container:%~%# "

# Or even simpler:
# PROMPT="> "

# ===============================================
# Container-Optimized Environment
# ===============================================

# Fast locale
export LC_ALL=C

# Minimal PATH
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Disable unnecessary features
setopt NO_BEEP
setopt NO_GLOBAL_RCS
setopt NO_RCS

# ===============================================
# Essential Aliases
# ===============================================

# Basic file operations
alias ll='ls -alF'
alias l='ls -CF'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

alias python=python3
alias pip=pip3

# ===============================================
# CI/CD Friendly Functions
# ===============================================

# Exit with clear error message
die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Check if command exists
require() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Print environment info (useful for debugging)
env-info() {
    echo "=== Container Environment Info ==="
    echo "In Container: $IN_CONTAINER"
    echo "User: $(whoami)"
    echo "UID: $(id -u)"
    echo "GID: $(id -g)"
    echo "Home: $HOME"
    echo "Shell: $SHELL"
    echo "Path: $PATH"
    echo "Python: $(python --version 2>&1)"
    echo "Node: $(node --version 2>&1)"
    echo ""
}

# ===============================================
# Development Tool Aliases (if available)
# ===============================================

# Git shortcuts
if command -v git &>/dev/null; then
    alias g='git'
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git pull'
    alias gd='git diff'
    alias gb='git branch'
    alias gco='git checkout'
fi

# npm shortcuts
if command -v npm &>/dev/null; then
    alias ni='npm install'
    alias nr='npm run'
    alias ns='npm start'
    alias nt='npm test'
    alias nb='npm run build'
fi

# pip shortcuts
if command -v pip &>/dev/null; then
    alias pi='pip install'
    alias pl='pip list'
    alias pf='pip freeze'
fi

# ===============================================
# Container-Specific Utilities
# ===============================================

# Quick package installation hints
install-hints() {
    echo "=== Package Installation Hints ==="
    echo "Python: pip install <package>"
    echo "Node: npm install -g <package>"
    echo "APT (if available): apt-get update && apt-get install <package>"
    echo "YUM (if available): yum install <package>"
    echo ""
}

# Show container resource usage
container-resources() {
    if [[ -f /sys/fs/cgroup/memory.max ]] 2>/dev/null; then
        echo "=== Memory Limits (cgroup v2) ==="
        cat /sys/fs/cgroup/memory.max 2>/dev/null || echo "Not available"
    elif [[ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]] 2>/dev/null; then
        echo "=== Memory Limits (cgroup v1) ==="
        cat /sys/fs/cgroup/memory/memory.limit_in_bytes 2>/dev/null || echo "Not available"
    fi

    if [[ -f /sys/fs/cgroup/cpu.max ]] 2>/dev/null; then
        echo "=== CPU Limits (cgroup v2) ==="
        cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo "Not available"
    elif [[ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ]] 2>/dev/null; then
        echo "=== CPU Limits (cgroup v1) ==="
        cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us 2>/dev/null || echo "Not available"
    fi
}

# ===============================================
# Wait for service utility
# ===============================================

wait-for-service() {
    local host="$1"
    local port="${2:-80}"
    local timeout="${3:-30}"

    echo "Waiting for $host:$port (timeout: ${timeout}s)..."

    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if timeout 1 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
            echo "Service $host:$port is available!"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    echo "ERROR: Service $host:$port not available after ${timeout}s"
    return 1
}

# ===============================================
# No completion for fastest startup
# ===============================================

# Comment out the following to enable completion
# autoload -Uz compinit
# compinit -u

# ===============================================
# Optional: Load user functions from mounted volume
# ===============================================

if [[ -d /workspace/.zsh/functions ]]; then
    for f in /workspace/.zsh/functions/*.zsh; do
        [[ -f "$f" ]] && source "$f"
    done
fi

# ===============================================
# Optional: Environment-specific configuration
# ===============================================

if [[ -f /.docker-env ]]; then
    source /.docker-env
fi

# ===============================================
# Fast exit on error for CI/CD
# ===============================================

# Uncomment for CI/CD pipelines
# set -e
# set -o pipefail

# ===============================================
# Container startup message (optional)
# ===============================================

# Uncomment to show on login
# echo "🐳 Docker Container Environment Ready"
# env-info
