#!/bin/bash
# Session Start Hook - 会话启动时运行
# 显示环境信息并设置环境变量

# 设置持久化环境变量（如果支持）
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$CLAUDE_ENV_FILE"
  echo 'export PYTHONPATH="$HOME/projects:$PYTHONPATH"' >> "$CLAUDE_ENV_FILE"
fi

# 显示环境信息
echo "🚀 Claude Code 会话已启动"
echo "📍 工作目录: $(pwd)"
echo "🐍 Python: $(python3 --version 2>&1 | head -1 || echo '未安装')"
echo "📦 Node: $(node --version 2>&1 || echo '未安装')"
echo "🔧 Git: $(git --version 2>&1 | head -1 || echo '未安装')"

# 检查是否在 git 仓库中
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo "🌿 Git 分支: $BRANCH"
fi

exit 0
