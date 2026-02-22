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

# === 核心改进：提取复合命令中的所有子命令 ===
# CC 经常生成 "if [ -f x ]; then grep ..." 或 "cmd1 && cmd2 ; cmd3" 这样的复合命令
# 把它们拆成子命令逐个检查，只要所有子命令都安全就放行
extract_subcommands() {
  local cmd="$1"
  # 按 ; && || | then do else 拆分，提取每个子命令的首个 token
  echo "$cmd" | sed 's/;/\n/g; s/&&/\n/g; s/||/\n/g; s/|/\n/g' \
    | sed 's/then /\n/g; s/do /\n/g; s/else /\n/g; s/fi//g; s/done//g' \
    | sed 's/^[[:space:]]*//' \
    | sed 's/^(//; s/)$//' \
    | sed 's/^[[:space:]]*//' \
    | sed -E 's/^([A-Z_][A-Z_0-9]*="[^"]*"[[:space:]]*)+//' \
    | sed -E "s/^([A-Z_][A-Z_0-9]*='[^']*'[[:space:]]*)+//" \
    | sed -E 's/^([A-Z_][A-Z_0-9]*=[^[:space:]]*[[:space:]]*)+//' \
    | sed 's/^[[:space:]]*//' \
    | grep -v '^$' \
    | grep -v '^\[' \
    | grep -v '^#'
}

# 安全命令关键词（不再用 ^ 锚定，因为子命令已被提取）
SAFE_COMMANDS="ls|pwd|whoami|date|echo|cat|head|tail|grep|find|tree|wc|sort|uniq|cut|awk|sed|du|df|stat|md5|shasum|file|which|type|command|jq|pgrep|lsof|netstat|ps|zipinfo|ping|dig|nslookup|export|cd|sleep|true|false|test|env|xargs"
SAFE_GIT="git status|git log|git diff|git show|git branch|git remote|git fetch|git ls-files|git ls-tree|git rev-parse|git describe|git tag|git --version|git config"
SAFE_PKG="npm list|npm outdated|pip list|pip freeze|pip3 list|poetry show|node --version|npm --version|python3 --version|python --version|pip --version|pip3 --version|uv --version"

# 子命令注册表（仅包含 SAFE_GIT/SAFE_PKG/CAREFUL_COMMANDS 中引用的子命令）
GIT_SUBCMDS="status|log|diff|show|branch|remote|fetch|ls-files|ls-tree|rev-parse|describe|tag|config|add|commit|pull|stash|checkout|clone|init|rm|push|worktree|mv|reset|rebase"
NPM_SUBCMDS="list|outdated|test|run|install|ci|update"
PIP_SUBCMDS="list|freeze|install|show"
POETRY_SUBCMDS="show|install|update|run"
RUFF_SUBCMDS="check|format"
BREW_SUBCMDS="install"

# 规范化命令：跳过全局选项，找到第一个已知子命令，重组为 <tool> <subcmd> <args>
normalize_cmd() {
  local cmd="$1"
  local tool="${cmd%% *}"

  local subcmds
  case "$tool" in
    git)      subcmds="$GIT_SUBCMDS" ;;
    npm)      subcmds="$NPM_SUBCMDS" ;;
    pip|pip3) subcmds="$PIP_SUBCMDS" ;;
    poetry)   subcmds="$POETRY_SUBCMDS" ;;
    ruff)     subcmds="$RUFF_SUBCMDS" ;;
    brew)     subcmds="$BREW_SUBCMDS" ;;
    *)        echo "$cmd"; return ;;
  esac

  local rest="${cmd#"$tool" }"
  [ "$rest" = "$cmd" ] && { echo "$cmd"; return; }

  local remaining="$rest"
  while [ -n "$remaining" ]; do
    local token="${remaining%% *}"
    if [[ "$remaining" == *" "* ]]; then
      remaining="${remaining#* }"
    else
      remaining=""
    fi
    # 匹配子命令（bash builtin，无子进程）
    if [[ "$token" =~ ^($subcmds)$ ]]; then
      [ -n "$remaining" ] && echo "$tool $token $remaining" || echo "$tool $token"
      return
    fi
    # --version 伪子命令
    if [ "$token" = "--version" ]; then
      [ -n "$remaining" ] && echo "$tool --version $remaining" || echo "$tool --version"
      return
    fi
  done

  echo "$cmd"
}

# 检查单个子命令是否安全
is_safe() {
  local subcmd="$1"
  local normalized
  normalized=$(normalize_cmd "$subcmd")
  echo "$subcmd" | grep -qE "^($SAFE_COMMANDS) " && return 0
  echo "$subcmd" | grep -qE "^($SAFE_COMMANDS)$" && return 0
  echo "$normalized" | grep -qE "^($SAFE_GIT)" && return 0
  echo "$normalized" | grep -qE "^($SAFE_PKG)" && return 0
  echo "$subcmd" | grep -qE "^(unzip -l|tar -tf|tar -tzf)" && return 0
  return 1
}

# 谨慎但可自动批准的命令
CAREFUL_COMMANDS="git add|git commit|git pull|git stash|git checkout|git clone|git init|git rm|git push|git remote|git worktree|npm test|npm run|npm install|npm ci|npm update|npx|pytest|ruff check|ruff format|mypy|pip install|pip3 install|brew install|brew|poetry install|poetry update|poetry run|mkdir|touch|cp|mv|rm|unzip|tar|zip|curl|wget|kill|pkill|python|python3|sqlite3|ln|source|bash|sh|zsh|chmod|open|sshpass|ssh|ssh-keyscan|scp|gh|mdfind|rsync|osascript|defaults|virtualenv|black|isort|code|ghostty|gemini|crontab|uv|uvx|crwl|claude|playwright"

is_careful() {
  local subcmd="$1"
  local normalized
  normalized=$(normalize_cmd "$subcmd")
  echo "$subcmd" | grep -qE "^($CAREFUL_COMMANDS)( |$)" && return 0
  echo "$normalized" | grep -qE "^($CAREFUL_COMMANDS)( |$)" && return 0
  echo "$subcmd" | grep -qE "^\\.venv/bin/" && return 0
  # ~/.claude/ scripts (sync, hooks, etc.)
  echo "$subcmd" | grep -qE "^~/.claude/|^\\\$HOME/.claude/|^/Users/.*/\.claude/" && return 0
  return 1
}

# === 主检查逻辑 ===

# 策略：先尝试整条命令匹配（快速路径），再拆子命令逐个检查
approve_as() {
  local level="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - AUTO-APPROVED ($level): $COMMAND" >> "$AUDIT_LOG"
  if [ "$level" != "SAFE" ]; then
    echo "✓ 自动批准: $COMMAND" >&2
  fi
  jq -n '{
    "hookSpecificOutput": {
      "hookEventName": "PermissionRequest",
      "decision": {
        "behavior": "allow"
      }
    }
  }'
  exit 0
}

# 快速路径：bash 注释行直接放行
echo "$COMMAND" | grep -qE "^#" && approve_as "SAFE"

# 快速路径：整条命令直接匹配
is_safe "$COMMAND" && approve_as "SAFE"
is_careful "$COMMAND" && approve_as "CAREFUL"

# 慢速路径：拆分复合命令，逐个检查
SUBCOMMANDS=$(extract_subcommands "$COMMAND")
if [ -n "$SUBCOMMANDS" ]; then
  ALL_SAFE=true
  ALL_KNOWN=true
  HAS_CAREFUL=false

  while IFS= read -r subcmd; do
    [ -z "$subcmd" ] && continue
    if is_safe "$subcmd"; then
      continue
    elif is_careful "$subcmd"; then
      HAS_CAREFUL=true
    else
      ALL_KNOWN=false
      break
    fi
  done <<< "$SUBCOMMANDS"

  if $ALL_KNOWN; then
    if $HAS_CAREFUL; then
      approve_as "CAREFUL-COMPOUND"
    else
      approve_as "SAFE-COMPOUND"
    fi
  fi
fi

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

# 不匹配任何模式，记录后让用户手动决定
echo "$(date '+%Y-%m-%d %H:%M:%S') - NEEDS-MANUAL: $COMMAND" >> "$AUDIT_LOG"
exit 0
