# 核心库 API 参考文档

**版本**: 2.3.0
**更新日期**: 2026-01-31

---

## 概述

dev-env 项目包含多个可复用的核心库，提供跨平台兼容性、日志记录、性能监控等功能。本文档详细说明各库的 API 接口。

---

## 📚 库列表

| 库名称 | 大小 | 用途 |
|--------|------|------|
| `lib_platform_compat.sh` | ~400 行 | 跨平台兼容性层 |
| `lib_logging.sh` | ~500 行 | 结构化日志系统 |
| `lib_performance.sh` | ~600 行 | 性能监控和分析 |
| `lib_version.sh` | ~350 行 | 版本管理 (v2.3 新增) |
| `lib_migration.sh` | ~400 行 | 迁移执行引擎 (v2.3 新增) |
| `lib_health.sh` | ~350 行 | 健康检查系统 (v2.3 新增) |
| `lib_backup.sh` | ~350 行 | 备份恢复系统 (v2.3 新��) |

---

## lib_platform_compat.sh

跨平台兼容性库，抽象 macOS 和 Linux 之间的差异。

### 使用方式

```bash
source "$(dirname "$0")/lib_platform_compat.sh"
```

### API 函数

#### `get_os_type`

获取当前操作系统类型。

```bash
get_os_type
# 返回: "linux" | "macos" | "unknown"
```

**返回值**:
- `0`: 成功
- `1`: 无法检测操作系统

#### `is_macos`

检查是否运行在 macOS 上。

```bash
is_macos
# 返回码: 0=是macOS, 1=不是macOS
```

**示例**:
```bash
if is_macos; then
    # macOS 特定代码
else
    # Linux 特定代码
fi
```

#### `is_linux`

检查是否运行在 Linux 上。

```bash
is_linux
# 返回码: 0=是Linux, 1=不是Linux
```

#### `get_file_size`

获取文件大小（字节）。

```bash
get_file_size <file_path>
# 返回: 文件大小（字节）
```

**参数**:
- `file_path`: 文件路径

**示例**:
```bash
size=$(get_file_size "$HOME/.zshrc")
echo "Config size: $size bytes"
```

#### `get_timestamp_ms`

获取当前时间戳（毫秒）。

```bash
get_timestamp_ms
# 返回: 毫秒时间戳
```

**跨平台支持**:
- Linux: 使用 `date +%s%3N`
- macOS: 使用 Python 或 Perl 回退

#### `get_date_relative`

获取相对日期字符串。

```bash
get_date_relative <date_string>
# 返回: 相对日期描述（如"2天前"）
```

**参数**:
- `date_string`: 日期字符串（格式：YYYY-MM-DD HH:MM:SS）

**示例**:
```bash
relative=$(get_date_relative "2026-01-29 10:00:00")
echo "$relative"  # 输出: 2天前
```

### 环境变量

无

---

## lib_logging.sh

结构化日志系统，支持日志级别、轮转和查看。

### 使用方式

```bash
source "$(dirname "$0")/lib_logging.sh"

# 初始化日志系统（可选，有默认值）
init_logging

# 使用日志函数
log_info "系统启动"
log_success "操作成功"
log_error "发生错误"
```

### API 函数

#### `init_logging`

初始化日志系统。

```bash
init_logging
```

**默认值**:
- `LOG_DIR`: `$PROJECT_ROOT/data/logs`
- `LOG_FILE`: `clm.log`
- `LOG_MAX_SIZE`: 10485760 (10MB)
- `LOG_MAX_FILES`: 5

#### `log_debug`

记录调试级别日志。

```bash
log_debug <message>
```

**参数**:
- `message`: 日志消息

#### `log_info`

记录信息级别日志。

```bash
log_info <message>
```

#### `log_success`

记录成功级别日志（带绿色 emoji）。

```bash
log_success <message>
```

#### `log_warn`

记录警告级别日志（带黄色 emoji）。

```bash
log_warn <message>
```

#### `log_error`

记录错误级别日志（带红色 emoji）。

```bash
log_error <message>
```

#### `log_with_level`

使用指定级别记录日志。

```bash
log_with_level <level> <message>
```

**参数**:
- `level`: DEBUG|INFO|SUCCESS|WARN|ERROR
- `message`: 日志消息

#### `rotate_logs`

手动触发日志轮转。

```bash
rotate_logs
```

#### `view_logs`

查看日志内容。

```bash
view_logs [lines]
```

**参数**:
- `lines`: 显示行数（默认：50）

#### `clear_logs`

清空当前日志文件。

```bash
clear_logs
```

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `LOG_LEVEL` | INFO | 最小日志级别 |
| `LOG_DIR` | data/logs | 日志目录 |
| `LOG_FILE` | clm.log | 日志文件名 |
| `LOG_MAX_SIZE` | 10485760 | 最大文件大小（字节） |
| `LOG_MAX_FILES` | 5 | 保留的日志文件数量 |

---

## lib_performance.sh

性能监控和分析库。

### 使用方式

```bash
source "$(dirname "$0")/lib_performance.sh"

# 记录启动时间
record_startup_time "normal" 1568

# 生成报告
generate_performance_report
```

### API 函数

#### `record_startup_time`

记录启动时间到 CSV 文件。

```bash
record_startup_time <mode> <time_ms>
```

**参数**:
- `mode`: 启动模式 (minimal|fast|normal)
- `time_ms`: 启动时间（毫秒）

**文件**:
- `PERFORMANCE_DATA_FILE`: `data/performance/startup_times.csv`

#### `get_performance_stats`

获取性能统计信息。

```bash
get_performance_stats <mode>
```

**返回**: JSON 格式的统计数据
- `count`: 记录次数
- `min`: 最小值
- `max`: 最大值
- `avg`: 平均值
- `stddev`: 标准差

#### `detect_performance_regression`

检测性能回归。

```bash
detect_performance_regression <mode> <current_time> [threshold_percent]
```

**参数**:
- `mode`: 启动模式
- `current_time`: 当前启动时间
- `threshold_percent`: 回归阈值（默认：20）

**返回码**:
- `0`: 无回归
- `1`: 检测到回归

#### `generate_performance_report`

生成性能报告。

```bash
generate_performance_report
```

#### `get_performance_data_info`

获取性能数据文件信息。

```bash
get_performance_data_info
```

**返回**: JSON 格式的文件信息

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PERFORMANCE_DATA_DIR` | data/performance | 性能数据目录 |
| `STARTUP_TIMES_CSV` | startup_times.csv | 启动时间 CSV 文件 |
| `REGRESSION_THRESHOLD` | 20 | 回归检测阈值（%） |

---

## lib_version.sh

版本管理库（v2.3 新增）。

详细文档: [CONFIG_LIFECYCLE_MANAGEMENT.md](CONFIG_LIFECYCLE_MANAGEMENT.md)

### API 函数

| 函数 | 说明 |
|------|------|
| `get_current_version` | 获取当前配置版本 |
| `set_version` | 设置配置版本 |
| `compare_versions` | 比较两个版本号 |
| `needs_migration` | 检查是否需要迁移 |
| `generate_version_report` | 生成版本报告 |
| `update_last_migration` | 更新最后迁移记录 |

---

## lib_migration.sh

迁移执行引擎（v2.3 新增）。

详细文档: [CONFIG_LIFECYCLE_MANAGEMENT.md](CONFIG_LIFECYCLE_MANAGEMENT.md)

### API 函数

| 函数 | 说明 |
|------|------|
| `get_pending_migrations` | 获取待处理迁移列表 |
| `execute_migration` | 执行单个迁移 |
| `run_migrations` | 执行所有待处理迁移 |
| `rollback_migration` | 回滚指定迁移 |
| `log_migration` | 记录迁移历史 |
| `create_migration` | 创建新迁移模板 |

---

## lib_health.sh

健康检查系统（v2.3 新增）。

详细文档: [CONFIG_LIFECYCLE_MANAGEMENT.md](CONFIG_LIFECYCLE_MANAGEMENT.md)

### API 函数

| 函数 | 说明 |
|------|------|
| `run_health_check` | 运行完整健康检查 |
| `check_syntax` | 检查配置文件语法 |
| `check_plugins` | 检查插件状态 |
| `check_dependencies` | 检查依赖工具 |
| `generate_health_report` | 生成健康报告（JSON） |

---

## lib_backup.sh

备份恢复系统（v2.3 新增）。

详细文档: [CONFIG_LIFECYCLE_MANAGEMENT.md](CONFIG_LIFECYCLE_MANAGEMENT.md)

### API 函数

| 函数 | 说明 |
|------|------|
| `create_backup` | 创建配置备份 |
| `list_backups` | 列出所有备份 |
| `get_backup_info` | 获取备份详细信息 |
| `restore_backup` | 从备份恢复配置 |
| `delete_backup` | 删除指定备份 |
| `cleanup_old_backups` | 清理旧备份 |

---

## 使用示例

### 完整示例：使用多个库

```bash
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source 核心库
source "$PROJECT_ROOT/scripts/lib_platform_compat.sh"
source "$PROJECT_ROOT/scripts/lib_logging.sh"
source "$PROJECT_ROOT/scripts/lib_performance.sh"

# 初始化
init_logging

# 记录开始时间
start_time=$(get_timestamp_ms)

log_info "开始处理"

# 检测操作系统
if is_macos; then
    log_info "运行在 macOS 上"
else
    log_info "运行在 Linux 上"
fi

# 记录启动时间
end_time=$(get_timestamp_ms)
elapsed=$((end_time - start_time))

log_success "处理完成，耗时 ${elapsed}ms"

# 记录性能数据
record_startup_time "custom" $elapsed
```

---

## 开发指南

### 添加新库

1. 创建 `lib_yourlibrary.sh`
2. 添加库级文档注释
3. 实现公共函数
4. 添加单元测试
5. 更新本文档

### 代码规范

1. **函数命名**: 使用 `library_function_name` 格式
2. **错误处理**: 使用返回码，0=成功，非0=失败
3. **日志**: 使用 lib_logging.sh 记录重要操作
4. **文档**: 为公共函数添加注释说明

---

## 相关文档

- [CLM 用户指南](CONFIG_LIFECYCLE_MANAGEMENT.md)
- [CLM 技术设计](design/CONFIG_LIFECYCLE_MANAGEMENT_DESIGN.md)
- [项目开发指南](../CLAUDE.md)

---

**最后更新**: 2026-01-31
**维护者**: Development Team
