#!/bin/bash
# Auto-approve Read tool - 自动批准所有读取操作（除非是敏感文件）

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# 敏感文件列表（拒绝自动批准）
SENSITIVE_PATTERNS=(
  ".*id_rsa$"           # SSH 私钥
  ".*id_ed25519$"       # SSH 私钥
  ".*/\.ssh/.*"         # SSH 目录
  ".*\.pem$"            # 证书文件
  ".*\.key$"            # 密钥文件
  ".*credentials.*"     # 凭证文件
  ".*/\.aws/.*"         # AWS 配置
  ".*/\.kube/config"    # Kubernetes 配置
)

# 检查是否是敏感文件
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" =~ $pattern ]]; then
    # 敏感文件，不自动批准（让用户决定）
    exit 0
  fi
done

# 非敏感文件，自动批准 Read 操作
if [ "$TOOL_NAME" = "Read" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PermissionRequest\",\"decision\":{\"behavior\":\"allow\"}}}"
  exit 0
fi

# 默认：无决定（询问用户）
exit 0
