# Task: 修复迁移回滚功能

## Objective
修复 lib_migration.sh 中的 rollback_migration() 函数，当前该函数在回滚后没有正确更新迁移历史记录。

## Required Context
- Modules: `lib_migration`, `lib_version`, `lib_logging`
- Contracts: `.ai/CONTRACTS/lib_migration.run_migrations.yaml`
- Docs: `DEPENDENCY_GRAPH.md`
- Source: `scripts/lib_migration.sh`
- Bug Report: 见下方

## Bug Report

**Title**: 迁移回滚后历史记录未更新

**Description**:
当执行 `rollback_migration "002_add_template_system"` 时：
1. 迁移脚本的 migrate_down() 正确执行
2. 但迁移历史记录未移除该迁移
3. 导致 `get_pending_migrations()` 仍将其列为已执行

**Expected Behavior**:
回滚后，迁移历史应该移除该迁移记录

**Actual Behavior**:
迁移历史保持不变

## Task Steps

1. **分析问题**
   - 阅读 lib_migration.sh 理解当前实现
   - 查看 migrate_down() 调用后是否更新历史
   - 确定修复位置

2. **修复代码**
   - 在 rollback_migration() 中添加历史记录更新
   - 使用 log_migration() 记录回滚操作
   - 确保错误处理正确

3. **更新契约**
   - 更新 `.ai/CONTRACTS/lib_migration.rollback_migration.yaml`
   - 添加 side_effects 说明历史记录更新

4. **添加测试**
   - 测试正常回滚场景
   - 测试回滚不存在的迁移
   - 测试回滚后 get_pending_migrations() 结果

## Expected Output Format

### 修复后的函数片段
```bash
rollback_migration() {
    local migration_id="$1"

    # 执行 migrate_down
    ...

    # 🆕 更新迁移历史：移除回滚的迁移
    update_last_migration ""  # 清空最后迁移记录
    # 或者：从历史文件中移除该迁移

    log_info "✅ Migration $migration_id rolled back"
}
```

### 契约更新
```yaml
side_effects:
  - description: 执行迁移的 migrate_down() 函数
    risk: medium
  - description: 从迁移历史中移除该迁移
    risk: low
  - description: 更新版本文件
    risk: low
```

## Success Criteria
- [ ] rollback_migration() 正确更新迁移历史
- [ ] 回滚后 get_pending_migrations() 不再列出该迁移
- [ ] 回滚操作被记录到迁移历史日志
- [ ] 错误处理正确（迁移不存在、migrate_down 失败）
- [ ] CONTRACTS/ 已更新
- [ ] 添加了回归测试

## Constraints
- 不得破坏现有的 run_migrations() 功能
- 必须保持迁移历史的完整性
- 必须处理迁移文件不存在的情况
- 需要考虑部分回滚（如果 migrate_down 失败）

## Test Cases

### Case 1: 正常回滚
```bash
# Setup: 执行迁移 002
run_migrations

# Test: 回滚 002
rollback_migration "002_add_template_system"

# Verify: 历史已更新
pending=$(get_pending_migrations)
assert_contains "$pending" "002_add_template_system"
```

### Case 2: 回滚不存在的迁移
```bash
# Test: 回滚不存在的迁移
rollback_migration "999_nonexistent"

# Verify: 返回错误，不修改历史
# Expected: return code 1, error message
```

### Case 3: 回滚第一个迁移
```bash
# Setup: 只执行了迁移 001
run_migrations

# Test: 回滚 001
rollback_migration "001_initial"

# Verify: 版本回到 0.0.0
version=$(get_current_version)
assert_equals "$version" "0.0.0"
```

## Evaluation Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Bug fixed | Yes | ___ |
| Regression tests added | Yes | ___ |
| Contract updated | Yes | ___ |
| Code style compliance | 100% | ___ |
| Test coverage | >90% | ___ |

## Notes

- 迁移历史存储在 `data/migration_history.log`
- 每次成功迁移后调用 `update_last_migration`
- 可能需要修改 update_last_migration 支持删除操作

---

**Task ID**: EVAL-002
**Category**: Bug Fix
**Difficulty**: Medium
**Estimated Time**: 45 minutes
**AIRS Version**: 1.0
