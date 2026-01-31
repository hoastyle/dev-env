# ZSH 模块化配置系统

**版本**: 2.0
**状态**: 稳定
**最后更新**: 2025-01-31

---

## 概述

dev-env v2.0 引入了模块化配置系统，将传统的 monolithic `.zshrc` 拆分为多个独立的功能模块。这使得配置更易于管理、维护和定制。

### 优势

- ✅ **模块化**: 每个功能独立管理，便于维护
- ✅ **灵活性**: 可以选择性启用/禁用模块
- ✅ **可扩展**: 支持用户自定义模块
- ✅ **向后兼容**: 保留传统配置文件

---

## 模块列表

### 系统模块

| 模块 | 描述 | 状态 |
|------|------|------|
| `00-core.zsh` | Powerlevel10k instant prompt、Antigen插件管理器 | 必需 |
| `10-python.zsh` | Python3、Conda、NVM配置 | 可选 |
| `20-tools.zsh` | FZF、CUDA、TensorRT、Autojump | 可选 |
| `30-aliases.zsh` | 颜色支持和命令别名 | 可选 |
| `40-functions.zsh` | 自定义函数加载 | 可选 |
| `50-completion.zsh` | 优化的补全系统（缓存） | 必需 |
| `60-matrix-nav.zsh` | Matrix iCrane2导航函数 | 可选 |
| `70-environment.zsh` | 环境变量和PATH配置 | 可选 |
| `80-p10k.zsh` | Powerlevel10k主题配置 | 必需 |
| `99-matrix.zsh` | Matrix系统状态模块（可选） | 可选 |

### 用户模块

用户自定义模块存放在 `~/.zshrc.local.d/`，不会被版本控制系统追踪。

---

## 使用方法

### 启用模块化配置

```bash
# 使用配置管理脚本启用
./scripts/zsh_config_manager.sh enable-modular

# 手动启用
cp config/.zshrc.modular ~/.zshrc
mkdir -p ~/.zshrc.d
cp config/.zshrc.d/*.zsh ~/.zshrc.d/
exec zsh
```

### 管理模块

```bash
# 列出所有可用模块
./scripts/zsh_config_manager.sh list

# 查看当前状态
./scripts/zsh_config_manager.sh status

# 验证配置语法
./scripts/zsh_config_manager.sh validate

# 备份当前配置
./scripts/zsh_config_manager.sh backup
```

### 禁用模块

```bash
# 删除对应模块文件即可
rm ~/.zshrc.d/60-matrix-nav.zsh

# 或重命名以保留文件
mv ~/.zshrc.d/60-matrix-nav.zsh ~/.zshrc.d/.60-matrix-nav.zsh.disabled
```

### 启用已禁用的模块

```bash
# 从系统模块目录恢复
cp config/.zshrc.d/60-matrix-nav.zsh ~/.zshrc.d/

# 重新加载配置
exec zsh
```

---

## 创建自定义模块

### 方法一：用户模块目录

1. 创建用户模块目录：
   ```bash
   mkdir -p ~/.zshrc.local.d
   ```

2. 创建自定义模块文件（使用数字前缀控制加载顺序）：
   ```bash
   # ~/.zshrc.local.d/45-myconfig.zsh
   # Description: My custom configuration

   # My custom aliases
   alias myproject='cd ~/projects/myproject'

   # My custom functions
   myfunction() {
       echo "Hello from my custom module!"
   }
   ```

3. 重新加载配置：
   ```bash
   exec zsh
   ```

### 方法二：添加到系统模块

1. 在 `config/.zshrc.d/` 创建新模块文件：
   ```bash
   # config/.zshrc.d/45-custom.zsh
   # Description: Custom project-specific configuration
   ```

2. 更新版本控制：
   ```bash
   git add config/.zshrc.d/45-custom.zsh
   git commit -m "feat: add custom configuration module"
   ```

---

## 模块开发规范

### 文件命名

- 使用数字前缀控制加载顺序（00-99）
- 使用 `.zsh` 扩展名
- 使用小写字母和连字符

```bash
00-core.zsh          # 最先加载
10-python.zsh        # Python环境
20-tools.zsh         # 开发工具
...
99-matrix.zsh        # 最后加载
```

### 文件结构

```bash
# ===============================================
# 模块名称 (简短描述)
# ===============================================
# Description: 详细描述
# Version: 1.0
# Dependencies: (依赖的其他模块)
# ===============================================

# 模块内容...
```

### 最佳实践

1. **单一职责**: 每个模块只负责一个功能领域
2. **独立性**: 模块应该尽可能独立，减少依赖
3. **文档化**: 在模块头部添加描述信息
4. **测试**: 使用 `zsh -n` 验证语法
5. **向后兼容**: 保留传统配置文件作为备选

---

## 配置管理命令

### zsh_config_manager.sh

```bash
# 列出所有模块
./scripts/zsh_config_manager.sh list

# 显示当前状态
./scripts/zsh_config_manager.sh status

# 验证配置语法
./scripts/zsh_config_manager.sh validate

# 备份当前配置
./scripts/zsh_config_manager.sh backup

# 启用模块化配置
./scripts/zsh_config_manager.sh enable-modular
```

---

## 故障排除

### 配置未生效

1. 检查模块是否正确安装：
   ```bash
   ls -la ~/.zshrc.d/
   ```

2. 验证配置语法：
   ```bash
   ./scripts/zsh_config_manager.sh validate
   ```

3. 检查主配置文件：
   ```bash
   cat ~/.zshrc
   ```

4. 重新加载配置：
   ```bash
   exec zsh
   ```

### 启动缓慢

1. 禁用不需要的模块
2. 使用延迟加载（将函数模块改为autoload）
3. 检查模块性能：
   ```bash
   zsh -x -i -c exit 2>&1 | grep zshrc.d
   ```

### 模块冲突

1. 检查模块加载顺序
2. 使用数字前缀调整顺序
3. 检查是否有重复的配置

---

## 迁移指南

### 从传统配置迁移

1. 备份当前配置：
   ```bash
   ./scripts/zsh_config_manager.sh backup
   ```

2. 启用模块化配置：
   ```bash
   ./scripts/zsh_config_manager.sh enable-modular
   ```

3. 验证功能：
   ```bash
   # 检查关键功能
   python --version
   conda --version
   fzf --version

   # 检查别名
   alias ll
   alias la

   # 检查函数
   type cdlog
   type cdcrane
   ```

4. 如有问题，恢复备份：
   ```bash
   cp ~/.zshrc.backup.* ~/.zshrc
   exec zsh
   ```

---

## 相关文档

- [CLAUDE.md](../CLAUDE.md) - 项目文档
- [OPTIMIZATION_RECOMMENDATIONS.md](../OPTIMIZATION_RECOMMENDATIONS.md) - 优化建议
- [docs/TROUBLESHOOTING_DEBUG_GUIDE.md](TROUBLESHOOTING_DEBUG_GUIDE.md) - 调试指南

---

**维护者**: Dev-Env Team
**反馈**: 请在GitHub Issues中报告问题
