# Claude Code 配置仓库

这是我的 Claude Code 个人配置仓库，包含全局配置、自定义 hooks、技能和权限系统优化。

## 📁 仓库结构

```
claude-config/
├── README.md                     # 本文件
├── CLAUDE.md                     # 全局配置文档（核心）
├── AUTO_APPROVE_GUIDE.md         # 权限自动批准系统使用指南
├── CONFIG_PACKAGE_GUIDE.md       # 配置包使用指南
├── settings.json                 # 全局设置（已脱敏）
├── settings.local.json           # 用户扩展设置
├── sync-config.sh                # 同步共享配置
├── sync-to-remote.sh             # 本地 → 远程同步脚本
├── restore-from-remote.sh        # 远程 → 本地恢复脚本
├── skill-sources.json            # 第三方 skill 来源记录
├── hooks/                        # Hook 脚本
│   ├── auto-approve-safe.sh     # 权限自动批准（激进模式）
│   ├── validate-bash.sh         # Bash 命令验证
│   ├── protect-files.sh         # 文件保护
│   ├── auto-format.sh           # 自动格式化
│   ├── inject-context.sh        # 上下文注入
│   ├── session-start.sh         # 会话启动
│   ├── list-permissions.sh      # 列出权限配置
│   ├── test-permission.sh       # 测试权限
│   └── validate-config.sh       # 配置验证
├── skills/                       # 自定义技能
│   ├── commit/                  # Git commit 消息生成
│   ├── debug/                   # 系统化调试
│   ├── explain/                 # 代码解释
│   ├── python-style/            # Python 代码风格检查
│   ├── refactor/                # 代码重构建议
│   ├── review/                  # 代码审查
│   ├── test/                    # 测试生成
│   ├── doc-control/             # 文档控制
│   └── x2md/                    # X/Twitter 转 Markdown
├── agents/                       # 自定义 agent 定义
│   ├── bug-analyzer.md
│   ├── code-reviewer.md
│   ├── dev-planner.md
│   ├── story-generator.md
│   └── ui-sketcher.md
├── commands/                     # 自定义命令
│   └── commit.md
├── output-styles/                # 输出样式
│   ├── coding-vibes.md
│   └── structural-thinking.md
├── plans/                        # 规划系统基础设施
│   ├── README.md
│   ├── PLANS_INDEX.md
│   └── templates/
├── plugins/                      # 插件清单
│   └── installed_plugins.json
└── docs/                         # 文档
    └── CONFIG_PACKAGE_GUIDE.md  # 配置包指南
```

## 🚀 快速开始

### 安装配置

1. **克隆仓库**
```bash
git clone git@github.com:Mixiaomiupup/claude-config.git
cd claude-config
```

2. **备份现有配置**（如果有）
```bash
cp -r ~/.claude ~/.claude.backup.$(date +%Y%m%d)
```

3. **安装配置文件**
```bash
# 复制主配置文件
cp CLAUDE.md ~/.claude/
cp AUTO_APPROVE_GUIDE.md ~/.claude/
cp settings.json ~/.claude/
cp settings.local.json ~/.claude/

# 复制 hooks（保留可执行权限）
cp -r hooks/* ~/.claude/hooks/
chmod +x ~/.claude/hooks/*.sh

# 复制 skills
cp -r skills/* ~/.claude/skills/
```

4. **配置敏感信息**

编辑 `~/.claude/settings.json`，替换以下内容：
- `ANTHROPIC_AUTH_TOKEN`: 你的 API Token
- `ANTHROPIC_BASE_URL`: 根据需要修改（默认使用 BigModel 代理）

```bash
# 使用你的 token 替换
export YOUR_TOKEN="sk-ant-..."
jq ".env.ANTHROPIC_AUTH_TOKEN = \"$YOUR_TOKEN\"" ~/.claude/settings.json > ~/.claude/settings.json.tmp
mv ~/.claude/settings.json.tmp ~/.claude/settings.json
```

5. **验证配置**
```bash
~/.claude/hooks/validate-config.sh
```

## 🎯 核心特性

### 1. 权限自动批准系统（激进模式）

**效果**: 减少 80%+ 手动权限批准

**特点**:
- ✅ 静默批准只读命令（ls, git status, cat 等）
- ✅ 通知后批准写操作（git commit, npm install 等）
- ✅ 保留危险命令拦截（rm -rf /, chmod 777 等）
- ✅ 完整审计日志记录

**使用**:
```bash
# 查看所有权限
~/.claude/hooks/list-permissions.sh

# 测试命令
~/.claude/hooks/test-permission.sh "git commit"

# 查看审计日志
tail -f ~/.claude/auto-approve-audit.log
```

详见: [AUTO_APPROVE_GUIDE.md](AUTO_APPROVE_GUIDE.md)

### 2. 全局开发工作流

**Level 1-3 分级管理**:
- Level 1: 文件级修改（直接实施）
- Level 2: 模块级功能（可选 brainstorming）
- Level 3: 系统级架构（必需 brainstorming → writing-plans → executing-plans）

**代码质量标准**:
- Python: PEP 8 + type hints + Google docstrings
- Git: Google convention style commits
- Testing: 上下文相关覆盖率目标

详见: [CLAUDE.md](CLAUDE.md)

### 3. 自定义技能

**已安装技能**:
- `commit` - Git commit 消息生成（Google 风格）
- `debug` - 系统化调试流程
- `explain` - 代码解释（类比 + 图表）
- `python-style` - Python 代码风格检查
- `refactor` - 重构建议
- `review` - 代码审查
- `test` - 测试用例生成
- `doc-control` - 智能文档生成控制
- `baoyu-skills` - Baoyu 技能集（额外功能）

**使用示例**:
```bash
claude skill commit
claude skill python-style
claude skill debug
```

### 4. Hooks 系统

**PreToolUse Hooks**:
- `validate-bash.sh` - 阻止危险 Bash 命令
- `protect-files.sh` - 保护敏感文件（.env, SSH keys）

**PostToolUse Hooks**:
- `auto-format.sh` - 自动格式化代码

**PermissionRequest Hooks**:
- `auto-approve-safe.sh` - 自动批准安全命令

**SessionStart Hooks**:
- `session-start.sh` - 会话初始化

**UserPromptSubmit Hooks**:
- `inject-context.sh` - 注入 Git 上下文

## 📊 权限配置统计

- **全局白名单**: 147 条命令模式
- **SAFE_PATTERNS**: 60+ 条（静默批准）
- **CAREFUL_PATTERNS**: 41 条（通知+批准）
- **审计日志**: 启用标准审计

## 🔒 安全特性

### 危险命令拦截
- `rm -rf /`, `rm -rf ~`
- `chmod 777`, `chown -R`
- `dd if=/dev/zero`
- `curl | sh`, `wget | bash`
- Fork bombs: `:(){ :|:& };:`

### 敏感文件保护
- `.env`, `.env.local`
- `credentials.json`, `secrets.yaml`
- `.git/config`
- SSH 密钥文件
- API token 文件

### 审计追踪
所有自动批准的命令记录到 `~/.claude/auto-approve-audit.log`：
```
2026-02-05 22:36:46 - AUTO-APPROVED (SAFE): ls -la
2026-02-05 22:36:48 - AUTO-APPROVED (CAREFUL): npm install
```

## 🛠️ 自定义配置

### 添加项目特定权限

在项目目录创建 `.claude/settings.json`:
```json
{
  "permissions": {
    "allow": [
      "Bash(your-command:*)"
    ]
  }
}
```

### 添加项目特定模式

在项目目录创建 `.claude/auto-approve-patterns.txt`:
```bash
# 项目特定自动批准模式
^your-command
^your-pattern.*
```

### 修改全局配置

编辑 `~/.claude/CLAUDE.md` 自定义：
- 开发工作流
- 代码质量标准
- 文档策略
- Superpowers 技能整合

## 📖 文档

- [CLAUDE.md](CLAUDE.md) - 完整的全局配置文档
- [AUTO_APPROVE_GUIDE.md](AUTO_APPROVE_GUIDE.md) - 权限自动批准系统详解
- [CONFIG_PACKAGE_GUIDE.md](docs/CONFIG_PACKAGE_GUIDE.md) - 配置包使用指南

## 🔄 配置同步

本仓库使用自动化脚本实现 `~/.claude/` 到远程仓库的单向同步。

### 同步到远程（日常使用）

```bash
# 预览变更（不提交）
~/.claude/sync-to-remote.sh --dry-run

# 同步并推送（会提示确认）
~/.claude/sync-to-remote.sh

# 自定义提交信息
~/.claude/sync-to-remote.sh -m "feat: add new skill"
```

脚本自动处理：
- `settings.json` 脱敏（替换 token、删除 model 字段）
- 排除第三方 skill（如 baoyu-skills），仅记录其 git URL 到 `skill-sources.json`
- 排除运行时数据、缓存、临时文件
- 同步 agents、commands、output-styles、plans 基础设施、插件清单

### 新机器恢复

```bash
# 1. 获取恢复脚本
git clone git@github.com:Mixiaomiupup/claude-config.git /tmp/claude-config
cp /tmp/claude-config/restore-from-remote.sh ~/.claude/

# 2. 预览恢复内容
~/.claude/restore-from-remote.sh --dry-run

# 3. 执行完整恢复（自动备份现有配置）
~/.claude/restore-from-remote.sh

# 4. 选择性恢复
~/.claude/restore-from-remote.sh --only skills hooks
```

恢复脚本自动处理：
- 备份现有 `~/.claude/` 到 `~/.claude.backup.YYYYMMDD_HHMMSS/`
- `settings.json` 合并策略：保留本地 token，其余从仓库恢复
- 根据 `skill-sources.json` 自动 `git clone` 第三方 skill
- 恢复 hook 可执行权限

## 🎨 配置亮点

### 1. 智能文档生成控制
- Level 1-3 分级决策树
- 避免过度生成文档
- 项目文档模式（strict/standard/comprehensive）

### 2. 双轨规划系统
- **Superpowers 工作流**: 细粒度实施计划（`docs/plans/`）
- **架构文档**: 高层设计记录（`docs/ARCHITECTURE.md`）

### 3. 激进权限模式
- 最大化自动批准（80%+）
- 完整审计追踪
- 保持安全边界

### 4. 质量门控系统
- **本地检查**: ruff format + ruff check（预提交）
- **远程检查**: mypy + pytest + security scan（CI/CD）

## 🐛 故障排查

### Hook 不执行
```bash
# 检查权限
ls -la ~/.claude/hooks/*.sh

# 添加执行权限
chmod +x ~/.claude/hooks/*.sh
```

### 命令仍需手动批准
```bash
# 测试命令匹配
~/.claude/hooks/test-permission.sh "your-command"

# 检查配置
~/.claude/hooks/validate-config.sh
```

### 审计日志不工作
```bash
# 检查日志文件
ls -la ~/.claude/auto-approve-audit.log

# 手动创建
touch ~/.claude/auto-approve-audit.log
```

## 📈 版本历史

### v1.0.0 (2026-02-05)
- ✅ 激进权限自动批准系统
- ✅ 全局 CLAUDE.md 配置文档（v3.1.0）
- ✅ 工具脚本集（list/test/validate）
- ✅ 自定义技能集成
- ✅ 完整 Hooks 系统

## 🤝 贡献

这是个人配置仓库，但欢迎：
- 提出改进建议（Issues）
- 分享你的配置思路（Discussions）
- Fork 并定制为你自己的配置

## 📄 许可

MIT License - 自由使用和修改

## 🙏 致谢

- [Claude Code](https://claude.com/claude-code) - 官方 CLI 工具
- [Superpowers](https://github.com/anthropics/superpowers) - 技能市场
- 社区贡献者

---

**维护者**: [@Mixiaomiupup](https://github.com/Mixiaomiupup)
**更新日期**: 2026-02-05
**Claude Code 版本**: Latest
