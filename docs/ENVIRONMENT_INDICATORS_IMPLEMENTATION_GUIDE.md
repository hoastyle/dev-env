# 环境指示器实现指南

**基于当前设计的具体实现**

---

## 📋 实现方案

### 推荐方案：独立状态行（默认可选）

```
[ENV] 🐳 container | 🌐 ssh | 🔐 proxy
～/Workspace/MM/utility/dev-env ⎇ master 71    1m 475 s ✓ hao@mm
$
```

**为何选择这个方案**：
- ✅ 与现有 Powerlevel10k 设计完全兼容
- ✅ 不增加提示符的水平长度（已经相当长）
- ✅ 环境信息清晰独立
- ✅ 用户可随时启用/禁用
- ✅ 性能影响极小

---

## 🛠️ 具体实现步骤

### 第 1 阶段：基础命令 `env_status`

**文件**: `zsh-functions/context.zsh`（新建）

```bash
#!/usr/bin/env zsh
# ===============================================
# Environment Context Detection Functions
# ===============================================

# 检测是否在 Docker 容器中
_is_in_container() {
    [[ -f "/.dockerenv" ]] && return 0
    return 1
}

# 检测是否在 SSH 会话中
_is_in_ssh() {
    [[ -n "$SSH_CLIENT" ]] || [[ -n "$SSH_CONNECTION" ]] || [[ -n "$SSH_TTY" ]]
    return $?
}

# 检测是否使用了代理
_is_using_proxy() {
    [[ -n "$HTTP_PROXY$HTTPS_PROXY$http_proxy$https_proxy$SOCKS_PROXY$socks_proxy" ]]
    return $?
}

# 获取代理信息
_get_proxy_info() {
    if _is_using_proxy; then
        # 优先级: HTTP_PROXY > HTTPS_PROXY > http_proxy > https_proxy > SOCKS_PROXY > socks_proxy
        echo "${HTTP_PROXY:-$HTTPS_PROXY:-$http_proxy:-$https_proxy:-$SOCKS_PROXY:-$socks_proxy}"
    fi
}

# 获取 SSH 连接信息
_get_ssh_info() {
    if [[ -n "$SSH_CLIENT" ]]; then
        echo "${SSH_CLIENT%% *}"  # 客户端 IP
    elif [[ -n "$SSH_CONNECTION" ]]; then
        echo "${SSH_CONNECTION%% *}"  # 客户端 IP
    fi
}

# 环境状态查询命令（一次性查询）
env_status() {
    if handle_help_param "env_status" "$1"; then
        cat << 'HELP'
Show current environment context (container, SSH, proxy status)

Usage:
  env_status          Show environment status
  env_status --help   Show this help message

Example:
  $ env_status
  ┌─ Environment Context ──────────────────────────┐
  │ 🐳 Docker:    In container (container_name)   │
  │ 🌐 SSH:       SSH session (user@1.2.3.4)      │
  │ 🔐 Proxy:     Active - http://proxy:8080      │
  └────────────────────────────────────────────────┘
HELP
        return 0
    fi

    echo ""
    echo "┌─ Environment Context ──────────────────────────┐"

    # Docker 状态
    if _is_in_container; then
        printf "│ 🐳 Docker:    %-34s │\n" "In container ($(hostname))"
    else
        printf "│ 🐳 Docker:    %-34s │\n" "Physical machine"
    fi

    # SSH 状态
    if _is_in_ssh; then
        local ssh_client=$(_get_ssh_info)
        printf "│ 🌐 SSH:       %-34s │\n" "SSH session from $ssh_client"
    else
        printf "│ 🌐 SSH:       %-34s │\n" "Local session"
    fi

    # 代理状态
    if _is_using_proxy; then
        local proxy_addr=$(_get_proxy_info)
        # 截断代理地址以适应行宽
        proxy_addr="${proxy_addr:0:30}"
        printf "│ 🔐 Proxy:     %-34s │\n" "Active - $proxy_addr"
    else
        printf "│ 🔐 Proxy:     %-34s │\n" "Not configured"
    fi

    echo "└────────────────────────────────────────────────┘"
    echo ""
}

# 显示环境指示符行（在提示符前显示）
_show_env_context_line() {
    [[ "$DEV_ENV_SHOW_CONTEXT_LINE" != "1" ]] && return

    local indicators=""
    local separators=""

    if _is_in_container; then
        indicators+="🐳 container"
        separators+=" | "
    fi

    if _is_in_ssh; then
        indicators+="${indicators:+${separators}}🌐 ssh"
        separators+=" | "
    fi

    if _is_using_proxy; then
        indicators+="${indicators:+${separators}}🔐 proxy"
    fi

    # 只在至少有一个指示符时显示
    [[ -n "$indicators" ]] && echo "[ENV] $indicators"
}

# 配置自动显示（在 precmd 中调用）
if [[ "$DEV_ENV_SHOW_CONTEXT_LINE" == "1" ]]; then
    # 如果 precmd_functions 还没有定义，定义它
    [[ -z "${precmd_functions[@]}" ]] && typeset -a precmd_functions

    # 添加到 precmd 钩子（在提示符显示前执行）
    precmd_functions+=(_show_env_context_line)
fi
```

---

### 第 2 阶段：修改配置文件

**文件修改**: `config/.zshrc`

在"自定义函数加载"部分后添加：

```bash
# ===============================================
# Environment Context Configuration (Optional)
# ===============================================

# 可选：启用环境上下文指示行
# 取消以下注释来启用环境上下文显示
# export DEV_ENV_SHOW_CONTEXT_LINE=1

# 注意：
# - 默认禁用（保持提示符简洁）
# - 启用后在提示符前显示 [ENV] 指示行
# - 仅在存在容器/SSH/代理时显示
#
# 启用方式：
#   1. 编辑 ~/.zshrc，取消上面的注释
#   2. 运行 exec zsh 重新加载
#   3. 或使用命令: export DEV_ENV_SHOW_CONTEXT_LINE=1 && exec zsh
#
# 禁用方式：
#   unset DEV_ENV_SHOW_CONTEXT_LINE && exec zsh
```

---

### 第 3 阶段：更新帮助系统

**文件修改**: `zsh-functions/help.zsh`

在 `_list_all_commands()` 函数的命令列表中添加：

```bash
env_status)
    echo "Show environment context (Docker container, SSH session, proxy status)"
    ;;
```

在 `_show_command_help()` 函数中添加对 `env_status` 的支持（实际上已通过 `handle_help_param` 自动支持）。

---

## 📊 使用示例

### 基础使用

**查询环境状态**:
```bash
$ env_status

┌─ Environment Context ──────────────────────────┐
│ 🐳 Docker:    Physical machine                 │
│ 🌐 SSH:       Local session                    │
│ 🔐 Proxy:     Not configured                   │
└────────────────────────────────────────────────┘
```

**查看帮助**:
```bash
$ zsh_help env_status
$ env_status --help
```

### 启用自动显示

**方式 1：修改配置文件**
```bash
# 编辑 ~/.zshrc
export DEV_ENV_SHOW_CONTEXT_LINE=1

# 重新加载
exec zsh
```

**方式 2：临时启用**
```bash
$ export DEV_ENV_SHOW_CONTEXT_LINE=1 && exec zsh
```

**启用后的效果**:
```
[ENV] 🐳 container | 🌐 ssh | 🔐 proxy
～/Workspace/MM/utility/dev-env ⎇ master 71    1m 475 s ✓ hao@mm
$
```

### 禁用自动显示

```bash
$ unset DEV_ENV_SHOW_CONTEXT_LINE && exec zsh
```

---

## 🎨 自定义指示符格式

用户可以在环境变量中自定义显示的内容。在 `context.zsh` 中修改以下部分：

```bash
# 修改图标
# Docker: 🐳 → 🐳  🐳  💻  等
# SSH:    🌐 → 🌐  🌍  📡  🔗  等
# Proxy:  🔐 → 🔐  🛡️  🔒  🌐  等

# 修改分隔符
# 默认: " | "
# 可改为: " • ", " | ", " ➜ " 等

# 修改行前缀
# 默认: "[ENV]"
# 可改为: "[CONTEXT]", "[STATUS]", "⚙️  " 等
```

---

## ✅ 验收标准

完成实现应满足：

- [x] 创建 `context.zsh` 文件包含所有检测函数
- [x] `env_status` 命令可正确显示三种环境状态
- [x] 可通过 `DEV_ENV_SHOW_CONTEXT_LINE` 启用/禁用自动显示
- [x] 自动显示在提示符前独立一行
- [x] 完全与现有 Powerlevel10k 兼容
- [x] 更新帮助系统文档
- [x] 添加完整的使用文档

---

## 🚀 分阶段实现时间表

| 阶段 | 功能 | 预计工作量 | 优先级 |
|------|------|----------|--------|
| 1 | `env_status` 命令 + 自动显示功能 | 30 分钟 | 🔴 高 |
| 2 | 修改配置文件和帮助系统 | 10 分钟 | 🔴 高 |
| 3 | 文档和示例 | 15 分钟 | 🟡 中 |
| **总计** | - | **55 分钟** | - |

---

## 💡 设计决策说明

### 为什么不集成到 Powerlevel10k？

虽然技术上可行，但基于您当前的提示符设计：

1. **已经充实** - 左侧（路径+Git）+ 右侧（时间+用户）
2. **避免过长** - 提示符已接近理想长度限制
3. **信息分离** - 环境上下文是"系统级"信息，与命令信息分离更清晰
4. **用户自主** - 可选显示，不强制所有人接受

### 为什么选择可选启用？

- 🎯 默认保持极简（不影响快速启动）
- 🎯 需要时才显示（符合最小化原则）
- 🎯 尊重用户偏好（有人喜欢简洁，有人需要完整信息）
- 🎯 易于调试（配置问题时可禁用）

---

## 🔧 故障排除

**Q: `env_status` 命令找不到？**
A: 确保 `context.zsh` 已被加载。检查 `~/.zsh/functions/` 中是否存在该文件，或运行 `source ~/.zsh/functions/context.zsh`

**Q: 自动显示未出现？**
A: 检查环境变量设置：`echo $DEV_ENV_SHOW_CONTEXT_LINE`。确保设置为 `1` 并重新加载 zsh。

**Q: SSH 检测未工作？**
A: 某些 SSH 配置可能未设置 `SSH_CLIENT` 等变量。使用 `env_status` 命令手动检查，或检查 SSH 配置文件。

**Q: 提示符位置不对？**
A: 使用 `zsh_help check_environment` 检查调试信息，或查看 `TROUBLESHOOTING_DEBUG_GUIDE.md`。

---

## 📚 相关文档

- `ENVIRONMENT_INDICATORS_ARCHITECTURE.md` - 完整架构分析
- `TROUBLESHOOTING_DEBUG_GUIDE.md` - 调试指南
- `zsh-functions/help.zsh` - 帮助系统

