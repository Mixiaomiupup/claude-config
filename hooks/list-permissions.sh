#!/bin/bash
# 列出所有自动批准的命令

echo "=== Claude Code 权限配置 ==="
echo ""

echo "📁 全局静态白名单 (settings.json):"
jq -r '.permissions.allow[]' ~/.claude/settings.json 2>/dev/null | grep "Bash(" | grep -v "^//" | head -20
echo "... (共 $(jq -r '.permissions.allow[]' ~/.claude/settings.json 2>/dev/null | grep "Bash(" | grep -v "^//" | wc -l | tr -d ' ') 条)"
echo ""

if [ -f ~/.claude/settings.local.json ]; then
  echo "📁 用户扩展白名单 (settings.local.json):"
  jq -r '.permissions.allow[]' ~/.claude/settings.local.json 2>/dev/null | grep "Bash(" | grep -v "^//" | head -20
  echo "... (共 $(jq -r '.permissions.allow[]' ~/.claude/settings.local.json 2>/dev/null | grep "Bash(" | grep -v "^//" | wc -l | tr -d ' ') 条)"
  echo ""
fi

echo "✓ SAFE_PATTERNS (静默自动批准):"
grep "\"^" ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null | head -20 | sed 's/.*"\^/  /' | sed 's/"$//'
echo "... (共 $(grep -c "\"^" ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null) 条模式)"
echo ""

echo "⚠️  CAREFUL_PATTERNS (通知+自动批准):"
awk '/^CAREFUL_PATTERNS=/,/^\)/' ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null | grep "\"^" | sed 's/.*"\^/  /' | sed 's/"$//' | head -15
careful_count=$(awk '/^CAREFUL_PATTERNS=/,/^\)/' ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null | grep -c "\"^")
echo "... (共 $careful_count 条模式)"
echo ""

if [ -f ".claude/auto-approve-patterns.txt" ]; then
  echo "🎯 项目特定模式:"
  grep -v "^#" .claude/auto-approve-patterns.txt 2>/dev/null | grep -v "^$" | sed 's/^/  /'
  echo ""
fi

if [ -f ~/.claude/auto-approve-audit.log ]; then
  echo "📊 最近自动批准的命令 (最近10条):"
  tail -10 ~/.claude/auto-approve-audit.log 2>/dev/null | sed 's/^/  /'
else
  echo "📊 审计日志: 未找到（首次运行时会自动创建）"
fi

echo ""
echo "配置模式: 激进模式 + 标准审计"
