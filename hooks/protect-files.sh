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

# 文件安全，允许修改
exit 0
