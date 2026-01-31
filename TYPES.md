# 类型定义标准 (Type Definition Standard)

> **目的**: 为 Bash 脚本提供类型注解标准，增强代码可读性和大模型理解能力。

**版本**: 1.0
**最后更新**: 2026-01-31

---

## 📋 基础类型

### `string`

字符串类型，表示任意文本数据。

```bash
# @param string $name
# @return string
greet() {
    local name="$1"
    echo "Hello, $name"
}
```

### `int`

整数类型，表示数值。

```bash
# @param int $count
# @return int
increment() {
    local count="$1"
    echo $((count + 1))
}
```

### `bool`

布尔类型，`0` 表示 true（成功），`1` 表示 false（失败）。

```bash
# @return bool
is_installed() {
    command -v "$1" >/dev/null 2>&1
    return $?  # 0=true, 1=false
}
```

### `path`

文件系统路径，表示文件或目录的路径。

```bash
# @param path $file_path
# @return int
get_file_size() {
    local file_path="$1"
    stat -c%s "$file_path" 2>/dev/null || echo "0"
}
```

### `exitcode`

退出码，`0` 表示成功，非 `0` 表示失败。

```bash
# @return exitcode
validate_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        return 1  # 失败
    fi
    return 0  # 成功
}
```

---

## 🔤 复合类型

### `VersionString`

语义化版本字符串，格式为 `MAJOR.MINOR.PATCH`。

**格式**: `^\d+\.\d+\.\d+$`

**示例**:
- `"2.3.0"`
- `"1.0.0"`
- `"0.0.1"`

```bash
# @param VersionString $version
# @return exitcode
set_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format" >&2
        return 1
    fi
    ...
}
```

### `BackupId`

备份 ID，格式为 `YYYYMMDD-HHMMSS`。

**格式**: `^\d{8}-\d{6}$`

**示例**:
- `"20260131-103000"`
- `"20261225-235959"`

```bash
# @param BackupId $backup_id
# @return exitcode
restore_backup() {
    local backup_id="$1"
    if ! [[ "$backup_id" =~ ^[0-9]{8}-[0-9]{6}$ ]]; then
        echo "Error: Invalid backup ID format" >&2
        return 1
    fi
    ...
}
```

### `Timestamp`

Unix 时间戳（秒）或毫秒时间戳。

**格式**: 整数

**示例**:
- `1706698800` (秒级)
- `1706698800000` (毫秒级)

```bash
# @return Timestamp (milliseconds)
get_timestamp_ms() {
    echo $(($(date +%s) * 1000 + $(date +%N % 1000)))
}
```

### `LogLevel`

日志级别枚举。

**可选值**:
- `DEBUG` - 调试信息
- `INFO` - 一般信息
- `SUCCESS` - 成功信息
- `WARN` - 警告信息
- `ERROR` - 错误信息

```bash
# @param LogLevel $level
# @param string $message
log_with_level() {
    local level="$1"
    local message="$2"
    case "$level" in
        DEBUG|INFO|SUCCESS|WARN|ERROR)
            # 有效级别
            ;;
        *)
            echo "Error: Invalid log level" >&2
            return 1
            ;;
    esac
    ...
}
```

### `MigrationId`

迁移 ID，格式为三位数字加下划线和描述。

**格式**: `^\d{3}_[a-z_]+$`

**示例**:
- `"001_initial"`
- `"002_add_template_system"`
- `"100_new_feature"`

```bash
# @param MigrationId $migration_id
# @return exitcode
execute_migration() {
    local migration_id="$1"
    if ! [[ "$migration_id" =~ ^[0-9]{3}_[a-z_]+$ ]]; then
        echo "Error: Invalid migration ID" >&2
        return 1
    fi
    ...
}
```

### `OSType`

操作系统类型枚举。

**可选值**:
- `linux`
- `macos`
- `unknown`

```bash
# @return OSType
get_os_type() {
    local os_type=$(uname -s)
    case "$os_type" in
        Darwin) echo "macos" ;;
        Linux) echo "linux" ;;
        *) echo "unknown" ;;
    esac
}
```

### `FilePath`

已存在的文件路径。

**验证**: 文件必须存在且可读。

```bash
# @param FilePath $config_file
# @return string
load_config() {
    local config_file="$1"
    if [[ ! -f "$config_file" ]]; then
        echo "Error: File not found: $config_file" >&2
        return 1
    fi
    cat "$config_file"
}
```

### `DirPath`

已存在的目录路径。

**验证**: 目录必须存在且可访问。

```bash
# @param DirPath $dir_path
# @return string[]
list_files() {
    local dir_path="$1"
    if [[ ! -d "$dir_path" ]]; then
        echo "Error: Directory not found: $dir_path" >&2
        return 1
    fi
    ls -1 "$dir_path"
}
```

---

## 📚 数组类型

### `string[]`

字符串数组。

```bash
# @return string[]
list_backups() {
    local -a backups=()
    for dir in "$BACKUP_DIR"/*/; do
        backups+=("$(basename "$dir")")
    done
    printf '%s\n' "${backups[@]}"
}
```

### `MigrationId[]`

迁移 ID 数组。

```bash
# @return MigrationId[]
get_pending_migrations() {
    local applied=$(get_applied_migrations)
    local -a pending=()
    for file in "$MIGRATION_DIR"/*.sh; do
        local id=$(basename "$file" .sh)
        if ! [[ "$applied" =~ "$id" ]]; then
            pending+=("$id")
        fi
    done
    printf '%s\n' "${pending[@]}"
}
```

### `KeyValue[]`

键值对数组，格式为 `key=value`。

```bash
# @return KeyValue[]
get_config() {
    while IFS= read -r line; do
        if [[ "$line" =~ ^[A-Z_]+= ]]; then
            echo "$line"
        fi
    done < "$CONFIG_FILE"
}
```

---

## 🎯 类型注解语法

### 函数级别注解

```bash
# @tag public
# @category version_management
# @param VersionString $version 新版本号
# @param string [date] 构建日期（可选，默认今天）
# @return exitcode 成功返回0，失败返回1
set_version() {
    local version="$1"
    local date="${2:-$(date +%Y-%m-%d)}"
    ...
}
```

### 变量级别注解

```bash
# VersionString: 当前版本号
local current_version

# BackupId: 备份ID
local backup_id

# int: 文件大小（字节）
local file_size

# bool: 是否成功
local success=false
```

### 参数验证注解

```bash
# @param VersionString $version
# @throws InvalidVersion 如果版本格式不正确
set_version() {
    local version="$1"
    if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: InvalidVersion: format must be MAJOR.MINOR.PATCH" >&2
        return 1
    fi
    ...
}
```

---

## 📝 使用示例

### 完整类型注解示例

```bash
#!/bin/bash
# =============================================================================
# Version Management Library
# =============================================================================

# Get current configuration version
# @tag public
# @category version_management
# @return VersionString 当前版本号，如 "2.3.0"；如果未找到返回 "0.0.0"
get_current_version() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "0.0.0"
        return 1
    fi

    local version=$(grep "^VERSION=" "$VERSION_FILE" 2>/dev/null | cut -d'"' -f2)
    if [[ -z "$version" ]]; then
        echo "0.0.0"
        return 1
    fi

    echo "$version"
    return 0
}

# Set configuration version
# @tag public
# @category version_management
# @param VersionString $new_version 新版本号，格式 "MAJOR.MINOR.PATCH"
# @param string [build_date] 构建日期（可选），默认今天
# @return exitcode 成功返回0，失败返回1
# @throws InvalidVersion 如果版本格式不正确
set_version() {
    local new_version="$1"
    local build_date="${2:-$(date +%Y-%m-%d)}"

    # 验证类型
    if [[ -z "$new_version" ]]; then
        echo "Error: Version cannot be empty" >&2
        return 1
    fi

    if ! [[ "$new_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: InvalidVersion: Expected MAJOR.MINOR.PATCH format" >&2
        return 1
    fi

    # 实现逻辑...
    echo "✅ Version set to: $new_version"
    return 0
}

# Compare two version strings
# @tag public
# @category version_management
# @param VersionString $v1 第一个版本号
# @param VersionString $v2 第二个版本号
# @param string [op] 比较操作符：-eq, -ne, -lt, -le, -gt, -ge
# @return bool 比较结果，0=true, 1=false
# @example
#   if compare_versions "2.3.0" "2.2.0" -gt; then
#       echo "v1 is greater"
#   fi
compare_versions() {
    local v1="$1"
    local v2="$2"
    local op="${3:--lt}"

    # 验证版本格式
    if ! [[ "$v1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
       ! [[ "$v2" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Invalid version format" >&2
        return 1
    fi

    # 实现比较逻辑...
    # 返回 0=true, 1=false
}
```

---

## 📖 类型转换

### 字符串到整数

```bash
# @param string $input
# @return int
string_to_int() {
    local input="$1"
    echo $((input))
}
```

### 整数到字符串

```bash
# @param int $input
# @return string
int_to_string() {
    local input="$1"
    echo "$input"
}
```

### 验证类型

```bash
# @param string $value
# @param string $expected_type
# @return bool
validate_type() {
    local value="$1"
    local expected_type="$2"

    case "$expected_type" in
        VersionString)
            [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
            ;;
        BackupId)
            [[ "$value" =~ ^[0-9]{8}-[0-9]{6}$ ]]
            ;;
        int)
            [[ "$value" =~ ^-?[0-9]+$ ]]
            ;;
        bool)
            [[ "$value" =~ ^(0|1|true|false)$ ]]
            ;;
        *)
            return 1
            ;;
    esac
}
```

---

## 🔍 类型检查工具

### 创建类型检查函数

```bash
# types.sh - 类型检查库

# 检查是否为有效的版本号
is_version_string() {
    [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# 检查是否为有效的备份ID
is_backup_id() {
    [[ "$1" =~ ^[0-9]{8}-[0-9]{6}$ ]]
}

# 检查是否为整数
is_int() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

# 检查是否为布尔值
is_bool() {
    [[ "$1" =~ ^(0|1|true|false)$ ]]
}

# 检查是否为文件路径
is_file_path() {
    [[ -f "$1" ]]
}

# 检查是否为目录路径
is_dir_path() {
    [[ -d "$1" ]]
}
```

---

## 📚 相关文档

- [FUNCTION_INDEX.md](FUNCTION_INDEX.md) - 函数索引（包含类型信息）
- [SEMANTIC_TAGS.md](SEMANTIC_TAGS.md) - 语义标签标准
- [CODEMAP.json](CODEMAP.json) - 项目结构映射

---

## 💡 最佳实践

1. **总是为公共函数添加类型注解**
2. **使用语义类型别名**（如 VersionString 而非 string）
3. **在函数内部验证类型**
4. **返回有意义的退出码**
5. **为复杂类型添加使用示例**

---

**维护者**: Development Team
**文档版本**: 1.0
**最后更新**: 2026-01-31
