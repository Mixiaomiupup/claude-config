# Claude 配置打包与使用指南

本指南说明如何将你的 Claude Code 配置打包，并在其他电脑上使用。

## 📦 快速开始

### 在当前电脑上打包配置

```bash
# 运行打包脚本
~/.claude/package-config.sh

# 或者从任何目录
cd ~/.claude && ./package-config.sh
```

**生成的文件**:
- `~/claude-config-YYYYMMDD_HHMMSS.tar.gz` - 配置包
- `~/claude-config-YYYYMMDD_HHMMSS.tar.gz.sha256` - 校验和（用于验证完整性）

### 在新电脑上安装配置

```bash
# 1. 复制配置包到新电脑（使用 scp、U盘、云存储等）

# 2. 解压
tar -xzf claude-config-YYYYMMDD_HHMMSS.tar.gz
cd claude-config-YYYYMMDD_HHMMSS

# 3. 运行安装脚本
./install.sh

# 4. 重启 Claude Code
```

---

## 📋 包含的内容

配置包包含以下文件：

### ✅ 核心配置
- **CLAUDE.md** - 全局配置文件（包含规划工作流、代码质量标准等）
- **plans/** - 完整的规划系统
  - `templates/plan-template.md` - 规划模板
  - `PLANS_INDEX.md` - 主索引
  - `README.md` - 使用说明
  - `active/` - 活跃的计划（如果有）
  - `archive/` - 已完成的计划（如果有）

### ✅ 自定义技能
- **skills/** - 自定义技能目录
  - `commit/` - Google 风格提交消息
  - `debug/` - 调试技能
  - `explain/` - 代码解释
  - `python-style/` - Python 代码风格检查
  - `refactor/` - 重构建议
  - `review/` - 代码审查
  - `test/` - 测试生成

### ⚠️ 设置文件
- **settings.json.example** - 设置文件示例（需要根据新机器调整）

### 🔧 工具文件
- **install.sh** - 自动安装脚本
- **README.md** - 包说明文档
- **VERSION** - 版本信息

### ❌ 不包含的内容（这些是运行时数据，不需要共享）
- 对话历史 (history.jsonl)
- 调试日志
- 缓存文件
- 临时文件
- settings.local.json（机器特定的设置）
- 插件缓存（通过 `claude plugin install` 重新安装）

---

## 🚀 详细使用说明

### 场景 1: 同步个人电脑和工作电脑

#### 在电脑 A（源电脑）打包

```bash
# 1. 创建配置包
~/.claude/package-config.sh

# 2. 查看生成的包
ls -lh ~/claude-config-*.tar.gz

# 3. 验证校验和（可选）
cat ~/claude-config-*.tar.gz.sha256
```

#### 传输到电脑 B（目标电脑）

**方法 1: 使用 scp**
```bash
# 在电脑 A 上
scp ~/claude-config-20260114_141216.tar.gz user@work-computer:~/
```

**方法 2: 使用云存储**
```bash
# 上传到 iCloud、Google Drive、Dropbox 等
# 然后在目标电脑下载
```

**方法 3: 使用 USB 驱动器**
```bash
# 复制到 USB，然后在目标电脑上复制出来
```

#### 在电脑 B 上安装

```bash
# 1. 解压
tar -xzf claude-config-20260114_141216.tar.gz
cd claude-config-20260114_141216

# 2. 查看内容（可选）
cat README.md

# 3. 运行安装
./install.sh

# 4. 安装后检查
cat ~/.claude/CLAUDE.md
ls -la ~/.claude/plans/

# 5. 重启 Claude Code
```

### 场景 2: 与团队共享配置

#### 作为配置维护者

```bash
# 1. 创建团队配置包
~/.claude/package-config.sh

# 2. 上传到团队共享位置
# - Git repository
# - 内部文件服务器
# - 云存储（如 Google Drive）

# 3. 通知团队成员
echo "配置包已更新: claude-config-20260114_141216.tar.gz"
```

#### 作为团队成员

```bash
# 1. 下载配置包
wget https://team-server/configs/claude-config-latest.tar.gz

# 2. 验证完整性（如果提供校验和）
shasum -a 256 claude-config-latest.tar.gz
# 比对输出与提供的校验和

# 3. 安装
tar -xzf claude-config-latest.tar.gz
cd claude-config-*
./install.sh
```

### 场景 3: 版本控制

```bash
# 1. 将配置包加入版本控制
git init claude-config
cd claude-config
tar -xzf ~/claude-config-20260114_141216.tar.gz
mv claude-config-package/* .
rm -rf claude-config-package
git add .
git commit -m "Add Claude configuration v2.0.0"
git push

# 2. 在其他机器上克隆
git clone https://github.com/yourusername/claude-config
cd claude-config
./install.sh
```

---

## 🔧 自定义打包脚本

如果你想修改打包脚本以包含其他文件：

```bash
# 编辑打包脚本
nano ~/.claude/package-config.sh

# 在 "Copy planning system" 部分后添加：
# Copy custom plugins (if you have any)
if [ -d "$HOME/.claude/plugins/custom" ]; then
    log_info "Copying custom plugins..."
    mkdir -p "$TEMP_DIR/$PACKAGE_DIR/plugins/custom"
    cp -r "$HOME/.claude/plugins/custom/"* "$TEMP_DIR/$PACKAGE_DIR/plugins/custom/"
    log_success "✓ Custom plugins included"
fi
```

---

## 🛠️ 故障排除

### 问题 1: 安装脚本权限错误

**症状**:
```
bash: ./install.sh: Permission denied
```

**解决**:
```bash
chmod +x install.sh
./install.sh
```

### 问题 2: 配置未生效

**症状**: 安装后 Claude Code 使用旧配置

**解决**:
```bash
# 1. 检查文件是否存在
ls -la ~/.claude/CLAUDE.md
ls -la ~/.claude/plans/

# 2. 重启 Claude Code
# 完全退出并重新启动

# 3. 清除缓存（如果需要）
rm -rf ~/.claude/debug/*
rm -rf ~/.claude/session-env/*
```

### 问题 3: 想恢复之前的配置

```bash
# 找到备份
ls -la ~/.claude_backup_*/

# 恢复
rm -rf ~/.claude
mv ~/.claude_backup_* ~/.claude
```

### 问题 4: 设置文件在新机器上不兼容

```bash
# 手动编辑设置
cp ~/.claude/settings.json.example ~/.claude/settings.json
nano ~/.claude/settings.json

# 或者删除设置文件，使用默认设置
rm ~/.claude/settings.json
```

---

## 📊 包大小和管理

### 查看所有配置包

```bash
ls -lh ~/claude-config-*.tar.gz*
```

### 清理旧包

```bash
# 删除 7 天前的包
find ~/claude-config-*.tar.gz -mtime +7 -delete
find ~/claude-config-*.tar.gz.sha256 -mtime +7 -delete
```

### 定期更新配置

```bash
# 每次修改配置后重新打包
~/.claude/package-config.sh

# 包名会自动包含时间戳，便于版本管理
```

---

## 🔐 安全注意事项

1. **敏感信息**: 检查配置中是否包含敏感信息
   ```bash
   # 在打包前检查
   grep -r "password\|token\|key" ~/.claude/CLAUDE.md
   grep -r "password\|token\|key" ~/.claude/plans/
   ```

2. **校验和**: 始终使用校验和验证包的完整性
   ```bash
   # 生成校验和
   shasum -a 256 claude-config-20260114_141216.tar.gz

   # 验证校验和
   shasum -c claude-config-20260114_141216.tar.gz.sha256
   ```

3. **传输**: 使用安全的方法传输配置包
   - ✅ scp (SSH)
   - ✅ HTTPS (从可信来源下载)
   - ✅ 加密的 USB 驱动器
   - ⚠️  避免通过不安全的 HTTP 传输

---

## 📝 更新日志

### 版本 2.0.0 (2026-01-14)
- ✨ 新增配置打包脚本
- ✨ 新增自动安装脚本
- ✨ 包含完整的规划系统
- ✨ 包含自定义技能
- 📝 完整的使用文档

---

## 💡 最佳实践

1. **定期打包**: 每次更新配置后重新打包
2. **版本管理**: 保留最近几个版本的包，删除旧版本
3. **团队协作**: 为团队创建统一的配置包
4. **测试先行**: 在非关键机器上先测试新配置
5. **备份重要**: 始终保留旧配置的备份

---

## 🆘 获取帮助

- Claude Code 文档: https://github.com/anthropics/claude-code
- 配置文件位置: `~/.claude/CLAUDE.md`
- 规划系统文档: `~/.claude/plans/README.md`

---

**创建日期**: 2026-01-14
**配置版本**: 2.0.0
