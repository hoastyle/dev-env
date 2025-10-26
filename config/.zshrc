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
# Environment Variables & Colors
# ===============================================

# Basic environment
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=vim

# Color support for terminal commands (Cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Use GNU coreutils if available (better colors), otherwise BSD ls
    export CLICOLOR=1
    export LSCOLORS=GxFxCxDxBxegedabagaced

    if command -v gls >/dev/null 2>&1; then
        # Prefer GNU ls (gls) for consistent colors across platforms
        alias ls='gls --color=auto'
        # Enhanced LS_COLORS with 70+ file types for development
        export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33;1:cd=1;33;1:su=0;41:sg=0;46:tw=0;42:ow=0;43:'\
'*.tar=1;31:*.tgz=1;31:*.zip=1;31:*.gz=1;31:*.bz2=1;31:*.7z=1;31:*.rar=1;31:*.deb=1;31:*.rpm=1;31:'\
'*.jpg=1;35:*.jpeg=1;35:*.png=1;35:*.gif=1;35:*.svg=1;35:*.webp=1;35:*.ico=1;35:'\
'*.mp3=1;36:*.mp4=1;36:*.avi=1;36:*.mkv=1;36:*.wav=1;36:*.flac=1;36:'\
'*.pdf=1;33:*.doc=1;33:*.docx=1;33:*.ppt=1;33:*.pptx=1;33:*.xls=1;33:*.xlsx=1;33:'\
'*.py=1;33:*.js=1;33:*.ts=1;33:*.jsx=1;33:*.tsx=1;33:*.go=1;33:*.rs=1;33:*.java=1;33:*.c=1;33:*.cpp=1;33:*.h=1;33:*.hpp=1;33:*.cs=1;33:*.php=1;33:*.rb=1;33:*.swift=1;33:*.kt=1;33:*.scala=1;33:'\
'*.sh=1;32:*.bash=1;32:*.zsh=1;32:*.fish=1;32:*.vim=1;32:'\
'*.json=1;33:*.yaml=1;33:*.yml=1;33:*.toml=1;33:*.xml=1;33:*.html=1;33:*.css=1;33:*.scss=1;33:*.sass=1;33:'\
'*.md=1;37:*.txt=1;37:*.rst=1;37:*.org=1;37:'\
'*.log=0;37:*.out=0;37:'\
'*.conf=1;33:*.config=1;33:*.ini=1;33:*.cfg=1;33:'\
'*Dockerfile=1;36:*.dockerfile=1;36:*Makefile=1;36:*.mk=1;36:'\
'*.sql=1;33:*.db=1;35:*.sqlite=1;35:*.sqlite3=1;35:'\
'*.lock=0;90:*.bak=0;90:*.tmp=0;90:*.temp=0;90:*.swp=0;90:*.swo=0;90:*~=0;90:'\
'*.git=0;90:*.gitignore=0;90:*.gitmodules=0;90:*.gitattributes=0;90:'\
'*.env=1;31:*.key=1;31:*.pem=1;31:*.crt=1;31:*.cer=1;31:*.p12=1;31:'\
'*.dmg=1;31:*.iso=1;31:*.img=1;31:'\
'*.app=1;32:*.exe=1;32:*.msi=1;32:*.bat=1;32:*.cmd=1;32:'
    else
        # Fallback to macOS BSD ls with -G flag
        alias ls='ls -G'
    fi
else
    # Linux: Use GNU ls (default on Linux)
    alias ls='ls --color=auto'
    # Enhanced LS_COLORS with 70+ file types for development
    export LS_COLORS='di=1;34:ln=1;36:so=1;35:pi=1;33:ex=1;32:bd=1;33;1:cd=1;33;1:su=0;41:sg=0;46:tw=0;42:ow=0;43:'\
'*.tar=1;31:*.tgz=1;31:*.zip=1;31:*.gz=1;31:*.bz2=1;31:*.7z=1;31:*.rar=1;31:*.deb=1;31:*.rpm=1;31:'\
'*.jpg=1;35:*.jpeg=1;35:*.png=1;35:*.gif=1;35:*.svg=1;35:*.webp=1;35:*.ico=1;35:'\
'*.mp3=1;36:*.mp4=1;36:*.avi=1;36:*.mkv=1;36:*.wav=1;36:*.flac=1;36:'\
'*.pdf=1;33:*.doc=1;33:*.docx=1;33:*.ppt=1;33:*.pptx=1;33:*.xls=1;33:*.xlsx=1;33:'\
'*.py=1;33:*.js=1;33:*.ts=1;33:*.jsx=1;33:*.tsx=1;33:*.go=1;33:*.rs=1;33:*.java=1;33:*.c=1;33:*.cpp=1;33:*.h=1;33:*.hpp=1;33:*.cs=1;33:*.php=1;33:*.rb=1;33:*.swift=1;33:*.kt=1;33:*.scala=1;33:'\
'*.sh=1;32:*.bash=1;32:*.zsh=1;32:*.fish=1;32:*.vim=1;32:'\
'*.json=1;33:*.yaml=1;33:*.yml=1;33:*.toml=1;33:*.xml=1;33:*.html=1;33:*.css=1;33:*.scss=1;33:*.sass=1;33:'\
'*.md=1;37:*.txt=1;37:*.rst=1;37:*.org=1;37:'\
'*.log=0;37:*.out=0;37:'\
'*.conf=1;33:*.config=1;33:*.ini=1;33:*.cfg=1;33:'\
'*Dockerfile=1;36:*.dockerfile=1;36:*Makefile=1;36:*.mk=1;36:'\
'*.sql=1;33:*.db=1;35:*.sqlite=1;35:*.sqlite3=1;35:'\
'*.lock=0;90:*.bak=0;90:*.tmp=0;90:*.temp=0;90:*.swp=0;90:*.swo=0;90:*~=0;90:'\
'*.git=0;90:*.gitignore=0;90:*.gitmodules=0;90:*.gitattributes=0;90:'\
'*.env=1;31:*.key=1;31:*.pem=1;31:*.crt=1;31:*.cer=1;31:*.p12=1;31:'\
'*.dmg=1;31:*.iso=1;31:*.img=1;31:'\
'*.app=1;32:*.exe=1;32:*.msi=1;32:*.bat=1;32:*.cmd=1;32:'
fi

# ===============================================
# Python Environment
# ===============================================

# Use Python 3 by default
alias python=python3
alias pip=pip3

# Conda Environment (Cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - check for miniforge3 or anaconda3
    CONDA_PREFIX="$HOME/Software/miniforge3"
    if [[ ! -d "$CONDA_PREFIX" ]]; then
        CONDA_PREFIX="$HOME/anaconda3"
    fi
    if [[ ! -d "$CONDA_PREFIX" ]]; then
        CONDA_PREFIX="$HOME/miniforge3"
    fi
else
    # Linux - default to anaconda3
    CONDA_PREFIX="$HOME/anaconda3"
fi

# Try to initialize conda
__conda_setup="$(CONDA_REPORT_ERRORS=false "$CONDA_PREFIX/bin/conda" shell.zsh hook 2> /dev/null)"
if [ $? -eq 0 ]; then
    \eval "$__conda_setup"
else
    if [ -f "$CONDA_PREFIX/etc/profile.d/conda.sh" ]; then
        . "$CONDA_PREFIX/etc/profile.d/conda.sh"
        CONDA_CHANGEPS1=false conda activate base
    else
        \export PATH="$CONDA_PREFIX/bin:$PATH"
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

# FZF Configuration (Cross-platform)
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --hidden --follow -E ".git" -E "node_modules" . "$HOME"'
elif command -v fdfind &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fdfind --hidden --follow -E ".git" -E "node_modules" . "$HOME"'
else
    export FZF_DEFAULT_COMMAND='find "$HOME" -name ".git" -prune -o -name "node_modules" -prune -o -type f -print'
fi

export FZF_DEFAULT_OPTS='--height 90% --layout=reverse --bind=alt-j:down,alt-k:up,alt-i:toggle+down --border --preview "echo {} | ~/.fzf/fzf_preview.py" --preview-window=down'

# FZF Completion Functions (Cross-platform)
_fzf_compgen_path() {
  # Use fd on macOS, fdfind on Linux, fallback to find
  if command -v fd &> /dev/null; then
    fd --hidden --follow -E ".git" -E "node_modules" . "$HOME"
  elif command -v fdfind &> /dev/null; then
    fdfind --hidden --follow -E ".git" -E "node_modules" . "$HOME"
  else
    find "$HOME" -name ".git" -prune -o -name "node_modules" -prune -o -type f -print
  fi
}

_fzf_compgen_dir() {
  # Use fd on macOS, fdfind on Linux, fallback to find
  if command -v fd &> /dev/null; then
    fd --type d --hidden --follow -E ".git" -E "node_modules" . "$HOME"
  elif command -v fdfind &> /dev/null; then
    fdfind --type d --hidden --follow -E ".git" -E "node_modules" . "$HOME"
  else
    find "$HOME" -name ".git" -prune -o -name "node_modules" -prune -o -type d -print
  fi
}

# ===============================================
# Development Tools
# ===============================================

# Search Tools and Network Proxy functions are loaded from ~/.zsh/functions/

# CUDA & TensorRT (Cross-platform)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - Apple Silicon or Intel
    if [[ -d "/opt/homebrew/cuda" ]]; then
        # Apple Silicon
        export CUDA_HOME="/opt/homebrew/cuda"
    elif [[ -d "/usr/local/cuda" ]]; then
        # Intel
        export CUDA_HOME="/usr/local/cuda"
    fi

    if [[ -n "$CUDA_HOME" && -d "$CUDA_HOME" ]]; then
        export PATH="$CUDA_HOME/bin:$PATH"
        export DYLD_LIBRARY_PATH="$CUDA_HOME/lib:$DYLD_LIBRARY_PATH"
    fi
else
    # Linux
    if [[ -d "/usr/local/cuda-11.1" ]]; then
        export CUDA_HOME="/usr/local/cuda-11.1"
        export LD_LIBRARY_PATH="/usr/local/cuda-11.1/lib64/:/usr/local/TensorRT/targets/x86_64-linux-gnu/lib/:$LD_LIBRARY_PATH"
        export PATH="/usr/local/cuda-11.1/bin/:$PATH"
    elif [[ -d "/usr/local/cuda" ]]; then
        export CUDA_HOME="/usr/local/cuda"
        export LD_LIBRARY_PATH="/usr/local/cuda/lib64:$LD_LIBRARY_PATH"
        export PATH="/usr/local/cuda/bin:$PATH"
    fi
fi

# ===============================================
# Autojump Configuration
# ===============================================
# Fast directory jumping with autojump
# Install: brew install autojump (macOS) OR apt-get install autojump (Linux)
#
# HOW AUTOJUMP WORKS:
# - As you navigate directories, autojump builds a database of your most visited paths
# - Use 'j <partial-name>' to jump to frequently visited directories
# - Example: After visiting ~/Software/dev_utility several times, you can use 'j dev' to jump there
# - The database builds automatically as you cd into directories

# Remove any existing j aliases that could conflict with autojump's function
unalias j jhistory 2>/dev/null || true

# Directly source the autojump shell integration for the current platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: Try Homebrew installation paths
    if [[ -f "/opt/homebrew/etc/profile.d/autojump.sh" ]]; then
        source "/opt/homebrew/etc/profile.d/autojump.sh"
    elif [[ -f "/usr/local/etc/profile.d/autojump.sh" ]]; then
        source "/usr/local/etc/profile.d/autojump.sh"
    fi
else
    # Linux: Try standard installation paths
    if [[ -f "/usr/share/autojump/autojump.sh" ]]; then
        source "/usr/share/autojump/autojump.sh"
    elif [[ -f "$HOME/.autojump/etc/profile.d/autojump.sh" ]]; then
        source "$HOME/.autojump/etc/profile.d/autojump.sh"
    fi
fi

# Verify autojump is properly loaded, otherwise provide helpful fallback
if ! typeset -f j &>/dev/null; then
    if command -v autojump &>/dev/null; then
        # Autojump binary exists but shell integration failed - provide basic alias
        alias j='autojump'
        alias jhistory='autojump -s'
        echo "⚠️  Note: Autojump shell integration not loaded. Directory tracking may not work." >&2
        echo "   Try: exec zsh" >&2
    else
        # Autojump not installed - provide informative error function
        j() {
            echo "❌ autojump is not installed" >&2
            echo "   macOS: brew install autojump" >&2
            echo "   Linux: apt-get install autojump" >&2
            return 1
        }
    fi
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
# Platform-Specific Configurations
# ===============================================

# iTerm2 Shell Integration (macOS only)
if [[ "$OSTYPE" == "darwin"* ]] && [[ -f "${HOME}/.iterm2_shell_integration.zsh" ]]; then
    source "${HOME}/.iterm2_shell_integration.zsh"
fi

# Point Cloud Tools (if pcl_viewer is available)
if command -v pcl_viewer &> /dev/null; then
    alias pm="pcl_viewer -use_point_picking -ax 4 -multiview 1"
    alias pa="pcl_viewer -ax 4 -use_point_picking"
fi

# Platform-specific PATH additions
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS-specific paths
    if [[ -d "/opt/homebrew/opt/qt@5/bin" ]]; then
        export PATH="/opt/homebrew/opt/qt@5/bin:$PATH"
    fi
    if [[ -d "/opt/homebrew/Cellar/pcl" ]]; then
        # Find PCL viewer app and add to PATH if exists
        local pcl_path=$(find /opt/homebrew/Cellar/pcl -name "pcl_viewer.app" 2>/dev/null | head -1)
        if [[ -n "$pcl_path" && -d "$pcl_path/Contents/MacOS" ]]; then
            export PATH="$pcl_path/Contents/MacOS:$PATH"
        fi
    fi
else
    # Linux-specific paths can be added here
    :
fi

# Google Cloud Project (if gcloud is available)
if command -v gcloud &> /dev/null; then
    export GOOGLE_CLOUD_PROJECT="gen-lang-client-0165913056"
fi

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
