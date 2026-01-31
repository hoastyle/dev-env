# 语义标签标准 (Semantic Tags Standard)

> **目的**: 定义函数和代码的语义标签，帮助大模型快速理解代码用途和分类。

**版本**: 1.0
**最后更新**: 2026-01-31

---

## 🏷️ 标签分类

### 访问级别标签 (@tag)

定义函数的访问级别和使用范围。

#### `@tag public`

公共 API 函数，可以被外部代码调用。

```bash
# @tag public
# @category version_management
get_current_version() {
    ...
}
```

**特点**:
- 稳定的接口，不会随意变更
- 有完整的文档和类型注解
- 经过充分测试

#### `@tag internal`

内部函数，仅供模块内部使用。

```bash
# @tag internal
# @category logging
# @internal 仅供 log_with_level 调用
_log() {
    ...
}
```

**特点**:
- 可能随时变更
- 不保证向后兼容
- 不在 API 文档中列出

#### `@tag cli`

CLI 命令入口函数。

```bash
# @tag cli
# @category config_tools
cmd_backup() {
    ...
}
```

**特点**:
- 通过命令行直接调用
- 参数解析在函数内部
- 有用户可见的输出

#### `@tag callback`

回调函数，用于事件处理或钩子。

```bash
# @tag callback
# @category migration
migrate_up() {
    ...
}

migrate_down() {
    ...
}
```

#### `@tag deprecated`

已弃用的函数，保留用于兼容。

```bash
# @tag deprecated
# @deprecated 请使用 get_current_version 代替
get_version() {
    get_current_version
}
```

---

### 功能分类标签 (@category)

定义函数所属的功能领域。

| 分类 | 说明 | 示例函数 |
|------|------|----------|
| `version_management` | 版本管理 | get_current_version, set_version |
| `migration_engine` | 迁移执行 | execute_migration, rollback_migration |
| `health_checking` | 健康检查 | run_health_check, check_syntax |
| `backup_restore` | 备份恢复 | create_backup, restore_backup |
| `logging` | 日志记录 | log_info, log_error |
| `performance_monitoring` | 性能监控 | record_startup_time, get_performance_stats |
| `platform_abstraction` | 平台抽象 | get_os_type, is_macos |
| `search_enhancement` | 搜索增强 | hg, hig, hrg |
| `proxy_management` | 代理管理 | proxy, unproxy |
| `help_system` | 帮助系统 | zsh_help, show_command_help |
| `validation` | 参数验证 | assert_param, validate_file |
| `testing` | 测试支持 | dry_exec, is_dry_run |

---

### 参数标签 (@param)

描述函数参数的名称和类型。

```bash
# @param VersionString $version 版本号
# @param string [date] 构建日期（可选）
# @param int [count=10] 数量（可选，默认10）
set_version() {
    local version="$1"
    local date="${2:-$(date +%Y-%m-%d)}"
    local count="${3:-10}"
    ...
}
```

**语法**:
```
@param <Type> $<name> [<description>]
```

**可选参数**: 用方括号 `[]` 包裹参数名
**默认值**: 用 `=<value>` 表示默认值

---

### 返回值标签 (@return)

描述函数的返回值类型和含义。

```bash
# @return VersionString 当前版本号
get_current_version() {
    ...
}

# @return exitcode 成功返回0，失败返回1
validate_config() {
    ...
}

# @return bool true表示条件满足
is_installed() {
    ...
}

# @return string[] 备份ID列表
list_backups() {
    ...
}
```

---

### 异常标签 (@throws)

描述函数可能抛出的错误。

```bash
# @return exitcode
# @throws InvalidVersion 如果版本格式不正确
# @throws FileNotFound 如果版本文件不存在
set_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: InvalidVersion" >&2
        return 1
    fi
    ...
}
```

---

### 示例标签 (@example)

提供函数使用示例。

```bash
# @example
#   # 获取当前版本
#   version=$(get_current_version)
#   echo "Current: $version"
#
#   # 设置新版本
#   set_version "2.3.0"
get_current_version() {
    ...
}
```

---

## 📋 完整注解模板

### 公共函数模板

```bash
# <Brief description>
#
# @tag public
# @category <category_name>
# @param <Type> $<param_name> <parameter description>
# @param <Type> [$optional_param] <optional parameter description>
# @return <Type> <return value description>
# @throws <ErrorType> <error condition>
# @example
#   <usage example>
function_name() {
    ...
}
```

### 内部函数模板

```bash
# <Brief description>
#
# @tag internal
# @category <category_name>
# @internal <usage context>
_internal_function() {
    ...
}
```

### CLI 命令模板

```bash
# <Brief description>
#
# @tag cli
# @category <category_name>
# @usage <command> <arguments>
# @example
#   <usage example>
cmd_command_name() {
    ...
}
```

---

## 🎯 标签使用原则

### 1. 最小化原则

只为需要外部访问的函数添加完整注解。

```bash
# ✅ 好的：公共函数有完整注解
# @tag public
# @category version_management
# @param VersionString $version
# @return exitcode
set_version() { ... }

# ✅ 好的：内部函数只需基本说明
# @tag internal
# 内部辅助函数
_validate_version_format() { ... }

# ❌ 不好：过度注解
# @tag internal
# @category version_management
# @param string $version 版本号字符串
# @param string $pattern 正则表达式模式
# @return bool 返回true表示匹配
# @throws RegexError 如果正则表达式无效
# @example ...太多示例...
_validate_version_format() { ... }
```

### 2. 语义化原则

标签名称应该自解释，避免冗余。

```bash
# ✅ 好的：标签名称已说明用途
# @param VersionString $version

# ❌ 不好：冗余描述
# @param string $version 版本号字符串
```

### 3. 一致性原则

相同功能的函数使用相同的分类标签。

```bash
# ✅ 好的：一致使用分类
# @category version_management
get_current_version() { ... }

# @category version_management
set_version() { ... }

# @category version_management
compare_versions() { ... }
```

---

## 🤖 大模型使用指南

### 查找公共 API

**Prompt**:
```
请查找所有 @tag public 的函数，按 @category 分组显示。
```

### 查找 CLI 命令

**Prompt**:
```
请列出所有 @tag cli 的命令，包括它们的 @usage 说明。
```

### 查找特定功能

**Prompt**:
```
请查找 @category backup_restore 下的所有公共函数，
包括它们的 @param 和 @return 说明。
```

### 生成代码

**Prompt**:
```
请创建一个新函数，使用以下标准：
1. @tag public
2. @category version_management
3. 完整的 @param 和 @return 注解
4. 包含 @example

函数功能：验证版本号格式
```

---

## 📚 相关文档

- [TYPES.md](TYPES.md) - 类型定义标准
- [FUNCTION_INDEX.md](FUNCTION_INDEX.md) - 函数索引
- [CODEMAP.json](CODEMAP.json) - 项目结构映射

---

## 💡 最佳实践

1. **公共函数必须有完整注解**
2. **内部函数保持简洁**
3. **使用语义化的分类名称**
4. **参数和返回值必须有类型**
5. **复杂函数需要使用示例**

---

**维护者**: Development Team
**文档版本**: 1.0
**最后更新**: 2026-01-31
