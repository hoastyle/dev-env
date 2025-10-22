# PLANNING.md - dev-env 架构规划文档

**版本**: 2.1.1
**最后更新**: 2025-10-19
**状态**: 稳定

---

## 🏗️ 架构总览

### 核心架构

```
┌─────────────────────────────────────────────────────────────┐
│                    dev-env 项目架构                          │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  用户接口层 (User Interface Layer)                            │
│  ├── 命令行工具: zsh_launcher.sh, zsh_tools.sh               │
│  └── 自动化脚本: install_zsh_config.sh                       │
│                                                               │
│  配置管理层 (Configuration Layer)                            │
│  ├── 配置文件: .zshrc, .zshrc.optimized, .zshrc.ultra-opt   │
│  ├── 主题配置: .p10k.zsh, .p10k.zsh.backup                  │
│  └── 备份机制: ~/zsh-backup-*/ 目录                          │
│                                                               │
│  功能模块层 (Function Module Layer)                          │
│  ├── 环境检测: environment.zsh, context.zsh                 │
│  ├── 搜索增强: search.zsh                                    │
│  ├── 实用工具: utils.zsh                                     │
│  ├── 帮助系统: help.zsh                                      │
│  └── 性能分析: performance.zsh                               │
│                                                               │
│  外部依赖层 (External Dependencies)                          │
│  ├── 插件管理: Antigen                                       │
│  ├── 主题: Powerlevel10k                                     │
│  └── 工具: FZF, fd, ripgrep                                  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 模块职责

| 模块 | 职责 | 文件 |
|------|------|------|
| **安装器** | 一键安装整个系统 | `install_zsh_config.sh` |
| **启动器** | 多模式启动和切换 | `zsh_launcher.sh` |
| **优化器** | 性能分析和优化 | `zsh_optimizer.sh` |
| **工具集** | 配置管理和维护 | `zsh_tools.sh` |
| **环境模块** | 环境检测和指示符 | `environment.zsh`, `context.zsh` |
| **搜索模块** | 文件搜索增强 | `search.zsh` |
| **工具模块** | 代理、命令等工具 | `utils.zsh` |
| **帮助模块** | 统一帮助系统 | `help.zsh` |
| **性能模块** | 性能分析和报告 | `performance.zsh` |

---

## 🔄 启动流程

### 标准启动流程

```
zsh 启动
  ↓
.zshrc 读取
  ├── Powerlevel10k 即时提示符
  ├── Antigen 插件管理器初始化
  ├── 插件加载 (git, completions, autosuggestions 等)
  ├── 主题应用 (Powerlevel10k)
  ├── FZF 配置
  ├── 自定义函数加载 (~/.zsh/functions/)
  ├── 环境变量设置
  └── 完成初始化
  ↓
Shell 就绪
```

### 多模式启动

```
极速模式 (Minimal - 2ms)
  └── 仅基础功能，跳过补全和插件

快速模式 (Fast - 0.6s)
  └── 主要功能，补全延迟加载

标准模式 (Normal - 1.5s)
  └── 完整功能，所有插件启用
```

---

## 📊 性能优化策略

### 性能瓶颈分析

| 瓶颈 | 耗时 | 优化方案 |
|------|------|---------|
| ZSH 补全初始化 | 437ms | 缓存 zcompdump，延迟加载 |
| 插件加载 | 180ms | 使用 Antigen lazy loading |
| Antigen 本身 | 120ms | 最小化 hook 数量 |
| 环境变量设置 | 85ms | 按需加载 (NVM, Conda) |
| 主题初始化 | 40ms | Powerlevel10k 即时提示符 |

### 优化成果

| 指标 | 优化前 | 优化后 | 提升 |
|------|--------|--------|------|
| 冷启动 | 1.568s | 2ms | **99.9%** ⚡ |
| 快速模式 | N/A | 0.606s | **61%** |
| 内存占用 | 45MB | 32MB | **28%** |
| 补全缓存 | 新建 | 复用 | **性能倍增** |

---

## 🔧 配置文件设计

### 配置版本

#### 1. 标准配置 (.zshrc)

* 适用: 日常开发
* 特点: 完整功能
* 启动: ~1.5s

#### 2. 优化配置 (.zshrc.optimized)

* 适用: 快速开发任务
* 特点: 补全延迟加载
* 启动: ~0.6s

#### 3. 超优化配置 (.zshrc.ultra-optimized)

* 适用: 极速启动需求
* 特点: 仅基础功能
* 启动: ~2ms

#### 4. NVM 优化配置 (.zshrc.nvm-optimized)

* 适用: Node.js 开发环境
* 特点: NVM 延迟加载
* 启动: 提升 78.9%

---

## 🎯 开发规范

### 脚本编写规范

#### Shell 脚本规范

```bash
#!/bin/bash
# 使用 bash，不是 sh
set -e          # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'    # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 错误处理
trap 'log_error "执行失败"; exit 1' ERR

# 函数说明
# 函数名应该清晰表达功能
function_name() {
    local param="$1"
    # 实现
}
```

#### ZSH 函数规范

```zsh
#!/usr/bin/env zsh
# 使用 zsh，支持 zsh 特性

# 函数注释
my_function() {
    # 帮助参数处理
    if handle_help_param "my_function" "$1"; then
        return 0
    fi

    # 实现
}

# 导出函数 (使其对子 shell 可用)
export -f my_function
```

### 代码质量指标

* **可读性**: 使用清晰的变量名和注释
* **可维护性**: 模块化设计，单一职责
* **可测试性**: 函数应该可以单独测试
* **可扩展性**: 易于添加新功能
* **可移植性**: 支持 Linux/macOS

### 错误处理

```bash
# ✅ 好的错误处理
if ! command_that_might_fail; then
    log_error "操作失败"
    log_info "请检查网络连接"
    return 1
fi

# ❌ 不好的错误处理
command_that_might_fail  # 无错误检查
```

---

## 🧪 测试策略

### 测试类型

#### 1. 单元测试

* 测试单个函数
* 验证参数处理
* 检查返回值

#### 2. 集成测试

* 测试多个模块交互
* 验证完整流程
* 检查依赖关系

#### 3. 性能测试

* 启动时间测量
* 内存使用分析
* 性能基准对比

#### 4. 兼容性测试

* Linux 各发行版
* macOS 各版本
* Docker 环境

### 测试工具

```bash
# 脚本语法检查
bash -n script.sh
zsh -n config.zsh

# 性能测试
time zsh -i -c 'exit'

# 配置验证
./scripts/zsh_tools.sh validate

# 系统诊断
./scripts/zsh_tools.sh doctor
```

---

## 📦 依赖管理

### 必需依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| ZSH | 5.8+ | Shell 环境 |
| Bash | 4.0+ | 脚本执行 |
| curl | 最新 | 下载 Antigen |
| git | 最新 | 版本控制 |

### 可选依赖

| 依赖 | 版本 | 用途 | 替代方案 |
|------|------|------|---------|
| FZF | 最新 | 模糊搜索 | N/A |
| fd | 最新 | 快速查找 | find |
| ripgrep | 最新 | 快速搜索 | grep |
| Antigen | 最新 | 插件管理 | oh-my-zsh |

### 安装方式

```bash
# Ubuntu/Debian
sudo apt-get install fzf fd-find ripgrep

# macOS
brew install fzf fd ripgrep

# Arch
sudo pacman -S fzf fd ripgrep

# 自动安装 (通过脚本)
./scripts/install_zsh_config.sh
```

---

## 🚀 部署策略

### 标准安装

```bash
cd /path/to/dev-env
./scripts/install_zsh_config.sh
exec zsh
```

### 临时使用

```bash
cd /path/to/dev-env/scripts
./zsh_launcher.sh minimal
```

### Docker 部署

```bash
# 在 Dockerfile 中
RUN cd /path/to/dev-env && \
    ./scripts/install_zsh_config.sh && \
    echo "export SHELL=/bin/zsh" >> ~/.bashrc
```

---

## 🔐 安全考虑

### 权限管理

* 脚本不需要 root 权限
* 配置文件存放在用户主目录
* 不修改系统文件

### 数据保护

* 配置自动备份
* 备份文件独立管理
* 支持快速恢复

### 错误恢复

* 重要操作前备份
* 提供回滚机制
* 清晰的错误提示

---

## 📊 性能基准

### 启动时间基准

```
极速模式:        2ms      (99.9% 提升)
快速模式:      606ms      (61% 提升)
标准模式:    1,568ms      (基准)
```

### 内存占用

```
基础占用:    ~20MB
插件加载:    ~15MB (可选)
缓存占用:     ~5MB
总计:        ~35MB (标准模式)
```

### 启动项数

```
极速模式:      3 个
快速模式:      8 个
标准模式:     10 个
```

---

## 🔄 维护计划

### 日常维护

* 周: 检查 issue 和反馈
* 月: 性能测试和基准
* 季: 依赖更新和版本升级

### 版本维护

* 活跃版本: v2.1.1+
* LTS 版本: v2.0
* 不维护: v1.x

### 支持时间

* 新版本: 6 个月活跃支持
* 旧版本: 3 个月安全修复

---

## 🎯 未来规划

### 短期 (1-3 个月)

* [ ] 自动化测试套件
* [ ] CI/CD 集成
* [ ] 配置模板系统

### 中期 (3-6 个月)

* [ ] 图形化配置工具
* [ ] 性能监控仪表板
* [ ] 插件推荐系统

### 长期 (6+ 个月)

* [ ] 插件市场集成
* [ ] 用户社区建设
* [ ] 商业支持服务

---

*本文档定义了 dev-env 的技术架构和开发规范。*
