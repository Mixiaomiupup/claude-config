# Claude Code Hooks 速查卡

**更新**: 2026-02-22 | **详细架构**: `~/.claude/AUTO_APPROVE_GUIDE.md`

---

## 三层权限体系

```
① permissions.allow (5+15条) → 直接通过
② hooks (auto-approve-*.sh)  → 脚本判定
③ 弹窗问用户                  → 手动决定
```

---

## 自动阻止 (PreToolUse)

```bash
rm -rf /          # validate-bash.sh
chmod 777         # validate-bash.sh
dd if=            # validate-bash.sh
curl ... | sh     # validate-bash.sh
.env / .ssh/      # protect-files.sh
```

---

## 自动批准 — Bash (auto-approve-safe.sh)

**SAFE（静默）**:
```
ls cat grep find tree head tail wc sort pwd whoami date echo
git status  git log  git diff  git show  git branch
npm list  pip list  python3 --version  uv --version
```

**CAREFUL（通知）**:
```
git add  git commit  git push  git pull  git checkout
npm install  pip install  pytest  ruff  mypy
mkdir cp mv rm curl wget python3 uv uvx claude gh
```

**COMPOUND**: 复合命令拆分后逐个检查

---

## 自动批准 — 其他工具

| Hook 脚本 | 工具 | 策略 |
|-----------|------|------|
| auto-approve-read.sh | Read | 全部（敏感文件除外） |
| auto-approve-write.sh | Write/Edit | 全部（敏感文件除外） |
| auto-approve-tools.sh | Glob/Grep/WebFetch/Task* | 全部 |
| inline hooks | mcp__yunxiao/tavily/ucal__ | 全部 |

---

## permissions.allow 保留的条目 (hooks 盲区)

| 条目 | 原因 |
|------|------|
| `WebSearch` | 非 Bash 工具 |
| `Bash(open:*)` | 安全考虑不放 hook |
| `Bash(.claude/package-config.sh)` | 相对路径 |
| `Bash(git -C ...)` x2 | git -C 非子命令 |
| `WebFetch(domain:*)` x2 | 非 Bash 工具 |
| `Skill(kb)` | 非 Bash 工具 |
| `mcp__yunxiao__*` x5 | hook 故障兜底 |
| `/opt/homebrew/bin/*` x3 | 绝对路径 |
| `/Users/.../.local/bin/uv` | 绝对路径 |

---

## 维护命令

```bash
# 审计日志
grep "NEEDS-MANUAL" ~/.claude/auto-approve-audit.log | tail -20

# 统计
grep -c 'SAFE)' ~/.claude/auto-approve-audit.log    # SAFE 次数
grep -c 'CAREFUL)' ~/.claude/auto-approve-audit.log  # CAREFUL 次数
grep -c 'NEEDS-MANUAL' ~/.claude/auto-approve-audit.log  # 手动次数

# 新增命令 → 编辑 hooks/auto-approve-safe.sh
# 新增非 Bash 工具 → 编辑 settings.json 或 settings.local.json
```
