# AIRS Golden Outputs

此目录包含评估任务的期望输出，用于验证 AI 代理的性能。

## Structure

```
golden/
├── add_version_check/
│   ├── contract.yaml          # 期望的契约文件
│   ├── function.sh            # 期望的函数实现
│   └── test_output.txt        # 期望的测试输出
├── fix_migration_bug/
│   ├── fixed_function.sh      # 修复后的函数
│   ├── contract_delta.yaml    # 契约变更
│   └── test_results.txt       # 测试结果
└── ...
```

## Usage

```bash
# 运行任务
run_task "add_version_check" /tmp/eval_output/

# 比较输出
diff -u .ai/EVAL/golden/add_version_check/contract.yaml \
      /tmp/eval_output/add_version_check/contract.yaml

# 生成评估报告
generate_eval_report /tmp/eval_output/
```

## Evaluation Criteria

### Correctness (40%)
- 输出与 golden 匹配程度
- 功能正确性
- 边界情况处理

### Style Compliance (30%)
- 遵循 PROMPTS/style_rules.txt
- 代码格式一致性
- 命名约定

### Documentation (20%)
- 契约完整性
- 类型注解准确性
- 文档同步

### Best Practices (10%)
- 错误处理
- 日志记录
- 测试覆盖

## Golden Output Format

### add_version_check/contract.yaml
期望的完整契约文件，包含：
- entity: lib_version.is_version_at_least
- stability: stable
- inputs: current (VersionString), minimum (VersionString)
- outputs: bool (0=true, 1=false)
- errors: InvalidVersion
- examples: 至少 3 个

### add_version_check/function.sh
期望的函数实现，包含：
- 完整的文档注释
- @tag public, @category version_management
- @param VersionString 注解
- @return bool 注解
- 错误处理
- 使用现有 compare_versions()

### fix_migration_bug/fixed_function.sh
修复后的 rollback_migration()：
- 添加历史记录更新逻辑
- 保持现有功能不变
- 正确的错误处理

## Verification Script

```bash
#!/bin/bash
# verify_eval.sh - 验证评估输出

TASK_DIR="$1"
GOLDEN_DIR=".ai/EVAL/golden/$(basename $TASK_DIR)"

# 检查文件存在
check_file() {
    local file="$1"
    if [[ ! -f "$TASK_DIR/$file" ]]; then
        echo "❌ Missing: $file"
        return 1
    fi
    echo "✅ Found: $file"
}

# 比较文件内容
compare_file() {
    local file="$1"
    local expected="$GOLDEN_DIR/$file"
    local actual="$TASK_DIR/$file"

    if diff -u "$expected" "$actual" > /dev/null; then
        echo "✅ Match: $file"
        return 0
    else
        echo "❌ Diff: $file"
        diff -u "$expected" "$actual" | head -20
        return 1
    fi
}

# 主检查流程
echo "Verifying: $TASK_DIR"
echo "===================="

# 检查必需文件
check_file "contract.yaml"
check_file "function.sh" || check_file "fixed_function.sh"
check_file "test_output.txt" || check_file "test_results.txt"

# 比较内容（如果存在）
if [[ -f "$GOLDEN_DIR/contract.yaml" ]]; then
    compare_file "contract.yaml"
fi

echo "===================="
echo "Verification complete"
```

## Continuous Integration

在 CI 中自动运行评估：

```yaml
# .github/workflows/eval.yml
name: AI Evaluation

on: [push, pull_request]

jobs:
  eval:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run evaluation tasks
        run: |
          for task in .ai/EVAL/tasks/*.md; do
            ./scripts/run_eval.sh "$task"
          done
      - name: Compare with golden
        run: |
          ./scripts/verify_eval.sh /tmp/eval_output/
```

---

**AIRS Version**: 1.0
**Project**: dev-env
**Last Updated**: 2026-02-01
