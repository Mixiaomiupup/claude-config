#!/bin/bash
# Bash Validation Hook - 验证并阻止危险的 Bash 命令
# 在执行 Bash 命令前运行

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# 如果无法解析命令，放行（让 Claude 处理）
if [ -z "$COMMAND" ]; then
  exit 0
fi

# 定义危险命令模式（阻止列表）
DANGEROUS_PATTERNS=(
  "rm -rf /"           # 删除根目录
  "rm -rf ~"           # 删除用户目录
  "chmod 777"          # 不安全的权限
  "chmod -R 777"       # 递归不安全权限
  "> /dev/sda"         # 直接写入磁盘
  "dd if="             # 危险的磁盘操作
  "mkfs"               # 格式化文件系统
  ":(){ :|:& };:"      # Fork 炸弹
  "curl.*\\|.*\\.sh"   # 下载并执行 .sh 脚本
  "wget.*\\|.*\\.sh"   # 下载并执行 .sh 脚本
  "sudo rm"            # Sudo 删除
)

# 检查危险模式
for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    # 拒绝执行
    jq -n --arg pattern "$pattern" '{
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": ("🚫 检测到危险命令模式: " + $pattern)
      }
    }'
    exit 0
  fi
done

# 警告但不阻止的命令（需要用户确认）
WARNING_PATTERNS=(
  "rm -rf"
  "DROP TABLE"
  "DELETE FROM"
  "TRUNCATE"
  "sudo"
)

for pattern in "${WARNING_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    # 输出警告但允许用户决定
    echo "⚠️  警告: 命令包含潜在危险操作 '$pattern'"
    exit 0
  fi
done

# 命令安全，放行
exit 0
