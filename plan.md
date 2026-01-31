# dev-env v2.2 实施计划 - 新手可执行版

**版本**: 1.0  
**创建日期**: 2025-11-11  
**目标版本**: v2.2  
**预计完成**: 2025-11-29 (3周)  
**维护者**: Development Team

---

## 📋 目录

- [总体概述](#总体概述)
- [第一周任务详情](#第一周任务详情-2025-11-11---2025-11-15)
- [第二周任务详情](#第二周任务详情-2025-11-15---2025-11-22)
- [第三周任务详情](#第三周任务详情-2025-11-22---2025-11-29)
- [验收标准](#验收标准)
- [常见问题](#常见问题)

---

## 总体概述

### 项目目标

在3周内完成以下核心功能，将项目从 v2.1.1 升级到 v2.2：

1. ✅ **日志系统集成** - 为所有脚本添加结构化日志
2. ✅ **性能监控系统** - 建立性能基准和趋势分析
3. ✅ **自动化测试套件** - 完成核心功能测试覆盖
4. ✅ **配置模板系统** - 提供针对不同场景的配置模板

### 时间线总览

```
Week 1 (11-11 ~ 11-15):  日志系统 + 性能监控 MVP
Week 2 (11-15 ~ 11-22):  测试套件 Phase 1 + 配置模板原型
Week 3 (11-22 ~ 11-29):  测试套件 Phase 2 + CI/CD集成 + 文档更新
```

### 里程碑

| 里程碑 | 日期 | 交付物 |
|--------|------|--------|
| M1: 日志系统完成 | 2025-11-13 | lib_logging.sh + 集成 |
| M2: 性能监控 MVP | 2025-11-15 | 性能数据记录 + 趋势分析 |
| M3: 测试 Phase 1 | 2025-11-20 | 核心功能测试 |
| M4: 配置模板原型 | 2025-11-22 | 3个基础模板 + 生成器 |
| M5: 测试 Phase 2 | 2025-11-27 | 性能测试 + 集成测试 |
| M6: v2.2 发布 | 2025-11-29 | 完整功能 + 文档 |

---

## 第一周任务详情 (2025-11-11 ~ 2025-11-15)

### 任务 1.1: 创建日志系统库 (1-2天)

**负责人**: [待分配]  
**优先级**: 🔴 高  
**预估时间**: 8-16 小时

#### 📝 任务描述

创建一个通用的日志库 `scripts/lib_logging.sh`，为所有脚本提供统一的日志功能。

#### ✅ 执行步骤

**Step 1: 创建日志库文件 (2小时)**

```bash
# 1. 在项目根目录执行
cd /home/howie/Workspace/Utility/dev-env

# 2. 创建日志库文件
cat > scripts/lib_logging.sh << 'LOGEOF'
#!/bin/bash
# ==============================================
# dev-env 日志库
# 版本: 1.0
# ==============================================

# 日志级别定义
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# 当前日志级别
CURRENT_LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

# 日志目录和文件
LOG_DIR="${LOG_DIR:-$HOME/.zsh/logs}"
LOG_FILE="${LOG_FILE:-$LOG_DIR/dev-env.log}"

# 确保日志目录存在
ensure_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR" 2>/dev/null || {
            echo "Warning: Cannot create log directory $LOG_DIR" >&2
            return 1
        }
    fi
}

# 初始化日志系统
init_logging() {
    ensure_log_dir
    log_info "=== Logging session started ==="
}

# 获取时间戳
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# 日志记录核心函数
_log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(get_timestamp)
    local log_entry="[$timestamp] [$level] $message"

    if [[ $level == "ERROR" || $level == "WARN" ]]; then
        echo "$log_entry" >&2
    else
        echo "$log_entry"
    fi

    ensure_log_dir
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
}

# 各级别日志函数
log_debug() { [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_DEBUG ]] && _log "DEBUG" "$@"; }
log_info() { [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_INFO ]] && _log "INFO" "$@"; }
log_warn() { [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_WARN ]] && _log "WARN" "$@"; }
log_error() { [[ $CURRENT_LOG_LEVEL -le $LOG_LEVEL_ERROR ]] && _log "ERROR" "$@"; }
log_success() { 
    local timestamp=$(get_timestamp)
    local log_entry="[SUCCESS] [$timestamp] $*"
    echo "$log_entry"
    ensure_log_dir
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
}

# 查看日志
view_logs() {
    local lines=${1:-50}
    if [[ -f "$LOG_FILE" ]]; then
        tail -n "$lines" "$LOG_FILE"
    else
        echo "Log file not found: $LOG_FILE"
        return 1
    fi
}

# 清理旧日志
clean_old_logs() {
    local days=${1:-7}
    ensure_log_dir
    find "$LOG_DIR" -name "*.log" -type f -mtime +$days -delete 2>/dev/null
    log_info "Cleaned logs older than $days days"
}

# 导出函数
export -f log_debug log_info log_warn log_error log_success
export -f view_logs clean_old_logs init_logging
LOGEOF

# 3. 设置执行权限
chmod +x scripts/lib_logging.sh

# 4. 验证
ls -lh scripts/lib_logging.sh
```

**Step 2: 测试日志库 (1小时)**

```bash
# 创建测试脚本
cat > /tmp/test_logging.sh << 'EOF'
#!/bin/bash
source /home/howie/Workspace/Utility/dev-env/scripts/lib_logging.sh

init_logging
log_debug "Debug message"
log_info "Info message"
log_warn "Warning message"
log_error "Error message"
log_success "Success message"

echo ""
echo "=== Last 5 log entries ==="
view_logs 5
EOF

chmod +x /tmp/test_logging.sh
/tmp/test_logging.sh
```

**验收标准**:
- ✅ scripts/lib_logging.sh 文件存在且可执行
- ✅ 日志目录 ~/.zsh/logs/ 自动创建
- ✅ 日志文件正确写入
- ✅ 各级别日志输出格式正确

---

### 任务 1.2: 集成日志到核心脚本 (4-6小时)

**负责人**: [待分配]  
**优先级**: 🔴 高  
**预估时间**: 4-6 小时

#### ✅ 执行步骤

```bash
# 备份原文件
cp scripts/zsh_tools.sh scripts/zsh_tools.sh.bak

# 在文件开头添加（#!/bin/bash 后）：
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib_logging.sh"
init_logging

# 替换 echo 语句
# echo "✓ ..." → log_info "..."
# echo "⚠️ ..." → log_warn "..."
# echo "❌ ..." → log_error "..."
# echo "🎉 ..." → log_success "..."

# 批量替换
sed -i 's/echo "✓ \(.*\)"/log_info "\1"/g' scripts/zsh_tools.sh
sed -i 's/echo "⚠️  \(.*\)"/log_warn "\1"/g' scripts/zsh_tools.sh
sed -i 's/echo "❌ \(.*\)"/log_error "\1"/g' scripts/zsh_tools.sh
sed -i 's/echo "🎉 \(.*\)"/log_success "\1"/g' scripts/zsh_tools.sh

# 测试
./scripts/zsh_tools.sh validate
tail -20 ~/.zsh/logs/dev-env.log
```

对其他脚本重复相同操作。

---

### 任务 1.3: 创建性能监控系统 (2-3天)

**负责人**: [待分配]  
**优先级**: 🔴 高  
**预估时间**: 16-24 小时

#### ✅ 执行步骤

```bash
# 创建性能监控库
cat > scripts/lib_performance.sh << 'PERFEOF'
#!/bin/bash
# ==============================================
# dev-env 性能监控库
# ==============================================

PERF_DATA_DIR="${PERF_DATA_DIR:-$HOME/.zsh/performance}"
PERF_DATA_FILE="$PERF_DATA_DIR/startup_times.csv"

ensure_perf_dir() {
    mkdir -p "$PERF_DATA_DIR" 2>/dev/null
}

# 记录启动时间
record_startup_time() {
    local mode=$1
    local time_ms=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    ensure_perf_dir
    echo "$timestamp,$mode,$time_ms" >> "$PERF_DATA_FILE"
}

# 性能趋势分析
analyze_performance_trend() {
    local mode=${1:-}
    local days=${2:-7}
    
    ensure_perf_dir
    
    if [[ ! -f "$PERF_DATA_FILE" ]]; then
        echo "No performance data available"
        return 1
    fi
    
    echo "=== Performance Trend (Last $days days) ==="
    
    if [[ -n "$mode" ]]; then
        _analyze_mode "$mode" "$days"
    else
        for m in minimal fast normal; do
            _analyze_mode "$m" "$days"
            echo ""
        done
    fi
}

_analyze_mode() {
    local mode=$1
    local days=$2
    
    awk -F',' -v m="$mode" -v d="$days" '
        BEGIN { sum=0; count=0; min=999999; max=0 }
        $2 == m && systime() - mktime(gensub(/[-:]/, " ", "g", $1)) <= d*86400 {
            sum += $3; count++
            if ($3 < min) min = $3
            if ($3 > max) max = $3
        }
        END {
            if (count > 0) {
                avg = sum / count
                printf "Mode: %s\n", m
                printf "  Samples: %d\n", count
                printf "  Average: %.2f ms\n", avg
                printf "  Min: %.2f ms\n", min
                printf "  Max: %.2f ms\n", max
            }
        }
    ' "$PERF_DATA_FILE"
}

# 导出函数
export -f record_startup_time analyze_performance_trend
PERFEOF

chmod +x scripts/lib_performance.sh

# 在 zsh_tools.sh 中添加命令
perf_report() {
    source "${SCRIPT_DIR}/lib_performance.sh"
    analyze_performance_trend "" 7
}

# 在主命令 case 中添加
perf-report)
    perf_report
    ;;
```

---

## 第二周任务详情 (2025-11-15 ~ 2025-11-22)

### 任务 2.1-2.3: 单元测试实现

参考完整文档中的详细步骤创建：
- test_path_detection.sh
- test_error_handling.sh  
- test_config_validation.sh

### 任务 2.4-2.5: 配置模板系统

参考完整文档创建模板和生成器。

---

## 第三周任务详情 (2025-11-22 ~ 2025-11-29)

### 任务 3.1: 性能测试
### 任务 3.2: CI/CD 集成
### 任务 3.3: 文档更新

---

## 验收标准

### 功能完整性
- ✅ 日志系统在所有核心脚本中集成
- ✅ 性能数据自动记录和可视化
- ✅ 单元测试覆盖率达到 92%+
- ✅ 7个配置模板可用
- ✅ 配置生成器可交互式生成配置

### 质量标准
- ✅ 所有新代码有测试覆盖
- ✅ ShellCheck 零警告
- ✅ 所有脚本有正确的可执行权限
- ✅ 文档完整且准确

### 性能标准
- ✅ 日志系统开销 <1ms
- ✅ 性能监控开销 <2ms
- ✅ 所有模式启动时间符合预期

---

## 常见问题

### Q: 如何开始第一个任务？

1. 选择一个任务
2. 阅读任务描述和执行步骤
3. 按照步骤逐一执行
4. 运行验收标准验证
5. 标记任务为完成

### Q: 遇到问题怎么办？

1. 检查日志：`tail -f ~/.zsh/logs/dev-env.log`
2. 运行诊断：`./scripts/zsh_tools.sh doctor`
3. 查看相关文档
4. 在团队频道提问

### Q: 如何测试更改？

```bash
# 运行所有测试
cd tests && ./test_runner.sh

# 运行特定测试
./test_runner.sh --filter <name>

# 检查语法
shellcheck <script.sh>
```

---

**祝开发顺利！🚀**

记住：小步快跑，频繁验证，及时沟通。
