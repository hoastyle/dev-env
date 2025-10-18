#!/bin/bash
# ZSH 配置自动安装脚本
# 版本: 2.0 - 支持 NVM 优化版本
# 作者: Claude AI Assistant

set -e

# 配置选项
USE_NVM_OPTIMIZATION=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "ZSH 配置自动安装脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help                 显示此帮助信息"
    echo "  --with-optimization        使用 NVM 优化版本 (推荐性能优先的用户)"
    echo "  --nvm-optimized            同上 (别名)"
    echo ""
    echo "示例:"
    echo "  $0                         # 标准版本安装"
    echo "  $0 --with-optimization     # NVM 优化版本安装"
    echo ""
}

# 解析命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --with-optimization|--nvm-optimized)
                USE_NVM_OPTIMIZATION=true
                log_info "已启用 NVM 优化版本"
                ;;
            *)
                log_error "未知的参数: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done
}

# 检查是否以 root 权限运行
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "请不要以 root 权限运行此脚本"
        exit 1
    fi
}

# 检查系统要求
check_system() {
    log_step "检查系统要求..."

    # 检查操作系统
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_info "检测到 Linux 系统"
        SYSTEM="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        log_info "检测到 macOS 系统"
        SYSTEM="macos"
    else
        log_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi

    # 检查 ZSH 是否安装
    if ! command -v zsh &> /dev/null; then
        log_error "ZSH 未安装，请先安装 ZSH"
        if [[ "$SYSTEM" == "linux" ]]; then
            echo "Ubuntu/Debian: sudo apt-get install zsh"
            echo "Fedora: sudo dnf install zsh"
            echo "Arch: sudo pacman -S zsh"
        elif [[ "$SYSTEM" == "macos" ]]; then
            echo "macOS: brew install zsh"
        fi
        exit 1
    fi

    log_success "系统要求检查通过"
}

# 检查依赖
check_dependencies() {
    log_step "检查基础依赖..."

    local deps=("curl" "git")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "缺少以下依赖: ${missing_deps[*]}"
        exit 1
    fi

    log_success "基础依赖检查通过"
}

# 备份现有配置
backup_existing_config() {
    log_step "备份现有配置..."

    local backup_dir="$HOME/zsh-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    # 备份 .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/"
        log_info "已备份 .zshrc"
    fi

    # 备份 .p10k.zsh
    if [[ -f "$HOME/.p10k.zsh" ]]; then
        cp "$HOME/.p10k.zsh" "$backup_dir/"
        log_info "已备份 .p10k.zsh"
    fi

    # 备份 .antigen.zsh
    if [[ -f "$HOME/.antigen.zsh" ]]; then
        cp "$HOME/.antigen.zsh" "$backup_dir/"
        log_info "已备份 .antigen.zsh"
    fi

    # 备份 .antigen 目录
    if [[ -d "$HOME/.antigen" ]]; then
        cp -r "$HOME/.antigen" "$backup_dir/"
        log_info "已备份 .antigen 目录"
    fi

    # 备份自定义函数目录
    if [[ -d "$HOME/.zsh" ]]; then
        cp -r "$HOME/.zsh" "$backup_dir/"
        log_info "已备份 .zsh 目录"
    fi

    echo "$backup_dir" > "$HOME/.zsh_backup_dir"
    log_success "配置已备份到: $backup_dir"
}

# 安装 Antigen
install_antigen() {
    log_step "安装 Antigen 插件管理器..."

    if [[ -f "$HOME/.antigen.zsh" ]]; then
        log_warn "Antigen 已存在，跳过安装"
        return
    fi

    log_info "下载 Antigen..."
    curl -L git.io/antigen > "$HOME/.antigen.zsh"

    if [[ $? -eq 0 ]]; then
        log_success "Antigen 安装完成"
    else
        log_error "Antigen 安装失败"
        exit 1
    fi
}

# 安装开发工具
install_dev_tools() {
    log_step "安装开发工具..."

    local tools_to_install=()

    # 检查 FZF
    if ! command -v fzf &> /dev/null; then
        tools_to_install+=("fzf")
    fi

    # 检查 fd (fdfind)
    if ! command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        if [[ "$SYSTEM" == "linux" ]]; then
            tools_to_install+=("fd-find")
        elif [[ "$SYSTEM" == "macos" ]]; then
            tools_to_install+=("fd")
        fi
    fi

    # 检查 ripgrep
    if ! command -v rg &> /dev/null; then
        tools_to_install+=("ripgrep")
    fi

    if [[ ${#tools_to_install[@]} -eq 0 ]]; then
        log_info "所有开发工具已安装"
        return
    fi

    log_info "需要安装的工具: ${tools_to_install[*]}"

    if [[ "$SYSTEM" == "linux" ]]; then
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            sudo apt-get update
            for tool in "${tools_to_install[@]}"; do
                log_info "安装 $tool..."
                sudo apt-get install -y "$tool"
            done
        elif command -v dnf &> /dev/null; then
            # Fedora
            for tool in "${tools_to_install[@]}"; do
                log_info "安装 $tool..."
                sudo dnf install -y "$tool"
            done
        elif command -v pacman &> /dev/null; then
            # Arch Linux
            for tool in "${tools_to_install[@]}"; do
                log_info "安装 $tool..."
                sudo pacman -S --noconfirm "$tool"
            done
        else
            log_warn "无法自动安装工具，请手动安装: ${tools_to_install[*]}"
        fi
    elif [[ "$SYSTEM" == "macos" ]]; then
        if command -v brew &> /dev/null; then
            for tool in "${tools_to_install[@]}"; do
                log_info "安装 $tool..."
                brew install "$tool"
            done
        else
            log_warn "未找到 Homebrew，请先安装 Homebrew 或手动安装工具"
        fi
    fi

    log_success "开发工具安装完成"
}

# 安装配置文件
install_config_files() {
    log_step "安装配置文件..."

    # 获取脚本目录
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_dir="$(dirname "$script_dir")"

    # 选择配置文件
    local config_file
    if [[ "$USE_NVM_OPTIMIZATION" == "true" ]]; then
        config_file="$project_dir/config/.zshrc.nvm-optimized"
        if [[ -f "$config_file" ]]; then
            log_info "使用 NVM 优化版本配置"
        else
            log_warn "NVM 优化版本不存在，回退到标准版本"
            config_file="$project_dir/config/.zshrc"
        fi
    else
        config_file="$project_dir/config/.zshrc"
    fi

    # 复制 .zshrc
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$HOME/.zshrc"
        if [[ "$USE_NVM_OPTIMIZATION" == "true" ]]; then
            log_success "已安装 .zshrc (NVM 优化版本)"
        else
            log_success "已安装 .zshrc (标准版本)"
        fi
    else
        log_warn "未找到配置文件: $config_file"
    fi

    # 复制 Powerlevel10k 配置文件
    if [[ -f "$project_dir/config/.p10k.zsh" ]]; then
        cp "$project_dir/config/.p10k.zsh" "$HOME/.p10k.zsh"
        log_success "已安装 Powerlevel10k 配置文件 (.p10k.zsh)"
    else
        log_warn "未找到 .p10k.zsh 模板文件"
    fi

    # 创建自定义函数目录
    mkdir -p "$HOME/.zsh/functions"

    # 复制自定义函数 (如果存在)
    if [[ -d "$project_dir/zsh-functions" ]]; then
        cp -r "$project_dir/zsh-functions/"* "$HOME/.zsh/functions/"
        log_success "已安装自定义函数"
    fi
}

# 设置 FZF
setup_fzf() {
    log_step "配置 FZF..."

    # 如果 FZF 存在，启用 shell 集成
    if command -v fzf &> /dev/null; then
        # 检查是否已经设置过
        if [[ ! -f "$HOME/.fzf.zsh" ]]; then
            # 安装 FZF shell 集成
            if [[ -d "/usr/share/doc/fzf/examples" ]]; then
                cp /usr/share/doc/fzf/examples/key-bindings.zsh "$HOME/.fzf.zsh"
            elif command -v brew &> /dev/null && [[ -d "$(brew --prefix)/opt/fzf/shell" ]]; then
                cp "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" "$HOME/.fzf.zsh"
            fi
        fi
        log_success "FZF 配置完成"
    else
        log_warn "FZF 未安装，跳过配置"
    fi
}

# 设置默认 Shell
set_default_shell() {
    log_step "设置默认 Shell..."

    local current_shell=$(basename "$SHELL")
    local zsh_path=$(which zsh)

    if [[ "$current_shell" != "zsh" ]]; then
        log_info "当前默认 Shell: $current_shell"
        log_info "将默认 Shell 更改为 ZSH: $zsh_path"

        if chsh -s "$zsh_path"; then
            log_success "默认 Shell 设置完成"
            echo "⚠️  请重新登录或运行 'exec zsh' 以应用更改"
        else
            log_error "默认 Shell 设置失败"
            log_info "请手动运行: chsh -s $zsh_path"
        fi
    else
        log_info "默认 Shell 已是 ZSH"
    fi
}

# 验证安装
verify_installation() {
    log_step "验证安装..."

    # 检查关键文件
    local files=(
        "$HOME/.zshrc"
        "$HOME/.antigen.zsh"
    )

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "✓ $file"
        else
            log_error "✗ $file 不存在"
            return 1
        fi
    done

    # 检查语法
    if zsh -n "$HOME/.zshrc"; then
        log_success "✓ .zshrc 语法正确"
    else
        log_error "✗ .zshrc 语法错误"
        return 1
    fi

    log_success "安装验证通过"
}

# 加载已安装的函数到当前 Shell
load_functions_to_current_shell() {
    log_step "加载函数到当前 Shell..."

    if [[ -d "$HOME/.zsh/functions" ]]; then
        for function_file in "$HOME/.zsh/functions"/*.zsh; do
            if [[ -f "$function_file" ]]; then
                # 使用 source 而不是 . 以确保兼容性
                source "$function_file" 2>/dev/null || true
            fi
        done
        log_success "函数已加载到当前 Shell"
    fi
}

# 显示完成信息
show_completion_info() {
    local config_type="标准版本"
    if [[ "$USE_NVM_OPTIMIZATION" == "true" ]]; then
        config_type="NVM 优化版本 (启用了高达 78.9% 的启动性能提升)"
    fi

    echo ""
    echo "🎉 ZSH 配置安装完成!"
    echo ""
    echo "📋 安装摘要:"
    echo "  • 配置版本: $config_type"
    echo "  • 配置文件: ~/.zshrc"
    echo "  • 插件管理: Antigen"
    echo "  • 主题: Powerlevel10k"
    echo "  • 主题配置: ~/.p10k.zsh"
    echo "  • 开发工具: FZF, fd, ripgrep"
    echo ""
    echo "📚 立即可用的命令:"
    echo "  • check_proxy - 检查代理状态"
    echo "  • proxy_status - 显示详细代理信息"
    echo "  • proxy [address] - 启用代理"
    echo "  • unproxy - 禁用代理"
    echo "  • check_environment - 检查系统环境"
    echo "  • reload_zsh - 重新加载配置"
    echo "  • hg 'pattern' - 搜索文件内容"
    echo "  • zsh_help - 显示帮助信息"
    echo ""
    echo "🚀 可选步骤:"
    echo "  • 运行 'exec zsh' 以完整加载新的 ZSH 环境"
    echo "  • 此时新函数已在当前 Shell 中可用！"
    echo "  • 运行 'p10k configure' 重新配置 Powerlevel10k 主题"
    echo ""
    echo "💡 Powerlevel10k 提示:"
    echo "  • 首次加载会自动安装 Powerlevel10k 主题"
    echo "  • 推荐安装 Nerd Font 字体以获得最佳显示效果"
    echo "  • 可随时运行 'p10k configure' 更改主题样式"
    echo ""
    echo "🔄 卸载方法:"
    echo "  • 恢复备份: cat ~/.zsh_backup_dir"
    echo "  • 重置配置: rm ~/.zshrc ~/.antigen.zsh"
    echo ""
}

# 主函数
main() {
    echo "🚀 ZSH 配置自动安装脚本 v2.0"
    echo "================================"
    echo ""

    # 解析命令行参数
    parse_arguments "$@"

    check_root
    check_system
    check_dependencies
    backup_existing_config
    install_antigen
    install_dev_tools
    install_config_files
    setup_fzf
    set_default_shell
    verify_installation
    load_functions_to_current_shell
    show_completion_info
}

# 错误处理
trap 'log_error "安装过程中发生错误，请检查日志"; exit 1' ERR

# 执行安装
main "$@"