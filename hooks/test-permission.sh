#!/bin/bash
# 测试命令是否会被自动批准

COMMAND="$1"

if [ -z "$COMMAND" ]; then
  echo "用法: $0 '要测试的命令'"
  echo ""
  echo "示例:"
  echo "  $0 'ls -la'"
  echo "  $0 'git status'"
  echo "  $0 'npm install'"
  exit 1
fi

echo "测试命令: $COMMAND"
echo ""

# 测试静态白名单
check_whitelist() {
  local file=$1
  if [ -f "$file" ]; then
    # 提取第一个单词作为命令
    cmd_word=$(echo "$COMMAND" | awk '{print $1}')

    # 检查完整命令模式
    if jq -r '.permissions.allow[]' "$file" 2>/dev/null | grep -q "Bash($COMMAND"; then
      echo "✓ 匹配白名单 (完整): $file"
      return 0
    fi

    # 检查通配符模式
    if jq -r '.permissions.allow[]' "$file" 2>/dev/null | grep -q "Bash($cmd_word:"; then
      echo "✓ 匹配白名单 (通配符): $file"
      return 0
    fi
  fi
  return 1
}

if check_whitelist ~/.claude/settings.json; then
  echo "结果: ✅ 自动执行 (全局白名单)"
  exit 0
fi

if check_whitelist ~/.claude/settings.local.json; then
  echo "结果: ✅ 自动执行 (用户白名单)"
  exit 0
fi

if check_whitelist .claude/settings.json; then
  echo "结果: ✅ 自动执行 (项目白名单)"
  exit 0
fi

# 测试 SAFE_PATTERNS
echo "检查 SAFE_PATTERNS..."
while IFS= read -r line; do
  pattern=$(echo "$line" | sed 's/.*"\^\(.*\)"/\1/' | sed 's/"$//')
  if echo "$COMMAND" | grep -qE "^$pattern"; then
    echo "✓ 匹配 SAFE_PATTERNS: ^$pattern"
    echo "结果: ✅ 静默自动批准"
    exit 0
  fi
done < <(grep "\"^" ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null | head -100)

# 测试 CAREFUL_PATTERNS
echo "检查 CAREFUL_PATTERNS..."
while IFS= read -r line; do
  pattern=$(echo "$line" | sed 's/.*"\^\(.*\)"/\1/' | sed 's/"$//')
  if echo "$COMMAND" | grep -qE "^$pattern"; then
    echo "⚠️  匹配 CAREFUL_PATTERNS: ^$pattern"
    echo "结果: ✅ 通知+自动批准"
    exit 0
  fi
done < <(awk '/^CAREFUL_PATTERNS=/,/^\)/' ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null | grep "\"^")

# 测试项目模式
if [ -f ".claude/auto-approve-patterns.txt" ]; then
  echo "检查项目特定模式..."
  while IFS= read -r pattern; do
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue
    if echo "$COMMAND" | grep -qE "$pattern"; then
      echo "🎯 匹配项目模式: $pattern"
      echo "结果: ✅ 自动批准 (项目特定)"
      exit 0
    fi
  done < ".claude/auto-approve-patterns.txt"
fi

echo "✗ 未匹配任何自动批准模式"
echo "结果: ⚠️  需要手动批准"
exit 2
