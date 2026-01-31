#!/bin/bash
# ZSH Launcher - Multiple startup modes for different needs
# ZSH启动器 - 提供多种启动模式以满足不同需求
# 版本: 2.0 (集成日志和性能监控)

set -e

# =============================================================================
# 加载核心库
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载日志库
if [[ -f "$SCRIPT_DIR/lib_logging.sh" ]]; then
    source "$SCRIPT_DIR/lib_logging.sh"
    # 初始化日志系统
    init_logging 2>/dev/null || true
else
    echo "Warning: lib_logging.sh not found, using basic logging" >&2
    # 基础日志函数（备用）
    log_info() { echo "[INFO] $*"; }
    log_success() { echo "[SUCCESS] $*"; }
    log_warn() { echo "[WARN] $*" >&2; }
    log_error() { echo "[ERROR] $*" >&2; }
fi

# 加载性能监控库
if [[ -f "$SCRIPT_DIR/lib_performance.sh" ]]; then
    source "$SCRIPT_DIR/lib_performance.sh"
fi

# 加载跨平台兼容性库
if [[ -f "$SCRIPT_DIR/lib_platform_compat.sh" ]]; then
    source "$SCRIPT_DIR/lib_platform_compat.sh"
fi

# =============================================================================
# 兼容性别名（保留原有API）
# =============================================================================

log_header() {
    log_section "$*"
}

# 获取项目根目录
get_project_root() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(dirname "$script_dir")"
    echo "$project_root"
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
    local project_root="$(get_project_root)"

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
    local project_root="$(get_project_root)"
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
# =============================================================================
# 精确性能测试函数（毫秒级，跨平台）
# =============================================================================

# 测量启动时间（精确到毫秒）
measure_startup_time() {
    local config_file=$1
    local mode=$2

    if [[ ! -f "$config_file" ]]; then
        echo "N/A"
        return 1
    fi

    # 使用跨平台的毫秒级时间测量
    local start_time
    local end_time

    if command -v python &>/dev/null; then
        # Python 方法（最精确）
        start_time=$(python -c 'import time; print(int(time.time()*1000))' 2>/dev/null)
        zsh -c "source $config_file && exit" 2>/dev/null || true
        end_time=$(python -c 'import time; print(int(time.time()*1000))' 2>/dev/null)
    elif command -v perl &>/dev/null; then
        # Perl 方法
        start_time=$(perl -MTime::HiRes -e 'printf("%d",Time::HiRes::time()*1000)' 2>/dev/null)
        zsh -c "source $config_file && exit" 2>/dev/null || true
        end_time=$(perl -MTime::HiRes -e 'printf("%d",Time::HiRes::time()*1000)' 2>/dev/null)
    else
        # Shell 内置时间（秒级精度）
        start_time=$(date +%s)000
        zsh -c "source $config_file && exit" 2>/dev/null || true
        end_time=$(date +%s)000
    fi

    local duration=$((end_time - start_time))
    echo "$duration"
}

# 快速性能测试（更精确，记录到性能监控系统）
quick_benchmark() {
    log_header "快速性能测试 (精确模式)"

    local project_root="$(get_project_root)"
    local results=()
    local iterations=3

    # 测试 minimal 模式
    log_info "测试 minimal 模式..."
    local total_time=0
    for ((i=1; i<=iterations; i++)); do
        local time=$(measure_startup_time "$project_root/config/.zshrc.ultra-optimized" "minimal")
        total_time=$((total_time + time))
    done
    local avg_time=$((total_time / iterations))
    results+=("Minimal: ${avg_time}ms")

    # 记录性能数据
    if command -v record_startup_time &>/dev/null; then
        record_startup_time "minimal" "$avg_time"
    fi

    # 测试 fast 模式
    log_info "测试 fast 模式..."
    total_time=0
    for ((i=1; i<=iterations; i++)); do
        local time=$(measure_startup_time "$project_root/config/.zshrc.optimized" "fast")
        total_time=$((total_time + time))
    done
    avg_time=$((total_time / iterations))
    results+=("Fast: ${avg_time}ms")

    if command -v record_startup_time &>/dev/null; then
        record_startup_time "fast" "$avg_time"
    fi

    # 测试 normal 模式
    log_info "测试 normal 模式..."
    total_time=0
    for ((i=1; i<=iterations; i++)); do
        local time=$(measure_startup_time "$project_root/config/.zshrc" "normal")
        total_time=$((total_time + time))
    done
    avg_time=$((total_time / iterations))
    results+=("Normal: ${avg_time}ms")

    if command -v record_startup_time &>/dev/null; then
        record_startup_time "normal" "$avg_time"
    fi

    # 显示结果
    echo ""
    log_header "性能测试结果"
    for result in "${results[@]}"; do
        echo "  $result"
    done

    # 性能分析
    echo ""
    log_info "性能分析:"
    echo "  Minimal模式用于快速命令执行"
    echo "  Fast模式用于日常开发工作"
    echo "  Normal模式用于复杂开发任务"
}

run_benchmark() {
    log_header "ZSH性能基准测试"

    local project_root="$(get_project_root)"
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

    # 运行精确测试
    echo ""
    log_info "运行精确性能测试..."
    quick_benchmark
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
    local project_root="$(get_project_root)"
    if [[ ! -f "$project_root/config/.zshrc" ]]; then
        log_error "配置文件不存在: $project_root/config/.zshrc"
        log_info "请确保在 dev-env 项目目录中运行此脚本"
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
