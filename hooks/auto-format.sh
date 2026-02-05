#!/bin/bash
# Auto-format Hook - 自动格式化代码文件
# 在 Write/Edit 操作后运行

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 如果无法解析文件路径，退出
if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  exit 0
fi

# Python 文件 - 使用 ruff format
if [[ "$FILE" == *.py ]]; then
  if command -v ruff &> /dev/null; then
    ruff format "$FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "✨ 已自动格式化 Python 文件: $FILE"
    fi

    # 运行 ruff check 但不阻止（仅提示）
    LINT_RESULT=$(ruff check "$FILE" 2>&1)
    if [ $? -ne 0 ]; then
      echo "⚠️  Ruff 检查发现问题:"
      echo "$LINT_RESULT" | head -10
    fi
  fi
fi

# JavaScript/TypeScript 文件 - 使用 prettier
if [[ "$FILE" =~ \.(js|jsx|ts|tsx)$ ]]; then
  if command -v npx &> /dev/null && [ -f "package.json" ]; then
    npx prettier --write "$FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "✨ 已自动格式化 JS/TS 文件: $FILE"
    fi
  fi
fi

# JSON 文件 - 使用 jq 格式化
if [[ "$FILE" == *.json ]]; then
  if command -v jq &> /dev/null; then
    TEMP_FILE=$(mktemp)
    if jq '.' "$FILE" > "$TEMP_FILE" 2>/dev/null; then
      mv "$TEMP_FILE" "$FILE"
      echo "✨ 已自动格式化 JSON 文件: $FILE"
    else
      rm -f "$TEMP_FILE"
    fi
  fi
fi

# Markdown 文件 - 使用 prettier
if [[ "$FILE" == *.md ]]; then
  if command -v npx &> /dev/null && [ -f "package.json" ]; then
    npx prettier --write "$FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "✨ 已自动格式化 Markdown 文件: $FILE"
    fi
  fi
fi

# YAML 文件 - 使用 prettier
if [[ "$FILE" =~ \.(yaml|yml)$ ]]; then
  if command -v npx &> /dev/null && [ -f "package.json" ]; then
    npx prettier --write "$FILE" 2>/dev/null
    if [ $? -eq 0 ]; then
      echo "✨ 已自动格式化 YAML 文件: $FILE"
    fi
  fi
fi

exit 0
