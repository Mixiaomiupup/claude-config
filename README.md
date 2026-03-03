# Claude Code 配置仓库

个人 Claude Code 全局配置，包含自动批准权限系统、hooks、技能和开发工作流。

## 文档导航

| 文档 | 说明 |
|------|------|
| [AUTO_APPROVE_GUIDE.md](AUTO_APPROVE_GUIDE.md) | **自动批准系统架构** — 三层权限体系、设计决策、维护操作 |
| [CLAUDE.md](CLAUDE.md) | **全局开发工作流** — Level 1-3 分级、代码标准、Superpowers 整合 |
| [CONFIG_PACKAGE_GUIDE.md](CONFIG_PACKAGE_GUIDE.md) | **配置包指南** — 安装/恢复/同步说明 |
| [CC_SYNC_GUIDE.md](CC_SYNC_GUIDE.md) | **cc-sync 使用指南** — push/pull/status 命令详解 |
| [MCP_SERVERS.md](MCP_SERVERS.md) | **MCP 服务器配置** — 新机器密钥填写指南 |
| [hooks/README.md](hooks/README.md) | **Hooks 使用说明** — 各 hook 分类、自定义方法、调试 |
| [hooks/QUICK_REFERENCE.md](hooks/QUICK_REFERENCE.md) | **Hooks 速查卡** — 一页纸速查 |

---

## 仓库结构

```
claude-config/
├── README.md                        # 本文件（导航入口）
├── AUTO_APPROVE_GUIDE.md            # 自动批准系统架构文档
├── CLAUDE.md                        # 全局开发工作流配置
├── CONFIG_PACKAGE_GUIDE.md          # 配置包使用指南
├── CC_SYNC_GUIDE.md                 # cc-sync 使用指南
├── MCP_SERVERS.md                   # MCP 服务器新机器配置指南
│
├── settings.json                    # 全局设置（已脱敏：token→placeholder, model→删除）
├── settings.local.json              # 扩展设置（hooks 盲区的工具/命令）
├── mcp-servers.json                 # MCP 服务器配置（已脱敏，push 时从 ~/.claude.json 提取）
├── component-manifest.json          # 组件清单（skills 来源、脱敏规则）
│
├── cc-sync                          # 统一同步 CLI（push/pull/status）
├── sync-config.sh                   # 同步共享配置变量
│
├── hooks/                           # Hook 脚本
│   ├── auto-approve-safe.sh         # Bash 命令自动批准（SAFE/CAREFUL/COMPOUND）
│   ├── auto-approve-read.sh         # Read 工具自动批准（敏感文件除外）
│   ├── auto-approve-write.sh        # Write/Edit 自动批准（敏感文件除外）
│   ├── auto-approve-tools.sh        # Glob/Grep/WebFetch/Task 自动批准
│   ├── validate-bash.sh             # 危险命令黑名单（PreToolUse）
│   ├── protect-files.sh             # 敏感文件保护（PreToolUse）
│   ├── auto-format.sh               # 代码自动格式化（PostToolUse）
│   ├── inject-context.sh            # Git 上下文注入（UserPromptSubmit）
│   ├── session-start.sh             # 环境信息显示（SessionStart）
│   ├── README.md                    # Hooks 使用说明
│   └── QUICK_REFERENCE.md           # Hooks 速查卡
│
├── skills/                          # 自定义技能
│   ├── commit/                      # Git commit 消息（Google 风格）
│   ├── debug/                       # 系统化调试
│   ├── doc-control/                 # 文档生成控制
│   ├── explain/                     # 代码解释
│   ├── kb/                          # Obsidian 知识库管理
│   ├── python-style/                # Python PEP 8 检查
│   ├── refactor/                    # 代码重构建议
│   ├── remote-repos/                # 远程仓库操作
│   ├── review/                      # 代码审查
│   ├── gemini-image/                 # Gemini AI 图片工具
│   ├── lark-mcp/                    # 飞书 MCP 集成
│   ├── server/                      # 服务器管理
│   ├── sync-config/                 # 配置同步
│   ├── test/                        # 测试生成
│   ├── ucal/                        # 跨平台内容分析
│   └── x2md/                        # X/Twitter 转 Markdown
│
├── agents/                          # 自定义 agent 定义
├── commands/                        # 自定义命令
├── output-styles/                   # 输出样式
├── plans/                           # 规划系统基础设施
│   ├── README.md
│   ├── PLANS_INDEX.md
│   └── templates/
└── plugins/                         # 插件清单
    └── installed_plugins.json
```

---

## 自动批准系统概览

三层权限体系，匹配即终止：

```
① permissions.allow (settings.json 5条 + settings.local.json 15条)
   非 Bash 工具、绝对路径命令、特殊前缀 → 直接通过

② PermissionRequest hooks
   auto-approve-safe.sh  → Bash: SAFE 静默 / CAREFUL 通知 / COMPOUND 拆分
   auto-approve-read.sh  → Read: 全部（敏感文件除外）
   auto-approve-write.sh → Write/Edit: 全部（敏感文件除外）
   auto-approve-tools.sh → Glob/Grep/WebFetch/Task: 全部
   inline hooks          → mcp__yunxiao/tavily/ucal/lark-mcp__: 全部

③ 弹窗问用户
```

安全层（PreToolUse）独立于权限层，优先执行：
- `validate-bash.sh` 阻止 `rm -rf /`, `chmod 777`, fork 炸弹等
- `protect-files.sh` 阻止修改 `.env`, SSH keys, lock 文件等

详细架构见 [AUTO_APPROVE_GUIDE.md](AUTO_APPROVE_GUIDE.md)。

---

## 快速开始

### 新机器恢复

```bash
# 1. Bootstrap
git clone git@github.com:Mixiaomiupup/claude-config.git /tmp/cc
cp /tmp/cc/{cc-sync,sync-config.sh,component-manifest.json} ~/.claude/
chmod +x ~/.claude/cc-sync

# 2. Pull 全部配置和 skills
~/.claude/cc-sync pull

# 3. 填入密钥
#    - ~/.claude/settings.json 中的 ANTHROPIC_AUTH_TOKEN
#    - ~/.claude.json 中搜索 YOUR_ 填入 MCP 密钥（见 MCP_SERVERS.md）
```

恢复脚本自动处理：
- 备份现有 `~/.claude/` 到 `~/.claude.backup.YYYYMMDD_HHMMSS/`
- `settings.json` 合并：保留本地 token，其余从仓库恢复
- MCP 配置合并：保留本地密钥，新增 repo 中的服务器
- 根据 `component-manifest.json` 自动 clone 第三方 skill
- 恢复 hook 可执行权限

### 日常同步

```bash
~/.claude/cc-sync push --dry-run         # 预览变更
~/.claude/cc-sync push                   # 同步并推送（会提示确认）
~/.claude/cc-sync push -m "message"      # 自定义提交信息
~/.claude/cc-sync status                 # 查看同步状态
```

脱敏处理：
- `settings.json`：`ANTHROPIC_AUTH_TOKEN` → `"YOUR_TOKEN_HERE"`，`model` 字段删除
- `mcp-servers.json`：API key → 占位符，lark 密钥 → 占位符，路径 → `$HOME`

---

## 版本

| 组件 | 版本 | 更新日期 |
|------|------|---------|
| 自动批准系统架构 | 2.1.0 | 2026-02-23 |
| 全局工作流 (CLAUDE.md) | 3.1.0 | 2026-02-05 |
| 配置同步系统 | 1.0.0 | 2026-02-05 |
| 能力全景指南 | 1.0.0 | 2026-03-01 |

---

**维护者**: [@Mixiaomiupup](https://github.com/Mixiaomiupup)
