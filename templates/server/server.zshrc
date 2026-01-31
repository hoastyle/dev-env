# ===============================================
# ZSH Configuration Template - Server/Production Environment
# ===============================================
# Template: server
# Description: Production server environment with stability and security focus
# Use Case: Production servers, minimal resource usage, enhanced logging
# Startup Time: ~20-50ms
# ===============================================

# ===============================================
# Security Settings
# ===============================================

# Disable history logging for sensitive operations
setopt HIST_IGNORE_SPACE
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS

# Limit history size
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history_server

# ===============================================
# Minimal Prompt for Server
# ===============================================

autoload -U colors && colors

# Simple hostname-based prompt with exit status
PROMPT="%{$fg_bold[green]%}%m%{$reset_color%}:%{$fg_bold[blue]%}%~%{$reset_color%}%# "
RPROMPT="%(?..%{$fg[red]%}[%?]%{$reset_color%})"

# ===============================================
# Server Environment Variables
# ===============================================

export EDITOR=vim
export VISUAL=vim
export PAGER=less

# Server locale
export LANG=C
export LC_ALL=C

# ===============================================
# Path Configuration
# ===============================================

# Add common server paths
typeset -U path
path=(
    /usr/local/sbin
    /usr/local/bin
    /usr/sbin
    /usr/bin
    /sbin
    /bin
    $path
)

# ===============================================
# Essential Aliases
# ===============================================

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# Listing aliases
alias ll='ls -alFh'
alias la='ls -A'
alias l='ls -CF'
alias lt='ls -alth'

# System monitoring
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ps='ps auxf'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'

# Service management
alias svc-status='systemctl status'
alias svc-start='systemctl start'
alias svc-stop='systemctl stop'
alias svc-restart='systemctl restart'
alias journal='journalctl -u'

# Log viewing shortcuts
alias syslog='sudo journalctl -f'
alias authlog='sudo journalctl -f -u ssh'

# ===============================================
# Server Utility Functions
# ===============================================

# View system resource usage
server-status() {
    echo "=== System Status ==="
    echo "Uptime: $(uptime)"
    echo ""
    echo "=== CPU Usage ==="
    top -bn1 | head -20
    echo ""
    echo "=== Memory Usage ==="
    free -h
    echo ""
    echo "=== Disk Usage ==="
    df -h
}

# View recent logins
recent-logins() {
    last | head -20
}

# Monitor specific process
watch-process() {
    if [[ -z "$1" ]]; then
        echo "Usage: watch-process <process_name>"
        return 1
    fi
    watch -n 1 "ps aux | grep -v grep | grep $1"
}

# Find large files in current directory
large-files() {
    local size="${1:-100M}"
    find . -type f -size +"$size" -exec ls -lh {} \; 2>/dev/null | awk '{print $5, $9}' | sort -rh | head -20
}

# Quick backup function
backup-file() {
    if [[ -z "$1" ]]; then
        echo "Usage: backup-file <file>"
        return 1
    fi
    local timestamp=$(date +%Y%m%d_%H%M%S)
    cp -i "$1" "$1.backup_$timestamp"
    echo "Backed up $1 to $1.backup_$timestamp"
}

# ===============================================
# Docker Helper Functions (if Docker available)
# ===============================================

if command -v docker &>/dev/null; then
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlog='docker logs -f'

    # Docker container resource usage
    dstats() {
        if [[ -n "$1" ]]; then
            docker stats "$1" --no-stream
        else
            docker stats --no-stream
        fi
    }
fi

# ===============================================
# Systemd Helper Functions
# ===============================================

# Check if service is active
is-active() {
    if [[ -z "$1" ]]; then
        echo "Usage: is-active <service_name>"
        return 1
    fi
    systemctl is-active "$1"
}

# List failed services
failed-services() {
    systemctl list-units --state=failed
}

# ===============================================
# Network Diagnostics
# ===============================================

# Check listening ports
listening-ports() {
    if command -v ss &>/dev/null; then
        sudo ss -tulpn
    elif command -v netstat &>/dev/null; then
        sudo netstat -tulpn
    else
        echo "Neither ss nor netstat available"
        return 1
    fi
}

# Test connection to host
test-connection() {
    if [[ -z "$1" ]]; then
        echo "Usage: test-connection <host> [port]"
        return 1
    fi
    local host="$1"
    local port="${2:-80}"
    timeout 5 bash -c "cat < /dev/null > /dev/tcp/$host/$port" && echo "Connected to $host:$port" || echo "Failed to connect to $host:$port"
}

# ===============================================
# Security Utilities
# ===============================================

# Check for suspicious cron jobs
check-cron() {
    echo "=== Root Crontab ==="
    sudo crontab -l 2>/dev/null || echo "No root crontab"
    echo ""
    echo "=== User Crontab ==="
    crontab -l 2>/dev/null || echo "No user crontab"
    echo ""
    echo "=== System Cron Dirs ==="
    ls -la /etc/cron.* 2>/dev/null || echo "No system cron dirs"
}

# View active SSH sessions
active-ssh() {
    who -u
}

# ===============================================
# Minimal Completion
# ===============================================

autoload -Uz compinit
compinit -u

# Basic completion style
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ===============================================
# Performance Optimization
# ===============================================

# Disable unnecessary features
setopt NO_BEEP
setopt NO_CASE_GLOB

# ===============================================
# Welcome Message
# ===============================================

# Show system status on login
# Comment out to disable
# server-status
