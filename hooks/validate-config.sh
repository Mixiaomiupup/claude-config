#!/bin/bash
# 验证 Claude Code 配置

echo "🔍 验证配置文件..."
echo ""

errors=0
warnings=0

# 检查 JSON 语法
echo "1. JSON 语法检查:"
for file in ~/.claude/settings.json ~/.claude/settings.local.json .claude/settings.json; do
  if [ -f "$file" ]; then
    if jq empty "$file" 2>/dev/null; then
      echo "  ✓ $file"
    else
      echo "  ✗ $file (无效的 JSON)"
      errors=$((errors + 1))
    fi
  fi
done
echo ""

# 检查 hook 脚本
echo "2. Hook 脚本检查:"
hook_dir="$HOME/.claude/hooks"
if [ -d "$hook_dir" ]; then
  for script in "$hook_dir"/*.sh; do
    if [ -f "$script" ]; then
      if [ -x "$script" ]; then
        echo "  ✓ $(basename "$script") (可执行)"
      else
        echo "  ⚠️  $(basename "$script") (不可执行)"
        echo "     运行: chmod +x $script"
        warnings=$((warnings + 1))
      fi
    fi
  done
else
  echo "  ✗ hooks 目录不存在: $hook_dir"
  errors=$((errors + 1))
fi
echo ""

# 检查依赖
echo "3. 依赖检查:"
for cmd in jq git python3 ruff; do
  if command -v "$cmd" >/dev/null 2>&1; then
    version=$("$cmd" --version 2>&1 | head -1)
    echo "  ✓ $cmd ($version)"
  else
    echo "  ✗ $cmd (未安装)"
    errors=$((errors + 1))
  fi
done
echo ""

# 检查审计日志
echo "4. 审计日志:"
if [ -f ~/.claude/auto-approve-audit.log ]; then
  count=$(wc -l < ~/.claude/auto-approve-audit.log | tr -d ' ')
  size=$(du -h ~/.claude/auto-approve-audit.log | awk '{print $1}')
  echo "  ✓ 日志文件存在 (共 $count 条记录, $size)"

  # 显示统计
  safe_count=$(grep -c "AUTO-APPROVED (SAFE)" ~/.claude/auto-approve-audit.log 2>/dev/null || echo 0)
  careful_count=$(grep -c "AUTO-APPROVED (CAREFUL)" ~/.claude/auto-approve-audit.log 2>/dev/null || echo 0)
  project_count=$(grep -c "AUTO-APPROVED (PROJECT)" ~/.claude/auto-approve-audit.log 2>/dev/null || echo 0)

  echo "     - SAFE: $safe_count"
  echo "     - CAREFUL: $careful_count"
  echo "     - PROJECT: $project_count"
else
  echo "  ℹ️  日志文件不存在 (首次运行时会自动创建)"
fi
echo ""

# 检查配置模式
echo "5. 配置模式检查:"
if grep -q "激进模式" ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null; then
  echo "  ✓ 激进模式已启用"

  # 统计 CAREFUL_PATTERNS 数量
  careful_patterns=$(awk '/^CAREFUL_PATTERNS=/,/^\)/' ~/.claude/hooks/auto-approve-safe.sh 2>/dev/null | grep -c "\"^")
  echo "  ✓ CAREFUL_PATTERNS: $careful_patterns 条"

  if [ "$careful_patterns" -lt 20 ]; then
    echo "  ⚠️  CAREFUL_PATTERNS 较少，可能未完全启用激进模式"
    warnings=$((warnings + 1))
  fi
else
  echo "  ℹ️  使用标准模式"
fi
echo ""

# 检查项目配置
echo "6. 项目配置检查:"
if [ -f ".claude/auto-approve-patterns.txt" ]; then
  pattern_count=$(grep -v "^#" .claude/auto-approve-patterns.txt 2>/dev/null | grep -v "^$" | wc -l | tr -d ' ')
  echo "  ✓ 项目特定模式文件存在 ($pattern_count 条模式)"
else
  echo "  ℹ️  无项目特定模式文件 (可选)"
fi
echo ""

# 总结
echo "========================================="
if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
  echo "✅ 验证通过 - 配置正常"
  exit 0
elif [ $errors -eq 0 ]; then
  echo "⚠️  验证完成 - 发现 $warnings 个警告"
  exit 0
else
  echo "❌ 验证失败 - 发现 $errors 个错误, $warnings 个警告"
  exit 1
fi
