#!/bin/bash
# ===============================================
# ZSH Modular Configuration Manager
# ===============================================
# Description: Manage modular ZSH configuration
# Version: 1.0
# Usage: ./zsh_config_manager.sh <command> [options]
# ===============================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SYSTEM_MODULES_DIR="$PROJECT_ROOT/config/.zshrc.d"
USER_MODULES_DIR="${HOME}/.zshrc.local.d"
BACKUP_DIR="${HOME}/.zsh-backup-$(date +%Y%m%d-%H%M%S)"

# ===============================================
# Helper Functions
# ===============================================

success_msg() {
    echo -e "${GREEN}✓${NC} $1"
}

error_msg() {
    echo -e "${RED}✗${NC} $1" >&2
}

warning_msg() {
    echo -e "${YELLOW}⚠${NC} $1"
}

info_msg() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# ===============================================
# Commands
# ===============================================

# List all available modules
cmd_list() {
    echo ""
    echo "📋 可用配置模块"
    echo "=================="
    echo ""

    echo "系统模块 (System Modules):"
    echo "  位置: $SYSTEM_MODULES_DIR"
    echo ""

    if [[ -d "$SYSTEM_MODULES_DIR" ]]; then
        for module in "$SYSTEM_MODULES_DIR"/*.zsh; do
            if [[ -f "$module" ]]; then
                local name=$(basename "$module")
                local desc=$(grep "^# Description:" "$module" | cut -d: -f2- | sed 's/^[[:space:]]*//')
                printf "  ${GREEN}%-25s${NC} %s\n" "$name" "$desc"
            fi
        done
    else
        warning_msg "系统模块目录不存在: $SYSTEM_MODULES_DIR"
    fi

    echo ""
    echo "用户模块 (User Modules):"
    echo "  位置: $USER_MODULES_DIR"
    echo ""

    if [[ -d "$USER_MODULES_DIR" ]]; then
        local count=0
        for module in "$USER_MODULES_DIR"/*.zsh; do
            if [[ -f "$module" ]]; then
                local name=$(basename "$module")
                local desc=$(grep "^# Description:" "$module" | cut -d: -f2- | sed 's/^[[:space:]]*//')
                printf "  ${GREEN}%-25s${NC} %s\n" "$name" "$desc"
                ((count++))
            fi
        done
        if [[ $count -eq 0 ]]; then
            info_msg "无用户模块"
        fi
    else
        info_msg "用户模块目录不存在（创建目录可添加自定义模块）"
    fi

    echo ""
    echo "管理命令:"
    echo "  zsh_config_manager.sh enable <module>   - 启用模块"
    echo "  zsh_config_manager.sh disable <module>  - 禁用模块"
    echo "  zsh_config_manager.sh validate          - 验证配置"
    echo "  zsh_config_manager.sh backup            - 备份配置"
    echo "  zsh_config_manager.sh status            - 查看状态"
    echo ""
}

# Validate configuration
cmd_validate() {
    echo ""
    echo "🔍 验证配置语法"
    echo "=================="
    echo ""

    local all_valid=true

    # Validate system modules
    if [[ -d "$SYSTEM_MODULES_DIR" ]]; then
        echo "验证系统模块:"
        for module in "$SYSTEM_MODULES_DIR"/*.zsh; do
            if [[ -f "$module" ]]; then
                local name=$(basename "$module")
                if zsh -n "$module" 2>/dev/null; then
                    success_msg "$name"
                else
                    error_msg "$name - 语法错误"
                    zsh -n "$module"
                    all_valid=false
                fi
            fi
        done
        echo ""
    fi

    # Validate user modules
    if [[ -d "$USER_MODULES_DIR" ]]; then
        echo "验证用户模块:"
        for module in "$USER_MODULES_DIR"/*.zsh; do
            if [[ -f "$module" ]]; then
                local name=$(basename "$module")
                if zsh -n "$module" 2>/dev/null; then
                    success_msg "$name"
                else
                    error_msg "$name - 语法错误"
                    zsh -n "$module"
                    all_valid=false
                fi
            fi
        done
        echo ""
    fi

    # Validate main config
    echo "验证主配置文件:"
    if [[ -f "$HOME/.zshrc" ]]; then
        if zsh -n "$HOME/.zshrc" 2>/dev/null; then
            success_msg "~/.zshrc"
        else
            error_msg "~/.zshrc - 语法错误"
            zsh -n "$HOME/.zshrc"
            all_valid=false
        fi
    else
        warning_msg "~/.zshrc 不存在"
    fi
    echo ""

    if [[ "$all_valid" == "true" ]]; then
        success_msg "所有配置文件语法正确"
        return 0
    else
        error_msg "发现语法错误"
        return 1
    fi
}

# Backup current configuration
cmd_backup() {
    echo ""
    echo "📦 备份当前配置"
    echo "=================="
    echo ""

    mkdir -p "$BACKUP_DIR"

    # Backup .zshrc
    if [[ -f "$HOME/.zshrc" ]]; then
        cp "$HOME/.zshrc" "$BACKUP_DIR/.zshrc"
        success_msg "已备份 ~/.zshrc"
    fi

    # Backup .zshrc.matrix
    if [[ -f "$HOME/.zshrc.matrix" ]]; then
        cp "$HOME/.zshrc.matrix" "$BACKUP_DIR/.zshrc.matrix"
        success_msg "已备份 ~/.zshrc.matrix"
    fi

    # Backup .p10k.zsh
    if [[ -f "$HOME/.p10k.zsh" ]]; then
        cp "$HOME/.p10k.zsh" "$BACKUP_DIR/.p10k.zsh"
        success_msg "已备份 ~/.p10k.zsh"
    fi

    # Backup user modules
    if [[ -d "$USER_MODULES_DIR" ]]; then
        cp -r "$USER_MODULES_DIR" "$BACKUP_DIR/.zshrc.local.d"
        success_msg "已备份用户模块"
    fi

    echo ""
    success_msg "备份完成: $BACKUP_DIR"
    echo ""
}

# Show current status
cmd_status() {
    echo ""
    echo "📊 配置状态"
    echo "============"
    echo ""

    echo "主配置文件:"
    if [[ -L "$HOME/.zshrc" ]]; then
        local target=$(readlink -f "$HOME/.zshrc")
        echo "  ~/.zshrc -> $target"
        if [[ "$target" == *"modular"* ]]; then
            success_msg "模块化配置已启用"
        else
            info_msg "使用其他配置"
        fi
    elif [[ -f "$HOME/.zshrc" ]]; then
        echo "  ~/.zshrc (传统配置)"
        info_msg "传统配置模式"
    else
        warning_msg "~/.zshrc 不存在"
    fi
    echo ""

    echo "系统模块:"
    if [[ -d "$SYSTEM_MODULES_DIR" ]]; then
        local count=0
        for module in "$SYSTEM_MODULES_DIR"/*.zsh; do
            if [[ -f "$module" ]]; then
                local name=$(basename "$module")
                local size=$(wc -l < "$module")
                printf "  ${GREEN}✓${NC} %-25s (%3d 行)\n" "$name" "$size"
                ((count++))
            fi
        done
        echo "  共 $count 个模块"
    else
        warning_msg "系统模块目录不存在"
    fi
    echo ""

    echo "用户模块:"
    if [[ -d "$USER_MODULES_DIR" ]]; then
        local count=0
        for module in "$USER_MODULES_DIR"/*.zsh; do
            if [[ -f "$module" ]]; then
                local name=$(basename "$module")
                local size=$(wc -l < "$module")
                printf "  ${GREEN}✓${NC} %-25s (%3d 行)\n" "$name" "$size"
                ((count++))
            fi
        done
        if [[ $count -eq 0 ]]; then
            info_msg "无用户模块"
        else
            echo "  共 $count 个模块"
        fi
    else
        info_msg "用户模块目录不存在"
    fi
    echo ""

    echo "可选模块:"
    if [[ -f "$HOME/.zshrc.matrix" ]]; then
        success_msg "Matrix系统已启用"
    else
        info_msg "Matrix系统未安装"
    fi
    echo ""
}

# Enable modular configuration
cmd_enable_modular() {
    echo ""
    echo "🚀 启用模块化配置"
    echo "=================="
    echo ""

    # Backup current config
    if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
        local backup_file="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$HOME/.zshrc" "$backup_file"
        info_msg "已备份当前配置: $backup_file"
    fi

    # Create modular config
    local modular_config="$PROJECT_ROOT/config/.zshrc.modular"
    if [[ ! -f "$modular_config" ]]; then
        error_msg "模块化配置文件不存在: $modular_config"
        return 1
    fi

    # Copy modules to ~/.zshrc.d/
    mkdir -p "$HOME/.zshrc.d"
    info_msg "正在安装模块到 ~/.zshrc.d/..."

    for module in "$SYSTEM_MODULES_DIR"/*.zsh; do
        if [[ -f "$module" ]]; then
            local name=$(basename "$module")
            cp "$module" "$HOME/.zshrc.d/$name"
            success_msg "已安装: $name"
        fi
    done

    # Install modular .zshrc
    cp "$modular_config" "$HOME/.zshrc"
    success_msg "已安装模块化配置"

    echo ""
    success_msg "模块化配置已启用！"
    echo ""
    echo "下一步操作:"
    echo "  1. 重新加载配置: exec zsh"
    echo "  2. 或重启终端"
    echo ""
    echo "管理命令:"
    echo "  zsh_config_manager.sh status   - 查看状态"
    echo "  zsh_config_manager.sh list     - 列出模块"
    echo "  zsh_config_manager.sh validate - 验证配置"
    echo ""
}

# Show help
cmd_help() {
    cat << 'EOF'
📖 ZSH 模块化配置管理器

用法:
  ./zsh_config_manager.sh <command> [options]

命令:
  list                      列出所有可用模块
  status                    显示当前配置状态
  validate                  验证配置语法
  backup                    备份当前配置
  enable-modular            启用模块化配置
  help                      显示此帮助信息

模块管理:
  要禁用某个模块，删除 ~/.zshrc.d/ 中的对应文件
  要启用某个模块，从 config/.zshrc.d/ 复制到 ~/.zshrc.d/
  要添加自定义模块，创建文件到 ~/.zshrc.local.d/

示例:
  ./zsh_config_manager.sh list
  ./zsh_config_manager.sh enable-modular
  ./zsh_config_manager.sh validate

EOF
}

# ===============================================
# Main
# ===============================================

main() {
    local command="${1:-help}"

    case "$command" in
        list)
            cmd_list
            ;;
        status)
            cmd_status
            ;;
        validate)
            cmd_validate
            ;;
        backup)
            cmd_backup
            ;;
        enable-modular)
            cmd_enable_modular
            ;;
        help|--help|-h)
            cmd_help
            ;;
        *)
            error_msg "未知命令: $command"
            echo ""
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"
