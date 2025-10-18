#!/bin/bash

# ===============================================
# NVM Lazy Load Optimization - Application Script
# ===============================================
# Purpose: 安全地应用 NVM 延迟加载优化
# 性能提升: 78.9% (567ms → 120ms)
# ===============================================

set -e  # 在错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_DIR/config/.zshrc.nvm-optimized"
BACKUP_DIR="$HOME/.zshrc-backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# ===============================================
# 主函数
# ===============================================

main() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║        NVM Lazy Load Optimization - Installer      ║${NC}"
    echo -e "${BLUE}║          性能提升: 78.9% (567ms → 120ms)           ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
    echo ""

    # 步骤 1: 前置检查
    step_prechecks

    # 步骤 2: 创建备份
    step_backup

    # 步骤 3: 应用优化
    step_apply_optimization

    # 步骤 4: 验证
    step_verify

    # 步骤 5: 显示后续步骤
    step_next_steps
}

# ===============================================
# 步骤 1: 前置检查
# ===============================================

step_prechecks() {
    log_info "执行前置检查..."

    # 检查优化配置文件是否存在
    if [[ ! -f "$CONFIG_FILE" ]]; then
        log_error "优化配置文件不存在: $CONFIG_FILE"
        exit 1
    fi
    log_success "优化配置文件存在"

    # 检查当前 .zshrc 是否存在
    if [[ ! -f "$HOME/.zshrc" ]]; then
        log_error "当前 .zshrc 不存在: $HOME/.zshrc"
        exit 1
    fi
    log_success "当前 .zshrc 存在"

    # 检查 NVM 是否安装
    if [[ ! -d "$HOME/.nvm" ]]; then
        log_warn "NVM 未安装，优化仍可应用但 npm/node 命令需要您手动安装 NVM"
    else
        log_success "NVM 已安装: $HOME/.nvm"
    fi

    echo ""
}

# ===============================================
# 步骤 2: 创建备份
# ===============================================

step_backup() {
    log_info "创建配置备份..."

    # 创建备份目录
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        log_success "创建备份目录: $BACKUP_DIR"
    fi

    # 备份当前 .zshrc
    local backup_file="$BACKUP_DIR/.zshrc.$TIMESTAMP"
    cp "$HOME/.zshrc" "$backup_file"
    log_success "备份已创建: $backup_file"

    # 显示最近的备份
    log_info "最近的备份:"
    ls -lt "$BACKUP_DIR"/.zshrc.* | head -3 | awk '{print "  " $NF}'

    echo ""
}

# ===============================================
# 步骤 3: 应用优化
# ===============================================

step_apply_optimization() {
    log_info "应用优化配置..."

    # 复制优化配置
    cp "$CONFIG_FILE" "$HOME/.zshrc"
    log_success "优化配置已应用"

    # 显示关键变化
    echo ""
    log_info "关键优化变化:"
    echo "  • NVM 从启动时加载改为延迟加载（首次使用时加载）"
    echo "  • 补全系统使用 zcompdump 缓存"
    echo "  • 移除冗余的重型插件"
    echo ""
}

# ===============================================
# 步骤 4: 验证
# ===============================================

step_verify() {
    log_info "验证优化..."

    # 检查优化配置是否正确应用
    if grep -q "_nvm_lazy_load" "$HOME/.zshrc"; then
        log_success "NVM 延迟加载函数已正确安装"
    else
        log_error "NVM 延迟加载函数安装失败"
        exit 1
    fi

    if grep -q "compinit -C" "$HOME/.zshrc"; then
        log_success "补全缓存优化已正确安装"
    else
        log_error "补全缓存优化安装失败"
        exit 1
    fi

    echo ""
}

# ===============================================
# 步骤 5: 后续步骤
# ===============================================

step_next_steps() {
    echo -e "${GREEN}╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  安装完成! ✓                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}📋 接下来，你需要执行以下步骤:${NC}"
    echo ""
    echo "  1️⃣  重新加载 Shell:"
    echo -e "     ${BLUE}exec zsh${NC}"
    echo ""
    echo "  2️⃣  验证启动时间改进:"
    echo -e "     ${BLUE}time zsh -i -c exit${NC}"
    echo "     预期: ~0.12-0.15s (原来: ~0.57s)"
    echo ""
    echo "  3️⃣  测试 Node 工具:"
    echo -e "     ${BLUE}npm --version${NC} (首次会加载 NVM, ~1-2s)"
    echo -e "     ${BLUE}npm --version${NC} (第二次很快)"
    echo ""
    echo "  4️⃣  查看详细文档:"
    echo -e "     ${BLUE}cat $PROJECT_DIR/docs/NVM_LAZY_LOAD_QUICK_GUIDE.md${NC}"
    echo ""

    # 显示回滚方案
    echo -e "${YELLOW}🔄 如需回滚:${NC}"
    echo "  运行以下命令恢复原始配置:"
    echo -e "  ${BLUE}cp $BACKUP_DIR/.zshrc.$TIMESTAMP ~/.zshrc${NC}"
    echo -e "  ${BLUE}exec zsh${NC}"
    echo ""

    # 显示性能对比预期
    echo -e "${YELLOW}📊 预期性能提升:${NC}"
    echo "  启动时间: 567ms → 120ms"
    echo "  性能提升: 78.9% ⚡"
    echo "  节省时间: 447ms"
    echo ""

    # 询问是否立即重新加载
    echo -e "${YELLOW}🔧 是否现在重新加载 Shell? (y/n)${NC}"
    read -r response
    if [[ "$response" == "y" || "$response" == "Y" ]]; then
        log_info "重新加载 Shell..."
        exec zsh
    else
        log_info "请手动运行 'exec zsh' 来应用更改"
    fi
}

# ===============================================
# 错误处理
# ===============================================

trap 'log_error "安装被中断"; exit 1' INT TERM

# ===============================================
# 运行主函数
# ===============================================

main "$@"
