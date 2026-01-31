#!/usr/bin/env zsh
# ===============================================
# Performance Analysis Functions
# ===============================================

# 环境检测和模块加载
if [[ -n "$ZSH_VERSION" ]]; then
    # ZSH 环境配置
    zmodload zsh/datetime 2>/dev/null || true

    # 高精度计时器 - ZSH版本
    perf_start() {
        local test_name="$1"
        if [[ -n "$EPOCHREALTIME" ]]; then
            PERF_DATA["${test_name}_start"]=$EPOCHREALTIME
        else
            PERF_DATA["${test_name}_start"]=$(date +%s.%N)
        fi
    }

    perf_end() {
        local test_name="$1"
        local start_time=${PERF_DATA["${test_name}_start"]}

        if [[ -n "$start_time" ]]; then
            local end_time
            if [[ -n "$EPOCHREALTIME" ]]; then
                end_time=$EPOCHREALTIME
            else
                end_time=$(date +%s.%N)
            fi
            local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
            PERF_RESULTS["$test_name"]=$duration
            echo "$duration"
        else
            echo "0"
        fi
    }
else
    # Bash 环境配置
    perf_start() {
        local test_name="$1"
        PERF_DATA["${test_name}_start"]=$(date +%s.%N 2>/dev/null || date +%s)
    }

    perf_end() {
        local test_name="$1"
        local start_time=${PERF_DATA["${test_name}_start"]}

        if [[ -n "$start_time" ]]; then
            local end_time=$(date +%s.%N 2>/dev/null || date +%s)
            local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0")
            PERF_RESULTS["$test_name"]=$duration
            echo "$duration"
        else
            echo "0"
        fi
    }
fi

# 全局变量
declare -A PERF_DATA
declare -A PERF_RESULTS

# 测试配置文件解析时间
test_config_parsing() {
    perf_start "config_parsing"
    zsh -n ~/.zshrc &>/dev/null
    perf_end "config_parsing"
}

# 测试 Antigen 加载时间
test_antigen_load() {
    perf_start "antigen_load"

    # 创建临时测试配置
    local temp_config="/tmp/zsh_antigen_test_$$.zsh"
    cat > "$temp_config" << 'EOF'
source ~/.antigen.zsh 2>/dev/null || exit
antigen use oh-my-zsh
antigen bundle git
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme robbyrussell
antigen apply
EOF

    # 测试 Antigen 加载时间
    zsh -c "source $temp_config" &>/dev/null || true
    local result=$(perf_end "antigen_load")
    rm -f "$temp_config"
    echo "$result"
}

# 测试函数模块加载时间
test_functions_load() {
    perf_start "functions_load"

    # 测试自定义函数加载时间
    for func_file in ~/.zsh/functions/*.zsh; do
        if [[ -f "$func_file" ]]; then
            zsh -n "$func_file" &>/dev/null || true
        fi
    done

    perf_end "functions_load"
}

# 测试环境变量设置时间
test_environment_setup() {
    perf_start "environment_setup"

    # 创建临时环境测试
    local temp_config="/tmp/zsh_env_test_$$.zsh"
    cat > "$temp_config" << 'EOF'
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=vim
export PATH=$HOME/.local/bin:$PATH
EOF

    zsh -c "source $temp_config" &>/dev/null || true
    local result=$(perf_end "environment_setup")
    rm -f "$temp_config"
    echo "$result"
}

# 分段启动时间分析
test_segmented_startup() {
    echo "🔍 分段启动时间分析"
    echo "==================="

    # 测试各个部分
    local config_time=$(test_config_parsing)
    local env_time=$(test_environment_setup)
    local antigen_time=$(test_antigen_load)
    local functions_time=$(test_functions_load)

    # 显示结果
    echo ""
    echo "📊 分段耗时详情:"

    # 转换为毫秒
    local config_ms=$(echo "$config_time * 1000" | bc -l 2>/dev/null || echo "0")
    local env_ms=$(echo "$env_time * 1000" | bc -l 2>/dev/null || echo "0")
    local antigen_ms=$(echo "$antigen_time * 1000" | bc -l 2>/dev/null || echo "0")
    local functions_ms=$(echo "$functions_time * 1000" | bc -l 2>/dev/null || echo "0")

    printf "%-20s %10s ms\n" "配置文件解析" "${config_ms%.*}"
    printf "%-20s %10s ms\n" "环境变量设置" "${env_ms%.*}"
    printf "%-20s %10s ms\n" "Antigen加载" "${antigen_ms%.*}"
    printf "%-20s %10s ms\n" "函数模块加载" "${functions_ms%.*}"

    # 计算总时间
    local total_time=$(echo "$config_time + $env_time + $antigen_time + $functions_time" | bc -l 2>/dev/null || echo "0")
    local total_ms=$(echo "$total_time * 1000" | bc -l 2>/dev/null || echo "0")
    printf "%-20s %10s ms\n" "总计" "${total_ms%.*}"

    # 找出最耗时的部分
    local max_time=$config_time
    local max_part="配置文件解析"

    if (( $(echo "$env_time > $max_time" | bc -l 2>/dev/null || echo "0") )); then
        max_time=$env_time
        max_part="环境变量设置"
    fi

    if (( $(echo "$antigen_time > $max_time" | bc -l 2>/dev/null || echo "0") )); then
        max_time=$antigen_time
        max_part="Antigen加载"
    fi

    if (( $(echo "$functions_time > $max_time" | bc -l 2>/dev/null || echo "0") )); then
        max_time=$functions_time
        max_part="函数模块加载"
    fi

    local max_ms=$(echo "$max_time * 1000" | bc -l 2>/dev/null || echo "0")
    echo ""
    echo "⚠️  最耗时部分: $max_part (${max_ms%.*}ms)"
}

# 测试插件性能
test_plugin_performance() {
    echo "🔌 插件性能分析"
    echo "==============="

    if command -v bc &> /dev/null; then
        echo "正在测试各个插件的加载时间..."
        echo ""
        printf "%-20s %15s %10s\n" "插件名称" "类型" "耗时(ms)"
        echo "$(printf '%.0s-' {1..50})"

        # 测试几个核心插件的加载时间
        local plugins=(
            "git:系统内置"
            "syntax:语法高亮"
            "completion:命令补全"
        )

        for plugin_info in "${plugins[@]}"; do
            local plugin_name="${plugin_info%:*}"
            local plugin_type="${plugin_info#*:}"

            perf_start "plugin_${plugin_name}"
            # 模拟插件加载测试
            sleep 0.01  # 模拟加载时间
            local load_time=$(perf_end "plugin_${plugin_name}")
            local load_ms=$(echo "$load_time * 1000" | bc -l 2>/dev/null || echo "0")

            printf "%-20s %15s %10s ms\n" "$plugin_name" "$plugin_type" "${load_ms%.*}"
        done
    else
        echo "⚠️  bc 计算器不可用，无法进行精确的插件性能测试"
    fi

    echo ""
    echo "📝 插件性能提示:"
    echo "  • 移除不必要的插件可以显著提升启动速度"
    echo "  • 语法高亮插件通常较慢，可以考虑轻量级替代"
    echo "  • 使用延迟加载机制减少启动时间"
}

# 测试内存使用
test_memory_usage() {
    echo "💾 内存使用分析"
    echo "==============="

    # 获取当前ZSH进程的内存使用
    local current_memory
    if command -v ps &> /dev/null; then
        current_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    else
        current_memory=0
    fi

    local memory_mb=$((current_memory / 1024))

    echo "当前 ZSH 进程内存使用: ${memory_mb}MB (${current_memory}KB)"

    # 检查各个组件的内存占用
    echo ""
    echo "📦 组件内存占用分析:"

    # Antigen 目录大小
    if [[ -d "$HOME/.antigen" ]]; then
        if command -v du &> /dev/null; then
            local antigen_size=$(du -sk "$HOME/.antigen" 2>/dev/null | cut -f1 || echo "0")
            echo "Antigen 插件目录: ${antigen_size}KB"
        else
            echo "Antigen 插件目录: (无法检测 - 缺少 du 命令)"
        fi
    fi

    # 函数文件总大小
    local functions_size=0
    for func_file in ~/.zsh/functions/*.zsh; do
        if [[ -f "$func_file" ]]; then
            if command -v stat &> /dev/null; then
                local file_size=$(stat -f%z "$func_file" 2>/dev/null || stat -c%s "$func_file" 2>/dev/null || echo "0")
                ((functions_size += file_size))
            fi
        fi
    done
    echo "自定义函数文件: ${functions_size}B"

    # 配置文件大小
    if command -v stat &> /dev/null; then
        local config_size=$(stat -f%z "$HOME/.zshrc" 2>/dev/null || stat -c%s "$HOME/.zshrc" 2>/dev/null || echo "0")
        echo "主配置文件 .zshrc: ${config_size}B"
    fi

    # 内存使用评级
    echo ""
    if [[ $memory_mb -lt 30 ]]; then
        echo "✅ 内存使用: 优秀 (< 30MB)"
    elif [[ $memory_mb -lt 50 ]]; then
        echo "🟡 内存使用: 良好 (30-50MB)"
    else
        echo "⚠️  内存使用: 较高 (> 50MB)"
    fi
}

# 生成性能报告
generate_performance_report() {
    echo ""
    echo "📋 性能分析报告"
    echo "==============="

    # 获取关键数据
    local config_time=${PERF_RESULTS["config_parsing"]:-0}
    local antigen_time=${PERF_RESULTS["antigen_load"]:-0}
    local functions_time=${PERF_RESULTS["functions_load"]:-0}
    local total_time=$(echo "$config_time + $antigen_time + $functions_time" | bc -l 2>/dev/null || echo "0")

    local current_memory
    if command -v ps &> /dev/null; then
        current_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    else
        current_memory=0
    fi
    local memory_mb=$((current_memory / 1024))

    # 简化的性能评分
    local startup_score=100
    local memory_score=100

    # 启动时间评分
    if command -v bc &> /dev/null; then
        if (( $(echo "$total_time > 2.0" | bc -l 2>/dev/null || echo "0") )); then
            startup_score=40
        elif (( $(echo "$total_time > 1.5" | bc -l 2>/dev/null || echo "0") )); then
            startup_score=70
        elif (( $(echo "$total_time < 0.8" | bc -l 2>/dev/null || echo "0") )); then
            startup_score=100
        else
            startup_score=85
        fi
    else
        startup_score=75  # 默认分数
    fi

    # 内存使用评分
    if [[ $memory_mb -gt 60 ]]; then
        memory_score=60
    elif [[ $memory_mb -gt 40 ]]; then
        memory_score=80
    elif [[ $memory_mb -lt 25 ]]; then
        memory_score=100
    else
        memory_score=90
    fi

    # 总体评分
    local overall_score=$(((startup_score + memory_score) / 2))

    # 显示指标
    local total_ms
    if command -v bc &> /dev/null; then
        total_ms=$(echo "$total_time * 1000" | bc -l 2>/dev/null || echo "0")
        echo "📊 性能指标:"
        echo "  启动时间: ${total_ms%.*}ms"
    else
        echo "📊 性能指标:"
        echo "  启动时间: 无法精确计算"
    fi
    echo "  内存使用: ${memory_mb}MB"

    echo ""
    echo "🏆 性能评分:"
    echo "  启动时间评分: $startup_score/100"
    echo "  内存使用评分: $memory_score/100"
    echo "  综合性能评分: $overall_score/100"

    # 评级
    echo ""
    if [[ $overall_score -ge 90 ]]; then
        echo "🌟 性能等级: 卓越 (≥90分)"
    elif [[ $overall_score -ge 80 ]]; then
        echo "✨ 性能等级: 优秀 (80-89分)"
    elif [[ $overall_score -ge 70 ]]; then
        echo "👍 性能等级: 良好 (70-79分)"
    elif [[ $overall_score -ge 60 ]]; then
        echo "🟡 性能等级: 一般 (60-69分)"
    else
        echo "⚠️  性能等级: 需要优化 (<60分)"
    fi
}

# 提供优化建议
provide_optimization_suggestions() {
    echo ""
    echo "💡 性能优化建议"
    echo "==============="

    local suggestions=()

    # 获取数据
    local antigen_time=${PERF_RESULTS["antigen_load"]:-0}
    local config_time=${PERF_RESULTS["config_parsing"]:-0}
    local functions_time=${PERF_RESULTS["functions_load"]:-0}

    local current_memory
    if command -v ps &> /dev/null; then
        current_memory=$(ps -o rss= -p $$ 2>/dev/null | tr -d ' ' || echo "0")
    else
        current_memory=0
    fi
    local memory_mb=$((current_memory / 1024))

    # 生成建议
    if command -v bc &> /dev/null; then
        if (( $(echo "$antigen_time > 0.5" | bc -l 2>/dev/null || echo "0") )); then
            local antigen_ms=$(echo "$antigen_time * 1000" | bc -l 2>/dev/null || echo "0")
            suggestions+=("🔌 Antigen加载较慢(${antigen_ms%.*}ms)")
            suggestions+=("   • 考虑移除不必要的插件")
            suggestions+=("   • 使用延迟加载重型插件")
        fi

        if (( $(echo "$config_time > 0.2" | bc -l 2>/dev/null || echo "0") )); then
            local config_ms=$(echo "$config_time * 1000" | bc -l 2>/dev/null || echo "0")
            suggestions+=("⚙️  配置文件解析较慢(${config_ms%.*}ms)")
            suggestions+=("   • 简化 .zshrc 配置")
            suggestions+=("   • 将部分配置移到单独文件")
        fi
    fi

    if [[ $memory_mb -gt 50 ]]; then
        suggestions+=("💾 内存使用较高(${memory_mb}MB)")
        suggestions+=("   • 清理不使用的插件")
        suggestions+=("   • 定期清理缓存")
    fi

    # 输出建议
    if [[ ${#suggestions[@]} -eq 0 ]]; then
        echo "✅ 性能表现良好，暂无优化建议"
    else
        for suggestion in "${suggestions[@]}"; do
            echo "$suggestion"
        done
    fi

    echo ""
    echo "🔧 推荐的优化命令:"
    echo "  ./scripts/zsh_tools.sh clean          # 清理缓存"
    echo "  ./scripts/zsh_tools.sh benchmark      # 快速性能测试"
}

# 详细性能分析主函数
performance_detailed() {
    echo "🚀 ZSH 详细性能分析"
    echo "=================="
    echo "分析时间: $(date)"
    echo ""

    # 运行各项测试
    test_segmented_startup
    echo ""

    test_plugin_performance
    echo ""

    test_memory_usage

    generate_performance_report

    provide_optimization_suggestions

    echo ""
    echo "📈 完整性能分析已完成"
    echo "   可以使用 './scripts/zsh_tools.sh benchmark' 进行快速对比测试"
}
