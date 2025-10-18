# 环境指示符功能 - 快速开始指南

## 🚀 30 秒快速开始

```bash
# 1. 查看当前环境状态
env_status

# 2. 在 RPROMPT 中自动显示指示符
# 无需任何配置，环境指示符会自动出现在提示符右侧

# 3. 查看帮助
zsh_help env_status
```

## 📊 工作原理

**自动显示的指示符**：
- 🐳 = 在 Docker 容器中
- 🌐 = SSH 会话中
- 🔐 = 启用了代理

**显示位置**：RPROMPT（提示符右侧）

**显示规则**：
- 正常情况（物理主机 + 本地 + 无代理）= 不显示
- 满足条件时 = 自动显示对应指示符

## 💡 示例

```
正常情况:
～/path ⎇ master    1m 30 s ✓ user@host

SSH + 代理启用:
～/path ⎇ master    🌐 🔐 1m 30 s ✓ user@host

Docker + SSH + 代理:
～/path ⎇ master    🐳 🌐 🔐 1m 30 s ✓ user@host
```

## 📚 详细文档

| 文档 | 说明 |
|------|------|
| `docs/ENVIRONMENT_INDICATORS_ARCHITECTURE.md` | 完整的技术分析和架构设计 |
| `docs/ENVIRONMENT_INDICATORS_RPROMPT_GUIDE.md` | RPROMPT 集成实现指南 |
| `docs/P10K_INTEGRATION_GUIDE.md` | Powerlevel10k 配置和故障排除 |
| `docs/IMPLEMENTATION_SUMMARY.md` | 实现总结和使用指南 |

## 🔧 自定义（可选）

### 修改图标

编辑 `~/.zsh/functions/context.zsh` 中的 `_get_env_indicators()` 函数：

```bash
# 例如：改为其他图标
_is_in_container && indicators+="💻"  # 改为 💻
_is_in_ssh && indicators+="${indicators:+ }🖥️ "  # 改为 🖥️
_is_using_proxy && indicators+="${indicators:+ }🛡️ "  # 改为 🛡️
```

### 修改分隔符

```bash
# 默认分隔符：空格
# 改为 | 分隔：indicators+="${indicators:+|}🌐"
# 改为 • 分隔：indicators+="${indicators:+•}🌐"
```

## ❓ 常见问题

**Q: 为什么没有显示指示符？**
A: 您可能在物理主机上，无 SSH，无代理。这是正常的！使用 `env_status` 命令验证。

**Q: 如何禁用此功能？**
A: 该功能完全透明，正常情况下不会显示任何内容。无需禁用。

**Q: 可以改变显示位置吗？**
A: 当前设计在 RPROMPT 右侧。如需改变，请参考 `P10K_INTEGRATION_GUIDE.md`。

## 🔗 相关命令

```bash
# 查看环境状态
env_status

# 查看帮助
zsh_help env_status
env_status --help

# 查看所有命令
zsh_help

# 重新加载配置
exec zsh
```

---

**版本**: 1.0
**上次更新**: 2025-10-18
