# Task: 添加版本比较功能

## Objective
在 lib_version.sh 中添加一个新函数 `is_version_at_least()`，用于检查当前版本是否至少达到指定版本。

## Required Context
- Modules: `lib_version`
- Contracts: `.ai/CONTRACTS/lib_version.get_current_version.yaml`
- Docs: `TYPES.md`, `SEMANTIC_TAGS.md`
- Source: `scripts/lib_version.sh`

## Task Steps

1. **理解需求**
   - 阅读 lib_version.sh 了解现有版本比较逻辑
   - 查看 TYPES.md 了解 VersionString 类型定义
   - 查看 SEMANTIC_TAGS.md 了解标签使用

2. **创建契约**
   - 在 `.ai/CONTRACTS/` 创建 `lib_version.is_version_at_least.yaml`
   - 定义输入、输出、错误、示例

3. **实现函数**
   - 在 lib_version.sh 中实现 `is_version_at_least()`
   - 遵循 PROMPTS/style_rules.txt 代码风格
   - 添加适当的类型注解和语义标签

4. **更新文档**
   - 更新 FUNCTION_INDEX.md 添加新函数
   - 更新 .ai/MANIFEST.json 的 public_api

5. **添加测试**
   - 创建单元测试（边界情况）
   - 创建使用示例

## Expected Output Format

### 契约文件 (.ai/CONTRACTS/lib_version.is_version_at_least.yaml)
```yaml
entity: lib_version.is_version_at_least
stability: stable
inputs:
  - name: current
    type: VersionString
  - name: minimum
    type: VersionString
outputs:
  type: bool
  description: 0=true (current >= minimum), 1=false
...
```

### 函数实现 (scripts/lib_version.sh)
```bash
# @tag public
# @category version_management
# @param VersionString $current 当前版本
# @param VersionString $minimum 要求的最低版本
# @return bool 0=true, 1=false
is_version_at_least() {
    ...
}
```

### 文档更新
- FUNCTION_INDEX.md 添加函数条目
- MANIFEST.json 的 lib_version.public_api 添加函数名

## Success Criteria
- [ ] 契约文件创建并包含完整的输入/输出/错误定义
- [ ] 函数实现正确处理所有版本比较情况
- [ ] 使用语义标签 (@tag public, @category)
- [ ] 有类型注解 (@param VersionString, @return bool)
- [ ] FUNCTION_INDEX.md 已更新
- [ ] MANIFEST.json 已更新
- [ ] 包含至少 3 个测试用例（正常、边界、错误）

## Constraints
- 必须遵循 AIRS "契约优先" 原则
- 不得破坏现有 API（向后兼容）
- 必须处理无效版本格式（返回错误码）
- 必须使用现有的 compare_versions() 函数（如果可能）

## Example Usage

```bash
# 检查当前版本
current=$(get_current_version)

# 检查是否至少 2.3.0
if is_version_at_least "$current" "2.3.0"; then
    echo "✅ Version meets requirement"
else
    echo "❌ Version too old"
fi
```

## Evaluation Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Contract completeness | 100% | ___ |
| Code style compliance | 100% | ___ |
| Type annotation coverage | 100% | ___ |
| Test coverage | >80% | ___ |
| Documentation accuracy | 100% | ___ |

---

**Task ID**: EVAL-001
**Category**: Feature Addition
**Difficulty**: Medium
**Estimated Time**: 30 minutes
**AIRS Version**: 1.0
