#!/bin/bash
# ZSH Performance Optimizer
# 用于优化ZSH启动性能的工具

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 获取项目根目录的函数
get_project_root() {
    echo "$PROJECT_ROOT"
}

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
    echo "ZSH Performance Optimizer"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  analyze          分析当前ZSH性能"
    echo "  optimize         应用性能优化"
    echo "  restore          恢复原始配置"
    echo "  compare          对比优化前后的性能"
    echo "  benchmark        运行完整性能测试"
    echo ""
    echo "选项:"
    echo "  -h, --help       显示帮助信息"
    echo "  -v, --verbose    详细输出"
    echo ""
    echo "示例:"
    echo "  $0 analyze              # 分析当前性能"
    echo "  $0 optimize             # 应用优化"
    echo "  $0 compare              # 对比性能"
    echo ""
}

# 备份当前配置
backup_config() {
    local backup_dir="$HOME/zsh-optimizer-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    log_info "备份当前配置到: $backup_dir"
    cp "$HOME/.zshrc" "$backup_dir/" 2>/dev/null || true
    cp "$HOME/.antigen.zsh" "$backup_dir/" 2>/dev/null || true

    # 备份函数目录
    if [[ -d "$HOME/.zsh/functions" ]]; then
        cp -r "$HOME/.zsh/functions" "$backup_dir/"
    fi

    echo "$backup_dir" > "$HOME/.zsh_optimizer_last_backup"
    log_success "配置备份完成"
}

# 分析当前性能
analyze_performance() {
    log_header "分析当前ZSH性能"

    log_info "运行性能基准测试..."
    if ./zsh_tools.sh benchmark-detailed 2>/dev/null; then
        log_success "性能分析完成"
    else
        log_warn "详细性能分析失败，运行基础测试"
        ./zsh_tools.sh benchmark
    fi

    log_info "运行 zprof 启动剖析..."
    local profiler_tmp_dir="$(mktemp -d 2>/dev/null || mktemp -d -t zprof)"
    local profiler_cache_dir="$PROJECT_ROOT/.cache"
    mkdir -p "$profiler_cache_dir"
    local profiler_log="$profiler_cache_dir/zprof-$(date +%Y%m%d-%H%M%S).log"

    cat > "$profiler_tmp_dir/.zshrc" <<'EOF'
zmodload zsh/zprof 2>/dev/null
export ZSH_PROFILING=1
setopt prompt_subst
builtin source "$HOME/.zshrc"
zprof
EOF

    if ZDOTDIR="$profiler_tmp_dir" zsh -ic "exit" >"$profiler_log" 2>&1; then
        local top_entries
        top_entries=$(grep -E '^\s*[0-9]+\)' "$profiler_log" | head -n 5)
        if [[ -n "$top_entries" ]]; then
            log_info "zprof 耗时 Top 5:"
            echo "$top_entries" | sed 's/^/    /'
        else
            log_warn "未能从 zprof 输出中解析耗时信息，请查看日志: $profiler_log"
        fi
        log_success "zprof 分析结果已保存: $profiler_log"
    else
        log_warn "zprof 分析执行失败，详细日志: $profiler_log"
    fi

    rm -rf "$profiler_tmp_dir"

    # 检查插件数量
    log_info "统计插件加载情况..."
    local plugin_count=0
    if grep -q "antigen bundle" "$HOME/.zshrc" 2>/dev/null; then
        plugin_count=$(grep "antigen bundle" "$HOME/.zshrc" | grep -v "^#" | wc -l)
        log_info "当前加载插件数量: $plugin_count"
    fi

    # 检查内存使用
    local memory_kb=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    local memory_mb=$((memory_kb / 1024))
    log_info "当前内存使用: ${memory_mb}MB"

    # 检查Antigen目录大小
    if [[ -d "$HOME/.antigen" ]]; then
        local antigen_size=$(du -sk "$HOME/.antigen" 2>/dev/null | cut -f1 || echo "0")
        log_info "Antigen插件目录: ${antigen_size}KB"
    fi
}

# 应用性能优化
apply_optimization() {
    log_header "应用ZSH性能优化"

    # 检查是否已经优化过
    if [[ -f "$HOME/.zshrc.optimized" ]]; then
        log_warn "发现已优化的配置文件"
        read -p "是否覆盖现有优化? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "优化已取消"
            return 0
        fi
    fi

    # 备份当前配置
    log_info "备份当前配置..."
    backup_config

    # 应用优化配置
    local project_root="$(get_project_root)"
    local optimized_config="$project_root/config/.zshrc.optimized"

    if [[ -f "$optimized_config" ]]; then
        log_info "应用优化配置..."
        cp "$optimized_config" "$HOME/.zshrc"
        log_success "优化配置已应用"
    else
        log_error "优化配置文件不存在: $optimized_config"
        return 1
    fi

    log_success "优化完成！"
    log_info "请运行 'exec zsh' 或重新登录以应用更改"
}

# 恢复原始配置
restore_config() {
    log_header "恢复原始ZSH配置"

    # 查找最新备份
    local backup_dir=""
    if [[ -f "$HOME/.zsh_optimizer_last_backup" ]]; then
        backup_dir=$(cat "$HOME/.zsh_optimizer_last_backup")
    fi

    if [[ -z "$backup_dir" ]]; then
        log_error "未找到备份目录"
        return 1
    fi

    if [[ ! -d "$backup_dir" ]]; then
        log_error "备份目录不存在: $backup_dir"
        return 1
    fi

    log_info "从备份恢复: $backup_dir"

    # 恢复配置文件
    if [[ -f "$backup_dir/.zshrc" ]]; then
        cp "$backup_dir/.zshrc" "$HOME/.zshrc"
        log_success "已恢复 .zshrc"
    fi

    if [[ -f "$backup_dir/.antigen.zsh" ]]; then
        cp "$backup_dir/.antigen.zsh" "$HOME/.antigen.zsh"
        log_success "已恢复 .antigen.zsh"
    fi

    # 恢复函数目录
    if [[ -d "$backup_dir/functions" ]]; then
        cp -r "$backup_dir/functions" "$HOME/.zsh/functions"
        log_success "已恢复自定义函数"
    fi

    log_success "配置恢复完成"
    log_info "请运行 'exec zsh' 或重新登录以应用更改"
}

# 对比性能
compare_performance() {
    log_header "对比优化前后的性能"

    log_info "创建性能对比报告..."

    # 检查是否有备份配置
    local backup_dir=""
    if [[ -f "$HOME/.zsh_optimizer_last_backup" ]]; then
        backup_dir=$(cat "$HOME/.zsh_optimizer_last_backup")
    fi

    if [[ -z "$backup_dir" || ! -d "$backup_dir" ]]; then
        log_warn "未找到备份配置，无法进行对比"
        log_info "请先运行 '$0 analyze' 进行性能分析"
        return 1
    fi

    # 创建临时配置对比
    log_info "测试当前配置性能..."
    local current_time=$(time (zsh -i -c 'exit' 2>/dev/null) 2>&1 | grep real | awk '{print $2}' || echo "N/A")

    log_info "测试备份配置性能..."
    local backup_time="N/A"
    if [[ -f "$backup_dir/.zshrc" ]]; then
        backup_time=$(time (zsh -c "source $backup_dir/.zshrc && exit" 2>/dev/null) 2>&1 | grep real | awk '{print $2}' || echo "N/A")
    fi

    echo ""
    log_info "性能对比结果:"
    echo "当前配置启动时间: $current_time"
    echo "备份配置启动时间: $backup_time"

    if [[ "$current_time" != "N/A" && "$backup_time" != "N/A" ]]; then
        # 简单的对比分析
        local current_seconds=$(echo "$current_time" | sed 's/s//')
        local backup_seconds=$(echo "$backup_time" | sed 's/s//')

        if (( $(echo "$current_seconds < $backup_seconds" | bc -l 2>/dev/null || echo "0") )); then
            local improvement=$(echo "scale=1; (($backup_seconds - $current_seconds) / $backup_seconds) * 100" | bc -l 2>/dev/null || echo "0")
            log_success "优化后启动速度提升 ${improvement}%"
        else
            local degradation=$(echo "scale=1; (($current_seconds - $backup_seconds) / $backup_seconds) * 100" | bc -l 2>/dev/null || echo "0")
            log_warn "优化后启动速度降低 ${degradation}%"
        fi
    fi
}

# 运行完整基准测试
run_benchmark() {
    log_header "运行完整性能基准测试"

    if command -v ./zsh_tools.sh &> /dev/null; then
        ./zsh_tools.sh benchmark-detailed
    else
        log_error "zsh_tools.sh 工具不存在"
        return 1
    fi
}

# 主函数
main() {
    local command="$1"
    shift || true

    # 检查是否在正确的目录
    if [[ ! -f "./zsh_tools.sh" ]]; then
        log_error "请在 dev-env/scripts 目录中运行此脚本"
        exit 1
    fi

    case "$command" in
        "analyze")
            analyze_performance
            ;;
        "optimize")
            apply_optimization
            ;;
        "restore")
            restore_config
            ;;
        "compare")
            compare_performance
            ;;
        "benchmark")
            run_benchmark
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
