# Configuration Lifecycle Management (CLM) 用户指南

**版本**: 2.3.0
**更新日期**: 2026-01-31

---

## 概述

Configuration Lifecycle Management (CLM) 系统提供完整的配置版本管理、迁移、健康检查和备份恢复功能，帮助您安全地管理 ZSH 配置的整个生命周期。

### 核心功能

- **版本管理**: 跟踪配置版本，支持语义化版本比较
- **自动迁移**: 检测配置版本并自动执行必要的迁移脚本
- **健康检查**: 验证配置语法、插件状态、依赖完整性
- **备份恢复**: 带清单和元数据的完整备份系统
- **回滚支持**: 安全回滚到之前的配置状态

---

## 快速开始

### 1. 查看当前版本

```bash
./scripts/zsh_config_manager.sh version
```

输出示例:
```
当前配置版本: 2.2.0
构建日期: 2026-01-31
安装日期: 2026-01-31
最后迁移: 002_add_template_system
```

### 2. 检查待处理迁移

```bash
./scripts/zsh_config_manager.sh migrate --dry-run
```

### 3. 执行迁移

```bash
./scripts/zsh_config_manager.sh migrate
```

### 4. 运行健康检查

```bash
./scripts/zsh_config_manager.sh health
```

---

## 命令参考

### 版本管理

#### `version`

查看当前配置版本信息。

```bash
./scripts/zsh_config_manager.sh version
./scripts/zsh_config_manager.sh version --detailed  # 详细报告
```

**详细报告包含**:
- 当前版本和构建日期
- 安装历史
- 已应用的迁移列表
- 待处理迁移
- 用户自定义配置状态

---

### 配置迁移

#### `migrate`

执行待处理的配置迁移。

```bash
# 执行所有待处理迁移
./scripts/zsh_config_manager.sh migrate

# 预览迁移（不执行）
./scripts/zsh_config_manager.sh migrate --dry-run

# 强制重新执行指定迁移
./scripts/zsh_config_manager.sh migrate --force 001
```

#### `rollback`

回滚指定的迁移。

```bash
# 回滚到指定迁移之前
./scripts/zsh_config_manager.sh rollback 002

# 查看可回滚的迁移
./scripts/zsh_config_manager.sh rollback --list
```

**警告**: 回滚操作会修改配置状态，建议先创建备份。

#### `history`

查看迁移历史。

```bash
./scripts/zsh_config_manager.sh history
```

输出示例:
```
迁移历史:
  2026-01-31 10:30:15 | 001_initial.sh | 成功
  2026-01-31 10:30:20 | 002_add_template_system.sh | 成功
```

---

### 健康检查

#### `health`

运行完整的系统健康检查。

```bash
# 标准报告
./scripts/zsh_config_manager.sh health

# JSON 格式输出
./scripts/zsh_config_manager.sh health --json > health-report.json
```

**健康检查项目**:
- 配置文件语法验证
- 插件状态检查
- 依赖工具可用性
- 版本文件完整性
- 性能基准测试

#### `validate`

快速验证配置语法。

```bash
./scripts/zsh_config_manager.sh validate
```

---

### 备份与恢复

#### `backup`

创建配置备份。

```bash
# 创建带描述的备份
./scripts/zsh_config_manager.sh backup "升级前备份"

# 自动描述（使用当前时间戳）
./scripts/zsh_config_manager.sh backup
```

**备份内容包括**:
- 所有配置文件
- 版本元数据
- 迁移历史
- 清单文件 (manifest.txt)
- 元数据文件 (metadata.json)

#### `list-backups`

列出所有可用备份。

```bash
./scripts/zsh_config_manager.sh list-backups
```

输出示例:
```
可用的备份:
  ID: 20260131-103015 | 描述: 升级前备份 | 大小: 2.3MB
  ID: 20260131-092245 | 描述: 自动备份 | 大小: 2.3MB
```

#### `restore`

从备份恢复配置。

```bash
# 恢复最新备份
./scripts/zsh_config_manager.sh restore --latest

# 恢复指定备份
./scripts/zsh_config_manager.sh restore 20260131-103015

# 恢复前不创建安全备份
./scripts/zsh_config_manager.sh restore --no-safety-backup 20260131-103015
```

**恢复过程**:
1. 自动创建当前配置的安全备份
2. 验证备份完整性
3. 恢复配置文件
4. 更新版本元数据
5. 验证恢复后的配置

---

## 最佳实践

### 1. 定期备份

在进行重大更改前，始终创建备份:

```bash
./scripts/zsh_config_manager.sh backup "重大更改前的备份"
```

### 2. 检查迁移

在生产环境应用迁移前，先预览:

```bash
./scripts/zsh_config_manager.sh migrate --dry-run
```

### 3. 健康检查

定期运行健康检查，确保系统状态良好:

```bash
./scripts/zsh_config_manager.sh health
```

### 4. 版本跟踪

使用详细版本报告了解系统状态:

```bash
./scripts/zsh_config_manager.sh version --detailed
```

---

## 文件结构

CLM 系统使用以下目录结构:

```
dev-env/
├── config/
│   ├── .zshrc.version          # 版本元数据文件
│   └── migrations/             # 迁移脚本目录
│       ├── 001_initial.sh
│       └── 002_add_template_system.sh
├── scripts/
│   ├── lib_version.sh          # 版本管理库
│   ├── lib_migration.sh        # 迁移执行引擎
│   ├── lib_health.sh           # 健康检查库
│   ├── lib_backup.sh           # 备份恢复库
│   └── zsh_config_manager.sh   # CLI 工具
├── data/                       # 数据存储
│   └── migration_history.log   # 迁移历史
└── backups/                    # 配置备份
    └── YYYYMMDD-HHMMSS/       # 备份目录
        ├── manifest.txt        # 备份清单
        └── metadata.json       # 备份元数据
```

---

## 迁移脚本开发

### 创建新迁移

```bash
./scripts/zsh_config_manager.sh create-migration "描述"
```

这会在 `config/migrations/` 创建一个新的迁移模板。

### 迁移脚本结构

```bash
#!/bin/bash
# Migration: 003_example_migration.sh
# Description: 迁移描述
# Version: 2.4.0

migrate_up() {
    # 执行迁移逻辑
    echo "执行迁移..."
    return 0
}

migrate_down() {
    # 回滚迁移逻辑
    echo "回滚迁移..."
    return 0
}
```

---

## 故障排除

### 迁移失败

如果迁移失败:

1. 查看错误日志: `cat data/logs/clm.log`
2. 检查系统状态: `./scripts/zsh_config_manager.sh health`
3. 尝试回滚: `./scripts/zsh_config_manager.sh rollback <迁移ID>`
4. 从备份恢复: `./scripts/zsh_config_manager.sh restore --latest`

### 版本不匹配

如果检测到版本不匹配:

```bash
# 查看版本差异
./scripts/zsh_config_manager.sh version --detailed

# 执行必要的迁移
./scripts/zsh_config_manager.sh migrate
```

### 备份损坏

如果备份验证失败:

1. 列出所有备份: `./scripts/zsh_config_manager.sh list-backups`
2. 尝试恢复较早的备份
3. 检查备份目录权限

---

## 相关文档

- [CLM 技术设计](docs/design/CONFIG_LIFECYCLE_MANAGEMENT_DESIGN.md)
- [快速实施指南](docs/design/QUICK_START_IMPLEMENTATION.md)
- [实施检查清单](docs/design/IMPLEMENTATION_CHECKLIST.md)

---

**版本历史**:
- **v2.3.0** (2026-01-31): 初始 CLM 系统发布
