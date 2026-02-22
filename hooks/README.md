# Claude Code Hooks

**更新日期**: 2026-02-22
**架构文档**: `~/.claude/AUTO_APPROVE_GUIDE.md`

---

## 文件结构

```
~/.claude/hooks/
├── auto-approve-safe.sh     # PermissionRequest: Bash 命令 (SAFE/CAREFUL)
├── auto-approve-read.sh     # PermissionRequest: Read (排除敏感文件)
├── auto-approve-write.sh    # PermissionRequest: Write/Edit (排除敏感文件)
├── auto-approve-tools.sh    # PermissionRequest: Glob/Grep/WebFetch/Task
├── validate-bash.sh         # PreToolUse: 危险命令黑名单
├── protect-files.sh         # PreToolUse: 敏感文件保护
├── session-start.sh         # SessionStart: 显示环境信息
├── inject-context.sh        # UserPromptSubmit: 注入 Git 上下文
├── auto-format.sh           # PostToolUse: 自动格式化代码
├── README.md                # 本文档
└── QUICK_REFERENCE.md       # 速查卡
```

---

## Hook 分类

### 安全层 (PreToolUse) — 先于权限判定

| 脚本 | Matcher | 功能 |
|------|---------|------|
| `validate-bash.sh` | `Bash` | 阻止 `rm -rf /`, `chmod 777`, fork 炸弹等 |
| `protect-files.sh` | `Edit\|Write` | 阻止修改 `.env`, SSH keys, lock 文件等 |

### 权限层 (PermissionRequest) — 自动批准决策

| 脚本 | Matcher | 功能 |
|------|---------|------|
| `auto-approve-safe.sh` | `Bash` | SAFE/CAREFUL/COMPOUND 分级批准 |
| `auto-approve-read.sh` | `Read` | 全部批准（敏感文件除外） |
| `auto-approve-write.sh` | `Write\|Edit` | 全部批准（敏感文件/目录除外） |
| `auto-approve-tools.sh` | `Glob\|Grep\|WebFetch\|Task.*` | 全部批准 |
| inline echo | `mcp__yunxiao__.*` | 全部批准 |
| inline echo | `mcp__tavily__.*` | 全部批准 |
| inline echo | `mcp__ucal__.*` | 全部批准 |

### 增强层 (SessionStart / UserPromptSubmit / PostToolUse)

| 脚本 | 事件 | 功能 |
|------|------|------|
| `session-start.sh` | SessionStart | 显示 Python/Node/Git 版本、当前分支 |
| `inject-context.sh` | UserPromptSubmit | 注入分支、最近提交、未提交变更 |
| `auto-format.sh` | PostToolUse (Write\|Edit) | Python→ruff, JS/TS→prettier, JSON→jq |

### 通知 (Notification)

| Matcher | 功能 |
|---------|------|
| `permission_prompt\|idle_prompt` | macOS 桌面通知 + 提示音 |

---

## 自定义

### 添加 Bash 命令到自动批准

编辑 `auto-approve-safe.sh`：
- 只读命令 → `SAFE_COMMANDS` 变量
- 写操作 → `CAREFUL_COMMANDS` 变量
- Git 子命令 → `SAFE_GIT` 变量

### 添加敏感文件保护

编辑 `protect-files.sh`：
- 硬阻止 → `PROTECTED_PATTERNS` 数组
- 警告 → `WARNING_PATTERNS` 数组

### 添加项目特定 Bash 模式

在项目目录创建 `.claude/auto-approve-patterns.txt`，每行一个 ERE 正则。

---

## 调试

```bash
# 查看审计日志
tail -20 ~/.claude/auto-approve-audit.log

# 查看需要手动批准的命令
grep "NEEDS-MANUAL" ~/.claude/auto-approve-audit.log | tail -10

# 检查脚本执行权限
ls -la ~/.claude/hooks/*.sh

# 验证 jq 可用（hooks 依赖 jq）
jq --version
```

---

## 完整架构

三层权限体系、设计决策、维护操作的完整说明见：

**`~/.claude/AUTO_APPROVE_GUIDE.md`**
