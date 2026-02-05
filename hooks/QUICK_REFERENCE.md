# Claude Code Hooks 快速参考

## 🎯 核心功能一览

| Hook | 功能 | 自动/手动 |
|------|------|-----------|
| 🚀 SessionStart | 显示环境信息 | 自动 |
| 📌 UserPromptSubmit | 注入 Git 上下文 | 自动 |
| 🛡️ validate-bash | 阻止危险命令 | 自动 |
| 🔒 protect-files | 保护关键文件 | 自动 |
| ✨ auto-format | 自动格式化代码 | 自动 |
| ✓ auto-approve | 自动批准安全命令 | 自动 |
| 🔔 Notification | 桌面通知 | 自动 |
| 🛑 Stop | 防止过早停止 | 自动 |

---

## 🚫 自动阻止的危险操作

```bash
rm -rf /              # 删除根目录
chmod 777             # 不安全权限
dd if=                # 磁盘操作
:(){ :|:& };:         # Fork 炸弹
curl ... | sh         # 下载并执行
```

---

## 🔒 自动保护的文件

```
.env, .env.local          # 环境变量
credentials.json          # 凭证
package-lock.json         # 锁文件
.git/config              # Git 配置
.ssh/, id_rsa            # SSH 密钥
```

---

## ✓ 自动批准的安全命令

```bash
# 只读命令
ls, cat, head, tail, grep, find

# Git 查询
git status, git log, git diff

# 开发工具
npm test, pytest, ruff check

# 版本检查
python --version, node --version

# 安装命令
npm install, pip install, brew install
```

---

## ✨ 自动格式化支持

| 语言 | 工具 |
|------|------|
| Python (`.py`) | `ruff format` |
| JavaScript/TypeScript | `prettier` |
| JSON | `jq` |
| Markdown | `prettier` |
| YAML | `prettier` |

---

## 📝 常用命令

```bash
# 查看所有 hooks
/hooks

# 调试模式
claude --debug

# 切换详细输出
Ctrl+O

# 测试 hook 脚本
~/.claude/hooks/session-start.sh

# 验证 JSON 格式
jq empty ~/.claude/settings.json

# 查看 hooks 目录
ls -lh ~/.claude/hooks/
```

---

## 🔧 临时禁用 Hooks

### 方法 1: 通过界面
```
/hooks → 底部切换开关
```

### 方法 2: 重命名配置
```bash
mv ~/.claude/settings.json ~/.claude/settings.json.backup
```

---

## 🎯 项目级配置（可选）

```bash
# 1. 创建项目配置目录
cd /path/to/project
mkdir -p .claude/hooks

# 2. 复制模板
cp ~/.claude/hooks/project-settings-template.json .claude/settings.json

# 3. 创建项目 hook
nano .claude/hooks/project-setup.sh

# 4. 设置权限
chmod +x .claude/hooks/*.sh

# 5. 添加到 .gitignore
echo ".claude/settings.local.json" >> .gitignore
```

---

## 🐛 故障排查

| 问题 | 解决方法 |
|------|----------|
| Hook 不生效 | 检查执行权限、重启会话 |
| JSON 错误 | `jq empty ~/.claude/settings.json` |
| 脚本报错 | 手动运行脚本测试 |
| 需要 jq | `brew install jq` |

---

## 📚 更多信息

详细文档: `~/.claude/hooks/README.md`

官方文档: https://code.claude.com/docs/en/hooks

---

**配置完成时间**: 2026-02-02
**最后更新**: 2026-02-02
