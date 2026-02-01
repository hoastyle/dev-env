# AIRS Evaluation Tasks

此目录包含用于评估 AI 在 dev-env 项目上性能的代表性任务。

## Task Format

每个任务应该是一个 markdown 文件，描述：
- 任务目标
- 所需上下文（哪些模块、契约、文档）
- 期望的输出格式
- 成功标准

## Example Tasks

### 核心任务

- `add_version_check.md` - 添加版本检查功能（遵循 AIRS 工作流）
- `fix_migration_bug.md` - 修复迁移 bug（包含契约更新）
- `add_health_check.md` - 添加新的健康检查项
- `create_backup_contract.md` - 为备份功能创建契约
- `optimize_startup.md` - 优化启动性能（维护契约）

### 验证任务

- `validate_manifest.md` - 验证 MANIFEST.json 准确性
- `check_contract_coverage.md` - 检查契约覆盖度
- `verify_type_annotations.md` - 验证类型注解完整性

## Running Evaluations

```bash
# 运行所有评估任务
for task in .ai/EVAL/tasks/*.md; do
    echo "Running: $task"
    # 使用 AI 代理执行任务
done

# 比较输出与 golden/
diff -r .ai/EVAL/golden/ /tmp/actual_output/
```

## Task Template

```markdown
# Task: <Task Name>

## Objective
<简短描述任务目标>

## Required Context
- Modules: <依赖的模块>
- Contracts: <需要参考的契约>
- Docs: <需要阅读的文档>

## Task Steps
1. <步骤 1>
2. <步骤 2>
3. <步骤 3>

## Expected Output Format
<描述期望的输出格式>

## Success Criteria
- [ ] <成功标准 1>
- [ ] <成功标准 2>
- [ ] <成功标准 3>

## Constraints
- <约束 1>
- <约束 2>
```

---

**AIRS Version**: 1.0
**Project**: dev-env
**Last Updated**: 2026-02-01
