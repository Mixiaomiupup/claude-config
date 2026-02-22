# Claude Code 自动批准系统架构

**版本**: 2.0.0
**更新日期**: 2026-02-22
**设计原则**: permissions.allow 只放 hooks 盲区，hooks 统一管理所有 Bash 命令

---

## 一、三层权限体系

每次工具调用都经过以下三层检查，匹配即终止：

```
工具调用触发
  │
  ▼
① permissions.allow (settings.json / settings.local.json)
  │  内置前缀匹配，最快，无外部依赖
  │  匹配 → 直接通过（不触发 hooks）
  │
  ▼ 不匹配
② PermissionRequest hooks (auto-approve-*.sh + inline hooks)
  │  运行 shell 脚本，处理复合命令、环境变量前缀
  │  依赖 jq，有 5 秒超时
  │  输出 allow → 通过
  │  无输出 → 继续往下
  │
  ▼ 不匹配
③ 弹窗问用户
  │  用户选择 allow/deny
  │  allow 后 Claude Code 自动追加到 settings.local.json
```

### 与 PreToolUse 安全层的关系

权限层（是否允许执行）和安全层（是否阻止危险操作）是独立的：

```
工具调用
  │
  ├─ PreToolUse hooks（安全层，先执行）
  │    validate-bash.sh  → 阻止 rm -rf /, chmod 777 等
  │    protect-files.sh  → 阻止修改 .env, SSH keys 等
  │    决定：deny → 直接拒绝，不进入权限层
  │
  └─ PermissionRequest（权限层，安全层通过后执行）
       ① permissions.allow
       ② hooks
       ③ 弹窗
```

---

## 二、Layer 1: permissions.allow

### 设计原则

**只放 hooks 覆盖不到的工具/命令**：
- 非 Bash 工具（WebSearch, WebFetch, Skill, mcp__*）
- 绝对路径命令（/opt/homebrew/bin/*, /Users/.../.local/bin/uv）
- 特殊前缀命令（.claude/package-config.sh, git -C ...）

### 2.1 settings.json — 全局（sanitized 同步到远程）

**5 条**：

| 条目 | 保留理由 |
|------|---------|
| `WebSearch` | 非 Bash 工具，无 hook matcher |
| `Bash(open:*)` | macOS open 命令，不应加入 hook CAREFUL（可打开任意 URL） |
| `Bash(.claude/package-config.sh)` | 相对路径，hook 只匹配 `~/.claude/` 绝对路径 |
| `Bash(git -C /opt/homebrew/.../homebrew-core remote get-url:*)` | git -C 不是 git 子命令，hook 匹配不到 |
| `Bash(git -C /opt/homebrew/.../homebrew-cask remote get-url:*)` | 同上 |

### 2.2 settings.local.json — 全局（原样同步到远程）

**15 条**（含 2 行注释）：

| 类别 | 条目 | 保留理由 |
|------|------|---------|
| WebFetch | `domain:gitflic.ru`, `domain:github.com` | 非 Bash 工具 |
| Skill | `kb` | 非 Bash 工具 |
| MCP | `mcp__yunxiao__*` x5 | 非 Bash 工具，兼 hook 故障兜底 |
| 绝对路径 | `/opt/homebrew/bin/python*`, `node`, `npm` | hook 首 token 匹配不到 |
| 绝对路径 | `/Users/.../.local/bin/uv` | 同上 |

### 2.3 项目级 settings.local.json — 项目特定（不同步）

位置：`<project>/.claude/settings.local.json`

放该项目独有的、hooks 覆盖不到的工具。例如 `~/projects/` 下：

| 条目 | 保留理由 |
|------|---------|
| `WebFetch(domain:raw.githubusercontent.com)` | 非 Bash 工具 |
| `Bash(/opt/homebrew/bin/python3.12:*)` | 绝对路径 |
| `Skill(kb)` | 非 Bash 工具 |

### 2.4 注意事项

- **不要在 allow 里放明文密码**（如 sshpass -p '...'）
- **不要在 allow 里放 Bash 命令**，除非 hook 确实匹配不到
- 用户手动批准后 Claude Code 自动追加的一次性条目（`fi`, `done` 等），应定期清理

---

## 三、Layer 2: PermissionRequest Hooks

### 3.1 Hook 注册（settings.json hooks 配置）

```json
{
  "PermissionRequest": [
    { "matcher": "Bash",              "command": "auto-approve-safe.sh"  },
    { "matcher": "Read",              "command": "auto-approve-read.sh"  },
    { "matcher": "Write|Edit",        "command": "auto-approve-write.sh" },
    { "matcher": "Glob|Grep|WebFetch|Task.*", "command": "auto-approve-tools.sh" },
    { "matcher": "mcp__yunxiao__.*",  "command": "echo allow (inline)"   },
    { "matcher": "mcp__tavily__.*",   "command": "echo allow (inline)"   },
    { "matcher": "mcp__ucal__.*",     "command": "echo allow (inline)"   }
  ]
}
```

### 3.2 auto-approve-safe.sh — Bash 命令（核心）

**职责**：所有 Bash 命令的自动批准决策。

**判定流程**：

```
收到 Bash 命令
  │
  ├─ 快速路径：整条命令匹配
  │    is_safe()    → SAFE（静默通过）
  │    is_careful() → CAREFUL（通知 + 通过）
  │
  ├─ 慢速路径：extract_subcommands() 拆分复合命令
  │    所有子命令 safe      → SAFE-COMPOUND
  │    所有子命令 safe/careful → CAREFUL-COMPOUND
  │    任一子命令未知        → 继续往下
  │
  ├─ 项目模式：.claude/auto-approve-patterns.txt
  │    正则匹配 → PROJECT
  │
  └─ 无匹配 → NEEDS-MANUAL（记录到审计日志，弹窗问用户）
```

**SAFE 命令**（静默通过，不通知）：

```
ls pwd whoami date echo cat head tail grep find tree wc sort uniq
cut awk sed du df stat md5 shasum file which type command jq pgrep
lsof netstat ps zipinfo ping dig nslookup export cd sleep true false
test env xargs
```

**SAFE Git**：

```
git status  git log   git diff  git show   git branch
git remote  git fetch git ls-files  git ls-tree  git rev-parse
git describe  git tag  git --version  git config
```

**SAFE 包管理查询**：

```
npm list  npm outdated  pip list  pip freeze  pip3 list  poetry show
node --version  npm --version  python3 --version  python --version
pip --version  pip3 --version  uv --version
```

**CAREFUL 命令**（通知 + 通过）：

```
git add  git commit  git pull  git stash  git checkout  git clone
git init  git rm  git push  git remote  git worktree
npm test  npm run  npm install  npm ci  npm update  npx
pytest  ruff check  ruff format  mypy
pip install  pip3 install  brew install  brew
poetry install  poetry update  poetry run
mkdir  touch  cp  mv  rm  unzip  tar  zip
curl  wget  kill  pkill  python  python3  sqlite3
ln  source  bash  sh  zsh  chmod  open  sshpass  ssh
ssh-keyscan  scp  gh  mdfind  rsync  osascript  defaults
virtualenv  black  isort  code  ghostty  gemini  crontab
uv  uvx  crwl  claude  playwright
```

**特殊匹配**：
- `.venv/bin/*` — 虚拟环境命令
- `~/.claude/*` / `$HOME/.claude/*` / `/Users/*/.claude/*` — Claude 配置脚本

**复合命令解析**（extract_subcommands）：
- 按 `;` `&&` `||` `|` 拆分
- 剥离 `then` `do` `else` `fi` `done` 等 shell 语法
- 剥离环境变量前缀（`KEY="val"`, `KEY='val'`, `KEY=val`）
- 剥离子 shell 括号 `(` `)`
- 跳过 `[` 开头的条件表达式和 `#` 注释行

**审计日志**：`~/.claude/auto-approve-audit.log`

```
2026-02-22 20:51:54 - AUTO-APPROVED (SAFE): git --version
2026-02-22 20:52:01 - AUTO-APPROVED (CAREFUL): npm install express
2026-02-22 20:52:08 - AUTO-APPROVED (CAREFUL-COMPOUND): export PATH=... && uv sync
2026-02-22 20:53:00 - NEEDS-MANUAL: some-unknown-command
```

### 3.3 auto-approve-read.sh — Read 工具

**策略**：全部自动批准，除非是敏感文件。

**敏感文件（拒绝自动批准）**：
- SSH 私钥：`id_rsa`, `id_ed25519`, `.ssh/*`
- 证书：`*.pem`, `*.key`
- 凭证：`*credentials*`
- 云配置：`.aws/*`, `.kube/config`

### 3.4 auto-approve-write.sh — Write/Edit 工具

**策略**：全部自动批准，除非是敏感文件/目录。

**敏感目标（拒绝自动批准）**：
- SSH：`.ssh/*`, `id_rsa*`, `id_ed25519*`
- 证书：`*.pem`
- 云配置：`.aws/*`, `.kube/config`
- 系统目录：`/etc/*`, `/System/*`

### 3.5 auto-approve-tools.sh — 其他工具

**策略**：以下工具全部自动批准：

```
Glob  Grep  WebFetch  Task  TaskOutput  TaskStop
TaskList  TaskGet  TaskUpdate  TaskCreate
```

### 3.6 MCP Inline Hooks

直接在 settings.json 的 hooks 配置中用 `echo` 输出 allow：

| Matcher | 覆盖范围 |
|---------|---------|
| `mcp__yunxiao__.*` | 云效 DevOps 全部工具 |
| `mcp__tavily__.*` | Tavily 搜索/抓取全部工具 |
| `mcp__ucal__.*` | UCal 浏览器自动化全部工具 |

---

## 四、安全层（PreToolUse）

独立于权限层，在权限判定之前执行。

### 4.1 validate-bash.sh — 命令黑名单

**硬阻止（deny）**：
- `rm -rf /` / `rm -rf ~` — 删除根/用户目录
- `chmod 777` / `chmod -R 777` — 不安全权限
- `> /dev/sda` / `dd if=` / `mkfs` — 磁盘破坏
- `:(){ :|:& };:` — Fork 炸弹
- `curl...|...sh` / `wget...|...sh` — 下载执行
- `sudo rm` — 特权删除

**警告不阻止**：
- `rm -rf`（非根目录）
- `DROP TABLE` / `DELETE FROM` / `TRUNCATE`
- `sudo`

### 4.2 protect-files.sh — 文件保护

**硬阻止（deny Write/Edit）**：
- `.env` / `.env.local` / `.env.production`
- `credentials.json` / `secrets.yaml`
- `package-lock.json` / `yarn.lock` / `poetry.lock` / `Pipfile.lock`
- `.git/config`
- `.ssh/` / `id_rsa` / `id_ed25519`
- `.aws/credentials` / `.kube/config`

**警告不阻止**：
- `settings.json` / `config.json`
- `tsconfig.json` / `pyproject.toml`
- `Makefile` / `Dockerfile` / `.gitignore`

---

## 五、文件清单

```
~/.claude/
├── settings.json                    # Layer 1 全局 allow (5条) + hooks 注册
├── settings.local.json              # Layer 1 全局 allow (15条，无密码)
├── auto-approve-audit.log           # 审计日志（auto-approve-safe.sh 写入）
├── AUTO_APPROVE_GUIDE.md            # 本文档
├── sync-config.sh                   # 同步配置（含同步文件列表）
├── sync-to-remote.sh                # 推送到 claude-config 仓库
├── restore-from-remote.sh           # 从远程恢复
└── hooks/
    ├── auto-approve-safe.sh         # Layer 2: Bash 命令批准 (SAFE/CAREFUL)
    ├── auto-approve-read.sh         # Layer 2: Read 工具批准 (排除敏感文件)
    ├── auto-approve-write.sh        # Layer 2: Write/Edit 批准 (排除敏感文件)
    ├── auto-approve-tools.sh        # Layer 2: Glob/Grep/WebFetch/Task 批准
    ├── validate-bash.sh             # 安全层: 危险命令黑名单
    ├── protect-files.sh             # 安全层: 敏感文件保护
    ├── session-start.sh             # SessionStart: 环境信息
    ├── inject-context.sh            # UserPromptSubmit: Git 上下文注入
    ├── auto-format.sh               # PostToolUse: 自动格式化
    ├── README.md                    # Hooks 使用说明
    └── QUICK_REFERENCE.md           # 速查卡

<project>/.claude/
└── settings.local.json              # Layer 1 项目级 allow (hooks 盲区)
└── auto-approve-patterns.txt        # Layer 2 项目级正则模式 (可选)
```

---

## 六、远程同步

| 文件 | 目标仓库 | 同步方式 |
|------|---------|---------|
| `settings.json` | claude-config | Sanitized（token→placeholder, model→删除） |
| `settings.local.json` | claude-config | 原样（整改后无敏感信息） |
| `hooks/` 目录 | claude-config | 原样（纯脚本，无敏感信息） |
| `AUTO_APPROVE_GUIDE.md` | claude-config | 原样 |
| `skills/` 目录 | claude-config + claude-skills | 原样 |

同步命令：`~/.claude/sync-to-remote.sh`

---

## 七、维护操作

### 新增一条 Bash 命令的自动批准

1. 判断属于 SAFE 还是 CAREFUL
2. 编辑 `~/.claude/hooks/auto-approve-safe.sh`
3. 添加到对应的变量（`SAFE_COMMANDS` / `SAFE_GIT` / `CAREFUL_COMMANDS`）
4. **不需要**同时修改 permissions.allow

### 新增一个非 Bash 工具的自动批准

1. 如果是 MCP 工具：在 settings.json hooks 中添加 inline PermissionRequest hook
2. 如果是内置工具：添加到 `auto-approve-tools.sh` 的 case 列表
3. 或者添加到 `settings.json` / `settings.local.json` 的 permissions.allow

### 新增项目特定的 Bash 模式

1. 在项目目录创建 `.claude/auto-approve-patterns.txt`
2. 每行一个正则表达式（ERE 语法）
3. `auto-approve-safe.sh` 会自动读取

### 定期清理

1. 检查 `settings.local.json` 是否有 Claude Code 自动追加的一次性条目
2. 删除 `Bash(fi:*)`, `Bash(done)`, `Bash(if [...])` 等碎片
3. 检查审计日志中的 NEEDS-MANUAL，决定是否加入 hook

```bash
# 查看最近需要手动批准的命令
grep "NEEDS-MANUAL" ~/.claude/auto-approve-audit.log | tail -20

# 查看自动批准统计
echo "SAFE: $(grep -c 'SAFE)' ~/.claude/auto-approve-audit.log)"
echo "CAREFUL: $(grep -c 'CAREFUL)' ~/.claude/auto-approve-audit.log)"
echo "MANUAL: $(grep -c 'NEEDS-MANUAL' ~/.claude/auto-approve-audit.log)"
```

---

## 八、设计决策记录

### D1: 为什么 `open` 放在 allow 而不是 hook CAREFUL

`open` 可以打开任意文件和 URL，放在 CAREFUL 意味着所有 `open` 调用都自动通过。
保留在 allow 中使用前缀匹配 `Bash(open:*)` 更安全——只有直接以 `open` 开头的命令才匹配，
复合命令中的 `open` 不会被 allow 覆盖。

### D2: 为什么 mcp__yunxiao__ 同时在 allow 和 hook 中

Hook 有 5 秒超时和 jq 依赖，如果 hook 故障，allow 中的条目作为兜底。
两层不冲突：allow 先匹配则 hook 不触发。

### D3: 为什么绝对路径命令放在 allow 而不是 hook

`auto-approve-safe.sh` 通过提取命令首 token 匹配（如 `python3`, `uv`），
但 `/opt/homebrew/bin/python3` 的首 token 是完整绝对路径，
不会匹配 SAFE/CAREFUL 列表中的 `python3`。
修改 hook 支持路径解析会增加复杂度，不如直接放 allow。

### D4: 为什么 `git -C` 命令放在 allow

Hook 中 `git` 相关匹配是 `git status`, `git add` 等子命令模式，
`git -C /path remote get-url` 的首 token 是 `git`，第二个 token 是 `-C` 而非子命令，
不匹配任何 SAFE_GIT 或 CAREFUL 模式。

### D5: 2026-02-22 整改 — 从冗余到精简

整改前：permissions.allow 约 250 条（53 + 170 + 30），大量与 hook 重复。
整改后：permissions.allow 约 25 条（5 + 15 + 3），仅保留 hooks 盲区。

删除的关键类别：
- 约 200 条被 hook 覆盖的 Bash 命令
- 5 条含明文密码的 sshpass 命令（安全隐患）
- 约 20 条一次性碎片（fi, done, if [...]）

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 2.0.0 | 2026-02-22 | 重写为架构文档；记录三层体系、整改结果、设计决策 |
| 1.0.0 | 2026-02-05 | 初始版本：Phase 1-4 实施指南 |
