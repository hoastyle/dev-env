# dev-env 自动化测试套件

测试框架和测试用例集合，用于验证 dev-env 项目的所有核心功能。

## 📋 目录结构

```
tests/
├── test_runner.sh           # 主测试执行器
├── run_tests.sh            # 本地测试运行脚本（待实现）
├── README.md               # 本文件
├── lib/
│   ├── test_utils.sh       # 工具函数库 (~150 行)
│   │   └── 提供: 日志、计时、状态管理
│   ├── assertions.sh       # 断言函数库 (~250 行)
│   │   └── 提供: 20+ 断言函数
│   └── fixtures.sh         # 测试夹具库 (~250 行)
│       └── 提供: 测试数据、临时环境管理
├── unit/
│   ├── test_validation.sh    # 参数验证单元测试
│   ├── test_dryrun.sh        # 干运行模式单元测试
│   ├── test_install.sh       # 安装脚本单元测试
│   └── test_tools.sh         # 工具集单元测试
├── integration/
│   ├── test_end_to_end.sh    # 端到端集成测试
│   └── test_workflows.sh     # 工作流集成测试
└── .github/workflows/
    └── tests.yml            # GitHub Actions CI/CD
```

## 🚀 快速开始

### 运行所有测试

```bash
cd tests
./test_runner.sh
```

### 运行特定类型的测试

```bash
# 仅运行单元测试
./test_runner.sh --unit-only

# 仅运行集成测试
./test_runner.sh --integration-only

# 运行匹配特定模式的测试
./test_runner.sh --filter validation
```

### 调试选项

```bash
# 启用详细输出
./test_runner.sh --verbose

# 启用调试输出
./test_runner.sh --debug

# 在第一个失败处停止
./test_runner.sh --stop-on-failure
```

## 📚 测试框架库

### test_utils.sh - 工具函数库

提供日志、计时和状态管理功能。

**日志函数**:

* `log_info(message)` - 信息级日志
* `log_success(message)` - 成功消息
* `log_warn(message)` - 警告消息
* `log_error(message)` - 错误消息
* `log_debug(message)` - 调试消息

**计时函数**:

* `start_timer()` - 开始计时
* `get_elapsed_time(start, end)` - 计算耗时
* `format_time(ms)` - 格式化时间

**状态管理**:

* `init_test_state()` - 初始化测试状态
* `record_pass()` - 记录通过的测试
* `record_fail(name, reason)` - 记录失败的测试
* `record_skip()` - 记录跳过的测试
* `print_test_summary()` - 打印测试摘要

### assertions.sh - 断言函数库

提供 20+ 个断言函数用于验证测试结果。

**相等性断言**:

* `assert_equal(expected, actual, message)` - 相等断言
* `assert_not_equal(not_expected, actual, message)` - 不相等断言

**字符串断言**:

* `assert_string_contains(string, substring, message)` - 包含断言
* `assert_string_not_contains(string, substring, message)` - 不包含断言
* `assert_regex_match(string, pattern, message)` - 正则匹配
* `assert_empty(string, message)` - 空字符串断言
* `assert_not_empty(string, message)` - 非空字符串断言

**命令状态断言**:

* `assert_success(cmd, message)` - 成功执行断言
* `assert_failure(cmd, message)` - 失败执行断言
* `assert_exit_code(expected, cmd, message)` - 特定退出码断言

**数值断言**:

* `assert_num_equal(expected, actual, message)` - 数值相等
* `assert_num_gt(actual, threshold, message)` - 大于
* `assert_num_lt(actual, threshold, message)` - 小于

**文件和目录断言**:

* `assert_file_exists(file, message)` - 文件存在
* `assert_file_not_exists(file, message)` - 文件不存在
* `assert_dir_exists(dir, message)` - 目录存在
* `assert_dir_not_exists(dir, message)` - 目录不存在
* `assert_file_readable(file, message)` - 文件可读
* `assert_file_writable(file, message)` - 文件可写

**内容断言**:

* `assert_file_contains(file, text, message)` - 文件包含内容
* `assert_file_not_contains(file, text, message)` - 文件不包含内容
* `assert_files_equal(file1, file2, message)` - 文件相同

### fixtures.sh - 测试夹具库

提供测试数据和环境管理。

**生命周期函数**:

* `setup_fixtures()` - 初始化测试环境
* `teardown_fixtures()` - 清理测试环境
* `register_cleanup(cmd)` - 注册清理函数

**文件创建**:

* `create_test_file(filename, content, location)` - 创建测试文件
* `create_test_directory_structure(base, structure)` - 创建目录结构

**环境设置**:

* `setup_mock_environment(type)` - 设置模拟环境
* `restore_original_environment()` - 恢复原环境

**配置文件夹具**:

* `create_mock_zshrc(dir)` - 创建模拟 .zshrc
* `create_mock_validation(dir)` - 创建模拟 validation.zsh
* `create_mock_install_script(dir)` - 创建模拟安装脚本
* `create_mock_dryrun_lib(dir)` - 创建模拟 dryrun 库

**辅助函数**:

* `get_temp_dir()` - 获取临时目录
* `get_backup_dir()` - 获取备份目录
* `list_fixture_files(dir)` - 列出文件
* `dump_file(file)` - 转储文件内容

## ✍️ 编写测试

### 基本测试结构

```bash
#!/bin/bash
# unit/test_myfeature.sh

# 源测试库
source "$(dirname "${BASH_SOURCE[0]}")/../lib/test_utils.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/assertions.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/fixtures.sh"

# 定义测试函数
test_my_feature() {
    local result=$(some_command)
    assert_equal "expected_value" "$result" "Command should return expected value"
}

test_error_handling() {
    assert_failure "failing_command" "Command should fail"
}

test_file_operations() {
    local test_file="$FIXTURE_TEMP_DIR/test.txt"
    create_test_file "test.txt" "content" "$FIXTURE_TEMP_DIR"
    assert_file_exists "$test_file" "Test file should exist"
}

# 可选的生命周期函数
setup() {
    log_info "Setup for test suite"
    setup_fixtures
}

teardown() {
    log_info "Teardown for test suite"
    teardown_fixtures
}
```

### 测试最佳实践

1. **清晰的测试名称**: 使用描述性的函数名 `test_feature_should_do_something`
2. **单一职责**: 每个测试只测试一个功能
3. **独立测试**: 测试之间不应有依赖关系
4. **设置和清理**: 使用 `setup()` 和 `teardown()` 函数
5. **详细的消息**: 在断言中提供清晰的错误消息
6. **避免外部依赖**: 使用 fixtures 创建测试数据

## 🔍 测试执行流程

1. **发现** - test_runner.sh 在 unit 和 integration 目录中查找 test_*.sh 文件
2. **加载** - 加载测试库（test_utils.sh, assertions.sh, fixtures.sh）
3. **设置** - 调用 setup() 函数初始化环境
4. **执行** - 运行所有 test_* 函数
5. **验证** - 使用断言验证结果
6. **清理** - 调用 teardown() 函数清理资源
7. **报告** - 生成测试摘要报告

## 📊 测试输出示例

```
╔════════════════════════════════════════╗
║  dev-env Test Suite Execution Engine  ║
╚════════════════════════════════════════╝

Loading test libraries...
✓ Libraries loaded successfully

========== UNIT TESTS ==========

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Testing: test_validation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[INFO] Running: test_validation_error_msg
[✓] test_validation_error_msg
[INFO] Running: test_validation_success_msg
[✓] test_validation_success_msg

Test Summary
────────────────────────────────────────
  Total Tests                      : 2
  Passed                           : 2
  Failed                           : 0
  Skipped                          : 0
  Pass Rate                        : 100%

✓ All tests passed! ✓
```

## 🐛 调试失败的测试

1. **启用调试输出**:

   ```bash
   ./test_runner.sh --debug --filter failing_test_name
   ```

2. **检查临时文件**:

   ```bash
   dump_file "/path/to/file"
   ```

3. **逐个运行测试**:

   ```bash
   # 运行特定的测试文件
   source tests/lib/test_utils.sh
   source tests/unit/test_validation.sh
   test_specific_function
   ```

## 📈 代码覆盖率

目标覆盖率：**90%+**

覆盖范围：

* ✅ 路径检测函数 (100%)
* ✅ 参数验证函数 (100%)
* ✅ 干运行模式 (100%)
* ✅ 安装脚本 (90%+)
* ✅ 配置工具 (90%+)
* ✅ 性能基准 (85%+)

## 🚀 CI/CD 集成

测试框架已集成到 GitHub Actions：

```bash
# 手动触发测试
git push origin feature-branch

# 或在本地运行相同的测试
./test_runner.sh --verbose
```

## 📝 更新历史

* **v1.0** (2025-10-19): 初始版本发布
  * test_runner.sh - 主执行器
  * test_utils.sh - 工具库
  * assertions.sh - 断言库
  * fixtures.sh - 夹具库

## 🤝 贡献指南

添加新测试时：

1. 在适当的目录中创建 test_*.sh 文件
2. 源需要的库文件
3. 定义 test_* 函数
4. 运行 test_runner.sh 验证
5. 提交 pull request

## 📞 获取帮助

查看框架库中的详细文档：

* `lib/test_utils.sh` - 使用示例和文档
* `lib/assertions.sh` - 所有可用的断言函数
* `lib/fixtures.sh` - 环境和数据管理

---

**版本**: 1.0
**创建**: 2025-10-19
**维护者**: Development Team
