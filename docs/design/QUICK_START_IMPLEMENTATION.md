# 配置生命周期管理 - 快速实施指南

**目标读者**: 新手开发者  
**预计时间**: 第一天就能开始编码  

---

## 🚀 快速开始 (5分钟)

### 第一步: 理解你要做什么

你将构建一个**配置版本管理系统**，就像 Git 管理代码一样管理 ZSH 配置。

**核心功能**:
1. 📌 记录配置版本（就像 Git 的 commit）
2. 🔄 自动升级配置（就像数据库迁移）
3. 🏥 检查配置健康（就像体检）
4. 💾 备份和恢复（就像时光机）

### 第二步: 创建工作环境

```bash
cd /home/howie/Workspace/Utility/dev-env

# 创建必要的目录
mkdir -p scripts data backups config/migrations tests/unit

# 创建你的第一个文件
touch scripts/lib_version.sh
chmod +x scripts/lib_version.sh
```

---

## 📝 第一天: 实现版本管理 (4小时)

### 任务 1: 创建版本文件格式 (30分钟)

**文件**: `config/.zshrc.version`

```bash
# 创建版本文件
cat > config/.zshrc.version << 'EOF'
# ZSH Configuration Version File
VERSION="2.2.0"
BUILD_DATE="2026-01-31"
INSTALL_DATE="2026-01-31 10:30:00"
LAST_MIGRATION=""
USER_CUSTOMIZATIONS="false"
CUSTOM_CONFIG_HASH=""
EOF
```

**✅ 验证**: 文件创建成功，内容正确

### 任务 2: 实现版本读取函数 (1小时)

**文件**: `scripts/lib_version.sh`

```bash
#!/bin/bash
# 版本管理库
# 功能: 读取、设置、比较版本号

# 版本文件路径
VERSION_FILE="${VERSION_FILE:-$HOME/.zshrc.version}"

# 函数 1: 获取当前版本
get_current_version() {
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "0.0.0"
        return 1
    fi
    
    # 读取 VERSION 字段
    grep "^VERSION=" "$VERSION_FILE" | cut -d'"' -f2
}

# 函数 2: 设置版本
set_version() {
    local new_version="$1"
    local build_date="${2:-$(date +%Y-%m-%d)}"
    
    # 创建或更新版本文件
    cat > "$VERSION_FILE" << EOF
# ZSH Configuration Version File
VERSION="$new_version"
BUILD_DATE="$build_date"
INSTALL_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
LAST_MIGRATION=""
USER_CUSTOMIZATIONS="false"
CUSTOM_CONFIG_HASH=""
EOF
    
    echo "✅ 版本已设置为: $new_version"
}

# 函数 3: 比较版本号
compare_versions() {
    local version1="$1"
    local version2="$2"
    
    # 使用 sort -V 进行版本号比较
    if [[ "$(printf '%s\n' "$version1" "$version2" | sort -V | head -n1)" == "$version2" ]]; then
        return 0  # version1 >= version2
    else
        return 1  # version1 < version2
    fi
}

# 测试函数（可选）
test_version_functions() {
    echo "🧪 测试版本管理函数..."
    
    # 测试 1: 设置版本
    set_version "2.2.0" "2026-01-31"
    
    # 测试 2: 读取版本
    local current=$(get_current_version)
    echo "当前版本: $current"
    
    # 测试 3: 比较版本
    if compare_versions "2.2.0" "2.1.0"; then
        echo "✅ 版本比较正确: 2.2.0 >= 2.1.0"
    fi
}

# 如果直接运行此脚本，执行测试
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_version_functions
fi
```

**✅ 测试你的代码**:
```bash
# 运行测试
bash scripts/lib_version.sh

# 预期输出:
# 🧪 测试版本管理函数...
# ✅ 版本已设置为: 2.2.0
# 当前版本: 2.2.0
# ✅ 版本比较正确: 2.2.0 >= 2.1.0
```

### 任务 3: 添加更多功能 (1.5小时)

在 `lib_version.sh` 中添加:

```bash
# 函数 4: 检查是否需要迁移
needs_migration() {
    local current_version=$(get_current_version)
    local target_version="$1"
    
    if ! compare_versions "$current_version" "$target_version"; then
        echo "需要从 $current_version 迁移到 $target_version"
        return 0
    else
        echo "当前版本 $current_version 已是最新"
        return 1
    fi
}

# 函数 5: 生成版本报告
generate_version_report() {
    echo "📊 配置版本报告"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ ! -f "$VERSION_FILE" ]]; then
        echo "❌ 未找到版本文件"
        return 1
    fi
    
    # 读取所有字段
    while IFS='=' read -r key value; do
        # 跳过注释和空行
        [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
        
        # 移除引号
        value=$(echo "$value" | tr -d '"')
        
        echo "$key: $value"
    done < "$VERSION_FILE"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}
```

**✅ 测试新功能**:
```bash
# 在 lib_version.sh 末尾添加测试
test_new_functions() {
    echo ""
    echo "🧪 测试新功能..."
    
    # 测试需要迁移
    needs_migration "2.3.0"
    
    # 测试版本报告
    generate_version_report
}

# 更新主测试函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test_version_functions
    test_new_functions
fi
```

### 任务 4: 编写单元测试 (1小时)

**文件**: `tests/unit/test_version.sh`

```bash
#!/bin/bash
# 单元测试: 版本管理

# 测试框架（简单版）
TESTS_PASSED=0
TESTS_FAILED=0

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✅ PASS: $message"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: $message"
        echo "   Expected: $expected"
        echo "   Actual: $actual"
        ((TESTS_FAILED++))
    fi
}

# 加载被测试模块
source "$(dirname "$0")/../../scripts/lib_version.sh"

# 测试用例
test_get_version() {
    echo "测试: get_current_version"
    
    # 设置测试版本
    set_version "2.2.0" "2026-01-31" > /dev/null
    
    # 获取版本
    local version=$(get_current_version)
    
    assert_equals "2.2.0" "$version" "获取当前版本"
}

test_compare_versions() {
    echo "测试: compare_versions"
    
    if compare_versions "2.2.0" "2.1.0"; then
        echo "✅ PASS: 2.2.0 >= 2.1.0"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: 版本比较错误"
        ((TESTS_FAILED++))
    fi
    
    if ! compare_versions "2.0.0" "2.1.0"; then
        echo "✅ PASS: 2.0.0 < 2.1.0"
        ((TESTS_PASSED++))
    else
        echo "❌ FAIL: 版本比较错误"
        ((TESTS_FAILED++))
    fi
}

# 运行所有测试
run_all_tests() {
    echo "🧪 运行版本管理单元测试"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    test_get_version
    test_compare_versions
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "测试结果: $TESTS_PASSED 通过, $TESTS_FAILED 失败"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "✅ 所有测试通过！"
        return 0
    else
        echo "❌ 有测试失败"
        return 1
    fi
}

run_all_tests
```

**✅ 运行测试**:
```bash
chmod +x tests/unit/test_version.sh
bash tests/unit/test_version.sh
```

---

## 🎯 第一天总结

### 你完成了什么？

✅ 创建了版本文件格式  
✅ 实现了版本读取和设置  
✅ 实现了版本比较  
✅ 实现了版本报告  
✅ 编写了单元测试  

### 下一步做什么？

**第二天**: 实现迁移系统
- 创建迁移脚本模板
- 实现迁移执行逻辑
- 记录迁移历史

**第三天**: 实现健康检查
- 配置语法检查
- 插件状态检查
- 生成健康报告

---

## 💡 新手提示

### 遇到问题怎么办？

1. **语法错误**: 使用 `bash -n script.sh` 检查语法
2. **逻辑错误**: 添加 `echo` 调试输出
3. **不确定**: 先写测试，再写实现

### 好的编码习惯

```bash
# ✅ 好的做法
function my_function() {
    local param="$1"  # 使用 local 变量
    
    # 参数验证
    if [[ -z "$param" ]]; then
        echo "错误: 参数不能为空" >&2
        return 1
    fi
    
    # 实现逻辑
    echo "处理: $param"
    return 0
}

# ❌ 不好的做法
function bad_function() {
    param="$1"  # 全局变量
    echo "处理: $param"  # 没有错误处理
}
```

### 测试驱动开发 (TDD)

1. **先写测试** - 定义期望行为
2. **再写实现** - 让测试通过
3. **重构代码** - 优化实现

---

## 📚 参考资料

### 必读文档
- `docs/design/CONFIG_LIFECYCLE_MANAGEMENT_DESIGN.md` - 完整设计文档
- `docs/management/PLANNING.md` - 项目规划

### Bash 编程参考
- [Bash Guide](https://mywiki.wooledge.org/BashGuide)
- [ShellCheck](https://www.shellcheck.net/) - 语法检查工具

### 项目现有代码
- `scripts/lib_logging.sh` - 日志系统示例
- `scripts/lib_platform_compat.sh` - 跨平台兼容示例

---

## ✅ 检查清单

### 第一天结束前

- [ ] 创建了所有必要目录
- [ ] 实现了 lib_version.sh
- [ ] 所有函数都有注释
- [ ] 编写了单元测试
- [ ] 所有测试都通过
- [ ] 代码提交到 Git

### 准备第二天

- [ ] 阅读迁移系统设计
- [ ] 理解迁移脚本模板
- [ ] 准备测试环境

---

**祝你编码愉快！遇到问题随时查看完整设计文档。** 🚀
