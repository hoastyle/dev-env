#!/bin/bash
# NVM 懒加载功能测试脚本
# 用途: 验证 .zshrc.nvm-optimized 配置的正确性

echo "========================================="
echo "NVM 懒加载配置测试"
echo "========================================="
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

passed=0
failed=0

test_case() {
    local name="$1"
    local cmd="$2"
    local expected_pattern="$3"

    echo -n "测试: $name ... "

    output=$(zsh -c "$cmd" 2>&1) || output="$output"
    if echo "$output" | grep -q "$expected_pattern" 2>/dev/null; then
        echo -e "${GREEN}✓ PASS${NC}"
        ((passed++))
    else
        echo -e "${RED}✗ FAIL${NC}"
        echo "  输出: $output"
        echo "  期望匹配: $expected_pattern"
        ((failed++))
    fi
}

# 测试 1: 检查配置文件存在
echo "1️⃣  文件完整性检查"
if [ -f "$PROJECT_DIR/config/.zshrc.nvm-optimized" ]; then
    echo -e "  ${GREEN}✓${NC} .zshrc.nvm-optimized 存在"
    ((passed++))
else
    echo -e "  ${RED}✗${NC} .zshrc.nvm-optimized 不存在"
    ((failed++))
fi
echo ""

# 测试 2: 检查 NVM 加载函数
echo "2️⃣  配置正确性检查"
if grep -q "_nvm_load()" "$PROJECT_DIR/config/.zshrc.nvm-optimized"; then
    echo -e "  ${GREEN}✓${NC} _nvm_load() 函数已定义"
    ((passed++))
else
    echo -e "  ${RED}✗${NC} _nvm_load() 函数未定义"
    ((failed++))
fi

if grep -q "node() { _nvm_load; node" "$PROJECT_DIR/config/.zshrc.nvm-optimized"; then
    echo -e "  ${GREEN}✓${NC} node() 包装函数已定义"
    ((passed++))
else
    echo -e "  ${RED}✗${NC} node() 包装函数未定义"
    ((failed++))
fi

if grep -q "nvm() { _nvm_load; nvm" "$PROJECT_DIR/config/.zshrc.nvm-optimized"; then
    echo -e "  ${GREEN}✓${NC} nvm() 包装函数已定义"
    ((passed++))
else
    echo -e "  ${RED}✗${NC} nvm() 包装函数未定义"
    ((failed++))
fi
echo ""

# 测试 3: 功能测试
echo "3️⃣  功能测试"

test_case "第一次 nvm 调用（初始化）" \
    'source '"$PROJECT_DIR"'/config/.zshrc.nvm-optimized 2>/dev/null || true; nvm 2>&1 | head -1' \
    "Node Version Manager"

test_case "nvm 颜色代码显示" \
    'source '"$PROJECT_DIR"'/config/.zshrc.nvm-optimized 2>/dev/null || true; nvm 2>&1' \
    "Initial colors"

test_case "nvm --version 命令" \
    'source '"$PROJECT_DIR"'/config/.zshrc.nvm-optimized 2>/dev/null || true; nvm --version 2>&1' \
    "^[0-9]"

test_case "node 包装函数" \
    'export NVM_DIR="$HOME/.nvm"; source '"$PROJECT_DIR"'/config/.zshrc.nvm-optimized 2>/dev/null || true; type node 2>&1' \
    "node is"

echo ""
echo "========================================="
echo "测试结果"
echo "========================================="
echo -e "${GREEN}通过: $passed${NC}"
echo -e "${RED}失败: $failed${NC}"

if [ $failed -eq 0 ]; then
    echo -e "\n${GREEN}✨ 所有测试通过！${NC}"
    exit 0
else
    echo -e "\n${RED}❌ 部分测试失败${NC}"
    exit 1
fi
