# 函数索引 (Function Index)

> **快速导航** | [CODEMAP.json](CODEMAP.json) | [类型定义](TYPES.md) | [语义标签](SEMANTIC_TAGS.md) | [依赖关系](DEPENDENCY_GRAPH.md)

本索引按功能分类列出所有公共函数，包括参数、返回值和使用说明。

---

## 📊 版本管理 (lib_version.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `get_current_version` | - | `string` \| `"0.0.0"` | 获取当前配置版本号 |
| `set_version` | `version: VersionString`, `[date: string]` | `ExitCode` | 设置配置版本号 |
| `compare_versions` | `v1: VersionString`, `v2: VersionString` | `int` (-1/0/1) | 比较两个版本号 |
| `needs_migration` | - | `bool` | 检查是否需要执行迁移 |
| `generate_version_report` | `[verbose: bool]` | - | 生成版本报告 |
| `update_last_migration` | `migration_id: string` | `ExitCode` | 更新最后执行的迁移记录 |
| `mark_user_customizations` | - | `ExitCode` | 标记配置有用户自定义 |

**使用示例**:
```bash
source scripts/lib_version.sh

# 获取当前版本
version=$(get_current_version)
echo "Current: $version"

# 比较版本
if compare_versions "2.3.0" "2.2.0" -gt; then
    echo "Need upgrade"
fi

# 设置新版本
set_version "2.3.0"

# 检查并迁移
if needs_migration; then
    echo "Migration needed"
fi
```

---

## 🔄 迁移管理 (lib_migration.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `get_pending_migrations` | - | `string[]` | 获取待处理的迁移列表 |
| `execute_migration` | `migration_id: string` | `ExitCode` | 执行单个迁移脚本 |
| `run_migrations` | `[dry_run: bool]` | `ExitCode` | 执行所有待处理迁移 |
| `rollback_migration` | `migration_id: string` | `ExitCode` | 回滚指定迁移 |
| `log_migration` | `id: string`, `action: string`, `status: string` | - | 记录迁移历史 |
| `create_migration` | `description: string`, `[version: string]` | `ExitCode` | 创建新迁移模板 |
| `get_migration_history` | `[limit: int]` | `string` | 获取迁移历史记录 |
| `get_migration_version` | `migration_file: FilePath` | `VersionString` | 获取迁移脚本的版本号 |
| `migration_was_executed` | `migration_id: string` | `bool` | 检查迁移是否已执行 |

**使用示例**:
```bash
source scripts/lib_migration.sh

# 查看待处理迁移
pending=$(get_pending_migrations)
echo "Pending: $pending"

# 执行所有迁移
run_migrations

# 回滚指定迁移
rollback_migration "002_add_template_system"

# 创建新迁移
create_migration "Add new feature X" "2.4.0"
```

---

## 🏥 健康检查 (lib_health.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `run_health_check` | `[verbose: bool]` | `ExitCode` | 运行完整健康检查 |
| `check_syntax` | - | `bool` | 检查配置文件语法 |
| `check_plugins` | - | `bool` | 检查插件状态 |
| `check_dependencies` | - | `bool` | 检查依赖工具可用性 |
| `check_version_file` | - | `bool` | 检查版本文件完整性 |
| `generate_health_report` | `[output_file: FilePath]` | `ExitCode` | 生成 JSON 格式健康报告 |
| `display_health_report` | `report_json: string` | - | 显示健康报告 |

**使用示例**:
```bash
source scripts/lib_health.sh

# 运行健康检查
run_health_check

# 生成 JSON 报告
generate_health_report "/tmp/health.json"

# 单项检查
if check_syntax; then
    echo "Syntax OK"
fi
```

---

## 💾 备份恢复 (lib_backup.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `create_backup` | `description: string` | `FilePath` | 创建配置备份 |
| `list_backups` | `[limit: int]` | - | 列出所有备份 |
| `get_backup_info` | `backup_id: BackupId` | `string` \| `null` | 获取备份详细信息 |
| `restore_backup` | `backup_id: BackupId`, `[no_safety: bool]` | `ExitCode` | 从备份恢复配置 |
| `delete_backup` | `backup_id: BackupId` | `ExitCode` | 删除指定备份 |
| `cleanup_old_backups` | `keep_count: int` | `ExitCode` | 清理旧备份，保留指定数量 |

**使用示例**:
```bash
source scripts/lib_backup.sh

# 创建备份
backup_path=$(create_backup "Before upgrade")
echo "Backup: $backup_path"

# 列出备份
list_backups

# 恢复最新备份
restore_backup --latest

# 清理，只保留最近 5 个
cleanup_old_backups 5
```

---

## 📝 日志系统 (lib_logging.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `init_logging` | - | - | 初始化日志系统 |
| `log_info` | `message: string` | - | 记录信息级别日志 |
| `log_success` | `message: string` | - | 记录成功级别日志（绿色） |
| `log_warn` | `message: string` | - | 记录警告级别日志（黄色） |
| `log_error` | `message: string` | - | 记录错误级别日志（红色） |
| `log_debug` | `message: string` | - | 记录调试级别日志 |
| `log_section` | `title: string` | - | 输出章节标题 |
| `log_start` | `message: string` | - | 输出开始标记 |
| `log_end` | `message: string`, `[exit_code: int]` | - | 输出结束标记 |
| `rotate_logs` | - | - | 手动触发日志轮转 |
| `view_logs` | `[lines: int]` | - | 查看日志内容 |
| `clear_logs` | - | - | 清空当前日志文件 |

**日志级别**: DEBUG < INFO < SUCCESS < WARN < ERROR

**使用示例**:
```bash
source scripts/lib_logging.sh
init_logging

log_info "Starting process"
log_success "Operation completed"
log_warn "Deprecated feature used"
log_error "Operation failed: $error"

# 带章节标记
log_section "Installation"
log_start "Installing dependencies"
# ... 操作 ...
log_end "Installing dependencies" 0
```

---

## ⚡ 性能监控 (lib_performance.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `record_startup_time` | `mode: string`, `time_ms: int` | - | 记录启动时间 |
| `get_performance_stats` | `mode: string` | `json` | 获取性能统计信息 |
| `detect_performance_regression` | `mode: string`, `current_time: int`, `[threshold: int]` | `bool` | 检测性能回归 |
| `perf_show_info` | - | - | 显示性能数据信息 |
| `perf_show_trend` | `mode: string`, `[days: int]` | - | 显示性能趋势 |
| `perf_has_data` | `[mode: string]` | `bool` | 检查是否有性能数据 |
| `perf_get_record_count` | `[mode: string]` | `int` | 获取记录数量 |
| `perf_get_recent_time` | `mode: string` | `int` \| `null` | 获取最近的启动时间 |
| `perf_get_best_time` | `mode: string` | `int` \| `null` | 获取最佳启动时间 |
| `perf_calculate_stats` | `mode: string` | `json` | 计算统计数据 |
| `perf_compare_modes` | - | - | 比较不同模式的性能 |
| `perf_export_json` | `[output: FilePath]` | `string` | 导出 JSON 格式数据 |
| `perf_cleanup` | `[days: int]` | - | 清理旧性能数据 |

**使用示例**:
```bash
source scripts/lib_performance.sh

# 记录启动时间
record_startup_time "normal" 1568

# 获取统计
stats=$(get_performance_stats "normal")
echo "$stats"

# 检测性能回归
if detect_performance_regression "normal" 2000 20; then
    log_warn "Performance regression detected!"
fi

# 显示趋势
perf_show_trend "normal" 7
```

---

## 🌐 平台兼容 (lib_platform_compat.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `get_os_type` | - | `"linux"` \| `"macos"` \| `"unknown"` | 获取操作系统类型 |
| `is_macos` | - | `bool` | 检查是否为 macOS |
| `is_linux` | - | `bool` | 检查是否为 Linux |
| `get_os_version` | - | `string` | 获取操作系统版本 |
| `get_file_size` | `file_path: FilePath` | `int` | 获取文件大小（字节） |
| `get_file_perms` | `file_path: FilePath` | `string` | 获取文件权限 |
| `get_file_mtime` | `file_path: FilePath` | `int` | 获取文件修改时间戳 |
| `get_timestamp_ms` | - | `int` | 获取当前时间戳（毫秒） |
| `get_date_relative` | `date_string: string` | `string` | 获取相对日期描述 |
| `realpath_compat` | `path: string` | `string` \| `null` | 跨平台 realpath 替代 |
| `get_gnu_tool` | `tool: string` | `string` \| `null` | 获取 GNU 工具路径 |
| `get_compat_sed` | - | `string` | 获取兼容的 sed 命令 |
| `get_time_command` | - | `string` | 获取高精度时间命令 |
| `supports_color` | - | `bool` | 检查终端是否支持颜色 |
| `set_color_support` | `[force: bool]` | - | 设置颜色支持 |
| `get_current_shell` | - | `string` | 获取当前 shell 名称 |
| `get_shell_version` | - | `string` | 获取当前 shell 版本 |
| `detect_package_manager` | - | `"apt"` \| `"yum"` \| `"brew"` \| `"unknown"` | 检测包管理器 |
| `install_package` | `package: string` | `ExitCode` | 安装软件包 |
| `command_exists` | `command: string` | `bool` | 检查命令是否存在 |

**使用示例**:
```bash
source scripts/lib_platform_compat.sh

# 平台检测
if is_macos; then
    echo "Running on macOS"
elif is_linux; then
    echo "Running on Linux"
fi

# 跨平台文件操作
size=$(get_file_size "$HOME/.zshrc")
echo "Size: $size bytes"

# 时间操作
timestamp=$(get_timestamp_ms)
relative=$(get_date_relative "2026-01-29 10:00:00")
echo "Relative: $relative"
```

---

## 🔍 搜索增强 (zsh-functions/search.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `hg` | `pattern: string`, `[directory: path]` | - | 递归搜索文件内容（区分大小写） |
| `hig` | `pattern: string`, `[directory: path]` | - | 递归搜索文件内容（忽略大小写） |
| `hrg` | `pattern: string`, `[directory: path]` | - | 使用 ripgrep 搜索（高性能） |
| `hirg` | `pattern: string`, `[directory: path]` | - | 使用 ripgrep 搜索（忽略大小写） |

**使用示例**:
```bash
# 搜索代码中的 TODO
hg "TODO" ./src

# 忽略大小写搜索
hig "error" ./logs

# 使用 ripgrep 高性能搜索
hrg "function.*test" .
```

---

## 🔧 实用工具 (zsh-functions/utils.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `proxy` | `[config_file: path]` | - | 启用网络代理 |
| `unproxy` | - | - | 禁用网络代理 |
| `proxy_status` | - | - | 显示代理配置状态 |
| `check_environment` | - | - | 检查环境状态（容器/SSH） |
| `reload_zsh` | - | - | 重新加载 ZSH 配置 |

**使用示例**:
```bash
# 启用代理
proxy

# 查看代理状态
proxy_status

# 禁用代理
unproxy

# 重新加载配置
reload_zsh
```

---

## ❓ 帮助系统 (zsh-functions/help.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `zsh_help` | `[command: string]` | - | 显示命令帮助 |
| `handle_help_param` | `command: string`, `param: string` | - | 处理 --help 参数 |
| `init_help_database` | - | - | 初始化帮助数据库 |
| `show_help_overview` | - | - | 显示帮助概览 |
| `show_category_help` | `category: string` | - | 显示分类帮助 |
| `show_command_help` | `command: string` | - | 显示具体命令帮助 |
| `show_help_usage` | `command: string` | - | 显示命令用法 |

**使用示例**:
```bash
# 显示帮助概览
zsh_help

# 显示特定命令帮助
zsh_help proxy

# 命令支持 --help
proxy --help
```

---

## 📈 性能分析 (zsh-functions/performance.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `performance_detailed` | - | - | 运行详细性能分析 |
| `test_segmented_startup` | - | - | 测试分段启动时间 |
| `test_plugin_performance` | - | - | 测试插件性能 |
| `test_memory_usage` | - | - | 测试内存使用 |
| `generate_performance_report` | - | - | 生成性能报告 |
| `provide_optimization_suggestions` | `data: json` | - | 提供优化建议 |

**使用示例**:
```bash
# 完整性能分析
performance_detailed

# 测试启动时间
test_segmented_startup

# 测试内存
test_memory_usage
```

---

## ✅ 参数验证 (zsh-functions/validation.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `assert_param` | `value: any`, `param_name: string` | `bool` | 断言参数非空 |
| `assert_directory` | `path: string` | `bool` | 断言目录存在 |
| `assert_file` | `path: string` | `bool` | 断言文件存在 |
| `assert_command` | `command: string` | `bool` | 断言命令可用 |
| `assert_pattern` | `value: string`, `pattern: regex` | `bool` | 断言值匹配模式 |
| `validate_directory` | `path: string` | `bool` | 验证目录存在 |
| `validate_file` | `path: string` | `bool` | 验证文件存在 |
| `validate_not_empty` | `value: string` | `bool` | 验证值非空 |
| `validate_param_count` | `expected: int`, `actual: int` | `bool` | 验证参数数量 |
| `validate_pattern` | `value: string`, `pattern: regex` | `bool` | 验证值匹配模式 |

**使用示例**:
```bash
# 验证参数
if ! assert_param "$1" "config_file"; then
    echo "Error: config_file required"
    return 1
fi

# 验证目录
if ! validate_directory "$config_dir"; then
    echo "Error: directory not found: $config_dir"
    return 1
fi
```

---

## 🔐 上下文显示 (zsh-functions/context.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `_get_env_indicators` | - | `string[]` | 获取环境指示符列表 |
| `prompt_env_indicators` | - | `string` | 生成提示符环境指示符 |
| `_is_in_container` | - | `bool` | 检查是否在容器中 |
| `_is_in_ssh` | - | `bool` | 检查是否在 SSH 会话中 |
| `_is_using_proxy` | - | `bool` | 检查是否使用代理 |
| `check_proxy` | - | `bool` | 检查代理状态 |

---

## 🤖 Claude 集成 (zsh-functions/claude.zsh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `claude` | `[args: string[]]` | - | Claude AI 主命令 |
| `_cc_list` | - | - | 列出所有配置 |
| `_cc_create` | `name: string` | - | 创建新配置 |
| `_cc_edit` | `name: string` | - | 编辑配置 |
| `_cc_delete` | `name: string` | - | 删除配置 |
| `_cc_current` | - | - | 显示当前配置 |
| `_cc_refresh` | - | - | 刷新配置 |

---

## 🧪 干运行模式 (lib_dryrun.sh)

| 函数 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `is_dry_run` | - | `bool` | 检查是否为干运行模式 |
| `dry_run_notice` | - | - | 显示干运行提示 |
| `dry_exec` | `command: string` | - | 干运行执行命令 |
| `dry_chmod`, `dry_chown`, `dry_mkdir`, `dry_cp`, `dry_mv`, `dry_rm`, `dry_ln` | 同原生命令 | - | 干运行文件操作 |
| `dry_run_get_count` | - | `int` | 获取干运行操作计数 |
| `dry_run_complete` | - | - | 完成干运行并显示摘要 |

---

## 📋 CLI 工具命令

### zsh_config_manager.sh
```bash
zsh_config_manager.sh version          # 显示版本
zsh_config_manager.sh migrate          # 执行迁移
zsh_config_manager.sh health           # 健康检查
zsh_config_manager.sh backup "desc"    # 创建备份
zsh_config_manager.sh list-backups     # 列出备份
zsh_config_manager.sh restore <id>     # 恢复备份
zsh_config_manager.sh rollback <id>    # 回滚迁移
zsh_config_manager.sh history          # 迁移历史
zsh_config_manager.sh validate         # 验证配置
```

### zsh_tools.sh
```bash
zsh_tools.sh validate                  # 验证配置
zsh_tools.sh backup                    # 备份配置
zsh_tools.sh restore [path]            # 恢复配置
zsh_tools.sh update                    # 更新插件
zsh_tools.sh clean                     # 清理缓存
zsh_tools.sh benchmark                 # 性能测试
zsh_tools.sh doctor                    # 系统诊断
zsh_tools.sh perf-report               # 性能报告
zsh_tools.sh reset                     # 重置配置
```

### zsh_launcher.sh
```bash
zsh_launcher.sh minimal               # 极速模式
zsh_launcher.sh fast                  # 快速模式
zsh_launcher.sh normal                # 标准模式
zsh_launcher.sh benchmark             # 性能对比
```

---

## 🔗 相关文档

- [CODEMAP.json](CODEMAP.json) - 项目结构映射
- [TYPES.md](TYPES.md) - 类型定义
- [SEMANTIC_TAGS.md](SEMANTIC_TAGS.md) - 语义标签标准
- [DEPENDENCY_GRAPH.md](DEPENDENCY_GRAPH.md) - 依赖关系图
- [AI_OPTIMIZATION_GUIDE.md](AI_OPTIMIZATION_GUIDE.md) - 大模型优化指南

---

**最后更新**: 2026-01-31
**总函数数**: 150+
**文档覆盖率**: 85%
