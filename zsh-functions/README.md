# ZSH Functions - 模块化自定义函数

**模块版本**: 1.0
**创建日期**: 2025-10-15
**维护者**: Development Team

---

## 📋 概述

本目录包含模块化的 ZSH 自定义函数，按功能分类组织，提供实用的开发工具函数。所有函数都会被 ZSH 配置自动加载。

## 📁 模块结构

```
zsh-functions/
├── README.md              # 本文档
├── environment.zsh        # 环境检测和配置管理函数
├── search.zsh             # 搜索增强函数
├── utils.zsh              # 实用工具函数
├── help.zsh               # 统一命令帮助系统
└── performance.zsh        # 性能分析和优化建议系统
```

---

## 🔧 模块详解

### 🌍 environment.zsh - 环境检测模块

提供环境检测和配置管理功能。

#### 函数列表

| 函数名 | 功能描述 | 用法 |
|--------|----------|------|
| `check_environment` | 检测当前运行环境 | `check_environment` |
| `reload_zsh` | 安全重新加载 ZSH 配置 | `reload_zsh` |

#### 使用示例

```bash
# 检查当前环境
check_environment
# 输出示例:
# 🖥️  当前在物理主机环境中
#    主机名: mm
#    用户: hao
#    系统: Linux mm 5.15.0-139-generic

# 安全重载配置
reload_zsh
# 输出示例:
# 🔄 重新加载 zsh 配置...
# ✅ zsh 配置加载完成
# 🎨 当前主题: robbyrussell 风格
```

### 🔍 search.zsh - 搜索增强模块

提供强大的文件内容搜索功能。

#### 函数列表

| 函数名 | 功能描述 | 用法 |
|--------|----------|------|
| `hg` | 递归搜索文件内容（区分大小写） | `hg "pattern" directory` |
| `hig` | 递归搜索文件内容（忽略大小写） | `hig "pattern" directory` |
| `hrg` | 使用 ripgrep 搜索（区分大小写） | `hrg "pattern" directory` |
| `hirg` | 使用 ripgrep 搜索（忽略大小写） | `hirg "pattern" directory` |

#### 使用示例

```bash
# 在当前目录搜索包含 "function" 的文件
hg "function" .

# 忽略大小写搜索
hig "function" src/

# 使用 ripgrep 进行高性能搜索
hrg "TODO" .

# 忽略大小写的 ripgrep 搜索
hirg "error" logs/
```

### 🛠️ utils.zsh - 实用工具模块

提供开发环境实用工具函数。

#### 函数列表

| 函数名 | 功能描述 | 用法 |
|--------|----------|------|
| `proxy` | 启用网络代理 | `proxy` |
| `unproxy` | 禁用网络代理 | `unproxy` |
| `jdev` | 快速目录跳转 (需autojump) | `jdev <directory_name>` |

#### 使用示例

```bash
# 启用代理
proxy
# 输出: ✅ 代理已启用 (http://127.0.0.1:7890)

# 禁用代理
unproxy
# 输出: ❌ 代理已禁用

# 快速跳转
jdev workspace
# 输出: ✅ 已跳转到: /path/to/workspace
```

### 📖 help.zsh - 帮助系统模块

提供统一的命令帮助系统，支持命令发现和详细使用指导。

#### 主要功能

| 函数名 | 功能描述 | 用法 |
|--------|----------|------|
| `zsh_help` | 统一命令帮助系统 | `zsh_help [topic|command]` |
| `handle_help_param` | 处理 --help 参数 | 内部函数 |

### ⚡ performance.zsh - 性能分析模块

提供详细的 ZSH 性能分析和优化建议系统。

#### 主要功能

| 函数名 | 功能描述 | 用法 |
|--------|----------|------|
| `performance_detailed` | 详细性能分析主函数 | 通过 zsh_tools.sh 调用 |
| `test_segmented_startup` | 分段启动时间分析 | 内部函数 |
| `test_plugin_performance` | 插件性能分析 | 内部函数 |
| `test_memory_usage` | 内存使用分析 | 内部函数 |
| `generate_performance_report` | 生成性能报告 | 内部函数 |
| `provide_optimization_suggestions` | 提供优化建议 | 内部函数 |

#### 使用示例

```bash
# 运行详细性能分析
./scripts/zsh_tools.sh benchmark-detailed

# 输出内容:
# 🔍 分段启动时间分析
# 📊 分段耗时详情:
#   配置文件解析        10ms
#   环境变量设置         6ms
#   Antigen加载         92ms
#   函数模块加载        15ms
#   总计               125ms
#
# 🔌 插件性能分析
# 💾 内存使用分析
# 📋 性能分析报告
# 💡 性能优化建议
```

#### 性能分析特性

- **高精度计时**: 支持毫秒级精度的性能测试
- **分段分析**: 分别测试配置解析、环境设置、插件加载、函数加载
- **内存分析**: 分析各组件的内存占用情况
- **性能评分**: 提供量化的性能评分和等级评定
- **优化建议**: 基于测试结果提供具体的优化建议
- **兼容性**: 支持 ZSH 和 Bash 环境

---

## 🚀 自动加载机制

所有函数模块都会通过 `.zshrc` 配置自动加载：

```bash
# Load custom functions from ~/.zsh/functions
if [[ -d "$HOME/.zsh/functions" ]]; then
    for function_file in "$HOME/.zsh/functions"/*.zsh; do
        if [[ -f "$function_file" ]]; then
            source "$function_file"
        fi
    done
fi
```

---

## 📝 开发指南

### 添加新函数

1. **选择合适的模块**：
   - 环境相关函数 → `environment.zsh`
   - 搜索相关函数 → `search.zsh`
   - 工具相关函数 → `utils.zsh`
   - 帮助系统相关 → `help.zsh`
   - 性能分析相关 → `performance.zsh`
   - 新功能类别 → 创建新的 `.zsh` 文件

2. **函数命名规范**：
   - 使用小写字母和下划线
   - 名字应该简洁且描述性强
   - 避免与系统命令冲突

3. **函数模板**：

```bash
#!/usr/bin/env zsh
# ===============================================
# Module Name - 功能描述
# ===============================================

# 函数描述
function_name() {
    # 函数实现
    # 使用 echo 输出结果，提供清晰的用户反馈
}
```

### 代码规范

1. **注释规范**：
   - 每个函数都要有清晰的注释
   - 使用中文注释
   - 描述函数的用途和参数

2. **错误处理**：
   - 检查必要的参数
   - 提供友好的错误信息
   - 使用适当的退出码

3. **输出格式**：
   - 使用 emoji 增强可读性
   - 提供清晰的格式化输出
   - 重要操作要有确认反馈

### 使用示例

```bash
# 显示所有命令概览
zsh_help

# 查看特定类别帮助
zsh_help 搜索增强

# 查看具体命令帮助
zsh_help hg

# 查看命令自身的帮助
hg --help
hig -h
```

#### 帮助系统特性

- **命令发现**: 自动索引所有自定义命令
- **分类显示**: 按功能模块组织命令
- **详细说明**: 包含用法、示例和相关工具信息
- **参数检查**: 为命令添加友好的错误提示
- **工具检测**: 自动检查依赖工具的安装状态

---

## 🚀 自动加载机制

所有函数模块都会通过 `.zshrc` 配置自动加载：

```bash
# Load custom functions from ~/.zsh/functions
if [[ -d "$HOME/.zsh/functions" ]]; then
    for function_file in "$HOME/.zsh/functions"/*.zsh; do
        if [[ -f "$function_file" ]]; then
            source "$function_file"
        fi
    done
fi
```

---

## 📝 开发指南

### 添加新函数

1. **选择合适的模块**：
   - 环境相关函数 → `environment.zsh`
   - 搜索相关函数 → `search.zsh`
   - 工具相关函数 → `utils.zsh`
   - 新功能类别 → 创建新的 `.zsh` 文件

2. **函数命名规范**：
   - 使用小写字母和下划线
   - 名字应该简洁且描述性强
   - 避免与系统命令冲突

3. **函数模板**：

```bash
#!/usr/bin/env zsh
# ===============================================
# Module Name - 功能描述
# ===============================================

# 函数描述
function_name() {
    # 函数实现
    # 使用 echo 输出结果，提供清晰的用户反馈
}
```

### 代码规范

1. **注释规范**：
   - 每个函数都要有清晰的注释
   - 使用中文注释
   - 描述函数的用途和参数

2. **错误处理**：
   - 检查必要的参数
   - 提供友好的错误信息
   - 使用适当的退出码

3. **输出格式**：
   - 使用 emoji 增强可读性
   - 提供清晰的格式化输出
   - 重要操作要有确认反馈

---

## 🔧 配置和定制

### 代理配置

代理设置在 `utils.zsh` 中默认配置为：

```bash
# 代理服务器地址
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
export all_proxy=http://127.0.0.1:7890
```

如需修改代理地址，请编辑 `utils.zsh` 文件中的相关配置。

### 搜索工具配置

搜索函数会自动检测系统中可用的搜索工具：

- **优先级**: ripgrep > grep
- **默认参数**: 包含颜色高亮、行号显示
- **输出格式**: 通过 less 分页显示

---

## 🐛 故障排除

### 函数不可用

```bash
# 检查函数是否正确加载
type function_name

# 重新加载所有函数
source ~/.zshrc

# 检查函数文件语法
zsh -n ~/.zsh/functions/environment.zsh
```

#### 常见问题案例：新函数无法使用

**问题现象**：
```bash
zsh_help  # 返回: command not found: zsh_help
```

**诊断步骤**：
```bash
# 1. 检查函数文件是否存在
ls -la ~/.zsh/functions/ | grep help.zsh

# 2. 如果不存在，从项目目录复制
cp /path/to/project/zsh-functions/help.zsh ~/.zsh/functions/

# 3. 重新加载配置
source ~/.zshrc

# 4. 验证函数可用性
type zsh_help
```

**详细调试过程参考**：[调试指南文档](../docs/TROUBLESHOOTING_DEBUG_GUIDE.md)

### 权限问题

```bash
# 检查文件权限
ls -la ~/.zsh/functions/

# 修复权限（如果需要）
chmod 644 ~/.zsh/functions/*.zsh
```

### 性能问题

```bash
# 检查函数加载时间
zsh -i -c 'echo "ZSH loaded in $ZSH_DEBUG seconds"'

# 临时禁用函数加载进行测试
mv ~/.zsh/functions ~/.zsh/functions.bak
```

---

## 📚 相关文档

- [项目主文档](../README.md)
- [模块配置文档](../CLAUDE.md)
- [ZSH 官方文档](https://zsh.sourceforge.io/Doc/)

---

## 🤝 贡献指南

1. **创建新函数**时，请遵循现有的代码规范
2. **更新文档**，包括函数说明和使用示例
3. **测试函数**在不同环境下的兼容性
4. **提交 PR**时包含清晰的更改描述

---

## 🔄 版本历史

### v1.3 (2025-10-16)
- ✨ 新增详细性能分析系统 (performance.zsh)
- ✅ 实现高精度分段式性能测试
- ✅ 提供性能评分和优化建议
- ✅ 添加插件性能分析和内存使用分析
- ✅ 兼容 ZSH 和 Bash 环境

### v1.2 (2025-10-16)
- ✨ 新增统一命令帮助系统 (help.zsh)
- ✅ 为所有命令添加 --help / -h 参数支持
- ✅ 改进参数检查和错误提示
- ✅ 增强文档和示例代码
- ✅ 更新函数列表和使用说明

### v1.1 (2025-10-15)
- ✨ 初始版本发布
- ✅ 环境检测模块 (environment.zsh)
- ✅ 搜索增强模块 (search.zsh)
- ✅ 实用工具模块 (utils.zsh)
- ✅ 自动加载机制
- ✅ 完整的文档和使用指南

### v1.0 (2025-10-15)
- ✨ 初始版本发布

---

**模块维护**: Development Team
**最后更新**: 2025-10-15
**文档版本**: 1.0