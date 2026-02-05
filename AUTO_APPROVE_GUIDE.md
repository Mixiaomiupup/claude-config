# Claude Code 权限自动批准系统 - 使用指南

**配置模式**: 激进模式 + 标准审计
**实施日期**: 2026-02-05
**预期效果**: 减少 80%+ 手动批准

---

## 📊 配置概览

### 已实施的 4 个阶段

✅ **Phase 1: 全局静态白名单扩展**
- 文件: `~/.claude/settings.local.json`
- 新增: 100+ 条命令权限
- 包括: 开发工具、Git 操作、文件操作、网络命令等

✅ **Phase 2: Hook 模式扩展**
- 文件: `~/.claude/hooks/auto-approve-safe.sh`
- SAFE_PATTERNS: 60+ 条（静默自动批准）
- CAREFUL_PATTERNS: 40+ 条（通知+自动批准）
- 审计日志: 所有自动批准命令被记录

✅ **Phase 3: csfilter 项目配置**
- 文件: `/Users/mixiaomiupup/csfilter/.claude/settings.json`
- 文件: `/Users/mixiaomiupup/csfilter/.claude/auto-approve-patterns.txt`
- 项目特定命令: Python、数据库、网络、进程管理

✅ **Phase 4: 工具脚本**
- `list-permissions.sh` - 列出所有权限
- `test-permission.sh` - 测试命令是否自动批准
- `validate-config.sh` - 验证配置

---

## 🚀 快速使用

### 查看所有权限配置
```bash
~/.claude/hooks/list-permissions.sh
```

### 测试命令是否会自动批准
```bash
~/.claude/hooks/test-permission.sh "git status"
~/.claude/hooks/test-permission.sh "npm install"
```

### 验证配置
```bash
~/.claude/hooks/validate-config.sh
```

### 查看审计日志
```bash
tail -f ~/.claude/auto-approve-audit.log
```

---

## ✅ 自动批准的命令类型

### 只读命令（静默批准）
- 文件查看: `ls`, `cat`, `head`, `tail`, `find`, `tree`, `grep`
- Git 查看: `git status`, `git log`, `git diff`, `git show`
- 系统信息: `pwd`, `whoami`, `date`, `ps`, `netstat`
- 版本检查: `python --version`, `node --version`, `git --version`

### 写操作（通知+批准）
- Git 操作: `git add`, `git commit`, `git pull`, `git checkout`
- 包管理: `npm install`, `pip install`, `poetry install`
- 测试: `pytest`, `npm test`, `ruff check`
- 文件操作: `mkdir`, `touch`, `cp`, `mv`, `rm`（非递归）
- 网络: `curl`, `wget`

### csfilter 项目特定
- Python: `python`, `.venv/bin/*`
- 数据库: `sqlite3`
- 网络: `mitmdump`, `chromedriver`, `networksetup`
- 进程: `pkill`, `kill`, `lsof`

---

## ⚠️ 仍需手动批准的命令

- 危险删除: `rm -rf /`, `rm -rf ~`
- 权限修改: `chmod 777`, `chown`
- 系统管理: `sudo rm`, `systemctl`
- 下载执行: `curl | sh`, `wget | bash`
- 未知命令: 不在白名单和模式中的命令

---

## 🔒 安全保障

### 保持的安全机制
1. **validate-bash.sh** - 阻止真正危险的命令
2. **protect-files.sh** - 保护敏感文件（.env, SSH keys）
3. **审计日志** - 记录所有自动批准的命令

### 审计日志格式
```
2026-02-05 22:36:46 - AUTO-APPROVED (SAFE): ls -la
2026-02-05 22:36:48 - AUTO-APPROVED (CAREFUL): npm install
2026-02-05 22:36:50 - AUTO-APPROVED (PROJECT): .venv/bin/pytest
```

---

## 🛠️ 自定义配置

### 添加全局权限
编辑 `~/.claude/settings.local.json`：
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
编辑 `<project>/.claude/auto-approve-patterns.txt`：
```bash
# 项目特定模式
^your-command
^your-pattern.*
```

### 添加 Hook 模式
编辑 `~/.claude/hooks/auto-approve-safe.sh`：
- 只读命令 → 添加到 `SAFE_PATTERNS`
- 写操作 → 添加到 `CAREFUL_PATTERNS`

---

## 🔄 回滚方案

如果需要恢复原始配置：

```bash
# 1. 恢复原始 hook
cp ~/.claude/hooks/auto-approve-safe.sh.backup ~/.claude/hooks/auto-approve-safe.sh

# 2. 删除扩展配置（保留原有内容）
# 手动编辑 ~/.claude/settings.local.json 删除新增部分

# 3. 清理项目配置
rm /Users/mixiaomiupup/csfilter/.claude/auto-approve-patterns.txt

# 4. 重启 Claude Code
```

---

## 📈 效果统计

查看自动批准统计：
```bash
echo "总自动批准: $(wc -l < ~/.claude/auto-approve-audit.log)"
echo "SAFE 批准: $(grep -c 'AUTO-APPROVED (SAFE)' ~/.claude/auto-approve-audit.log)"
echo "CAREFUL 批准: $(grep -c 'AUTO-APPROVED (CAREFUL)' ~/.claude/auto-approve-audit.log)"
echo "PROJECT 批准: $(grep -c 'AUTO-APPROVED (PROJECT)' ~/.claude/auto-approve-audit.log)"
```

---

## 🎯 下一步优化建议

1. **定期审查日志**: 每周检查 `auto-approve-audit.log`
2. **添加常用命令**: 发现常用未批准命令时添加到配置
3. **项目模式**: 为其他项目创建专属 `auto-approve-patterns.txt`
4. **性能监控**: 观察命令执行流畅度

---

## 📞 故障排查

### 命令仍需手动批准
```bash
# 测试命令匹配情况
~/.claude/hooks/test-permission.sh "your-command"

# 检查配置
~/.claude/hooks/validate-config.sh
```

### 审计日志不工作
```bash
# 检查日志文件权限
ls -la ~/.claude/auto-approve-audit.log

# 手动创建
touch ~/.claude/auto-approve-audit.log
```

### Hook 不执行
```bash
# 检查执行权限
ls -la ~/.claude/hooks/*.sh

# 添加权限
chmod +x ~/.claude/hooks/*.sh
```

---

**版本**: 1.0.0
**维护者**: Claude Code 配置系统
**更新日期**: 2026-02-05
