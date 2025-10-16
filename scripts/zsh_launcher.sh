#!/bin/bash
# ZSH Launcher - Multiple startup modes for different needs
# ZSH启动器 - 提供多种启动模式以满足不同需求

set -e

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

# 显示帮助信息
show_help() {
    echo "ZSH Launcher - 多模式启动器"
    echo ""
    echo "用法: $0 <模式> [选项]"
    echo ""
    echo "启动模式:"
    echo "  normal          标准模式 (完整功能，正常启动速度)"
    echo "  fast            快速模式 (跳过补全系统，显著提升速度)"
    echo "  minimal         最小模式 (仅基础功能，极快启动)"
    echo "  benchmark       性能测试模式 (对比各模式性能)"
    echo ""
    echo "工具命令:"
    echo "  enable-completion    启用补全系统 (在fast/minimal模式下)"
    echo "  switch-mode <模式>   切换默认启动模式"
    echo "  benchmark-all        完整性能对比测试"
    echo "  quick-restore        快速恢复到启动前的配置"
    echo ""
    echo "选项:"
    echo "  -h, --help           显示帮助信息"
    echo "  -v, --verbose        详细输出"
    echo "  --persist            使模式选择持久化"
    echo ""
    echo "示例:"
    echo "  $0 fast                       # 快速模式启动ZSH"
    echo "  $0 benchmark                  # 运行性能测试"
    echo "  $0 switch-mode fast           # 设置快速模式为默认"
    echo ""
}

# 备份当前配置
backup_current_config() {
    local backup_dir="$HOME/zsh-launcher-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$backup_dir/"
        echo "$backup_dir" > "$HOME/.zsh_launcher_last_backup"
        log_info "已备份当前配置到: $backup_dir"
    fi
}

# 切换到指定模式
switch_to_mode() {
    local mode="$1"
    local persist="$2"
    local project_root="/home/hao/Workspace/MM/utility/dev-env"

    log_header "切换到 $mode 模式"

    # 备份当前配置
    backup_current_config

    # 选择对应的配置文件
    case "$mode" in
        "normal")
            config_source="$project_root/config/.zshrc"
            ;;
        "fast")
            config_source="$project_root/config/.zshrc.optimized"
            ;;
        "minimal")
            config_source="$project_root/config/.zshrc.ultra-optimized"
            ;;
        *)
            log_error "未知模式: $mode"
            return 1
            ;;
    esac

    # 应用配置
    if [[ -f "$config_source" ]]; then
        cp "$config_source" "$HOME/.zshrc"
        log_success "已切换到 $mode 模式"

        # 如果需要持久化
        if [[ "$persist" == "true" ]]; then
            echo "$mode" > "$HOME/.zsh_default_mode"
            log_info "已设置 $mode 为默认模式"
        fi

        log_info "请运行 'exec zsh' 或重新登录以应用更改"
    else
        log_error "配置文件不存在: $config_source"
        return 1
    fi
}

# 启动指定模式的ZSH
launch_zsh() {
    local mode="$1"
    local project_root="/home/hao/Workspace/MM/utility/dev-env"
    local parent_pid="$PPID"

    # Mark launcher-managed shells so we can collapse nested sessions.
    if [[ -n "$ZSH_LAUNCHER_ACTIVE" ]]; then
        export ZSH_LAUNCHER_PREV_PID="$parent_pid"
    else
        unset ZSH_LAUNCHER_PREV_PID
    fi
    export ZSH_LAUNCHER_ACTIVE=1
    export ZSH_LAUNCHER_MODE="$mode"

    case "$mode" in
        "normal")
            log_info "启动标准模式ZSH..."
            exec zsh
            ;;
        "fast")
            log_info "启动快速模式ZSH..."
            # 使用优化配置并跳过补全初始化
            FAST_MODE=true exec zsh -c "source $project_root/config/.zshrc.optimized && exec zsh"
            ;;
        "minimal")
            log_info "启动最小模式ZSH..."
            # 使用超优化配置，先复制到临时位置，然后设置为.zshrc
            cp "$project_root/config/.zshrc.ultra-optimized" "$HOME/.zshrc.minimal"
            # 备份当前配置
            [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup"
            # 设置最小模式配置
            cp "$HOME/.zshrc.minimal" "$HOME/.zshrc"
            exec zsh
            ;;
        *)
            log_error "未知启动模式: $mode"
            return 1
            ;;
    esac
}

# 运行性能基准测试
run_benchmark() {
    log_header "ZSH性能基准测试"

    local project_root="/home/hao/Workspace/MM/utility/dev-env"
    local results=()

    # 测试标准模式
    log_info "测试标准模式启动时间..."
    local normal_time=$(time (zsh -c "source $project_root/config/.zshrc && exit" 2>/dev/null) 2>&1 | grep real | awk '{print $2}' || echo "N/A")
    results+=("标准模式: $normal_time")

    # 测试优化模式
    log_info "测试优化模式启动时间..."
    local optimized_time=$(time (zsh -c "source $project_root/config/.zshrc.optimized && exit" 2>/dev/null) 2>&1 | grep real | awk '{print $2}' || echo "N/A")
    results+=("优化模式: $optimized_time")

    # 测试超优化模式 (快速)
    log_info "测试超优化模式启动时间..."
    local ultra_time=$(time (FAST_MODE=true zsh -c "source $project_root/config/.zshrc.ultra-optimized && exit" 2>/dev/null) 2>&1 | grep real | awk '{print $2}' || echo "N/A")
    results+=("超优化模式: $ultra_time")

    # 显示结果
    echo ""
    log_header "性能测试结果"
    for result in "${results[@]}"; do
        echo "$result"
    done

    # 生成建议
    echo ""
    log_info "性能建议:"
    if [[ "$ultra_time" != "N/A" && "$normal_time" != "N/A" ]]; then
        local ultra_seconds=$(echo "$ultra_time" | sed 's/s//')
        local normal_seconds=$(echo "$normal_time" | sed 's/s//')

        if (( $(echo "$ultra_seconds < $normal_seconds * 0.2" | bc -l 2>/dev/null || echo "0") )); then
            log_success "超优化模式比标准模式快 80% 以上，推荐用于快速任务"
        fi
    fi

    log_info "使用 '$0 minimal' 获得最快启动速度"
    log_info "使用 '$0 normal' 获得完整功能"
}

# 启用补全系统
enable_completion() {
    log_info "启用ZSH补全系统..."

    # 检查是否已在当前shell中定义了enable_completion函数
    if declare -f enable_completion &>/dev/null; then
        enable_completion
        log_success "补全系统已启用"
    else
        # 手动启用补全
        log_info "手动启用补全系统..."
        autoload -U compinit && compinit -u
        export COMPLETION_ENABLED=true
        log_success "补全系统已手动启用"
    fi
}

# 恢复备份配置
restore_backup() {
    local backup_dir=""
    if [[ -f "$HOME/.zsh_launcher_last_backup" ]]; then
        backup_dir=$(cat "$HOME/.zsh_launcher_last_backup")
    fi

    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        log_error "未找到备份配置"
        return 1
    fi

    log_info "恢复备份配置: $backup_dir"
    cp "$backup_dir/.zshrc" "$HOME/.zshrc"
    log_success "配置已恢复"

    # 清理临时文件
    rm -f "$HOME/.zshrc.minimal" "$HOME/.zshrc.backup"

    log_info "请运行 'exec zsh' 或重新登录以应用更改"
}

# 快速恢复到最后一个配置
quick_restore() {
    if [[ -f "$HOME/.zshrc.backup" ]]; then
        log_info "快速恢复到启动前的配置..."
        cp "$HOME/.zshrc.backup" "$HOME/.zshrc"
        rm -f "$HOME/.zshrc.minimal" "$HOME/.zshrc.backup"
        log_success "配置已恢复"
        log_info "请运行 'exec zsh' 或重新登录以应用更改"
    else
        log_warn "未找到快速恢复配置，尝试使用完整备份恢复..."
        restore_backup
    fi
}

# 主函数
main() {
    local command="$1"
    shift || true

    # 检查是否在正确的目录
    if [[ ! -f "/home/hao/Workspace/MM/utility/dev-env/config/.zshrc" ]]; then
        log_error "请在包含dev-env项目的环境中运行此脚本"
        exit 1
    fi

    local persist="false"

    # 解析选项
    while [[ $# -gt 0 ]]; do
        case $1 in
            --persist)
                persist="true"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                set -x
                shift
                ;;
            *)
                # 其他参数传递给具体命令
                break
                ;;
        esac
    done

    case "$command" in
        "normal"|"fast"|"minimal")
            launch_zsh "$command"
            ;;
        "benchmark")
            run_benchmark
            ;;
        "switch-mode")
            switch_to_mode "$1" "$persist"
            ;;
        "enable-completion")
            enable_completion
            ;;
        "benchmark-all")
            run_benchmark
            ;;
        "restore")
            restore_backup
            ;;
        "quick-restore")
            quick_restore
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
