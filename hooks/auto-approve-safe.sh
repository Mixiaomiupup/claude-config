#!/bin/bash
# Auto-approve Safe Commands Hook - 自动批准安全的命令
# 在权限请求时运行
# 激进模式 + 标准审计

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 如果无法解析命令，让用户决定
if [ -z "$COMMAND" ]; then
  exit 0
fi

# 审计日志文件
AUDIT_LOG="$HOME/.claude/auto-approve-audit.log"

# 定义安全命令模式（白名单 - 静默自动批准）
SAFE_PATTERNS=(
  "^ls "
  "^ls$"
  "^pwd$"
  "^whoami$"
  "^date$"
  "^echo "
  "^cat "
  "^head "
  "^tail "
  "^grep "
  "^find "
  "^tree "
  "^git status"
  "^git log"
  "^git diff"
  "^git show"
  "^git branch"
  "^git remote"
  "^python3 --version"
  "^python --version"
  "^node --version"
  "^npm --version"
  "^pip --version"
  "^pip3 --version"
  "^which "
  "^command -v "
  "^type "
  "^file "
  "^wc "
  "^sort "
  "^uniq "
  "^cut "
  "^awk "
  "^sed "
  "^du "
  "^df "
  "^stat "
  "^md5 "
  "^shasum "
  "^ps "
  "^pgrep "
  "^netstat "
  "^lsof "
  "^unzip -l"
  "^tar -tf"
  "^zipinfo "
  "^jq "
  "^git fetch"
  "^git ls-files"
  "^git ls-tree"
  "^git rev-parse"
  "^git describe"
  "^git tag"
  "^npm list"
  "^npm outdated"
  "^pip list"
  "^pip freeze"
  "^poetry show"
  "^ping "
  "^dig "
  "^nslookup "
)

# 检查是否匹配安全模式
for pattern in "${SAFE_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    # 记录到审计日志
    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO-APPROVED (SAFE): $COMMAND" >> "$AUDIT_LOG"

    # 自动批准
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "PermissionRequest",
        "decision": {
          "behavior": "allow"
        }
      }
    }'
    exit 0
  fi
done

# 定义需要小心但可以自动批准的命令（激进模式 - 通知但自动批准）
CAREFUL_PATTERNS=(
  "^git add"
  "^git commit"
  "^git pull"
  "^git stash"
  "^git checkout"
  "^npm test"
  "^npm run test"
  "^npm run "
  "^npm install"
  "^npm ci"
  "^npm update"
  "^pytest"
  "^python3 -m pytest"
  "^ruff check"
  "^ruff format"
  "^mypy "
  "^pip install"
  "^pip3 install"
  "^brew install"
  "^poetry install"
  "^poetry update"
  "^poetry run"
  "^mkdir "
  "^touch "
  "^cp "
  "^mv "
  "^rm "
  "^unzip "
  "^tar -xf"
  "^tar -czf"
  "^zip "
  "^curl "
  "^wget "
  "^kill "
  "^pkill "
  "^python "
  "^python3 "
  "^\.venv/bin/"
  "^source \.venv/bin/activate"
  "^sqlite3 "
  "^ln -s"
)

for pattern in "${CAREFUL_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    # 记录到审计日志
    echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO-APPROVED (CAREFUL): $COMMAND" >> "$AUDIT_LOG"

    # 显示提示但自动批准
    echo "✓ 自动批准常用命令: $COMMAND"
    jq -n '{
      "hookSpecificOutput": {
        "hookEventName": "PermissionRequest",
        "decision": {
          "behavior": "allow"
        }
      }
    }'
    exit 0
  fi
done

# 检查项目特定模式
PROJECT_PATTERNS_FILE=".claude/auto-approve-patterns.txt"
if [ -f "$PROJECT_PATTERNS_FILE" ]; then
  while IFS= read -r pattern; do
    # 跳过空行和注释
    [[ -z "$pattern" || "$pattern" =~ ^# ]] && continue

    if echo "$COMMAND" | grep -qE "$pattern"; then
      # 记录到审计日志
      echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO-APPROVED (PROJECT): $COMMAND" >> "$AUDIT_LOG"

      echo "✓ 自动批准项目命令: $COMMAND"
      jq -n '{
        "hookSpecificOutput": {
          "hookEventName": "PermissionRequest",
          "decision": {
            "behavior": "allow"
          }
        }
      }'
      exit 0
    fi
  done < "$PROJECT_PATTERNS_FILE"
fi

# 不匹配任何模式，让用户手动决定
exit 0
