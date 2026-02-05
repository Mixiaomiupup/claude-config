#!/bin/bash
# User Prompt Submit Hook - 用户提交提示词时注入上下文
# 自动添加 Git 信息作为上下文

# 检查是否在 git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  exit 0
fi

# 获取当前分支
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# 获取最近3次提交（简短版）
RECENT_COMMITS=$(git log --oneline -3 2>/dev/null | sed 's/^/  /')

# 检查是否有未提交的更改
UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')

# 输出上下文信息
if [ -n "$BRANCH" ]; then
  echo "📌 当前分支: $BRANCH"
fi

if [ -n "$RECENT_COMMITS" ]; then
  echo "📝 最近提交:"
  echo "$RECENT_COMMITS"
fi

if [ "$UNCOMMITTED" -gt 0 ]; then
  echo "⚠️  有 $UNCOMMITTED 个未提交的更改"
fi

exit 0
