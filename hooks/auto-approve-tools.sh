#!/bin/bash
# Auto-approve common safe tools: Glob, Grep, WebFetch, Task

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# 自动批准的工具列表
case "$TOOL_NAME" in
  "Glob"|"Grep"|"WebFetch"|"Task"|"TaskOutput"|"TaskStop"|"TaskList"|"TaskGet"|"TaskUpdate"|"TaskCreate")
    echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PermissionRequest\",\"decision\":{\"behavior\":\"allow\"}}}"
    exit 0
    ;;
esac

# 默认：无决定（询问用户）
exit 0
