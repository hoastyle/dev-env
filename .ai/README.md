# dev-env - AI Entry Point

> **Project**: dev-env (Development Environment Configuration Management)
> **Purpose**: ZSH Shell 配置生命周期管理系统
> **Version**: 2.3.0
> **AIRS Compliance**: v1.0

---

## Project Summary

dev-env 是一个完整的 ZSH 配置管理系统，专注于配置生命周期管理 (CLM)、性能优化和模块化函数管理。提供版本控制、自动迁移、健康检查、备份恢复等功能。

**What it is**: ZSH 配置管理工具，支持多模式启动和性能优化
**What it's not**: 不是通用的 shell 管理框架，专注于 ZSH 配置场景

---

## Main Entry Points

| Entry | Description |
|-------|-------------|
| `scripts/install_zsh_config.sh` | 一键安装脚本 |
| `scripts/zsh_config_manager.sh` | CLM 统一管理 CLI (version/migrate/health/backup) |
| `scripts/zsh_tools.sh` | 配置管理工具集 |
| `scripts/zsh_launcher.sh` | 多模式启动器 (minimal/fast/normal) |
| `config/.zshrc` | 主配置文件 |

---

## Minimum Reading Order

1. **Machine-readable first**: `.ai/MANIFEST.json` - 项目结构和依赖索引
2. **Function index**: `FUNCTION_INDEX.md` - 所有函数的快速索引
3. **Type definitions**: `TYPES.md` - Bash 类型注解标准
4. **Contracts**: `.ai/CONTRACTS/` - 核心库接口契约
5. **Source code**: `scripts/lib_*.sh` - 核心库实现

---

## Danger Areas

- **迁移系统**: `lib_migration.sh` 依赖于版本文件格式，手动修改可能导致迁移失败
- **备份路径**: 备份存储在 `backups/` 目录，清理前确认
- **性能数据**: `data/performance/` 包含启动时间统计，删除后历史数据丢失
- **配置兼容性**: Antigen 插件管理器需要预先安装

---

## Change Strategy

- **API Stability**: 核心库函数 (lib_*.sh) 遵循语义化版本控制
- **Configuration Changes**: 通过迁移系统 (`lib_migration.sh`) 管理
- **Backwards Compatibility**: 备份恢复功能支持回滚到之前版本
- **Deprecation**: 使用 `@tag deprecated` 标记弃用函数

---

## Module Architecture

### 核心库 (Core Libraries)
- **lib_version.sh**: 版本跟踪和比较
- **lib_logging.sh**: 结构化日志系统
- **lib_platform_compat.sh**: 跨平台兼容性层
- **lib_performance.sh**: 性能监控和分析
- **lib_dryrun.sh**: 干运行模式支持

### 业务库 (Business Libraries)
- **lib_migration.sh**: 迁移执行引擎
- **lib_health.sh**: 健康检查系统
- **lib_backup.sh**: 备份恢复系统

### CLI 工具 (CLI Tools)
- **zsh_config_manager.sh**: CLM 统一管理接口
- **zsh_tools.sh**: 配置管理工具集
- **zsh_launcher.sh**: 多模式启动器
- **zsh_optimizer.sh**: 性能优化工具

---

## Integration Notes

dev-env 集成:
- **Claude Code**: 使用 `.ai/PROMPTS/` 作为注入系统提示词
- **Serena MCP**: 通过 CODEMAP.json 进行代码符号导航
- **GitHub Actions**: CI 验证 MANIFEST.json 新鲜度

---

## Four Core Principles

1. **Discoverability** (可发现性)
   - MANIFEST.json 提供完整的项目结构索引
   - FUNCTION_INDEX.md 按功能分类列出所有函数
   - 语义标签 (`@tag`, `@category`) 帮助快速定位

2. **Determinism** (确定性)
   - 类型注解标准 (TYPES.md) 定义明确的参数和返回值类型
   - 依赖关系图 (DEPENDENCY_GRAPH.md) 可视化模块依赖
   - 接口契约 (CONTRACTS/) 提供机器可读的 API 规范

3. **Freshness** (一致性)
   - CODEMAP.json 可通过脚本自动生成
   - CI 验证文档与代码同步
   - 迁移系统确保配置一致性

4. **Verifiability** (可验证性)
   - 单元测试覆盖核心库功能
   - EVAL/ 框架提供 AI 评估任务
   - 健康检查系统验证配置状态

---

**Last Updated**: 2026-02-01
**AIRS Version**: 1.0
**Project Version**: 2.3.0
