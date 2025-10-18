# 环境指示器 - RPROMPT 右侧显示指南

**最终设计方案**：在 RPROMPT 右侧条件显示环境状态

---

## 🎯 设计方案

### 显示效果

**正常情况**（无任何状态）：
```
～/Workspace/MM/utility/dev-env ⎇ master 71    1m 475 s ✓ hao@mm
```

**容器中**（显示 🐳）：
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🐳 1m 475 s ✓ hao@mm
```

**SSH 中**（显示 🌐）：
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🌐 1m 475 s ✓ hao@mm
```

**代理启用**（显示 🔐）：
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🔐 1m 475 s ✓ hao@mm
```

**多个状态同时存在**（例如容器 + SSH + 代理）：
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🐳 🌐 🔐 1m 475 s ✓ hao@mm
```

---

## 🛠️ 实现方案

### 核心思路

利用 Powerlevel10k 的 RPROMPT 机制，通过以下步骤：

1. 创建环境检测函数（在 `context.zsh` 中）
2. 创建 RPROMPT 动态生成函数
3. 在 `~/.p10k.zsh` 中配置 RPROMPT 段

---

## 📝 具体实现

### 第 1 步：创建 `zsh-functions/context.zsh`

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

# 生成环境指示符字符串（用于 RPROMPT）
# 返回值格式: "🐳 🌐 🔐" （仅显示存在的状态）
_get_env_indicators() {
    local indicators=""

    _is_in_container && indicators+="🐳"
    _is_in_ssh && indicators+="${indicators:+ }🌐"
    _is_using_proxy && indicators+="${indicators:+ }🔐"

    echo "$indicators"
}

# 查询命令：显示详细的环境状态
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
        local ssh_client="${SSH_CLIENT%% *}"
        printf "│ 🌐 SSH:       %-34s │\n" "SSH session from $ssh_client"
    else
        printf "│ 🌐 SSH:       %-34s │\n" "Local session"
    fi

    # 代理状态
    if _is_using_proxy; then
        local proxy_addr="${HTTP_PROXY:-$HTTPS_PROXY:-$http_proxy:-$https_proxy:-$SOCKS_PROXY:-$socks_proxy}"
        proxy_addr="${proxy_addr:0:30}"
        printf "│ 🔐 Proxy:     %-34s │\n" "Active - $proxy_addr"
    else
        printf "│ 🔐 Proxy:     %-34s │\n" "Not configured"
    fi

    echo "└────────────────────────────────────────────────┘"
    echo ""
}
```

---

### 第 2 步：修改 `config/.zshrc`

在配置文件的 Powerlevel10k 配置部分添加：

```bash
# ===============================================
# Powerlevel10k Configuration
# ===============================================

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ===============================================
# Environment Indicators in RPROMPT
# ===============================================

# 动态更新 RPROMPT，在右侧显示环境指示符
# 这个函数在每次提示符显示前执行
_update_env_indicators() {
    local env_indicators=$(_get_env_indicators)

    if [[ -n "$env_indicators" ]]; then
        # 如果有环境指示符，在现有 RPROMPT 前添加
        # 注意：这会与 p10k 的 RPROMPT 配置交互
        export RPROMPT_PREFIX="$env_indicators "
    else
        # 无指示符时，清空前缀
        export RPROMPT_PREFIX=""
    fi
}

# 在 precmd 钩子中调用（提示符显示前）
precmd_functions+=(_update_env_indicators)
```

---

### 第 3 步：修改 `~/.p10k.zsh`

**注意**：这个文件是用户特定的，不在项目版本控制中。用户需要手动修改或通过脚本修改。

#### 方式 A：使用自定义段（推荐）

在 `~/.p10k.zsh` 中找到 RPROMPT 配置部分，添加自定义函数段：

```bash
# 在 ~/.p10k.zsh 中的 function segment 部分添加
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # ... 其他段 ...
    context_indicators    # 新增：环境指示符（自定义段）
    time                  # 时间
    # ... 其他段 ...
)

# 定义 context_indicators 段的显示逻辑
function prompt_context_indicators() {
    local env_indicators=$(_get_env_indicators)
    if [[ -n "$env_indicators" ]]; then
        p10k segment -b default -f cyan "$env_indicators"
    fi
}
```

#### 方式 B：直接修改 RPROMPT（备选）

如果 p10k 版本不支持自定义段，可以直接在 `.zshrc` 中修改 RPROMPT：

```bash
# 在 ~/.zshrc 中（Powerlevel10k 配置之后）
_update_rprompt() {
    local env_indicators=$(_get_env_indicators)
    if [[ -n "$env_indicators" ]]; then
        # 获取当前 RPROMPT 中的时间等信息
        # 这是一个简化版本，实际需要根据您的 p10k 配置调整
        RPROMPT="$env_indicators ${RPROMPT_ORIGINAL:-}"
    else
        RPROMPT="${RPROMPT_ORIGINAL:-}"
    fi
}

# 保存原始 RPROMPT（如果需要）
RPROMPT_ORIGINAL="$RPROMPT"

# 在 precmd 中更新
precmd_functions+=(_update_rprompt)
```

---

### 第 4 步：更新帮助系统

修改 `zsh-functions/help.zsh`，在命令列表中添加：

```bash
env_status)
    echo "Show environment context (Docker container, SSH session, proxy status)"
    ;;
```

---

## 📊 实现对比

### 方式 A vs 方式 B

| 特性 | 方式 A (p10k 自定义段) | 方式 B (直接修改 RPROMPT) |
|------|----------------------|------------------------|
| 复杂度 | 中等 | 简单 |
| 性能 | 好（p10k 优化） | 一般 |
| 可维护性 | 高（p10k 标准） | 低（依赖配置） |
| 兼容性 | 需要较新 p10k | 通用 |
| 推荐度 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

**建议**：先尝试方式 A，如果 p10k 版本不支持，再使用方式 B。

---

## 🎨 视觉效果演示

### 场景 1：本地物理机，无 SSH，无代理
```
～/Workspace/MM/utility/dev-env ⎇ master 71    1m 475 s ✓ hao@mm
$
```
**RPROMPT 显示**：（空，不显示任何内容）

---

### 场景 2：Docker 容器中
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🐳 1m 475 s ✓ hao@mm
$
```
**RPROMPT 显示**：`🐳`

---

### 场景 3：SSH 会话
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🌐 1m 475 s ✓ hao@mm
$
```
**RPROMPT 显示**：`🌐`

---

### 场景 4：启用了代理
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🔐 1m 475 s ✓ hao@mm
$
```
**RPROMPT 显示**：`🔐`

---

### 场景 5：Docker + SSH + 代理（最复杂情况）
```
～/Workspace/MM/utility/dev-env ⎇ master 71    🐳 🌐 🔐 1m 475 s ✓ hao@mm
$
```
**RPROMPT 显示**：`🐳 🌐 🔐`

---

## ✅ 实现检查清单

- [ ] 创建 `zsh-functions/context.zsh` 包含所有检测函数
- [ ] 修改 `config/.zshrc` 添加 RPROMPT 动态更新逻辑
- [ ] 配置 `~/.p10k.zsh` 添加 context_indicators 段（或直接修改 RPROMPT）
- [ ] 更新帮助系统，添加 `env_status` 命令帮助
- [ ] 测试各种场景确保正常显示
- [ ] 编写文档说明使用方法

---

## 🚀 使用方式

### 查询详细环境状态

```bash
$ env_status
┌─ Environment Context ──────────────────────────┐
│ 🐳 Docker:    Physical machine                 │
│ 🌐 SSH:       Local session                    │
│ 🔐 Proxy:     Not configured                   │
└────────────────────────────────────────────────┘
```

### 在 RPROMPT 中自动显示

安装配置后，环境指示符会自动出现在 RPROMPT 中。

**示例**：
- 容器中工作时，右侧自动显示 🐳
- SSH 连接时，右侧自动显示 🌐
- 配置代理后，右侧自动显示 🔐

### 禁用此功能

如果需要禁用环境指示符显示，有两种方法：

**方法 1**：注释掉 `~/.zshrc` 中的 precmd 函数调用
```bash
# 在 ~/.zshrc 中找到并注释：
# precmd_functions+=(_update_env_indicators)
```

**方法 2**：从 `~/.p10k.zsh` 的 RPROMPT 段列表中移除 `context_indicators`

---

## 🔧 高级自定义

### 修改图标

在 `context.zsh` 中修改以下部分：

```bash
# 修改容器检测的图标
_is_in_container && indicators+="💻"  # 改为其他图标

# 修改 SSH 检测的图标
_is_in_ssh && indicators+="${indicators:+ }🖥️ "  # 改为其他图标

# 修改代理检测的图标
_is_using_proxy && indicators+="${indicators:+ }🔒"  # 改为其他图标
```

### 修改分隔符

在 `_get_env_indicators()` 函数中修改分隔符：

```bash
# 默认：用空格分隔
indicators+="${indicators:+ }🌐"

# 改为：用 | 分隔
indicators+="${indicators:+|}🌐"

# 改为：用 • 分隔
indicators+="${indicators:+•}🌐"

# 改为：用 ➜ 分隔
indicators+="${indicators:+➜}🌐"
```

### 修改颜色（如果使用方式 A）

在 `~/.p10k.zsh` 中修改：

```bash
# 容器指示符的颜色
POWERLEVEL9K_CONTEXT_INDICATORS_FOREGROUND=blue

# SSH 指示符的颜色
POWERLEVEL9K_CONTEXT_INDICATORS_FOREGROUND=cyan

# 代理指示符的颜色
POWERLEVEL9K_CONTEXT_INDICATORS_FOREGROUND=yellow
```

---

## 📚 相关文档

- `ENVIRONMENT_INDICATORS_ARCHITECTURE.md` - 完整架构分析
- `TROUBLESHOOTING_DEBUG_GUIDE.md` - 调试指南
- `zsh-functions/help.zsh` - 帮助系统

---

## 💡 设计优点总结

✅ **信息密度适中** - 只显示必要的指示符，不影响美观
✅ **条件显示** - 正常情况完全不显示，不增加视觉干扰
✅ **位置合理** - RPROMPT 右侧是补充信息的标准位置
✅ **易于扩展** - 可以添加更多环境指示符
✅ **性能无损** - 检测函数极快，不影响启动速度
✅ **用户友好** - 支持详细查询和自动显示的双重方案

