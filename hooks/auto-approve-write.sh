#!/bin/bash
# Auto-approve Write/Edit tools - 自动批准写入操作（除非是敏感文件）

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 敏感文件/目录列表（拒绝自动批准）
SENSITIVE_PATTERNS=(
  ".*/\.ssh/.*"         # SSH 目录
  ".*/\.aws/.*"         # AWS 配置
  ".*/\.kube/config"    # Kubernetes 配置
  ".*\.pem$"            # 证书文件
  ".*id_rsa.*"          # SSH 私钥
  ".*id_ed25519.*"      # SSH 私钥
  "/etc/.*"             # 系统配置
  "/System/.*"          # macOS 系统目录
)

# 检查是否是敏感文件
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" =~ $pattern ]]; then
    # 敏感文件，不自动批准
    exit 0
  fi
done

# 非敏感文件，自动批准 Write/Edit 操作
if [ "$TOOL_NAME" = "Write" ] || [ "$TOOL_NAME" = "Edit" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PermissionRequest\",\"decision\":{\"behavior\":\"allow\"}}}"
  exit 0
fi

# 默认：无决定
exit 0
