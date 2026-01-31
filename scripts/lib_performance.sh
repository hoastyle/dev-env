#!/bin/bash
# =============================================================================
# dev-env Performance Monitoring Library
# =============================================================================
# 版本: 1.0
# 描述: 性能监控和数据记录（跨平台兼容）
# =============================================================================

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 加载跨平台兼容性库
if [[ -f "$SCRIPT_DIR/lib_platform_compat.sh" ]]; then
    source "$SCRIPT_DIR/lib_platform_compat.sh"
else
    # 最小兼容函数
    is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

    get_timestamp_ms() {
        if is_macos; then
            python -c 'import time; print(int(time.time()*1000))' 2>/dev/null || \
            perl -MTime::HiRes -e 'printf("%d",Time::HiRes::time()*1000)' 2>/dev/null || \
            date +%s000
        else
            date +%s%3N 2>/dev/null || date +%s000
        fi
    }
fi

# =============================================================================
# 常量定义
# =============================================================================

# 性能数据目录
PERF_DATA_DIR="${PERF_DATA_DIR:-$HOME/.zsh/performance}"
PERF_DATA_FILE="$PERF_DATA_DIR/startup_times.csv"
PERF_SUMMARY_FILE="$PERF_DATA_DIR/summary.json"

# =============================================================================
# 初始化
# =============================================================================

# 确保性能数据目录存在
ensure_perf_dir() {
    if [[ ! -d "$PERF_DATA_DIR" ]]; then
        mkdir -p "$PERF_DATA_DIR" 2>/dev/null || {
            echo "Warning: Cannot create performance directory: $PERF_DATA_DIR" >&2
            return 1
        }
    fi
    return 0
}

# =============================================================================
# 性能数据记录
# =============================================================================

# 记录启动时间
record_startup_time() {
    local mode=$1      # minimal/fast/normal
    local time_ms=$2   # 启动时间（毫秒）
    local timestamp=$(get_timestamp)
    local hostname=$(hostname)
    local user=$USER
    local os_type=$(get_os_type)

    ensure_perf_dir

    # 写入 CSV 文件
    echo "$timestamp,$mode,$time_ms,$hostname,$user,$os_type" >> "$PERF_DATA_FILE"

    return 0
}

# 获取当前时间戳（格式：YYYY-MM-DD HH:MM:SS）
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# =============================================================================
# 性能数据分析
# =============================================================================

# 计算统计数据（使用 awk 以保证跨平台）
perf_calculate_stats() {
    local mode=$1
    local days=${2:-7}
    local cutoff_time

    # 计算截止时间（跨平台）
    if is_macos; then
        # macOS: 使用 -v 选项
        cutoff_time=$(date -v-${days}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    else
        # Linux: 使用 -d 选项
        cutoff_time=$(date -d "$days days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    fi

    if [[ -z "$cutoff_time" ]]; then
        echo "Error: Cannot calculate cutoff time" >&2
        return 1
    fi

    # 使用 awk 计算统计数据（跨平台兼容）
    awk -F',' -v mode="$mode" -v cutoff="$cutoff_time" '
        BEGIN {
            sum = 0
            sum_sq = 0
            count = 0
            min = 999999999
            max = 0
        }
        NR > 1 && $2 == mode && $1 >= cutoff {
            sum += $3
            sum_sq += $3 * $3
            count++
            if ($3 < min) min = $3
            if ($3 > max) max = $3
        }
        END {
            if (count > 0) {
                avg = sum / count
                variance = (sum_sq / count) - (avg * avg)
                if (variance < 0) variance = 0
                stddev = sqrt(variance)

                # 计算中位数（简化方法）
                # 对于大数据集应该使用数组排序
                printf "%.2f,%.2f,%.2f,%.2f,%.2f,%d\n", avg, min, max, stddev, variance, count
            } else {
                print "0,0,0,0,0,0"
            }
        }
    ' "$PERF_DATA_FILE"
}

# 显示性能趋势
perf_show_trend() {
    local mode=${1:-normal}
    local days=${2:-7}

    ensure_perf_dir

    if [[ ! -f "$PERF_DATA_FILE" ]]; then
        echo "No performance data available"
        return 1
    fi

    echo "================================"
    echo "Performance Trend Analysis"
    echo "================================"
    echo "Mode: $mode"
    echo "Period: Last $days days"
    echo ""

    local stats=$(perf_calculate_stats "$mode" "$days")
    IFS=',' read -r avg min max stddev variance count <<< "$stats"

    if [[ $count -eq 0 ]]; then
        echo "No data available for the specified period."
        return 0
    fi

    printf "  Average: %.2f ms\n" "$avg"
    printf "  Min:     %.2f ms\n" "$min"
    printf "  Max:     %.2f ms\n" "$max"
    printf "  Std Dev: %.2f ms\n" "$stddev"
    printf "  Samples: %d\n" "$count"
    echo ""

    # 检测性能退化
    perf_detect_regression "$mode" "$days"
}

# 检测性能退化
perf_detect_regression() {
    local mode=$1
    local days=${2:-7}
    local threshold=1.2  # 20% 阈值

    # 计算最近3天和之前4天的平均值
    local recent_avg=$(_get_average_for_period "$mode" 3)
    local older_avg=$(_get_average_for_period "$mode" 7 3)

    if [[ -z "$recent_avg" || -z "$older_avg" ]]; then
        # 没有足够的数据
        return 0
    fi

    if [[ $(echo "$recent_avg > 0" | bc -l 2>/dev/null || echo "0") -eq 1 ]] && \
       [[ $(echo "$older_avg > 0" | bc -l 2>/dev/null || echo "0") -eq 1 ]]; then

        local ratio=$(echo "scale=4; $recent_avg / $older_avg" | bc)

        # 检查是否超过阈值
        local comparison=$(echo "$ratio > $threshold" | bc 2>/dev/null || echo "0")

        if [[ $comparison -eq 1 ]]; then
            local degradation=$(echo "scale=1; ($ratio - 1) * 100" | bc)
            echo "⚠️  WARNING: Performance regression detected!"
            echo "   Recent average: ${recent_avg} ms"
            echo "   Older average:  ${older_avg} ms"
            echo "   Degradation:    ${degradation}%"
        else
            echo "✓ No significant performance regression in $mode mode"
        fi
    fi
}

# 获取特定时间段的平均值
_get_average_for_period() {
    local mode=$1
    local days=$2
    local offset_days=${3:-0}

    local start_days=$((days + offset_days))
    local end_days=${offset_days}

    local start_time
    local end_time

    if is_macos; then
        start_time=$(date -v-${start_days}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        end_time=$(date -v-${end_days}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    else
        start_time=$(date -d "$start_days days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
        end_time=$(date -d "$end_days days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    fi

    if [[ -z "$start_time" || -z "$end_time" ]]; then
        return
    fi

    awk -F',' -v mode="$mode" -v start="$start_time" -v end="$end_time" '
        BEGIN { sum=0; count=0 }
        NR > 1 && $2 == mode && $1 >= end && $1 <= start {
            sum += $3
            count++
        }
        END {
            if (count > 0) printf "%.2f", sum/count
        }
    ' "$PERF_DATA_FILE"
}

# =============================================================================
# 性能报告生成
# =============================================================================

# 生成性能报告
perf_generate_report() {
    ensure_perf_dir

    local report_file="$PERF_DATA_DIR/report_$(date '+%Y%m%d_%H%M%S').txt"

    {
        echo "================================"
        echo "Performance Monitoring Report"
        echo "================================"
        echo "Generated: $(get_timestamp)"
        echo "OS Type: $(get_os_type)"
        echo "Hostname: $(hostname)"
        echo ""

        # 各模式趋势分析
        for mode in minimal fast normal; do
            echo "--- $mode mode ---"
            _show_mode_stats "$mode" 7
            echo ""
        done

        echo "--- Overall Statistics ---"
        local total=$(awk 'NR>1' "$PERF_DATA_FILE" 2>/dev/null | wc -l | tr -d ' ')
        echo "Total recordings: ${total:-0}"

        # 按模式统计
        echo ""
        echo "--- Recordings by Mode ---"
        awk -F',' 'NR>1 {count[$2]++} END {
            for (mode in count) {
                printf "  %s: %d\n", mode, count[mode]
            }
        }' "$PERF_DATA_FILE" 2>/dev/null || echo "  No data available"

        echo ""
        echo "--- Data Location ---"
        echo "CSV file: $PERF_DATA_FILE"
        echo "Report file: $report_file"

    } > "$report_file"

    # 显示报告
    cat "$report_file"
    echo ""
    echo "Report saved to: $report_file"
}

# 显示模式统计
_show_mode_stats() {
    local mode=$1
    local days=${2:-7}

    local stats=$(perf_calculate_stats "$mode" "$days")
    IFS=',' read -r avg min max stddev variance count <<< "$stats"

    if [[ $count -eq 0 ]]; then
        echo "No data available"
        return
    fi

    printf "  Average: %.2f ms\n" "$avg"
    printf "  Min:     %.2f ms\n" "$min"
    printf "  Max:     %.2f ms\n" "$max"
    printf "  Std Dev: %.2f ms\n" "$stddev"
    printf "  Samples: %d\n" "$count"
}

# =============================================================================
# 性能对比
# =============================================================================

# 对比不同模式的性能
perf_compare_modes() {
    ensure_perf_dir

    if [[ ! -f "$PERF_DATA_FILE" ]]; then
        echo "No performance data available"
        return 1
    fi

    echo "================================"
    echo "Performance Comparison (Last 7 days)"
    echo "================================"
    echo ""

    # 表头
    printf "%-10s %10s %10s %10s %10s\n" "Mode" "Avg(ms)" "Min(ms)" "Max(ms)" "Samples"
    printf "%-10s %10s %10s %10s %10s\n" "---" "-------" "-------" "-------" "-------"

    # 各模式数据
    for mode in minimal fast normal; do
        local stats=$(perf_calculate_stats "$mode" 7)
        IFS=',' read -r avg min max stddev variance count <<< "$stats"

        if [[ $count -gt 0 ]]; then
            printf "%-10s %10.2f %10.2f %10.2f %10d\n" "$mode" "$avg" "$min" "$max" "$count"
        fi
    done
}

# =============================================================================
# 数据清理
# =============================================================================

# 清理旧数据
perf_cleanup() {
    local days=${1:-30}

    ensure_perf_dir

    # 创建备份
    if [[ -f "$PERF_DATA_FILE" ]]; then
        cp "$PERF_DATA_FILE" "${PERF_DATA_FILE}.bak" 2>/dev/null
    fi

    # 删除旧数据（跨平台时间计算）
    local cutoff_time
    if is_macos; then
        cutoff_time=$(date -v-${days}d '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    else
        cutoff_time=$(date -d "$days days ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
    fi

    if [[ -n "$cutoff_time" && -f "$PERF_DATA_FILE" ]]; then
        local temp_file=$(mktemp)
        awk -F',' -v cutoff="$cutoff_time" 'NR==1 || $1 >= cutoff' "$PERF_DATA_FILE" > "$temp_file"
        mv "$temp_file" "$PERF_DATA_FILE"

        local remaining=$(awk 'NR>1' "$PERF_DATA_FILE" | wc -l | tr -d ' ')
        echo "Cleaned performance data older than $days days"
        echo "Remaining records: ${remaining:-0}"
    fi
}

# 导出所有性能数据为JSON格式
perf_export_json() {
    ensure_perf_dir

    if [[ ! -f "$PERF_DATA_FILE" ]]; then
        echo "[]"
        return
    fi

    echo "["
    awk -F',' 'NR>1 {
        printf "  {\n"
        printf "    \"timestamp\": \"%s\",\n", $1
        printf "    \"mode\": \"%s\",\n", $2
        printf "    \"time_ms\": %s,\n", $3
        printf "    \"hostname\": \"%s\",\n", $4
        printf "    \"user\": \"%s\",\n", $5
        printf "    \"os_type\": \"%s\"\n", $6
        printf "  },"
    }' "$PERF_DATA_FILE" | sed '$ s/,$//'
    echo "]"
}

# 获取最快的启动时间
perf_get_best_time() {
    local mode=${1:-normal}

    if [[ ! -f "$PERF_DATA_FILE" ]]; then
        echo "N/A"
        return
    fi

    awk -F',' -v mode="$mode" 'NR>1 && $2 == mode {
        if (NR==2 || $3 < min) min = $3
    } END {
        if (min) printf "%.2f ms", min
        else print "N/A"
    }' "$PERF_DATA_FILE"
}

# 获取最近的启动时间
perf_get_recent_time() {
    local mode=${1:-normal}
    local count=${2:-1}

    if [[ ! -f "$PERF_DATA_FILE" ]]; then
        echo "N/A"
        return
    fi

    awk -F',' -v mode="$mode" -v n="$count" '
        NR>1 && $2 == mode {
            count++
            if (count <= n) print $3
        }
    ' "$PERF_DATA_FILE" | tail -n 1
}

# =============================================================================
# 辅助函数
# =============================================================================

# 检查性能数据文件是否存在
perf_has_data() {
    [[ -f "$PERF_DATA_FILE" && -s "$PERF_DATA_FILE" ]]
}

# 获取数据记录数
perf_get_record_count() {
    if [[ -f "$PERF_DATA_FILE" ]]; then
        awk 'NR>1' "$PERF_DATA_FILE" | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# 显示性能数据文件信息
perf_show_info() {
    ensure_perf_dir

    echo "Performance Data Information"
    echo "==========================="
    echo ""
    echo "Data directory: $PERF_DATA_DIR"
    echo "Data file: $PERF_DATA_FILE"
    echo ""

    if [[ -f "$PERF_DATA_FILE" ]]; then
        echo "File size: $(get_file_size "$PERF_DATA_FILE") bytes"
        echo "Total records: $(perf_get_record_count)"
        echo "Last modified: $(get_file_mtime "$PERF_DATA_FILE")"
        echo ""
        echo "Modes available:"
        awk -F',' 'NR>1 {modes[$2]=1} END {
            for (m in modes) print "  - " m
        }' "$PERF_DATA_FILE"
    else
        echo "No performance data available yet."
    fi
}

# =============================================================================
# 初始化
# =============================================================================

ensure_perf_dir

# 注意：函数定义后，通过 source 此文件即可使用
# 如果需要在子shell中使用，请在 .zshrc 中 source 此文件
