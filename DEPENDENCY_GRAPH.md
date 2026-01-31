# 依赖关系图 (Dependency Graph)

> **目的**: 可视化展示模块之间的依赖关系，帮助理解代码架构。

**版本**: 1.0
**最后更新**: 2026-01-31

---

## 📊 模块依赖层级

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLI 工具层                                │
│  zsh_config_manager.sh  │  zsh_tools.sh  │  zsh_launcher.sh    │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        业务逻辑层                                │
│  lib_migration.sh  │  lib_health.sh  │  lib_backup.sh           │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        基础服务层                                │
│  lib_version.sh  │  lib_logging.sh  │  lib_performance.sh        │
│  lib_platform_compat.sh  │  lib_dryrun.sh                      │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔗 详细依赖关系

### 核心库依赖

#### lib_version.sh (无依赖)

```
lib_version.sh
├── (无外部依赖)
└── 提供: 版本管理功能
```

**导出**: `get_current_version`, `set_version`, `compare_versions`, `needs_migration`

---

#### lib_logging.sh (无依赖)

```
lib_logging.sh
├── (无外部依赖)
└── 提供: 结构化日志系统
```

**导出**: `log_info`, `log_success`, `log_warn`, `log_error`, `log_debug`

**被依赖**:
- lib_health.sh
- lib_backup.sh
- lib_migration.sh
- zsh_tools.sh
- zsh_launcher.sh
- zsh_optimizer.sh

---

#### lib_platform_compat.sh (无依赖)

```
lib_platform_compat.sh
├── (无外部依赖)
└── 提供: 跨平台兼容性
```

**导出**: `get_os_type`, `is_macos`, `is_linux`, `get_file_size`, `get_timestamp_ms`

**被依赖**:
- lib_performance.sh
- lib_backup.sh
- zsh_tools.sh

---

#### lib_performance.sh (无依赖)

```
lib_performance.sh
├── lib_platform_compat.sh (可选)
└── 提供: 性能监控
```

**导出**: `record_startup_time`, `get_performance_stats`, `detect_performance_regression`

**被依赖**:
- zsh_tools.sh
- zsh_launcher.sh
- zsh_optimizer.sh

---

#### lib_dryrun.sh (无依赖)

```
lib_dryrun.sh
├── (无外部依赖)
└── 提供: 干运行模式支持
```

**导出**: `is_dry_run`, `dry_exec`, `dry_run_notice`

**被依赖**:
- zsh_tools.sh

---

### 业务库依赖

#### lib_migration.sh

```
lib_migration.sh
├── lib_version.sh (版本比较和获取)
├── lib_logging.sh (日志记录)
└── 提供: 迁移执行引擎
```

**导出**: `get_pending_migrations`, `execute_migration`, `run_migrations`, `rollback_migration`

**被依赖**:
- zsh_config_manager.sh

---

#### lib_health.sh

```
lib_health.sh
├── lib_logging.sh (日志记录)
├── lib_platform_compat.sh (平台检测)
└── 提供: 健康检查
```

**导出**: `run_health_check`, `check_syntax`, `check_plugins`, `check_dependencies`

**被依赖**:
- zsh_config_manager.sh

---

#### lib_backup.sh

```
lib_backup.sh
├── lib_logging.sh (日志记录)
├── lib_platform_compat.sh (文件操作)
└── 提供: 备份恢复
```

**导出**: `create_backup`, `list_backups`, `restore_backup`, `delete_backup`

**被依赖**:
- zsh_config_manager.sh

---

### CLI 工具依赖

#### zsh_config_manager.sh

```
zsh_config_manager.sh
├── lib_version.sh
├── lib_migration.sh
│   ├── lib_version.sh
│   └── lib_logging.sh
├── lib_health.sh
│   ├── lib_logging.sh
│   └── lib_platform_compat.sh
└── lib_backup.sh
    ├── lib_logging.sh
    └── lib_platform_compat.sh
```

**提供**: CLM 统一管理接口

**命令**: `version`, `migrate`, `health`, `backup`, `restore`, `rollback`, `history`, `validate`

---

#### zsh_tools.sh

```
zsh_tools.sh
├── lib_logging.sh
├── lib_performance.sh
│   └── lib_platform_compat.sh (可选)
├── lib_platform_compat.sh
└── lib_dryrun.sh
```

**提供**: 配置管理工具集

**命令**: `validate`, `backup`, `restore`, `update`, `clean`, `benchmark`, `doctor`, `perf-report`

---

#### zsh_launcher.sh

```
zsh_launcher.sh
├── lib_logging.sh
├── lib_performance.sh
│   └── lib_platform_compat.sh (可选)
└── 提供: 多模式启动
```

**命令**: `minimal`, `fast`, `normal`, `benchmark`

---

#### zsh_optimizer.sh

```
zsh_optimizer.sh
├── lib_logging.sh
├── lib_performance.sh
│   └── lib_platform_compat.sh (可选)
└── 提供: 性能优化
```

**命令**: `analyze`, `optimize`, `compare`, `benchmark`

---

#### zsh_template_selector.sh

```
zsh_template_selector.sh
├── (无外部依赖)
└── 提供: 模板选择
```

**命令**: `list`, `apply`, `preview`, `compare`, `benchmark`

---

### ZSH 函数模块依赖

#### zsh-functions/search.zsh

```
search.zsh
├── validation.zsh (参数验证)
└── 提供: 搜索增强
```

**导出**: `hg`, `hig`, `hrg`, `hirg`

---

#### zsh-functions/help.zsh

```
help.zsh
├── (无外部依赖)
└── 提供: 帮助系统
```

**导出**: `zsh_help`, `handle_help_param`, `show_command_help`

---

#### zsh-functions/utils.zsh

```
utils.zsh
├── (无外部依赖)
└── 提供: 实用工具
```

**导出**: `proxy`, `unproxy`, `proxy_status`, `check_environment`, `reload_zsh`

---

#### zsh-functions/context.zsh

```
context.zsh
├── utils.zsh (代理检查)
└── 提供: 环境上下文
```

**导出**: `_get_env_indicators`, `prompt_env_indicators`, `_is_in_container`, `_is_in_ssh`

---

#### zsh-functions/performance.zsh

```
performance.zsh
├── (无外部依赖)
└── 提供: 性能分析
```

**导出**: `performance_detailed`, `test_segmented_startup`, `test_plugin_performance`

---

## 🔄 循环依赖检查

### ✅ 无循环依赖

项目设计良好，**不存在循环依赖**。

验证方法：
1. 所有核心库（lib_*）无相互依赖
2. 业务库单向依赖核心库
3. CLI 工具单向依赖业务库和核心库

---

## 📈 依赖统计

| 模块 | 直接依赖 | 被依赖次数 | 依赖层级 |
|------|----------|-----------|----------|
| lib_version.sh | 0 | 2 | 1 (核心) |
| lib_logging.sh | 0 | 6 | 1 (核心) |
| lib_platform_compat.sh | 0 | 4 | 1 (核心) |
| lib_performance.sh | 1 | 3 | 2 (服务) |
| lib_dryrun.sh | 0 | 1 | 2 (服务) |
| lib_migration.sh | 2 | 1 | 3 (业务) |
| lib_health.sh | 2 | 1 | 3 (业务) |
| lib_backup.sh | 2 | 1 | 3 (业务) |
| zsh_config_manager.sh | 4 | 0 | 4 (CLI) |
| zsh_tools.sh | 4 | 0 | 4 (CLI) |
| zsh_launcher.sh | 2 | 0 | 4 (CLI) |

---

## 🎯 依赖规则

### 1. 核心库规则

- **无依赖**: lib_version.sh, lib_logging.sh, lib_platform_compat.sh, lib_dryrun.sh
- **职责单一**: 每个核心库只负责一个功能领域
- **稳定接口**: 核心库提供稳定的公共 API

### 2. 业务库规则

- **单向依赖**: 业务库只能依赖核心库，不能相互依赖
- **明确职责**: 每个业务库解决一个特定业务问题
- **可替换性**: 业务库可以被替代而不影响核心库

### 3. CLI 工具规则

- **组合使用**: CLI 工具组合核心库和业务库
- **用户接口**: CLI 工具是对外的主要接口
- **可独立使用**: 每个 CLI 工具可以独立运行

### 4. ZSH 函数规则

- **可选依赖**: ZSH 函数之间的依赖是可选的
- **用户级**: 用于用户交互，不是核心功能
- **松耦合**: 通过验证和帮助模块实现松耦合

---

## 🔍 添加新模块时的依赖指南

### 1. 确定模块类型

```bash
# 核心库？无依赖，提供基础功能
# 业务库？依赖核心库，提供业务功能
# CLI 工具？依赖核心库和业务库
# ZSH 函数？可选依赖，用户级功能
```

### 2. 检查依赖

```bash
# 列出所有 source 语句
grep -n "^source" scripts/your_new_script.sh

# 确保没有循环依赖
# 确保依赖的模块存在
```

### 3. 更新 CODEMAP.json

```json
{
  "scripts/your_new_script.sh": {
    "exports": ["function1", "function2"],
    "depends_on": ["lib_logging.sh", "lib_version.sh"],
    "provides": "your_functionality"
  }
}
```

### 4. 更新本文档

添加新模块的依赖关系图。

---

## 📚 相关文档

- [CODEMAP.json](CODEMAP.json) - 完整的项目结构映射
- [FUNCTION_INDEX.md](FUNCTION_INDEX.md) - 函数索引
- [AI_OPTIMIZATION_GUIDE.md](AI_OPTIMIZATION_GUIDE.md) - 大模型优化指南

---

## 💡 最佳实践

1. **避免深层嵌套**: 依赖层级不超过 4 层
2. **单向依赖**: 避免双向依赖
3. **明确依赖**: 在文件头部声明所有 source
4. **最小依赖**: 只依赖真正需要的模块
5. **接口稳定**: 公共 API 保持向后兼容

---

**维护者**: Development Team
**文档版本**: 1.0
**最后更新**: 2026-01-31
