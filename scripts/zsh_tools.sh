#!/bin/bash
# ZSH 配置管理工具集
# 版本: 1.0
# 作者: Claude AI Assistant

set -e

# 全局标志
DRY_RUN=false

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

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

log_header() {
    echo -e "${PURPLE}=== $1 ===${NC}"
}

# 干运行模式输出
dry_run_msg() {
    echo -e "${CYAN}[DRY-RUN]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "ZSH 配置管理工具集"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  validate          验证 ZSH 配置"
    echo "  backup            备份 ZSH 配置"
    echo "  restore           恢复 ZSH 配置"
    echo "  update            更新 Antigen 插件"
    echo "  clean             清理插件缓存"
    echo "  benchmark         性能基准测试"
    echo "  benchmark-detailed 详细性能分析"
    echo "  doctor            系统诊断"
    echo "  reset             重置配置到默认状态"
    echo ""
    echo "全局选项:"
    echo "  --dry-run         干运行模式 (显示操作但不执行)"
    echo "  -h, --help        显示帮助信息"
    echo "  -v, --verbose     详细输出"
    echo "  -q, --quiet       静默模式"
    echo ""
    echo "示例:"
    echo "  $0 validate                      # 验证配置"
    echo "  $0 --dry-run backup             # 预览备份操作"
    echo "  $0 backup                        # 备份配置"
    echo "  $0 restore /path/to/backup       # 恢复配置"
    echo "  $0 update                        # 更新插件"
    echo ""
}

# 验证 ZSH 配置
validate_config() {
    log_header "验证 ZSH 配置"

    local issues=0

    # 检查 ZSH 版本
    log_info "检查 ZSH 版本..."
    local zsh_version=$(zsh --version | cut -d' ' -f2)
    log_info "当前版本: $zsh_version"

    if [[ $(echo "$zsh_version" | cut -d'.' -f1) -lt 5 ]]; then
        log_error "ZSH 版本过低，建议升级到 5.0+"
        ((issues++))
    else
        log_success "ZSH 版本符合要求"
    fi

    # 检查关键文件
    log_info "检查关键配置文件..."
    local critical_files=(
        "$HOME/.zshrc"
        "$HOME/.antigen.zsh"
    )

    for file in "${critical_files[@]}"; do
        if [[ -f "$file" ]]; then
            local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
            log_success "✓ $file (${size} bytes)"
        else
            log_error "✗ $file 不存在"
            ((issues++))
        fi
    done

    # 语法检查
    log_info "检查 .zshrc 语法..."
    if zsh -n "$HOME/.zshrc" 2>/dev/null; then
        log_success "✓ .zshrc 语法正确"
    else
        log_error "✗ .zshrc 语法错误"
        zsh -n "$HOME/.zshrc"
        ((issues++))
    fi

    # 检查 Antigen
    log_info "检查 Antigen 插件管理器..."
    if [[ -f "$HOME/.antigen.zsh" ]]; then
        log_success "✓ Antigen 已安装"

        # 检查 Antigen 插件
        if zsh -i -c "antigen list &>/dev/null"; then
            local plugin_count=$(zsh -i -c "antigen list | wc -l" 2>/dev/null || echo "0")
            log_success "✓ 已加载 $plugin_count 个插件"
        else
            log_warn "Antigen 插件检查失败"
        fi
    else
        log_error "✗ Antigen 未安装"
        ((issues++))
    fi

    # 检查开发工具
    log_info "检查开发工具..."
    local tools=("fzf" "fd" "fdfind" "rg")
    local available_tools=0

    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            log_success "✓ $tool"
            ((available_tools++))
        fi
    done

    if [[ $available_tools -eq 0 ]]; then
        log_warn "未检测到推荐的开发工具 (fzf, fd, ripgrep)"
    else
        log_info "已安装 $available_tools 个开发工具"
    fi

    # 检查主题
    log_info "检查主题设置..."
    if zsh -i -c 'echo $PROMPT' 2>/dev/null | grep -q "➜"; then
        log_success "✓ robbyrussell 主题已加载"
    else
        log_warn "主题可能未正确加载"
    fi

    # 总结
    echo ""
    if [[ $issues -eq 0 ]]; then
        log_success "🎉 配置验证通过，未发现问题"
        return 0
    else
        log_error "发现 $issues 个问题，请查看上述详细信息"
        return 1
    fi
}

# 备份配置
backup_config() {
    log_header "备份 ZSH 配置"

    local backup_dir="$HOME/zsh-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    log_info "备份目录: $backup_dir"

    # 备份文件列表
    local files=(
        ".zshrc"
        ".antigen.zsh"
        ".fzf.zsh"
        ".zsh_profile"
        ".zshenv"
    )

    local dirs=(
        ".antigen"
        ".zsh"
        ".oh-my-zsh"
    )

    # 备份文件
    log_info "备份配置文件..."
    local backed_up_files=0
    for file in "${files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            cp "$HOME/$file" "$backup_dir/"
            log_success "✓ $file"
            ((backed_up_files++))
        fi
    done

    # 备份目录
    log_info "备份配置目录..."
    local backed_up_dirs=0
    for dir in "${dirs[@]}"; do
        if [[ -d "$HOME/$dir" ]]; then
            cp -r "$HOME/$dir" "$backup_dir/"
            log_success "✓ $dir/"
            ((backed_up_dirs++))
        fi
    done

    # 创建备份信息文件
    cat > "$backup_dir/backup_info.txt" << EOF
ZSH 配置备份信息
==================

备份时间: $(date)
备份目录: $backup_dir
系统信息: $(uname -a)
ZSH 版本: $(zsh --version)

备份文件数量: $backed_up_files
备份目录数量: $backed_up_dirs

恢复方法:
1. 运行: $0 restore $backup_dir
2. 或手动复制文件到 HOME 目录
EOF

    # 保存备份路径
    echo "$backup_dir" > "$HOME/.zsh_last_backup"

    log_success "备份完成: $backup_dir"
    log_info "已备份 $backed_up_files 个文件，$backed_up_dirs 个目录"

    # 显示恢复命令
    echo ""
    log_info "恢复命令: $0 restore $backup_dir"
}

# 恢复配置
restore_config() {
    local backup_dir="$1"

    if [[ -z "$backup_dir" ]]; then
        # 使用最新备份
        if [[ -f "$HOME/.zsh_last_backup" ]]; then
            backup_dir=$(cat "$HOME/.zsh_last_backup")
        else
            log_error "未指定备份目录，且未找到最新备份"
            return 1
        fi
    fi

    if [[ ! -d "$backup_dir" ]]; then
        log_error "备份目录不存在: $backup_dir"
        return 1
    fi

    log_header "恢复 ZSH 配置"
    log_info "从备份恢复: $backup_dir"

    # 创建当前配置的备份
    log_warn "正在创建当前配置的备份..."
    backup_config

    # 恢复文件
    log_info "恢复配置文件..."
    local restored_files=0

    for file in "$backup_dir"/.*; do
        if [[ -f "$file" ]] && [[ "$(basename "$file")" != "." ]] && [[ "$(basename "$file")" != ".." ]]; then
            cp "$file" "$HOME/"
            log_success "✓ $(basename "$file")"
            ((restored_files++))
        fi
    done

    # 恢复目录
    log_info "恢复配置目录..."
    local restored_dirs=0

    for dir in "$backup_dir"/*; do
        if [[ -d "$dir" ]] && [[ "$(basename "$dir")" != "." ]] && [[ "$(basename "$dir")" != ".." ]]; then
            rm -rf "$HOME/$(basename "$dir")" 2>/dev/null || true
            cp -r "$dir" "$HOME/"
            log_success "✓ $(basename "$dir")/"
            ((restored_dirs++))
        fi
    done

    log_success "恢复完成: $restored_files 个文件，$restored_dirs 个目录"

    # 验证恢复的配置
    echo ""
    log_info "验证恢复的配置..."
    if validate_config; then
        log_success "配置恢复成功"
        log_info "请运行 'exec zsh' 或重新登录以应用更改"
    else
        log_error "配置恢复后验证失败，请检查配置"
    fi
}

# 更新 Antigen 插件
update_plugins() {
    log_header "更新 Antigen 插件"

    if [[ ! -f "$HOME/.antigen.zsh" ]]; then
        log_error "Antigen 未安装"
        return 1
    fi

    log_info "更新 Antigen 本身..."
    if zsh -i -c "antigen update" 2>/dev/null; then
        log_success "Antigen 更新完成"
    else
        log_warn "Antigen 更新失败或已是最新版本"
    fi

    log_info "更新所有插件..."
    if zsh -i -c "antigen update && antigen cleanup" 2>/dev/null; then
        log_success "插件更新完成"
    else
        log_error "插件更新失败"
        return 1
    fi

    log_info "重新加载配置..."
    if zsh -i -c "source ~/.zshrc" 2>/dev/null; then
        log_success "配置重新加载完成"
    else
        log_warn "配置重新加载失败，请手动运行 'source ~/.zshrc'"
    fi
}

# 清理插件缓存
clean_cache() {
    log_header "清理插件缓存"

    local cleaned_size=0

    # 清理 Antigen 缓存
    if [[ -d "$HOME/.antigen" ]]; then
        log_info "清理 Antigen 缓存..."
        local antigen_size=$(du -sk "$HOME/.antigen" 2>/dev/null | cut -f1)

        if [[ "$DRY_RUN" == "true" ]]; then
            dry_run_msg "rm -rf $HOME/.antigen/init.zsh"
            dry_run_msg "rm -rf $HOME/.antigen/.cache"
        else
            rm -rf "$HOME/.antigen/init.zsh"
            rm -rf "$HOME/.antigen/.cache"
        fi

        log_success "已清理 Antigen 缓存 (~${antigen_size}KB)"
        ((cleaned_size += antigen_size))
    fi

    # 清理 ZSH 缓存
    log_info "清理 ZSH 缓存..."

    if [[ "$DRY_RUN" == "true" ]]; then
        dry_run_msg "rm -f $HOME/.zcompdump*"
    else
        rm -f "$HOME/.zcompdump"* 2>/dev/null || true
    fi

    local comp_cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/dev-env"
    if [[ -d "$comp_cache_root" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            dry_run_msg "rm -f $comp_cache_root/zcompdump-*"
        else
            rm -f "$comp_cache_root"/zcompdump-* 2>/dev/null || true
        fi
    fi

    log_success "已清理 ZSH 补全缓存 (含 ${comp_cache_root#${HOME}/})"

    # 清理 FZF 缓存
    if [[ -f "$HOME/.fzf.zsh" ]]; then
        log_info "重新生成 FZF 缓存..."
        # FZF 缓存会在下次使用时自动生成
        log_success "FZF 缓存已标记为重新生成"
    fi

    if [[ $cleaned_size -gt 0 ]]; then
        log_success "总计清理: ~${cleaned_size}KB"
    else
        log_info "缓存清理完成"
    fi
}

# 性能基准测试
benchmark_performance() {
    log_header "性能基准测试"

    log_info "测试启动时间..."

    # 检查 /usr/bin/time 是否可用
    local time_cmd="/usr/bin/time"
    if [[ ! -x "$time_cmd" ]]; then
        time_cmd="time"
    fi

    # 测试冷启动时间
    local cold_start_output=$( { $time_cmd -f "%e" bash -c 'zsh -i -c "exit"' 2>&1; } 2>&1)
    local cold_start_time=$(echo "$cold_start_output" | tail -1 | grep -oE '^[0-9]+\.[0-9]+' || echo "0.0")
    log_info "冷启动时间: ${cold_start_time}s"

    # 测试热启动时间
    local warm_start_output=$( { $time_cmd -f "%e" bash -c 'zsh -i -c "exit"' 2>&1; } 2>&1)
    local warm_start_time=$(echo "$warm_start_output" | tail -1 | grep -oE '^[0-9]+\.[0-9]+' || echo "0.0")
    log_info "热启动时间: ${warm_start_time}s"

    # 检查内存使用
    log_info "检查内存使用..."
    local zsh_memory=$(ps -o rss= -p $$ 2>/dev/null || echo "0")
    log_info "ZSH 内存使用: ${zsh_memory}KB"

    # 检查插件数量
    log_info "统计插件信息..."
    local plugin_count=$(zsh -i -c "antigen list 2>/dev/null | wc -l" 2>/dev/null || echo "0")
    log_info "已加载插件数量: $plugin_count"

    # 性能评级
    echo ""
    log_info "性能评级:"

    # 启动时间评级 - 使用更稳健的比较方式
    if (( $(echo "$cold_start_time < 1.0" | bc -l 2>/dev/null || echo 0) )); then
        log_success "启动速度: 优秀 (< 1.0s)"
    elif (( $(echo "$cold_start_time < 2.0" | bc -l 2>/dev/null || echo 0) )); then
        log_info "启动速度: 良好 (1.0-2.0s)"
    else
        log_warn "启动速度: 一般 (> 2.0s)"
    fi

    # 内存使用评级
    if [[ $zsh_memory -lt 30000 ]]; then
        log_success "内存使用: 优秀 (< 30MB)"
    elif [[ $zsh_memory -lt 50000 ]]; then
        log_info "内存使用: 良好 (30-50MB)"
    else
        log_warn "内存使用: 较高 (> 50MB)"
    fi
}

# 详细性能分析
benchmark_detailed() {
    log_header "详细性能分析"

    # 检查依赖
    if ! command -v bc &> /dev/null; then
        log_error "缺少依赖工具: bc (用于数学计算)"
        log_info "安装方法: sudo apt install bc / brew install bc"
        return 1
    fi

    # 检查性能函数文件
    local perf_func_file="$HOME/.zsh/functions/performance.zsh"
    if [[ ! -f "$perf_func_file" ]]; then
        log_error "性能分析函数文件不存在: $perf_func_file"
        log_info "请确保性能模块已正确安装"
        return 1
    fi

    log_info "加载性能分析模块..."

    # 在子shell中加载并执行性能分析
    (
        source "$perf_func_file"
        performance_detailed
    )

    if [[ $? -eq 0 ]]; then
        log_success "详细性能分析完成"
    else
        log_error "性能分析过程中出现错误"
        return 1
    fi
}

# 系统诊断
run_doctor() {
    log_header "系统诊断"

    log_info "检查系统环境..."

    # 系统信息
    echo "系统信息:"
    echo "  操作系统: $(uname -s) $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  主机名: $(hostname)"
    echo "  用户: $(whoami)"
    echo "  Shell: $SHELL"
    echo ""

    # ZSH 信息
    echo "ZSH 信息:"
    echo "  版本: $(zsh --version)"
    echo "  配置文件: $HOME/.zshrc"
    echo "  大小: $(du -h "$HOME/.zshrc" 2>/dev/null | cut -f1)"
    echo ""

    # 依赖检查
    echo "依赖检查:"
    local deps=("curl" "git" "zsh")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            local version=$("$dep" --version 2>/dev/null | head -1 || echo "unknown")
            echo "  ✓ $dep: $version"
        else
            echo "  ✗ $dep: 未安装"
        fi
    done
    echo ""

    # 开发工具检查
    echo "开发工具:"
    local tools=("fzf" "fd" "fdfind" "rg" "nvim" "vim")
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            local version=$("$tool" --version 2>/dev/null | head -1 || echo "unknown")
            echo "  ✓ $tool: $version"
        else
            echo "  - $tool: 未安装"
        fi
    done
    echo ""

    # 插件状态
    echo "插件状态:"
    if [[ -f "$HOME/.antigen.zsh" ]]; then
        echo "  ✓ Antigen: 已安装"
        if zsh -i -c "antigen list &>/dev/null"; then
            local plugin_count=$(zsh -i -c "antigen list | wc -l" 2>/dev/null || echo "0")
            echo "  ✓ 插件数量: $plugin_count"
        else
            echo "  ✗ 插件状态: 检查失败"
        fi
    else
        echo "  ✗ Antigen: 未安装"
    fi

    # 运行完整验证
    echo ""
    if validate_config; then
        log_success "🎉 系统诊断完成，一切正常"
    else
        log_warn "系统诊断发现问题，请查看上述详细信息"
    fi
}

# 重置配置
reset_config() {
    log_header "重置 ZSH 配置"

    log_warn "此操作将删除所有 ZSH 配置文件和插件"
    read -p "确认继续? [y/N]: " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        return 0
    fi

    # 创建备份
    log_info "创建配置备份..."
    backup_config

    # 删除配置文件
    log_info "删除配置文件..."
    local files=(
        "$HOME/.zshrc"
        "$HOME/.antigen.zsh"
        "$HOME/.fzf.zsh"
        "$HOME/.zsh_profile"
        "$HOME/.zshenv"
    )

    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            rm "$file"
            log_success "已删除: $(basename "$file")"
        fi
    done

    # 删除配置目录
    log_info "删除配置目录..."
    local dirs=(
        "$HOME/.antigen"
        "$HOME/.zsh"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            log_success "已删除: $(basename "$dir")/"
        fi
    done

    # 创建基本配置
    log_info "创建基本配置..."
    cat > "$HOME/.zshrc" << 'EOF'
# Basic ZSH Configuration
# Generated by ZSH Tools

# Enable completion
autoload -U compinit
compinit

# Basic aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'

# Basic prompt
PROMPT='%n@%m:%~$ '
RPROMPT='%T'
EOF

    log_success "配置重置完成"
    log_info "已创建基本配置文件"
    log_info "请运行 'exec zsh' 或重新登录以应用更改"

    # 显示恢复选项
    echo ""
    local backup_dir=$(cat "$HOME/.zsh_last_backup" 2>/dev/null || echo "")
    if [[ -n "$backup_dir" ]]; then
        log_info "如需恢复配置，请运行: $0 restore $backup_dir"
    fi
}

# 主函数
main() {
    local command="$1"

    # 解析全局选项
    if [[ "$command" == "--dry-run" ]]; then
        DRY_RUN=true
        command="$2"
        shift 2 || shift || true
    else
        shift || true
    fi

    # 显示干运行模式提示
    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}┌─ 干运行模式已启用 ──────────────────────────────${NC}"
        echo -e "${YELLOW}│${NC} 将显示所有操作但${RED}不会实际执行${NC}"
        echo -e "${YELLOW}│${NC} 使用不带 --dry-run 参数执行实际操作"
        echo -e "${YELLOW}└───────────────────────────────────────────────${NC}"
        echo ""
    fi

    case "$command" in
        "validate")
            validate_config
            ;;
        "backup")
            backup_config
            ;;
        "restore")
            restore_config "$1"
            ;;
        "update")
            update_plugins
            ;;
        "clean")
            clean_cache
            ;;
        "benchmark")
            benchmark_performance
            ;;
        "benchmark-detailed")
            benchmark_detailed
            ;;
        "doctor")
            run_doctor
            ;;
        "reset")
            reset_config
            ;;
        "help"|"-h"|"--help"|"")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
