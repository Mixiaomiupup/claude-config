#!/bin/bash
# File Protection Hook - 保护关键文件不被修改
# 在 Edit/Write 操作前运行

INPUT=$(cat)
FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 如果无法解析文件路径，放行
if [ -z "$FILE" ]; then
  exit 0
fi

# 定义受保护的文件模式
PROTECTED_PATTERNS=(
  ".env"                      # 环境变量文件
  ".env.local"                # 本地环境变量
  ".env.production"           # 生产环境变量
  "credentials.json"          # 凭证文件
  "secrets.yaml"              # 密钥文件
  "package-lock.json"         # NPM 锁文件
  "yarn.lock"                 # Yarn 锁文件
  "poetry.lock"               # Poetry 锁文件
  "Pipfile.lock"              # Pipenv 锁文件
  ".git/config"               # Git 配置
  ".ssh/"                     # SSH 密钥目录
  "id_rsa"                    # SSH 私钥
  "id_ed25519"                # SSH 私钥
  ".aws/credentials"          # AWS 凭证
  ".kube/config"              # Kubernetes 配置
)

# 检查文件是否匹配受保护模式
for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    # 拒绝修改
    jq -n --arg file "$FILE" --arg pattern "$pattern" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": ("🔒 文件被保护: " + $file + " (匹配模式: " + $pattern + ")")
      }
    }'
    exit 0
  fi
done

# 警告但不阻止的文件模式（需要用户确认）
WARNING_PATTERNS=(
  "settings.json"
  "config.json"
  "tsconfig.json"
  "pyproject.toml"
  "Makefile"
  "Dockerfile"
  ".gitignore"
)

for pattern in "${WARNING_PATTERNS[@]}"; do
  if [[ "$FILE" == *"$pattern"* ]]; then
    echo "⚠️  警告: 即将修改配置文件 '$FILE'"
    exit 0
  fi
done

# ========================================================
# Superpowers 计划文件路径强制
# YYYY-MM-DD-*.md 不允许写入 ~/.claude/plans/
# 内置 plan mode 文件（随机词命名）不受影响
# ========================================================
if [[ "$FILE" == "$HOME/.claude/plans/"* ]]; then
  FILENAME=$(basename "$FILE")

  # 仅拦截 Superpowers 命名格式: YYYY-MM-DD-*.md
  if [[ "$FILENAME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$ ]]; then
    # 列出可用项目（有 .git 的目录）
    PROJECTS=""
    for proj_dir in "$HOME/projects"/*/; do
      if [ -d "${proj_dir}.git" ]; then
        PROJECTS="$PROJECTS $(basename "$proj_dir")"
      fi
    done

    jq -n --arg file "$FILE" --arg filename "$FILENAME" --arg projects "$PROJECTS" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": (
          "Superpowers plan \"" + $filename + "\" must go to a project directory, not ~/.claude/plans/.\n" +
          "Correct path: /Users/mixiaomiupup/projects/<project>/docs/plans/" + $filename + "\n" +
          "Available projects:" + $projects + "\n\n" +
          "Determine the target project from conversation context, mkdir -p the docs/plans/ dir if needed, then use the absolute path."
        )
      }
    }'
    exit 0
  fi

  # 非 YYYY-MM-DD 文件（内置 plan mode）→ 放行
fi

# 文件安全，允许修改
exit 0
