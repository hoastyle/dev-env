#!/usr/bin/env zsh
# ===============================================
# Utility Functions
# ===============================================

# ===============================================
# 代理配置管理 - Proxy Configuration Management
# ===============================================

# 代理配置文件位置
_PROXY_CONFIG_FILE="${HOME}/.proxy_config"
_PROXY_DEFAULT_PORT=7890
_PROXY_DEFAULT_HOST="127.0.0.1"

# 初始化代理配置文件
_init_proxy_config() {
    if [[ ! -f "$_PROXY_CONFIG_FILE" ]]; then
        mkdir -p "$(dirname "$_PROXY_CONFIG_FILE")"
        cat > "$_PROXY_CONFIG_FILE" << 'EOF'
# Proxy Configuration File
# Format: PROXY_HOST:PROXY_PORT
# Example: 127.0.0.1:7890

# Default proxy address (Clash, v2ray, etc.)
PROXY_ADDRESS=127.0.0.1:7890

# No proxy list (comma-separated)
NO_PROXY_LIST=localhost,127.0.0.1,.local,*.local

# Proxy timeout (seconds)
PROXY_TIMEOUT=3
EOF
        chmod 600 "$_PROXY_CONFIG_FILE"
    fi
}

# 读取代理配置
_get_proxy_config() {
    _init_proxy_config

    local proxy_address="$_PROXY_DEFAULT_HOST:$_PROXY_DEFAULT_PORT"
    local no_proxy_list="localhost,127.0.0.1,.local,*.local"

    if [[ -f "$_PROXY_CONFIG_FILE" ]]; then
        proxy_address=$(grep -E "^PROXY_ADDRESS=" "$_PROXY_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "$proxy_address")
        no_proxy_list=$(grep -E "^NO_PROXY_LIST=" "$_PROXY_CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 || echo "$no_proxy_list")
    fi

    echo "$proxy_address|$no_proxy_list"
}

# 检查代理是否启用
check_proxy() {
    local proxy_status_show="${1:---status}"

    if handle_help_param "check_proxy" "$1"; then
        return 0
    fi

    local is_enabled=false

    # 检查是否设置了代理环境变量
    if [[ -n "$http_proxy" || -n "$HTTP_PROXY" || -n "$all_proxy" || -n "$ALL_PROXY" ]]; then
        is_enabled=true
    fi

    if $is_enabled; then
        echo "✅ 代理已启用"
        if [[ "$proxy_status_show" == "--status" || "$proxy_status_show" == "-s" ]]; then
            proxy_status
        fi
        return 0
    else
        echo "❌ 代理未启用"
        return 1
    fi
}

# 显示代理状态
proxy_status() {
    if handle_help_param "proxy_status" "$1"; then
        return 0
    fi

    local config_info=$(_get_proxy_config)
    local proxy_addr="${config_info%|*}"
    local no_proxy="${config_info#*|}"

    echo ""
    echo "📊 代理状态信息："
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # 检查代理是否启用
    if [[ -n "$http_proxy" ]]; then
        echo "🟢 代理状态: 已启用"
        echo "   http_proxy: ${http_proxy}"
        echo "   https_proxy: ${https_proxy:-未设置}"
        echo "   all_proxy: ${all_proxy:-未设置}"
    else
        echo "🔴 代理状态: 未启用"
    fi

    echo ""
    echo "⚙️  默认配置:"
    echo "   代理地址: $proxy_addr"
    echo "   NO_PROXY: $no_proxy"

    # 检查代理服务是否可用
    echo ""
    echo "🔍 代理服务可用性检测:"
    _check_proxy_availability "$proxy_addr"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# 检查代理服务是否可用
_check_proxy_availability() {
    local proxy_addr="$1"
    local host="${proxy_addr%:*}"
    local port="${proxy_addr#*:}"
    local timeout=3

    # 尝试连接到代理服务
    if command -v timeout &> /dev/null; then
        timeout $timeout bash -c "echo > /dev/tcp/$host/$port" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            echo "   ✅ $host:$port 连接正常"
        else
            echo "   ⚠️  $host:$port 连接超时或拒绝"
        fi
    else
        echo "   ⏸️  跳过可用性检测 (timeout 命令不可用)"
    fi
}

# 网络代理设置 (优化版)
# Network proxy configuration (optimized)
proxy() {
    if handle_help_param "proxy" "$1"; then
        return 0
    fi

    # 支持自定义代理地址参数
    local proxy_target="${1:-}"
    local config_info=$(_get_proxy_config)
    local proxy_addr="${proxy_target:-${config_info%|*}}"
    local no_proxy="${config_info#*|}"

    # 验证代理地址格式
    if ! assert_pattern "$proxy_addr" "^[0-9a-zA-Z.-]+:[0-9]+$" "proxy_address"; then
        print_usage "proxy" 'proxy [host:port] [--verify]' 'proxy' 'proxy 127.0.0.1:7890' 'proxy 127.0.0.1:7890 -v'
        return 1
    fi

    local host="${proxy_addr%:*}"
    local port="${proxy_addr#*:}"

    # 设置代理环境变量 (统一使用http://前缀)
    export http_proxy="http://$proxy_addr"
    export https_proxy="http://$proxy_addr"
    export all_proxy="http://$proxy_addr"
    export ftp_proxy="http://$proxy_addr"

    # 大写版本
    export HTTP_PROXY="http://$proxy_addr"
    export HTTPS_PROXY="http://$proxy_addr"
    export ALL_PROXY="http://$proxy_addr"
    export FTP_PROXY="http://$proxy_addr"

    # 正确设置 NO_PROXY (排除不需要代理的域名/IP)
    export NO_PROXY="$no_proxy"
    export no_proxy="$no_proxy"

    success_msg "代理已启用"
    echo "   地址: http://$proxy_addr"
    echo "   NO_PROXY: $no_proxy"

    # 可选: 验证代理连接
    if [[ "$2" == "--verify" || "$2" == "-v" ]]; then
        echo ""
        _check_proxy_availability "$proxy_addr"
    fi
}

# 禁用网络代理 (优化版)
# Disable network proxy (optimized)
unproxy() {
    if handle_help_param "unproxy" "$1"; then
        return 0
    fi

    # 清除所有代理相关环境变量
    local proxy_vars=(
        http_proxy https_proxy all_proxy ftp_proxy
        HTTP_PROXY HTTPS_PROXY ALL_PROXY FTP_PROXY
        no_proxy NO_PROXY
    )

    for var in "${proxy_vars[@]}"; do
        unset $var
    done

    info_msg "代理已禁用"
}

# Fast directory jump function with autojump support
# 快速目录跳转函数 (支持 autojump)
# ===============================================

jdev() {
    # Handle help parameter
    if handle_help_param "jdev" "$1"; then
        cat << 'EOF'
USAGE: jdev <directory_name>
DESCRIPTION: Jump to frequently used development directory using autojump history

ARGUMENTS:
    <directory_name>  Directory name or pattern to jump to

EXAMPLES:
    jdev workspace    # Jump to workspace directory
    jdev projects     # Jump to projects directory
    jdev dev          # Jump to dev directory

REQUIREMENTS:
    - autojump must be installed
    - You must have previously visited the target directory

INSTALLATION:
    Ubuntu/Debian: apt-get install autojump
    macOS:         brew install autojump

NOTES:
    - After installation, run: exec zsh
    - Use 'j' command for direct autojump access
    - Use 'jhistory' to see autojump history
EOF
        return 0
    fi

    # Check if autojump is available
    if ! command -v autojump &> /dev/null; then
        error_msg "autojump is not installed"
        echo "Install with: apt-get install autojump (Ubuntu/Debian) or brew install autojump (macOS)"
        return 1
    fi

    # Validate required parameter
    if ! assert_param "$1" "directory_name"; then
        print_usage "jdev" 'jdev <directory_name>' 'jdev workspace' 'jdev projects'
        echo ""
        info_msg "Tip: First use autojump to visit a directory to record it in history"
        return 1
    fi

    local dir_name="$1"
    local target_dir=$(autojump "$dir_name" 2>/dev/null)

    # Check if directory was found in autojump history
    if [[ -z "$target_dir" ]] || [[ ! -d "$target_dir" ]]; then
        warning_msg "Directory '$dir_name' not found in autojump history"
        echo ""
        echo "You can:"
        echo "  1. Visit the directory first: cd /path/to/$dir_name"
        echo "  2. Then use: jdev $dir_name"
        echo "  3. Or view history: jhistory"
        return 1
    fi

    # Jump to directory
    cd "$target_dir"
    success_msg "Jumped to: $target_dir"
}

# ===============================================
# Lazy Loading Functions (Cross-platform)
# ===============================================

# Lazy load Autojump (Cross-platform)
autojump-lazy() {
    # Handle help parameter
    if handle_help_param "autojump-lazy" "$1"; then
        cat << 'EOF'
USAGE: autojump-lazy
DESCRIPTION: Load Autojump dynamically (useful in minimal mode)

This function loads Autojump and its shell integration, enabling:
- j command for directory jumping
- jdev command for development directory jumping
- autojump statistics and history

PLATFORMS:
- macOS: Loads from Homebrew or default paths
- Linux: Loads from system package manager paths

EXAMPLES:
    autojump-lazy && j workspace    # Load autojump then jump
    autojump-lazy && jdev dev       # Load autojump then use jdev

NOTES:
    Use this in minimal mode when autojump isn't automatically loaded
    After running once, autojump remains available for the session
EOF
        return 0
    fi

    # Check if autojump is already loaded
    if command -v autojump &> /dev/null; then
        info_msg "Autojump is already loaded"
        return 0
    fi

    # Try to load autojump based on platform
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - try multiple possible locations
        local autojump_paths=(
            "/opt/homebrew/etc/profile.d/autojump.sh"
            "/usr/local/etc/profile.d/autojump.sh"
            "$HOME/.autojump/etc/profile.d/autojump.sh"
        )

        for path in "${autojump_paths[@]}"; do
            if [[ -f "$path" ]]; then
                source "$path"
                success_msg "Autojump loaded from: $path"
                return 0
            fi
        done

        # Try homebrew package
        if command -v brew &> /dev/null && brew list autojump &> /dev/null; then
            local brew_prefix=$(brew --prefix)
            if [[ -f "$brew_prefix/etc/profile.d/autojump.sh" ]]; then
                source "$brew_prefix/etc/profile.d/autojump.sh"
                success_msg "Autojump loaded from Homebrew"
                return 0
            fi
        fi
    else
        # Linux - try system paths
        local autojump_paths=(
            "/usr/share/autojump/autojump.sh"
            "/etc/profile.d/autojump.sh"
            "$HOME/.autojump/etc/profile.d/autojump.sh"
        )

        for path in "${autojump_paths[@]}"; do
            if [[ -f "$path" ]]; then
                source "$path"
                success_msg "Autojump loaded from: $path"
                return 0
            fi
        done
    fi

    # If we reach here, autojump installation wasn't found
    error_msg "Autojump installation not found"
    echo ""
    echo "Install Autojump:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "  brew install autojump"
    else
        echo "  Ubuntu/Debian: sudo apt-get install autojump"
        echo "  Fedora: sudo dnf install autojump"
        echo "  Arch: sudo pacman -S autojump"
    fi
    echo ""
    echo "After installation, run: exec zsh"
    return 1
}

# Lazy load NVM (Cross-platform)
nvm-lazy() {
    # Handle help parameter
    if handle_help_param "nvm-lazy" "$1"; then
        cat << 'EOF'
USAGE: nvm-lazy
DESCRIPTION: Load NVM and Node.js environment dynamically

This function loads Node Version Manager (NVM) and enables:
- node command
- npm command
- nvm commands for version management
- npm tab completion

PLATFORMS:
- macOS: Loads from standard NVM installation paths
- Linux: Loads from standard NVM installation paths

EXAMPLES:
    nvm-lazy && node -v         # Load NVM then check Node version
    nvm-lazy && nvm use 18      # Load NVM then use Node 18

NOTES:
    Use this in minimal mode when NVM isn't automatically loaded
    After running once, NVM remains available for the session
EOF
        return 0
    fi

    # Check if NVM is already loaded
    if command -v nvm &> /dev/null; then
        info_msg "NVM is already loaded"
        return 0
    fi

    # Try to load NVM
    local nvm_dir="$HOME/.nvm"
    if [[ -d "$nvm_dir" ]]; then
        export NVM_DIR="$nvm_dir"

        # Load NVM
        if [[ -f "$nvm_dir/nvm.sh" ]]; then
            source "$nvm_dir/nvm.sh"

            # Load completion if available
            if [[ -f "$nvm_dir/bash_completion" ]]; then
                source "$nvm_dir/bash_completion"
            fi

            success_msg "NVM loaded successfully"

            # Show current Node version if available
            if command -v node &> /dev/null; then
                local node_version=$(node --version)
                info_msg "Current Node.js version: $node_version"
            else
                info_msg "No Node.js version installed. Use 'nvm install <version>' to install."
            fi

            return 0
        fi
    fi

    error_msg "NVM installation not found"
    echo ""
    echo "Install NVM:"
    echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
    echo ""
    echo "After installation, run: exec zsh"
    return 1
}

# Lazy load Conda (Cross-platform)
conda-init() {
    # Handle help parameter
    if handle_help_param "conda-init" "$1"; then
        cat << 'EOF'
USAGE: conda-init
DESCRIPTION: Initialize Conda environment dynamically

This function initializes Conda (Miniconda/Anaconda) and enables:
- conda command
- environment management
- package management

PLATFORMS:
- macOS: Detects Miniconda3/Anaconda3 in common locations
- Linux: Detects Miniconda3/Anaconda3 in standard locations

EXAMPLES:
    conda-init && conda info       # Initialize conda then show info
    conda-init && conda env list   # Initialize conda then list environments

NOTES:
    Use this in minimal mode when Conda isn't automatically loaded
    After running once, Conda remains available for the session
EOF
        return 0
    fi

    # Check if conda is already available
    if command -v conda &> /dev/null; then
        info_msg "Conda is already loaded"
        return 0
    fi

    # Try to find and initialize conda
    local conda_prefix=""

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - check common locations
        local conda_paths=(
            "$HOME/Software/miniforge3"
            "$HOME/anaconda3"
            "$HOME/miniforge3"
            "/opt/miniforge3"
            "/opt/anaconda3"
        )
    else
        # Linux - check common locations
        local conda_paths=(
            "$HOME/anaconda3"
            "$HOME/miniconda3"
            "/opt/anaconda3"
            "/opt/miniconda3"
        )
    fi

    for path in "${conda_paths[@]}"; do
        if [[ -d "$path" ]]; then
            conda_prefix="$path"
            break
        fi
    done

    if [[ -n "$conda_prefix" ]]; then
        # Initialize conda
        if [[ -f "$conda_prefix/etc/profile.d/conda.sh" ]]; then
            source "$conda_prefix/etc/profile.d/conda.sh"
            success_msg "Conda initialized from: $conda_prefix"

            # Show conda info
            if command -v conda &> /dev/null; then
                info_msg "Conda version: $(conda --version 2>/dev/null | cut -d' ' -f2-)"
                echo "Current environment: $CONDA_DEFAULT_ENV"
            fi

            return 0
        fi
    fi

    error_msg "Conda installation not found"
    echo ""
    echo "Install Conda:"
    echo "  Miniconda: https://docs.conda.io/en/latest/miniconda.html"
    echo "  Anaconda: https://www.anaconda.com/products/distribution"
    echo ""
    echo "After installation, run: exec zsh"
    return 1
}
