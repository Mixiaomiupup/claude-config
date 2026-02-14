# Claude 规划工作流系统

基于文件的规划系统，确保所有开发工作都有清晰的架构设计和执行计划。

## 🚀 快速开始

### 创建新计划

```bash
# 1. 复制模板
cp .claude/plans/templates/plan-template.md .claude/plans/active/your-plan-name.md

# 2. 编辑计划文件，填写具体信息

# 3. 在 PLANS_INDEX.md 中添加计划引用
```

### 使用计划

当你需要实现功能时：

1. **阅读计划** - 先查看对应的规划文档
2. **创建待办** - 使用 `TaskCreate` 同步任务
3. **执行实现** - 按照规划文档中的步骤执行
4. **更新进度** - 及时更新规划文档
5. **完成归档** - 完成后移动到 `archive/` 目录

## 📁 文件说明

### PLANS_INDEX.md
主索引文件，包含：
- 工作流原则和规则
- 所有计划的目录
- 使用指南
- 活跃计划列表

### templates/plan-template.md
规划模板，包含所有必需章节：
- 元信息
- 目标概述
- 架构设计
- 待办事项
- 工作流步骤
- 设计决策记录
- 历史记录

### active/
当前正在执行的计划文件

### archive/
已完成的计划文件（用于参考和审计）

## 🎯 核心原则

### 单一真实来源
- 架构文档是唯一权威来源
- 所有代码实现必须遵循架构文档
- 架构变更必须先更新文档

### 测试驱动
- 每个功能必须有测试计划
- 目标覆盖率：80%
- 所有测试必须通过才能合并

### 质量门控
- 本地：ruff format, ruff check
- 远程：mypy, pytest --cov, 安全扫描

### 向后兼容
- 优先非破坏性变更
- 破坏性变更必须明确说明
- 保持 API 稳定性

## 💡 最佳实践

1. **规划先行** - 在编写代码前，先完善规划文档
2. **及时更新** - 随着开发进展，同步更新规划
3. **记录决策** - 在决策记录表中记录重要技术决策
4. **维护历史** - 保留变更历史以便追溯
5. **定期审查** - 定期检查活跃计划的进展

## 🔧 与 Claude Code 集成

这个规划系统与 Claude Code 深度集成：

- **Task Management Tools** - TaskCreate/TaskUpdate/TaskList/TaskGet 与规划文档中的待办事项同步
- **AskUserQuestion** - 在规划阶段澄清需求
- **EnterPlanMode** - 进入专门的规划模式
- **Read/Edit 工具** - 管理规划文档

## 📊 状态管理

计划生命周期：
```
draft → active → completed → archived
   ↓                        ↑
cancelled ──────────────────┘
```

## 🤝 贡献

改进规划系统：
1. 更新模板以适应新的工作流需求
2. 优化 PLANS_INDEX.md 的结构
3. 添加新的最佳实践

---

## 📦 推荐项目文档结构

### 文档组织（参考 csfilter）

**推荐结构**:
```
<project>/
├── .claude/
│   ├── system-instructions.txt  # 项目特定执行准则（推荐）
│   ├── settings.local.json      # 权限配置
│   └── plans/                   # （可选）临时规划，不提交 git
├── docs/
│   ├── ARCHITECTURE.md          # 总架构文档
│   ├── COMPLETE_GUIDE.md        # 完整使用手册（可选）
│   ├── MODULE_A.md              # 模块A架构
│   ├── MODULE_B.md              # 模块B架构
│   └── plans/                   # Superpowers 实施计划（提交 git）
│       ├── 2026-02-02-feature-a.md
│       └── 2026-02-02-feature-b.md
└── src/
```

**成功案例：csfilter**
- `docs/COMPLETE_GUIDE.md` - 总项目架构和使用手册
- `docs/COLLECTOR_ARCHITECTURE.md` - 数据采集系统架构
- `docs/ANALYSIS_SYSTEM.md` - 分析系统架构
- `docs/DATABASE.md` - 数据库设计
- `.claude/system-instructions.txt` - 项目特定规则

### 向后兼容

全局 `~/.claude/plans/` 仍可用于：
- 个人学习笔记
- 跨项目的战略思考
- 临时探索性规划

但**强烈建议**：
- 项目架构文档放在 `<project>/docs/`
- Superpowers 实施计划放在 `<project>/docs/plans/`
- 项目规则放在 `<project>/.claude/system-instructions.txt`

---

**版本**: 2.0.0
**创建日期**: 2026-01-14
**更新日期**: 2026-02-02
