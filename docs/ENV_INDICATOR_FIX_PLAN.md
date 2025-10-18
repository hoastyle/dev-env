# 环境指示符功能 - 问题确认与修复计划

**确认日期**: 2025-10-19
**状态**: 问题确认完成，等待修复

---

## 📋 问题确认

### 问题 1️⃣：安装脚本不支持环境指示符

**当前状态** ❌
```
./scripts/install_zsh_config.sh
  • 不复制 context.zsh 文件
  • 不安装 RPROMPT 集成代码
  • 无法自动配置环境指示符

./scripts/install_zsh_config.sh --with-optimization
  • 同上，仅支持 NVM 优化参数
  • 环境指示符功能不可用
```

**用户需求** ✅
```
两种方式都应该支持环境指示符功能：
  • ./scripts/install_zsh_config.sh
  • ./scripts/install_zsh_config.sh --with-optimization
```

**影响** 🔴
- 用户无法通过安装脚本自动安装环境指示符
- 需要手动配置，降低用户体验

---

### 问题 2️⃣：指示符显示在第二行而非第一行

**当前实现** ❌
```
第一行（提示符所在行）:
～/workspace ⎇ master 71                   1m 475 s ✓ hao@mm

第二行（输入所在行）:
🌐 🔐
$  ← 光标在这里
```

**技术原因**
- 当前使用 RPROMPT（右侧提示符）
- Powerlevel10k 将 RPROMPT 显示在第二行
- 在 precmd 钩子中动态更新 RPROMPT

**用户需求** ✅
```
指示符应该显示在第一行：
～/workspace ⎇ master 71  🌐 🔐 1m 475 s ✓ hao@mm

$  ← 光标在第二行
```

**影响** 🔴
- 指示符位置不符合用户预期
- 占用额外的行空间

---

### 问题 3️⃣：指示符是条件显示而非常态显示

**当前实现** ❌
```
物理主机 + 本地会话 + 无代理:
～/workspace ⎇ master 71       1m 475 s ✓ hao@mm
(无任何指示符 - 不显示)

SSH 会话 + 启用代理:
～/workspace ⎇ master 71    🌐 🔐 1m 475 s ✓ hao@mm
(显示两个指示符)
```

**用户需求** ✅
```
常态化显示 - 总是显示所有环境状态：
物理主机 + 本地会话 + 无代理:
🖥️ 物理主机 🏠 本地 ✗ 无代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm

SSH 会话 + 启用代理:
🐳 Docker 🌐 SSH ✓ 代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm
```

**当前行为**
- 使用 `_get_env_indicators()` 检测条件
- 只在条件满足时生成指示符字符串
- 条件不满足时返回空字符串

**影响** 🔴
- 信息不完整，用户不知道当前是什么环境
- 需要主动运行 `env_status` 才能查看完整信息

---

## 🔧 修复计划

### 修复 1️⃣：安装脚本集成环境指示符

**修改范围**: `scripts/install_zsh_config.sh`

**修改内容**:
```bash
# 在 install_config_files() 函数中添加：
# 1. 复制 context.zsh 到 ~/.zsh/functions/
# 2. 确保 .zshrc 包含 RPROMPT 集成代码

# 两种方式都支持（无参数和 --with-optimization）
```

**实现步骤**:
1. 在 `install_config_files()` 函数中添加 context.zsh 复制逻辑
2. 验证 RPROMPT 集成代码已在 .zshrc 中
3. 两种安装方式都调用相同的安装逻辑

**预期结果**:
```bash
./scripts/install_zsh_config.sh
# ✓ 复制 context.zsh
# ✓ 配置 RPROMPT 集成

./scripts/install_zsh_config.sh --with-optimization
# ✓ 复制 context.zsh (使用优化版本配置)
# ✓ 配置 RPROMPT 集成
```

---

### 修复 2️⃣：将指示符显示在第一行

**修改范围**: `zsh-functions/context.zsh` 和 `config/.zshrc`

**当前机制** ❌
```bash
# 在 precmd 中动态更新 RPROMPT
# RPROMPT 在 Powerlevel10k 中显示在第二行
_update_env_indicators_rprompt() {
    export RPROMPT="$env_indicators ${RPROMPT_ORIGINAL}"
}
```

**新机制** ✅
```bash
# 将指示符集成到 PROMPT 或 PS1 中
# 需要修改 Powerlevel10k 左侧提示符

选项 A: 修改 ~/.p10k.zsh 中的 LEFT_PROMPT_ELEMENTS
选项 B: 使用自定义 PS1 段
选项 C: 在 LPROMPT 中添加环境指示符段
```

**推荐方案**: 选项 A
- 创建自定义 p10k 段 `context_indicators`
- 将其添加到 `LEFT_PROMPT_ELEMENTS` 的开头
- 在提示符左侧显示，视觉上在第一行

**实现步骤**:
1. 修改 `context.zsh` 中的指示符格式
2. 创建 p10k 兼容的段函数
3. 生成示例 p10k 配置
4. 提供集成文档

**预期结果**:
```
第一行（指示符 + 提示符）:
🌐 SSH  🔐 代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm
```

---

### 修复 3️⃣：常态化显示所有环境状态

**修改范围**: `zsh-functions/context.zsh`

**当前函数** ❌
```bash
_get_env_indicators() {
    local indicators=""
    _is_in_container && indicators+="🐳"
    _is_in_ssh && indicators+="${indicators:+ }🌐"
    _is_using_proxy && indicators+="${indicators:+ }🔐"
    echo "$indicators"
    # 结果: 只显示满足条件的指示符
    # 示例: "" 或 "🌐 🔐" 或 "🐳"
}
```

**新函数** ✅
```bash
_get_env_indicators_all() {
    local indicators=""

    # 总是显示所有状态
    if _is_in_container; then
        indicators+="🐳 Docker "
    else
        indicators+="🖥️ 物理 "
    fi

    if _is_in_ssh; then
        indicators+="🌐 SSH "
    else
        indicators+="🏠 本地 "
    fi

    if _is_using_proxy; then
        indicators+="✓ 代理"
    else
        indicators+="✗ 无代理"
    fi

    echo "$indicators"
    # 结果: 总是显示完整的环境状态
    # 示例: "🖥️ 物理 🏠 本地 ✗ 无代理"
    #      "🐳 Docker 🌐 SSH ✓ 代理"
}
```

**显示示例**:
```
【场景 1】物理主机 + 本地 + 无代理
  🖥️ 物理 🏠 本地 ✗ 无代理 ~/workspace ⎇ master

【场景 2】Docker + SSH + 代理
  🐳 Docker 🌐 SSH ✓ 代理 ~/workspace ⎇ master

【场景 3】Docker + 本地 + 无代理
  🐳 Docker 🏠 本地 ✗ 无代理 ~/workspace ⎇ master
```

**实现步骤**:
1. 创建 `_get_env_indicators_all()` 新函数
2. 修改 RPROMPT 更新逻辑使用新函数
3. 更新所有相关文档

---

## 📊 修复优先级

| 修复 | 优先级 | 工作量 | 复杂度 |
|------|--------|--------|--------|
| **修复 1** (安装脚本) | 🔴 高 | 30 分钟 | ⭐ 简单 |
| **修复 2** (第一行显示) | 🔴 高 | 60 分钟 | ⭐⭐ 中等 |
| **修复 3** (常态显示) | 🔴 高 | 20 分钟 | ⭐ 简单 |

**总工作量**: 约 2 小时

---

## 🎯 修复后的预期效果

### 使用体验

```bash
# 1. 安装（两种方式都支持）
./scripts/install_zsh_config.sh
或
./scripts/install_zsh_config.sh --with-optimization

# 2. 重新加载
exec zsh

# 3. 自动显示环境指示符在第一行，常态化显示
🐳 Docker 🌐 SSH ✓ 代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm
$

# 4. 查询详细信息（可选）
env_status
```

### 显示效果

**正常开发环境** (物理主机)
```
🖥️ 物理 🏠 本地 ✗ 无代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm
$
```

**远程开发** (SSH + 代理)
```
🖥️ 物理 🌐 SSH ✓ 代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm
$
```

**容器开发** (Docker + 本地)
```
🐳 Docker 🏠 本地 ✗ 无代理 ~/workspace ⎇ master 71  1m 475 s ✓ hao@mm
$
```

---

## ✅ 确认清单

所有三个问题都已确认：
- [✓] 问题 1: 安装脚本不支持环境指示符
- [✓] 问题 2: 指示符显示在第二行而非第一行
- [✓] 问题 3: 指示符是条件显示而非常态显示

修复计划已制定：
- [✓] 修复方案明确
- [✓] 优先级确定
- [✓] 工作量评估完成

---

**待执行**: 根据确认内容实施修复

**下一步**: 等待用户确认，开始修复实施

