# Claude 规划工作流索引

本文件是所有规划工作的中心索引。

## 📋 目录结构

```
.claude/plans/
├── templates/          # 规划模板
│   └── plan-template.md
├── active/            # 当前活跃的计划
├── archive/           # 已完成的归档计划
├── PLANS_INDEX.md     # 本文件 - 主索引
└── README.md          # 使用说明
```

## 🎯 使用原则

基于全局配置中的开发工作流规则：

### 1. 单一真实来源
- 每个项目/任务必须有一个对应的规划文档
- 所有代码实现必须先参考规划文档
- 规划文档必须在编码前更新并获得确认
- 规划文档必须与代码库保持同步

### 2. 向后兼容性
- 规划应优先考虑非破坏性变更
- 如需破坏性变更，必须在规划文档中明确说明
- 维护 API 稳定性和数据兼容性

### 3. 测试驱动
- 规划中应包含测试策略
- 定义成功标准和验收条件
- 确保代码覆盖率目标（最低 80%）

### 4. 质量门控
- 本地检查：代码格式化和 linting
- 远程检查：类型检查、完整测试套件、安全扫描
- 所有检查必须通过才能合并

### 5. 错误处理和日志
- 规划中应明确错误处理策略
- 定义关键操作的日志要求
- 输入验证和安全考虑

## 📝 规划文档内容

每个规划文档应包含：

1. **元信息**：创建日期、计划 ID、状态、优先级
2. **目标概述**：明确的目标定义
3. **背景与动机**：为什么需要这个计划
4. **架构设计**（如适用）：
   - 系统架构
   - 技术栈
   - 数据流
   - 接口设计
5. **待办事项清单**：按状态分类的任务列表
6. **工作流步骤**：详细的执行步骤
7. **设计决策记录**：重要的技术决策及其理由
8. **风险与挑战**：潜在风险和应对策略
9. **依赖项**：其他计划或资源
10. **成功标准**：明确的完成标准
11. **历史记录**：变更历史

## 🔄 工作流程

### 创建新计划
1. 复制 `templates/plan-template.md`
2. 填写计划信息
3. 保存到 `active/` 目录
4. 在本索引中添加引用

### 执行计划
1. 使用 `TaskCreate` 工具同步待办事项
2. 参考规划文档进行实现
3. 更新规划文档中的进度
4. 记录设计决策

### 完成计划
1. 确认所有待办事项已完成
2. 验证成功标准已达成
3. 将计划文档移动到 `archive/` 目录
4. 在本索引中更新状态

## 📌 当前活跃计划

| 计划文件 | 状态 | 优先级 | 备注 |
|---------|------|-------|------|
| [cs2-trend-line-visualization.md](active/cs2-trend-line-visualization.md) | Active | High | CS2 趋势线可视化 |
| [adaptive-percolating-dahl.md](active/adaptive-percolating-dahl.md) | Active | - | 待更新 |
| [bubbly-discovering-wilkes.md](active/bubbly-discovering-wilkes.md) | Active | - | 待更新 |
| [crispy-snuggling-stroustrup.md](active/crispy-snuggling-stroustrup.md) | Active | - | 待更新 |
| [eager-hugging-pudding.md](active/eager-hugging-pudding.md) | Active | - | 待更新 |
| [expressive-finding-haven.md](active/expressive-finding-haven.md) | Active | - | 待更新 |
| [happy-munching-spring.md](active/happy-munching-spring.md) | Active | - | 待更新 |
| [logical-discovering-crab.md](active/logical-discovering-crab.md) | Active | - | 待更新 |
| [nifty-mixing-castle.md](active/nifty-mixing-castle.md) | Active | - | 待更新 |
| [radiant-meandering-orbit.md](active/radiant-meandering-orbit.md) | Active | - | 待更新 |
| [spicy-watching-teapot.md](active/spicy-watching-teapot.md) | Active | - | 待更新 |
| [swift-cuddling-twilight.md](active/swift-cuddling-twilight.md) | Active | - | 待更新 |
| [swift-pondering-pebble.md](active/swift-pondering-pebble.md) | Active | - | 待更新 |
| [zany-singing-ladybug.md](active/zany-singing-ladybug.md) | Active | - | 待更新 |

> **注意**: 这些是从 `~/.claude/plans/` 根目录迁移的历史计划文件。建议审查每个文件，根据实际状态移至 `archive/` 或更新优先级。

## 📦 归档计划

<!-- 已完成的计划存档在这里 -->

### 示例：已完成项目
- **文件**: `archive/completed-project-plan.md`
- **完成日期**: 2026-01-10

---

**最后更新**: 2026-02-02
**维护者**: Claude Code Planning System
