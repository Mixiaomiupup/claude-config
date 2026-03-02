# Claude Code 配置同步系统（cc-sync）

**版本**: 1.0.0
**更新日期**: 2026-03-02
**设计原则**: config 和 skills 分仓管理，manifest 驱动脱敏，双平台镜像推送

---

## 一、系统架构

cc-sync 将 `~/.claude/` 下的配置拆分为两个独立仓库同步，每个仓库同时推送到 GitHub 和云效：

```
~/.claude/  (本地)
  │
  ├─ config 仓库：基础设施（hooks、settings、agents、commands 等）
  │     ↕ push/pull
  │     ├─ GitHub:  Mixiaomiupup/claude-config     (main)
  │     └─ 云效:    Common-Components/claude_config  (master)
  │
  └─ skills 仓库：16 个一方 skill
        ↕ push/pull
        ├─ GitHub:  Mixiaomiupup/claude-skills     (main)
        └─ 云效:    Common-Components/claude_skills  (master)
```

### 关键设计决策

| 决策 | 理由 |
|------|------|
| Config 和 skills 分仓 | Skills 变更频繁、数量多，独立版本控制；config 变更少但涉及安全（settings、hooks） |
| 双平台推送 | GitHub 开源可见，云效国内访问快（pull 默认从 GitHub，skills 优先从云效 clone） |
| Staging 区隔离 | 脱敏在 staging 中完成，本地 `~/.claude/` 始终保留真实凭据 |
| Manifest 驱动脱敏 | 脱敏规则集中在 `component-manifest.json`，新增 skill 只需加一行配置 |
| Lock 文件 | 防止并发 push 导致 staging 区冲突 |

---

## 二、数据流

### Push（local → remote）

```
~/.claude/
  │
  │  ① 复制文件到 staging 区
  ▼
/private/tmp/claude-config-staging/   ← config staging
/private/tmp/claude-skills-staging/   ← skills staging
  │
  │  ② 脱敏（settings.json token → placeholder, skill 文件凭据 → placeholder）
  │  ③ 清理（删除 legacy 文件、skills/ 目录残留）
  ▼
  │  ④ git add -A → diff → 确认 → commit → push
  │
  ├──→ GitHub (main)
  └──→ 云效 (master)
```

### Pull（remote → local）

```
GitHub/云效
  │
  │  ① clone 到 staging 区
  ▼
/private/tmp/claude-config-staging/
/private/tmp/claude-skills-staging/
  │
  │  ② 备份：~/.claude → ~/.claude.backup.YYYYMMDD_HHMMSS
  │  ③ 复制文件到 ~/.claude/
  │  ④ 智能合并 settings.json（保留本地 token，其余用远程覆盖）
  │  ⑤ 自动 clone 第三方 skills（按 manifest 配置）
  │  ⑥ 修复权限（hooks/*.sh, cc-sync → +x）
  ▼
~/.claude/  (已恢复)
```

---

## 三、同步内容清单

### Config 仓库

| 类别 | 内容 | 说明 |
|------|------|------|
| **核心文件** | `CLAUDE.md`, `AUTO_APPROVE_GUIDE.md`, `CONFIG_PACKAGE_GUIDE.md`, `CC_SYNC_GUIDE.md` | 原样同步 |
| **设置** | `settings.local.json` | 原样（已整改，无敏感信息） |
| **设置（脱敏）** | `settings.json` | `ANTHROPIC_AUTH_TOKEN` → `YOUR_TOKEN_HERE`；`model` 字段删除 |
| **目录** | `hooks/`, `agents/`, `commands/`, `output-styles/` | rsync --delete 完整同步 |
| **Plans 基础设施** | `plans/README.md`, `plans/PLANS_INDEX.md`, `plans/templates/` | 仅基础设施，不含实际计划 |
| **插件** | `plugins/`（排除 `cache/`, `marketplaces/`） | 插件配置但不含缓存 |
| **同步基础设施** | `sync-config.sh`, `cc-sync`, `component-manifest.json` | 保证新机器能自举 |

### Skills 仓库

| 类别 | 内容 | 说明 |
|------|------|------|
| **一方 skills（16 个）** | commit, debug, doc-control, explain, gemini-image, kb, lark-mcp, python-style, refactor, remote-repos, review, server, sync-config, test, ucal, x2md | rsync 同步 |
| **脱敏的 skills** | `server/SKILL.md`（密码、IP → 占位符）, `gemini-image/SKILL.md`（GCP 凭据 → 占位符） | 按 manifest patterns 正则替换 |
| **排除** | `baoyu-skills` | 有自己的 git 仓库，pull 时自动从 manifest 中 clone |

### 不同步的内容

| 内容 | 原因 |
|------|------|
| `settings.json` 中的真实 token | 脱敏后同步 |
| `plans/` 下的实际计划文件 | 项目特定，不属于通用配置 |
| `projects/` | 项目特定配置 |
| `plugins/cache/`, `plugins/marketplaces/` | 运行时数据 |
| `baoyu-skills/` | 三方 skill，有独立仓库 |
| `auto-approve-audit.log` | 运行时日志 |

---

## 四、命令参考

### Push（日常同步到远程）

```bash
# 推送全部（config + skills）到全部平台（GitHub + 云效）
~/.claude/cc-sync push

# 仅推送 config
~/.claude/cc-sync push --target config

# 仅推送 skills
~/.claude/cc-sync push --target skills

# 仅推送到 GitHub
~/.claude/cc-sync push --platform github

# 仅推送到云效
~/.claude/cc-sync push --platform yunxiao

# 预览变更（不提交不推送）
~/.claude/cc-sync push --dry-run

# 跳过确认提示
~/.claude/cc-sync push --yes

# 自定义提交信息
~/.claude/cc-sync push -m "feat: add lark-mcp block API docs"

# 组合选项
~/.claude/cc-sync push --target skills --platform github --dry-run
```

### Pull（从远程恢复）

```bash
# 拉取全部（config + skills）从 GitHub
~/.claude/cc-sync pull

# 仅拉取 config
~/.claude/cc-sync pull --target config

# 仅拉取 skills
~/.claude/cc-sync pull --target skills

# 从云效拉取
~/.claude/cc-sync pull --from yunxiao

# 预览将要恢复的内容
~/.claude/cc-sync pull --dry-run
```

### Status（查看同步状态）

```bash
~/.claude/cc-sync status
```

输出示例：
```
=== cc-sync status ===

[config]
  staging: /private/tmp/claude-config-staging
  last sync: 2026-03-02 10:30:00 +0800
  last commit: abc1234 sync: config sync 2026-03-02 10:30
  status: ✓ up to date (files checked)

[skills]
  staging: /private/tmp/claude-skills-staging
  last sync: 2026-03-02 10:30:05 +0800
  last commit: def5678 sync: skills sync 2026-03-02 10:30

[first-party skills]
  found: 16 / 16

[third-party skills]
  ✓ baoyu-skills → https://github.com/jimliu/baoyu-skills.git
```

---

## 五、脱敏机制

### 脱敏时机

脱敏发生在 **push 的 staging 区**，不修改本地文件：

```
~/.claude/settings.json          ← 真实 token（不变）
     │ cp
     ▼
/private/tmp/staging/settings.json  ← 脱敏后（token → YOUR_TOKEN_HERE）
     │ git push
     ▼
GitHub/云效                      ← 安全的
```

### 脱敏规则

集中管理在 `~/.claude/component-manifest.json` 的 `sanitize` 字段：

#### settings.json 脱敏

```json
{
  "settings.json": {
    "replace_env_keys": ["ANTHROPIC_AUTH_TOKEN"],
    "strip_fields": ["model"]
  }
}
```

- `replace_env_keys`：`.env.KEY` 的值替换为 `YOUR_TOKEN_HERE`
- `strip_fields`：删除顶级字段（`model` 是用户偏好，不应强制同步）

#### Skill 文件脱敏

```json
{
  "skills/server/SKILL.md": {
    "patterns": [
      ["mi954993689\\.", "YOUR_PASSWORD_HERE"],
      ["106\\.15\\.125\\.84", "YOUR_SERVER_IP"],
      ["172\\.24\\.17\\.232", "YOUR_PRIVATE_IP"]
    ]
  },
  "skills/gemini-image/SKILL.md": {
    "patterns": [
      ["uxfv3f-ogqz-cc08ce285c88\\.json", "YOUR_SERVICE_ACCOUNT_FILE"],
      ["uxfv3f-ogqz", "YOUR_GCP_PROJECT"]
    ]
  }
}
```

每个 pattern 是 `[正则模式, 替换文本]`，用 `sed` 在 staging 中执行。

### 还原时的 token 保留

Pull 时 `settings.json` 用**合并策略**：

```
远程 settings.json (token = YOUR_TOKEN_HERE)
     +
本地 settings.json (token = sk-ant-xxx...)
     =
合并结果 (token = sk-ant-xxx...)  ← 保留本地真实值
```

仅当本地 token 存在且不是占位符时才保留；否则用远程值（提醒用户手动设置）。

### 新增 skill 的脱敏

如果新 skill 包含敏感信息（密码、IP、凭据），在 `component-manifest.json` 的 `sanitize` 中添加：

```json
"skills/<skill-name>/SKILL.md": {
  "patterns": [
    ["<敏感正则>", "<占位符>"]
  ]
}
```

---

## 六、新机器自举

### 最小自举（3 条命令）

```bash
# 1. 克隆 config 仓库
git clone git@github.com:Mixiaomiupup/claude-config.git /tmp/cc

# 2. 复制自举三件套
cp /tmp/cc/{cc-sync,sync-config.sh,component-manifest.json} ~/.claude/
chmod +x ~/.claude/cc-sync

# 3. 拉取全部
~/.claude/cc-sync pull
```

### 自举后检查清单

| 检查项 | 命令 | 预期 |
|--------|------|------|
| 配置完整性 | `~/.claude/cc-sync status` | 16/16 skills found |
| Token 设置 | `grep TOKEN ~/.claude/settings.json` | 应为真实 token，不是 `YOUR_TOKEN_HERE` |
| Hook 权限 | `ls -la ~/.claude/hooks/*.sh` | 全部 +x |
| 三方 skill | `ls ~/.claude/skills/baoyu-skills/` | 存在且有内容 |
| 测试运行 | `claude` | 正常启动 |

### 如果 Token 是占位符

Pull 后如果 `settings.json` 中的 token 仍是 `YOUR_TOKEN_HERE`（新机器首次拉取）：

```bash
# 手动设置 token
jq '.env.ANTHROPIC_AUTH_TOKEN = "sk-ant-your-real-token"' \
  ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```

或直接在 Claude Code 中设置环境变量。

---

## 七、component-manifest.json

中央注册表，管理仓库地址、skill 清单、脱敏规则：

```json
{
  "version": "1.0.0",
  "remotes": {
    "config": { "github": "...", "yunxiao": "..." },
    "skills": { "github": "...", "yunxiao": "..." }
  },
  "skills": {
    "first-party": ["commit", "debug", ...],
    "third-party": {
      "baoyu-skills": { "url": "https://github.com/...", "branch": "main" }
    }
  },
  "sanitize": { ... }
}
```

### 常见操作

**添加新的一方 skill**：
1. 在 `skills.first-party` 数组中添加名称
2. 如有敏感内容，在 `sanitize` 中添加 pattern
3. 运行 `cc-sync push --target skills`

**添加新的三方 skill**：
1. 在 `skills.third-party` 中添加条目
2. 在 `EXCLUDE_SKILLS` 数组中添加名称（`sync-config.sh`）
3. 手动 clone：`git clone <url> ~/.claude/skills/<name>`
4. 运行 `cc-sync push --target config`（同步 manifest 变更）

**更换远程仓库地址**：
1. 修改 `remotes` 中的 URL
2. 同步修改 `sync-config.sh` 中的对应变量
3. 运行 `cc-sync push`

---

## 八、文件清单

```
~/.claude/
├── cc-sync                          # 主 CLI（本文档描述的工具）
├── sync-config.sh                   # 共享配置（仓库 URL、同步文件列表）
├── component-manifest.json          # 中央注册表（仓库、skills、脱敏规则）
├── CC_SYNC_GUIDE.md                 # 本文档
│
├── settings.json                    # 全局设置（push 时脱敏）
├── settings.local.json              # 全局设置（原样同步，无敏感信息）
├── CLAUDE.md                        # 全局 Claude 指令
├── AUTO_APPROVE_GUIDE.md            # 自动批准系统文档
├── CONFIG_PACKAGE_GUIDE.md          # 旧版打包指南（已被 cc-sync 取代）
│
├── hooks/                           # 自动批准 + 安全拦截脚本
├── agents/                          # Agent 配置
├── commands/                        # 自定义命令
├── output-styles/                   # 输出样式
├── plans/                           # 规划系统（仅同步基础设施）
│   ├── README.md                    # ← 同步
│   ├── PLANS_INDEX.md               # ← 同步
│   ├── templates/                   # ← 同步
│   └── *.md                         # ← 不同步（项目特定）
├── plugins/                         # 插件（排除 cache）
│
└── skills/                          # Skills 目录
    ├── commit/                      # ← skills 仓库
    ├── debug/                       # ← skills 仓库
    ├── ...                          # ← 共 16 个一方 skill
    └── baoyu-skills/                # ← 三方，独立 git 仓库

/private/tmp/
├── claude-config-staging/           # Config 仓库 staging 区
├── claude-skills-staging/           # Skills 仓库 staging 区
└── claude-config-sync.lock          # 并发锁
```

---

## 九、Skill 与 CLI 的关系

| 组件 | 位置 | 用户 | 职责 |
|------|------|------|------|
| **cc-sync CLI** | `~/.claude/cc-sync` (config 仓库) | 人 / Claude | 实际执行 push/pull/status 的 Bash 脚本 |
| **sync-config skill** | `~/.claude/skills/sync-config/` (skills 仓库) | Claude | 告诉 Claude 何时用、怎么用 cc-sync |
| **CC_SYNC_GUIDE.md** | `~/.claude/CC_SYNC_GUIDE.md` (config 仓库) | 人 | 系统架构文档（本文） |

Claude 通过 `sync-config` skill 知道用户说「同步」时应运行 `cc-sync push`；
人通过本文档理解整个系统的设计和维护方法。

---

## 十、推荐工作流

### 日常同步（改了配置/skill 后）

```bash
# 1. 预览
~/.claude/cc-sync push --dry-run

# 2. 确认后推送
~/.claude/cc-sync push -m "feat: add lark-mcp block API"
```

或在 Claude Code 中直接说「sync」，Claude 会调用 sync-config skill。

### 换机器

```bash
# 新机器：
git clone git@github.com:Mixiaomiupup/claude-config.git /tmp/cc
cp /tmp/cc/{cc-sync,sync-config.sh,component-manifest.json} ~/.claude/
chmod +x ~/.claude/cc-sync
~/.claude/cc-sync pull
# 设置 token
```

### 定期维护

```bash
# 检查状态
~/.claude/cc-sync status

# 检查 manifest 中的 skill 数量是否与实际一致
ls ~/.claude/skills/ | wc -l
jq '.skills["first-party"] | length' ~/.claude/component-manifest.json
```

---

## 十一、故障排查

| 问题 | 原因 | 解决 |
|------|------|------|
| `Another sync is running` | 上次 push 异常退出，锁未释放 | `rm /private/tmp/claude-config-sync.lock` |
| Push 报 `remote rejected` | 远程有未合并的变更 | `cd /private/tmp/claude-*-staging && git pull --rebase && cc-sync push` |
| Pull 后 token 是占位符 | 新机器首次 pull，本地无真实 token | 手动设置 `ANTHROPIC_AUTH_TOKEN` |
| Skill 脱敏没生效 | manifest 中未添加该 skill 的 pattern | 在 `component-manifest.json` 的 `sanitize` 中添加 |
| `jq: command not found` | 依赖缺失 | `brew install jq` |
| Push 时 staging 区冲突 | staging 区被手动修改 | `rm -rf /private/tmp/claude-*-staging` 后重新 push |
| 三方 skill 未 clone | manifest 中配置但本地不存在 | `cc-sync pull --target skills` 或手动 clone |
| hooks 无执行权限 | Pull 后权限丢失 | `chmod +x ~/.claude/hooks/*.sh ~/.claude/cc-sync` |
| 旧脚本仍在运行 | 使用了 `sync-to-remote.sh` 等已废弃脚本 | 改用 `cc-sync push`；旧脚本会在 push 时从 staging 中自动清理 |

---

## 十二、设计决策记录

### D1: 为什么 config 和 skills 分仓

Skills 数量多（16+）、更新频繁（几乎每天改）、每个 skill 独立完整。Config 更新少但涉及安全（hooks、settings）。分仓后：
- Skills 仓库提交历史清晰（每个 skill 的变更可独立追踪）
- Config 仓库不会被 skill 变更淹没
- 可以只同步 config 不动 skills（反之亦然）

### D2: 为什么用 staging 区而不直接在 ~/.claude/ 做 git

`~/.claude/` 目录包含大量运行时文件（audit log、projects/、cache 等），如果直接做 git 仓库会非常混乱。Staging 区只包含需要同步的文件，干净且可控。

### D3: 为什么双平台同时推送

GitHub 面向开源社区，方便他人参考。云效在国内访问快，作为工作环境的首选拉取源。两者内容完全相同，只是 branch 名不同（GitHub 用 `main`，云效用 `master`）。

### D4: 为什么脱敏用正则替换而不是 .gitignore

需要同步的文件（如 `settings.json`、`server/SKILL.md`）整体有用，只是其中几个字段含敏感信息。`.gitignore` 只能整文件排除。正则替换可以精确到字段级别，保留文件结构的同时去除敏感值。

### D5: Pull 时为什么备份整个 ~/.claude/

Pull 是覆盖操作。如果远程版本有问题（比如脱敏后的 token 覆盖了本地真实 token），用户需要回滚。自动备份到 `~/.claude.backup.YYYYMMDD_HHMMSS/` 提供了安全网。

### D6: 为什么三方 skills 用 manifest 管理而不是 git submodule

Git submodule 在 staging 区模型下很难管理（staging 区是临时的，每次 push 可能重新 clone）。Manifest 记录 URL 和 branch，pull 时按需 clone，更简单可靠。

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-03-02 | 初始版本：完整架构文档 |
