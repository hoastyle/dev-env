# Powerlevel10k 环境指示符集成指南

**用于将环境指示符集成到 ~/.p10k.zsh 的完整指南**

---

## 📋 概述

环境指示符功能已完成实现，包含以下组件：

1. ✅ **环境检测函数** - `zsh-functions/context.zsh`
2. ✅ **RPROMPT 集成** - `config/.zshrc` 中的动态更新逻辑
3. ✅ **查询命令** - `env_status` 命令用于查看详细状态

现在您需要配置 `~/.p10k.zsh` 来正确显示这些环境指示符。

---

## 🚀 快速开始

### 步骤 1：确认配置已安装

首先，确认所有配置已正确安装：

```bash
# 检查 context.zsh 已加载
grep -l "_get_env_indicators" ~/.zsh/functions/*.zsh

# 输出应该包含: /home/hao/.zsh/functions/context.zsh
```

### 步骤 2：验证 RPROMPT 更新逻辑

```bash
# 检查 .zshrc 中已添加 RPROMPT 更新
grep -A 5 "_update_env_indicators_rprompt" ~/.zshrc
```

### 步骤 3：测试功能

```bash
# 在新 ZSH 会话中执行
source ~/.zshrc

# 验证环境指示符
env_status

# 应该显示当前的环境上下文信息
```

---

## 🎨 Powerlevel10k 配置

### 理解 RPROMPT 的工作原理

在当前实现中，RPROMPT 的更新流程如下：

```
┌─ ZSH 启动
│
├─ 加载 ~/.p10k.zsh
│  ├─ 设置初始 RPROMPT 值
│  └─ 保存为 RPROMPT_ORIGINAL
│
├─ 加载 ~/.zshrc RPROMPT 集成代码
│  ├─ 定义 _save_original_rprompt()
│  ├─ 定义 _update_env_indicators_rprompt()
│  └─ 注册 precmd 钩子
│
├─ 每次提示符显示前 (precmd)
│  ├─ 调用 _update_env_indicators_rprompt()
│  ├─ 获取环境指示符（🐳🌐🔐）
│  ├─ 如有指示符，将其放在 RPROMPT 前面
│  └─ 如无指示符，保持 RPROMPT 不变
│
└─ 提示符显示
   └─ 根据当前 RPROMPT 显示内容
```

### 配置 Powerlevel10k RPROMPT

**重要**: Powerlevel10k 默认通过 `~/.p10k.zsh` 控制 RPROMPT。我们的实现与其兼容。

#### 方式 A：使用默认配置（推荐）

如果您还没有运行过 `p10k configure`，直接使用即可：

```bash
# 首次启动 ZSH（或运行 p10k configure）
p10k configure

# 在配置过程中选择默认选项
# 环境指示符会自动出现在 RPROMPT 中
```

#### 方式 B：在现有配置中添加自定义段

如果您已有 `~/.p10k.zsh` 配置，可以添加自定义段：

**步骤 1**: 打开 `~/.p10k.zsh`

```bash
vim ~/.p10k.zsh
```

**步骤 2**: 找到 RPROMPT 配置部分（通常在文件中间）

搜索 `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS`:

```bash
# 例如：
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # =========================[ Line #1 ]=========================
    context                      # user@hostname
    root_indicator
    # =========================[ Line #2 ]=========================
    command_execution_time        # previous command duration
    time                          # current time
    background_jobs               # presence of background jobs
)
```

**步骤 3**: 添加自定义 context_indicators 段（可选）

如果想在 p10k 中添加自定义段来显示环境指示符：

```bash
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    # ... 其他段 ...
    context_indicators            # 新增：环境指示符
    time
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

**步骤 4**: 保存并重载配置

```bash
# 方式 1：重新启动 ZSH
exec zsh

# 方式 2：或在现有会话中重载
source ~/.p10k.zsh
```

---

## 📊 显示效果对比

### 默认情况（无环境指示符）

```
～/Workspace/MM/utility/dev-env ⎇ master 71    1m 475 s ✓ hao@mm
$
```

**RPROMPT 中**：显示时间和用户信息，无额外指示符

---

### 在 Docker 容器中

```
～/Workspace/MM/utility/dev-env ⎇ master 71    🐳 1m 475 s ✓ hao@mm
$
```

**RPROMPT 中**：🐳 出现在时间前面

---

### 在 SSH 会话中

```
～/Workspace/MM/utility/dev-env ⎇ master 71    🌐 1m 475 s ✓ hao@mm
$
```

**RPROMPT 中**：🌐 出现在时间前面

---

### 启用代理

```
～/Workspace/MM/utility/dev-env ⎇ master 71    🔐 1m 475 s ✓ hao@mm
$
```

**RPROMPT 中**：🔐 出现在时间前面

---

### 多个指示符同时显示

```
～/Workspace/MM/utility/dev-env ⎇ master 71    🐳 🌐 🔐 1m 475 s ✓ hao@mm
$
```

**RPROMPT 中**：所有有效的指示符都显示

---

## 🔧 自定义选项

### 修改指示符图标

编辑 `~/.zsh/functions/context.zsh`（或 `zsh-functions/context.zsh`），修改 `_get_env_indicators()` 函数：

```bash
# 原始
_get_env_indicators() {
    local indicators=""
    _is_in_container && indicators+="🐳"
    _is_in_ssh && indicators+="${indicators:+ }🌐"
    _is_using_proxy && indicators+="${indicators:+ }🔐"
    echo "$indicators"
}

# 修改后（例子）
_get_env_indicators() {
    local indicators=""
    _is_in_container && indicators+="💻"        # 改为 💻
    _is_in_ssh && indicators+="${indicators:+ }🖥️ "   # 改为 🖥️
    _is_using_proxy && indicators+="${indicators:+ }🛡️ "  # 改为 🛡️
    echo "$indicators"
}
```

### 修改分隔符

在 `_get_env_indicators()` 中修改分隔符：

```bash
# 默认分隔符：空格 " "
_is_in_ssh && indicators+="${indicators:+ }🌐"

# 改为：| 分隔
_is_in_ssh && indicators+="${indicators:+|}🌐"

# 改为：• 分隔
_is_in_ssh && indicators+="${indicators:+•}🌐"

# 改为：➜ 分隔
_is_in_ssh && indicators+="${indicators:+➜}🌐"
```

### 修改 RPROMPT 中指示符的颜色

如果使用了方式 B 的自定义段，可以在 `~/.p10k.zsh` 中修改颜色：

```bash
# 容器指示符的颜色
POWERLEVEL9K_CONTEXT_INDICATORS_FOREGROUND=blue

# SSH 指示符的颜色
POWERLEVEL9K_CONTEXT_INDICATORS_FOREGROUND=cyan

# 代理指示符的颜色
POWERLEVEL9K_CONTEXT_INDICATORS_FOREGROUND=yellow

# 背景颜色
POWERLEVEL9K_CONTEXT_INDICATORS_BACKGROUND=black
```

---

## 🧪 故障排除

### 问题 1：环境指示符不显示

**症状**：即使在容器或 SSH 中，RPROMPT 也没有显示指示符

**排查步骤**：

```bash
# 1. 验证 context.zsh 已正确加载
echo "检查函数是否存在："
type _get_env_indicators

# 2. 手动测试环境检测
_is_in_container && echo "容器: yes" || echo "容器: no"
_is_in_ssh && echo "SSH: yes" || echo "SSH: no"
_is_using_proxy && echo "代理: yes" || echo "代理: no"

# 3. 手动获取指示符
_get_env_indicators

# 4. 检查 RPROMPT 更新函数是否被调用
env | grep RPROMPT
```

**常见原因和解决方案**：

- ❌ `context.zsh` 未加载
  ```bash
  # 检查 ~/.zshrc 是否加载自定义函数
  grep -n "~/.zsh/functions" ~/.zshrc

  # 如果未加载，添加到 ~/.zshrc
  if [[ -d "$HOME/.zsh/functions" ]]; then
      for func in $HOME/.zsh/functions/*.zsh; do
          source "$func"
      done
  fi
  ```

- ❌ RPROMPT 更新钩子未注册
  ```bash
  # 检查 precmd_functions
  echo $precmd_functions

  # 应该包含 _update_env_indicators_rprompt
  ```

- ❌ 环境变量未设置
  ```bash
  # 检查 SSH 环境变量
  echo $SSH_CLIENT
  echo $SSH_CONNECTION

  # 检查代理环境变量
  echo $HTTP_PROXY
  echo $HTTPS_PROXY
  ```

### 问题 2：RPROMPT 显示位置不对

**症状**：指示符显示在 RPROMPT 的不正确位置

**解决方案**：

```bash
# 1. 检查 RPROMPT_ORIGINAL 是否正确保存
echo "RPROMPT_ORIGINAL: $RPROMPT_ORIGINAL"
echo "RPROMPT: $RPROMPT"

# 2. 重新加载配置
exec zsh

# 3. 检查是否有多个 precmd 函数冲突
typeset -f precmd
```

### 问题 3：指示符闪烁或不稳定

**症状**：环境指示符时显示时不显示

**解决方案**：

```bash
# 1. 检查是否有其他进程修改环境变量
env | grep -i proxy

# 2. 检查 precmd 函数执行顺序
echo $precmd_functions

# 3. 禁用其他可能冲突的插件
# 例如，某些 antigen 插件可能会修改 RPROMPT
```

### 问题 4：环境检测不准确

**症状**：指示符显示错误的环境状态

**解决方案**：

```bash
# 1. 检查 Docker 检测
if [[ -f "/.dockerenv" ]]; then
    echo "在容器中"
else
    echo "在物理主机上"
fi

# 2. 检查 SSH 检测
echo "SSH_CLIENT: $SSH_CLIENT"
echo "SSH_CONNECTION: $SSH_CONNECTION"
echo "SSH_TTY: $SSH_TTY"

# 3. 检查代理检测
echo "HTTP_PROXY: $HTTP_PROXY"
echo "HTTPS_PROXY: $HTTPS_PROXY"
echo "SOCKS_PROXY: $SOCKS_PROXY"
```

---

## 📚 相关命令

### 查看环境状态

```bash
# 查看详细的环境信息
env_status

# 输出类似：
# ┌─ Environment Context ──────────────────────────┐
# │ 🐳 Docker:    Physical machine                 │
# │ 🌐 SSH:       SSH session from 127.0.0.1       │
# │ 🔐 Proxy:     Active - http://127.0.0.1:7890   │
# └────────────────────────────────────────────────┘
```

### 查看帮助

```bash
# 查看所有命令
zsh_help

# 查看环境检测类命令
zsh_help 环境检测

# 查看 env_status 命令帮助
zsh_help env_status
```

---

## ✅ 验证检查清单

安装和配置完成后，请确认以下项目：

- [ ] `context.zsh` 已复制到 `~/.zsh/functions/`
- [ ] `~/.zshrc` 中已添加 RPROMPT 更新逻辑
- [ ] `~/.p10k.zsh` 已正确加载（或重新生成）
- [ ] 运行 `env_status` 显示正确的环境信息
- [ ] RPROMPT 在不同环境下正确显示指示符：
  - [ ] 物理主机上不显示指示符
  - [ ] Docker 容器中显示 🐳
  - [ ] SSH 会话中显示 🌐
  - [ ] 启用代理时显示 🔐
- [ ] 多个条件同时满足时显示多个指示符
- [ ] 运行 `zsh_help env_status` 显示帮助信息

---

## 🎯 最佳实践

### 1. 备份 p10k 配置

在修改前备份 `~/.p10k.zsh`：

```bash
cp ~/.p10k.zsh ~/.p10k.zsh.backup
```

### 2. 逐步测试

修改后，立即测试功能：

```bash
# 新建一个 ZSH 会话
zsh

# 检查是否正常工作
env_status
```

### 3. 避免过度自定义

默认的指示符和分隔符已经过精心设计，避免过度自定义导致视觉混乱。

### 4. 性能考虑

所有环境检测函数都非常快速（<1ms），不会影响 ZSH 启动性能。

### 5. 定期更新

如果发现新的需求，可以扩展 `context.zsh` 中的检测函数，但应保持与原有系统的兼容性。

---

## 📞 获取帮助

### 查看相关文档

- `ENVIRONMENT_INDICATORS_ARCHITECTURE.md` - 完整架构分析
- `ENVIRONMENT_INDICATORS_RPROMPT_GUIDE.md` - RPROMPT 显示指南
- `TROUBLESHOOTING_DEBUG_GUIDE.md` - 调试指南

### 常用命令

```bash
# 查看所有帮助
zsh_help

# 查看特定命令
zsh_help env_status
zsh_help check_environment

# 运行诊断
env_status
```

---

**配置版本**: 1.0
**最后更新**: 2025-10-18
**维护人**: dev-env team

