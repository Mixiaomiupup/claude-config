# Claude Code Hooks 使用指南

这是一套完整的 Claude Code hooks 配置，用于提升开发效率和安全性。

## 📁 文件结构

```
~/.claude/
├── settings.json                    # 全局配置（已配置 hooks）
└── hooks/
    ├── session-start.sh             # 会话启动时显示环境信息
    ├── inject-context.sh            # 自动注入 Git 上下文
    ├── validate-bash.sh             # 验证并阻止危险命令
    ├── protect-files.sh             # 保护关键文件不被修改
    ├── auto-format.sh               # 自动格式化代码
    ├── auto-approve-safe.sh         # 自动批准安全命令
    ├── project-settings-template.json  # 项目级配置模板
    └── README.md                    # 本文档
```

---

## ✨ 已配置的 Hooks

### 1. SessionStart - 会话启动

**功能**: 显示环境信息

**触发时机**: 每次启动 Claude Code 会话

**输出示例**:
```
🚀 Claude Code 会话已启动
📍 工作目录: /Users/mixiaomiupup/project
🐍 Python: Python 3.11.5
📦 Node: v20.10.0
🔧 Git: git version 2.42.0
🌿 Git 分支: main
```

---

### 2. UserPromptSubmit - 提示词提交

**功能**: 自动注入 Git 上下文信息

**触发时机**: 每次你向 Claude 发送消息前

**输出示例**:
```
📌 当前分支: feature/auth
📝 最近提交:
  a1b2c3d Add login endpoint
  e4f5g6h Update user model
  i7j8k9l Fix validation bug
⚠️  有 3 个未提交的更改
```

**好处**: Claude 自动知道你在哪个分支、最近做了什么，无需手动解释。

---

### 3. PreToolUse - 执行前验证

#### 3a. Bash 命令验证 (`validate-bash.sh`)

**功能**: 阻止危险命令

**阻止的命令**:
- `rm -rf /` - 删除根目录
- `chmod 777` - 不安全的权限
- `dd if=` - 危险的磁盘操作
- `:(){ :|:& };:` - Fork 炸弹
- `curl ... | sh` - 下载并执行

**警告但不阻止**:
- `rm -rf` - 需要用户确认
- `sudo` - 需要用户确认
- `DELETE FROM` - 数据库操作

#### 3b. 文件保护 (`protect-files.sh`)

**功能**: 保护关键文件不被修改

**完全阻止修改**:
- `.env`, `.env.local` - 环境变量
- `credentials.json`, `secrets.yaml` - 凭证
- `package-lock.json`, `yarn.lock` - 锁文件
- `.git/config` - Git 配置
- `.ssh/`, `id_rsa` - SSH 密钥
- `.aws/credentials` - AWS 凭证

**警告但允许修改**:
- `settings.json`, `config.json`
- `tsconfig.json`, `pyproject.toml`
- `Dockerfile`, `Makefile`

---

### 4. PostToolUse - 执行后处理

#### 自动格式化 (`auto-format.sh`)

**功能**: 代码写入后自动格式化

**支持的文件类型**:
- **Python** (`.py`) → `ruff format` + `ruff check`
- **JavaScript/TypeScript** (`.js`, `.ts`, `.tsx`) → `prettier`
- **JSON** (`.json`) → `jq`
- **Markdown** (`.md`) → `prettier`
- **YAML** (`.yaml`, `.yml`) → `prettier`

**输出示例**:
```
✨ 已自动格式化 Python 文件: src/auth.py
✨ 已自动格式化 JSON 文件: package.json
```

---

### 5. PermissionRequest - 权限请求

#### 自动批准安全命令 (`auto-approve-safe.sh`)

**功能**: 自动批准常用安全命令，减少打断

**自动批准的命令**:
- **只读命令**: `ls`, `cat`, `head`, `tail`, `grep`, `find`
- **Git 查询**: `git status`, `git log`, `git diff`
- **版本检查**: `python --version`, `node --version`
- **开发工具**: `npm test`, `pytest`, `ruff check`
- **安装命令**: `npm install`, `pip install`, `brew install`

**输出示例**:
```
✓ 自动批准常用命令: npm test
✓ 自动批准常用命令: git status
```

**仍需手动批准的命令**:
- 任何不在白名单中的命令
- 写入、删除、修改类命令

---

### 6. Notification - 通知

**功能**: macOS 桌面通知

**触发时机**:
- Claude 需要权限时
- Claude 等待你输入时

**效果**: 收到系统通知提示音和弹窗。

---

### 7. Stop - 停止检查

**功能**: 防止 Claude 过早停止工作

**检查内容**:
1. 所有用户任务已完成？
2. 测试通过？
3. 无遗留错误？

**如果未完成**: Claude 会继续工作并说明原因。

---

## 🚀 使用方法

### 全局 Hooks（已生效）

所有脚本已安装到 `~/.claude/hooks/` 并在全局配置中启用。

**立即生效**: 重启 Claude Code 会话即可。

### 项目级 Hooks（可选）

如果你的项目需要特定的 hooks，可以创建项目配置：

#### 步骤 1: 复制模板

```bash
cd /path/to/your/project
mkdir -p .claude/hooks
cp ~/.claude/hooks/project-settings-template.json .claude/settings.json
```

#### 步骤 2: 创建项目 Hook 脚本

创建 `.claude/hooks/project-setup.sh`:

```bash
#!/bin/bash
# 项目特定的启动脚本

echo "🎯 项目: 我的项目名称"
echo "📝 检查依赖..."

# 检查 Python 虚拟环境
if [ -d ".venv" ]; then
  echo "✓ 虚拟环境存在"
else
  echo "⚠️  未发现虚拟环境，运行: python3 -m venv .venv"
fi

# 检查 node_modules
if [ -d "node_modules" ]; then
  echo "✓ Node 依赖已安装"
else
  echo "⚠️  未发现 node_modules，运行: npm install"
fi

exit 0
```

#### 步骤 3: 设置权限

```bash
chmod +x .claude/hooks/project-setup.sh
```

#### 步骤 4: 添加到 .gitignore

```bash
echo ".claude/settings.local.json" >> .gitignore
```

---

## 🔧 自定义 Hooks

### 修改安全命令列表

编辑 `~/.claude/hooks/auto-approve-safe.sh`，在 `SAFE_PATTERNS` 数组中添加或删除命令模式。

### 添加保护文件

编辑 `~/.claude/hooks/protect-files.sh`，在 `PROTECTED_PATTERNS` 数组中添加文件模式。

### 添加危险命令模式

编辑 `~/.claude/hooks/validate-bash.sh`，在 `DANGEROUS_PATTERNS` 数组中添加模式。

---

## 📊 查看 Hooks 状态

在 Claude Code 中运行：

```
/hooks
```

或在命令行：

```bash
claude --show-hooks
```

---

## 🐛 调试 Hooks

### 启用详细输出

在 Claude Code 中按 `Ctrl+O` 切换详细输出。

### 查看 Hook 执行日志

```bash
claude --debug
```

### 测试单个 Hook 脚本

```bash
# 测试 session-start
~/.claude/hooks/session-start.sh

# 测试 validate-bash（需要提供 JSON 输入）
echo '{"tool_input":{"command":"ls -la"}}' | ~/.claude/hooks/validate-bash.sh
```

---

## ⚙️ 临时禁用 Hooks

### 方法 1: 通过命令

在 Claude Code 中运行：
```
/hooks
```
然后在底部切换开关。

### 方法 2: 重命名配置

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.backup
```

---

## 🔒 安全建议

1. **定期审查自动批准列表**: 确保只批准真正安全的命令
2. **保护敏感文件**: 将项目特定的敏感文件添加到 `protect-files.sh`
3. **不要盲目信任**: Hook 只是第一道防线，关键操作仍需手动确认
4. **团队共享**: 将项目级 hooks 提交到 git，但 `.claude/settings.local.json` 应该 gitignore

---

## 🎯 最佳实践

### 1. 全局 Hooks（所有项目）

保持简单通用：
- 安全检查
- 基本格式化
- 通用命令自动批准

### 2. 项目 Hooks（特定项目）

添加项目特定规则：
- 项目特定的测试命令
- 自定义构建流程
- 特定文件保护

### 3. Hook 执行顺序

```
SessionStart (启动时)
    ↓
UserPromptSubmit (每次提示词前)
    ↓
PreToolUse (执行前验证)
    ↓
PermissionRequest (权限请求时)
    ↓
[工具执行]
    ↓
PostToolUse (执行后处理)
    ↓
Stop (停止前检查)
```

---

## 📚 参考资料

- [Claude Code Hooks 官方文档](https://code.claude.com/docs/en/hooks)
- [全局配置位置]: `~/.claude/settings.json`
- [项目配置位置]: `<project>/.claude/settings.json`

---

## ❓ 常见问题

### Q: Hook 没有生效？

**A**: 检查：
1. 脚本是否有执行权限？(`ls -l ~/.claude/hooks/`)
2. 配置文件 JSON 格式是否正确？
3. 重启 Claude Code 会话

### Q: 如何临时跳过某个 Hook？

**A**: 在 Claude Code 中运行 `/hooks`，然后禁用特定 hook。

### Q: Hook 脚本报错怎么办？

**A**:
1. 手动运行脚本测试：`~/.claude/hooks/validate-bash.sh`
2. 检查脚本中的依赖命令是否安装（如 `jq`）
3. 查看详细日志：`claude --debug`

### Q: 可以在 Windows 上使用吗？

**A**: 这些脚本是为 macOS/Linux 编写的。Windows 需要修改为 PowerShell 或 Batch 脚本。

---

## 🔄 更新日志

- **2026-02-02**: 初始版本，包含 7 个核心 hooks
- 支持 Python、JavaScript/TypeScript、JSON、YAML 自动格式化
- macOS 桌面通知集成
- 安全命令自动批准

---

**享受更智能、更安全的 Claude Code 开发体验！** 🎉
