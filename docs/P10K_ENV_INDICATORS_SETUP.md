# 在 Powerlevel10k 中集成环境指示符

本指南说明如何在 Powerlevel10k 提示符中显示环境指示符（🖥️ 🌐 🔐）在第一行右侧。

## ⚡ 重要更新

**环境指示符现已自动集成到安装脚本中！**

如果你使用 `install_zsh_config.sh` 安装配置，环境指示符会**自动配置**，无需额外操作。

## 前置要求

* ✅ 已安装 Powerlevel10k 主题
* ✅ 已运行 `p10k configure` 生成 `~/.p10k.zsh`
* ✅ 已安装项目的 ZSH 配置

## 自动设置（推荐 - 已集成到安装脚本）

使用项目的安装脚本会自动配置环境指示符：

```bash
# 标准安装（自动配置环境指示符）
./scripts/install_zsh_config.sh

# 或使用 NVM 优化版本（也自动配置环境指示符）
./scripts/install_zsh_config.sh --with-optimization
```

安装完成后重新加载 ZSH：

```bash
exec zsh
```

### 独立设置脚本（已弃用）

> **注意**: `setup-p10k-env-indicators.sh` 脚本已被集成到 `install_zsh_config.sh` 中。
> 建议使用主安装脚本进行完整配置。

如果你需要单独配置环境指示符（不推荐），可以参考下面的手动设置步骤。

### 手动设置

如果自动脚本失败，可以手动修改 `~/.p10k.zsh`：

#### 步骤 1：找到 RIGHT_PROMPT_ELEMENTS

编辑 `~/.p10k.zsh`：

```bash
vim ~/.p10k.zsh
```

搜索 `POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(`

你会看到类似：

```bash
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    status                      # exit code of the last command
    command_execution_time      # duration of the last command
    # ... more elements ...
    time                        # current time
)
```

#### 步骤 2：添加 env_indicators 段

在列表的开头添加 `env_indicators`（这样指示符会显示在最右边）：

```bash
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
    env_indicators              # 👈 添加这一行
    status                      # exit code of the last command
    command_execution_time      # duration of the last command
    # ... more elements ...
    time                        # current time
)
```

#### 步骤 3：添加段函数

在 `~/.p10k.zsh` 的末尾添加以下函数：

```bash
# Environment indicators segment (custom)
prompt_env_indicators() {
    # This function is called by Powerlevel10k to display env indicators
    if typeset -f _get_env_indicators &>/dev/null; then
        local indicators=$(_get_env_indicators)
        [[ -n "$indicators" ]] && print -P "$indicators"
    fi
}
```

#### 步骤 4：重新加载

```bash
# 重新加载 ZSH
exec zsh

# 如果需要，重新加载 p10k
p10k reload
```

## 验证设置

安装完成后，您的提示符应该显示为：

```
～/workspace ⎇ master 71           🖥️ 🌐 🔐 ✓ < hao@mm
$
```

关键特征：

* ✅ 指示符显示在第一行右侧（与用户名/时间同一行）
* ✅ 指示符持续显示（每个命令都显示）
* ✅ 仅显示图标，无文字（🖥️ 🌐 🔐）
* ✅ 图标含义：
  * 🖥️ = 物理主机 / 🐳 = Docker 容器
  * 🌐 = SSH 会话 / 🏠 = 本地会话
  * 🔐 = 代理已启用（仅在启用时显示）

## 自定义指示符

### 修改图标

编辑 `~/.zsh/functions/context.zsh` 中的 `_get_env_indicators()` 函数，修改图标定义：

```bash
# 容器状态
if _is_in_container; then
    indicators+="🐳"  # 修改此图标
else
    indicators+="🖥️"  # 修改此图标
fi

# 连接方式
if _is_in_ssh; then
    indicators+=" 🌐"  # 修改此图标
else
    indicators+=" 🏠"  # 修改此图标
fi

# 代理状态
if _is_using_proxy; then
    indicators+=" 🔐"  # 修改此图标
fi
```

### 修改样式

修改 `~/.p10k.zsh` 中的 `prompt_env_indicators()` 函数来改变显示样式：

```bash
prompt_env_indicators() {
    if typeset -f _get_env_indicators &>/dev/null; then
        local indicators=$(_get_env_indicators)
        # 使用括号：
        [[ -n "$indicators" ]] && print -P "[${indicators}]"
        # 或使用其他分隔符：
        # [[ -n "$indicators" ]] && print -P "${indicators} |"
    fi
}
```

## 故障排除

### 指示符不显示

1. **检查函数是否加载**：

```bash
type _get_env_indicators
# 应该输出: _get_env_indicators is a function
```

2. **检查 context.zsh 是否被加载**：

```bash
ls -la ~/.zsh/functions/context.zsh
# 应该存在
```

3. **手动测试指示符**：

```bash
source ~/.zsh/functions/context.zsh
_get_env_indicators
# 应该输出: 🖥️ 🌐 🔐 (或类似的图标组合)
```

4. **检查 ~/.p10k.zsh 修改**：

```bash
grep -n "env_indicators" ~/.p10k.zsh
# 应该找到两处：
# - 在 RIGHT_PROMPT_ELEMENTS 中
# - prompt_env_indicators 函数定义
```

### 指示符只显示一次

这通常是因为：

* p10k 段函数没有正确定义
* ~/.p10k.zsh 没有包含正确的段定义

**解决**：确保 `prompt_env_indicators()` 函数存在于 ~/.p10k.zsh 中，并且能正确调用 `_get_env_indicators`。

### 指示符显示在错误的位置

这通常是因为：

* env_indicators 没有在正确的位置添加到 RIGHT_PROMPT_ELEMENTS

**解决**：在 RIGHT_PROMPT_ELEMENTS 的开头添加 env_indicators，使其显示最靠近右边。

## 恢复到原始配置

如果出现问题，可以恢复备份：

```bash
# 恢复 ~/.p10k.zsh 备份
cp ~/.p10k.zsh.backup ~/.p10k.zsh

# 重新加载
exec zsh
```

## 获取帮助

查看环境状态详细信息：

```bash
env_status
```

查看帮助：

```bash
zsh_help env_status
```

---

**版本**: 1.0
**最后更新**: 2025-10-19
