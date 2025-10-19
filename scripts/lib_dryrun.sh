#!/bin/bash
# ===============================================
# Dry-Run Mode Library
# ===============================================
# 提供统一的干运行模式支持
# 版本: 1.0
# 作者: Claude AI Assistant

# 干运行模式标志
DRY_RUN="${DRY_RUN:-false}"

# ===============================================
# 干运行命令执行
# ===============================================

# 执行系统命令 (支持干运行)
# 用法: dry_exec <command> [args...]
dry_exec() {
    local cmd="$1"
    shift

    if [[ "$DRY_RUN" == "true" ]]; then
        # 干运行模式: 显示命令但不执行
        dry_print_command "$cmd" "$@"
        return 0
    else
        # 正常模式: 执行命令
        "$cmd" "$@"
        return $?
    fi
}

# 执行 mkdir 命令 (支持干运行)
dry_mkdir() {
    local target="$1"

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ ! -d "$target" ]]; then
            dry_print_action "mkdir -p" "$target"
        fi
        return 0
    else
        mkdir -p "$target"
        return $?
    fi
}

# 执行 cp 命令 (支持干运行)
dry_cp() {
    local source="$1"
    local dest="$2"
    local recursive="${3:-}"

    if [[ "$DRY_RUN" == "true" ]]; then
        local cmd="cp"
        [[ -n "$recursive" ]] && cmd="cp -r"

        if [[ -e "$source" ]]; then
            dry_print_action "$cmd" "$source -> $dest"
        fi
        return 0
    else
        if [[ -n "$recursive" ]]; then
            cp -r "$source" "$dest"
        else
            cp "$source" "$dest"
        fi
        return $?
    fi
}

# 执行 chmod 命令 (支持干运行)
dry_chmod() {
    local mode="$1"
    local target="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        if [[ -e "$target" ]]; then
            dry_print_action "chmod" "$mode $target"
        fi
        return 0
    else
        chmod "$mode" "$target"
        return $?
    fi
}

# 执行 rm 命令 (支持干运行)
dry_rm() {
    local recursive="${1:-}"
    local target="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        local cmd="rm"
        [[ "$recursive" == "-r" ]] && cmd="rm -rf"

        if [[ -e "$target" ]]; then
            dry_print_action "$cmd" "$target"
        fi
        return 0
    else
        if [[ "$recursive" == "-r" ]]; then
            rm -rf "$target"
        else
            rm "$target"
        fi
        return $?
    fi
}

# 执行 ln 命令 (支持干运行)
dry_ln() {
    local force="${1:-}"
    local source="$2"
    local target="$3"

    if [[ "$DRY_RUN" == "true" ]]; then
        local cmd="ln -s"
        [[ "$force" == "-f" ]] && cmd="ln -sf"

        if [[ -e "$source" ]]; then
            dry_print_action "$cmd" "$source -> $target"
        fi
        return 0
    else
        if [[ "$force" == "-f" ]]; then
            ln -sf "$source" "$target"
        else
            ln -s "$source" "$target"
        fi
        return $?
    fi
}

# 执行导出命令 (支持干运行)
dry_export() {
    local var_name="$1"
    local var_value="$2"

    if [[ "$DRY_RUN" == "true" ]]; then
        dry_print_action "export" "$var_name=\"$var_value\""
        return 0
    else
        export "$var_name=$var_value"
        return $?
    fi
}

# ===============================================
# 干运行模式输出
# ===============================================

# 打印操作 (干运行预览)
dry_print_action() {
    local action="$1"
    local details="$2"

    echo -e "${CYAN}[DRY-RUN]${NC} $action: $details"
}

# 打印命令 (干运行预览)
dry_print_command() {
    local cmd="$1"
    shift
    local args="$@"

    echo -e "${CYAN}[DRY-RUN]${NC} $cmd $args"
}

# 打印干运行模式启用信息
dry_run_notice() {
    echo ""
    echo -e "${YELLOW}┌─ 干运行模式已启用 ──────────────────────────────${NC}"
    echo -e "${YELLOW}│${NC} 将显示所有操作但${RED}不会实际执行${NC}"
    echo -e "${YELLOW}│${NC} 使用 ${CYAN}./script.sh${NC} 执行实际操作"
    echo -e "${YELLOW}└───────────────────────────────────────────────${NC}"
    echo ""
}

# 打印干运行模式完成信息
dry_run_complete() {
    echo ""
    echo -e "${GREEN}✓ 干运行模式预览完成${NC}"
    echo -e "${CYAN}要执行这些操作，请运行:${NC}"
    echo -e "${CYAN}  $0 $original_args${NC}"
    echo ""
}

# ===============================================
# 干运行模式验证
# ===============================================

# 检查是否启用了干运行模式
is_dry_run() {
    [[ "$DRY_RUN" == "true" ]]
}

# 获取干运行状态字符串
get_dry_run_status() {
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN]"
    else
        echo "[REAL]"
    fi
}

# ===============================================
# 干运行模式统计
# ===============================================

# 操作计数器
DRY_RUN_ACTION_COUNT=0

# 增加操作计数
dry_run_increment() {
    ((DRY_RUN_ACTION_COUNT++))
}

# 获取操作计数
dry_run_get_count() {
    echo "$DRY_RUN_ACTION_COUNT"
}

# 打印操作统计
dry_run_print_stats() {
    local count=$(dry_run_get_count)

    if [[ "$DRY_RUN" == "true" ]]; then
        echo ""
        echo -e "${CYAN}干运行模式统计:${NC}"
        echo -e "${CYAN}  预计操作数: $count${NC}"
        echo ""
    fi
}

# ===============================================
# 导出函数供其他脚本使用
# ===============================================

export -f dry_exec dry_mkdir dry_cp dry_chmod dry_rm dry_ln dry_export
export -f dry_print_action dry_print_command
export -f dry_run_notice dry_run_complete
export -f is_dry_run get_dry_run_status
export -f dry_run_increment dry_run_get_count dry_run_print_stats
