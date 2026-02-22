# Global Configuration

## Quick Reference

| Category | Standard | Tool/Command |
|----------|----------|--------------|
| **Python Style** | PEP 8 + type hints + Google docstrings | `python-style` skill |
| **Commit Messages** | Google convention | `commit` skill |
| **Planning** | Scaled to complexity | See Workflow Section 1.3 |
| **Quality Checks (Local)** | Format + Lint | `ruff format .` + `ruff check --fix .` |
| **Quality Checks (Remote)** | Type + Test + Security | CI/CD pipeline (mypy, pytest, scanning) |
| **Test Coverage** | Context-dependent | `pytest --cov` |

---

## 1. Development Workflow & Context Management

**Core Principle**: Context First → Confirm Direction → Document Impact → Implement.

### 1.1 Pre-Action Confirmation (Recommended)

**建议在以下情况下征求确认**:
1. **架构级变更**: 影响多个模块或系统设计
2. **破坏性修改**: 可能影响现有功能
3. **需求不明确**: 存在多种实现方式

**确认方式**:
- **批量确认（推荐）**: 描述整体方向和所有受影响文件
  ```
  "我将添加 JWT 认证支持，修改：
  - src/auth.py (添加令牌验证)
  - src/middleware.py (集成验证逻辑)
  - tests/test_auth.py (添加测试覆盖)
  整体方法：[简要描述]。是否继续？"
  ```
- **详细确认**: 对于有多种有效方案的复杂架构决策

**可以直接执行的情况**:
- Level 1 文件级修改（bug 修复、单函数添加）
- 需求明确且只有一种明显实现方式
- 用户已明确要求的操作

### 1.2 Context Gathering (Best Practice)

在进行代码修改前，**建议**遵循以下上下文收集流程：
1. **识别范围**: 这是单文件修复、模块更新还是系统级改造？
2. **收集上下文**: 使用 Read、Glob 或 Grep 理解受影响区域
   - *单文件*: 读取具体文件和直接导入
   - *模块/功能*: 读取模块 README、相关接口和现有测试
   - *系统级*: 审查架构文档、API 规范和数据流
3. **验证假设**: 避免猜测文件路径或内容

### 1.3 Impact-Based Documentation & Workflow

根据影响范围更新文档，*在*或*伴随*代码变更时：

| 变更范围 | 场景 | 所需行动 | 文档更新 | Superpowers 技能 |
| :--- | :--- | :--- | :--- | :--- |
| **Level 1: 文件级**<br>(单文件修改) | Bug 修复、添加单个函数、<br>重构单个文件 | 1. 读取文件<br>2. 批量确认方向<br>3. 实施 | 如果逻辑复杂则添加代码注释 | - |
| **Level 2: 模块级**<br>(多文件功能) | 新功能模块、<br>重构相关文件 | 1. 读取模块上下文<br>2. 确认设计方案<br>3. 实施 | 更新函数 docstrings<br>更新模块 README.md | `brainstorming` (可选)<br>`debug` (如适用) |
| **Level 3: 系统级**<br>(架构变更) | 新应用、<br>数据库迁移、<br>API 重新设计 | 1. **使用 Superpowers 工作流**<br>2. 用户批准<br>3. 实施 | 创建/更新 ARCHITECTURE.md<br>完整规划文档 | `brainstorming` (必需)<br>`writing-plans` (必需)<br>`executing-plans` (推荐) |

**Level 3 推荐工作流（使用 Superpowers）**:
```
brainstorming → writing-plans → executing-plans → finishing-a-development-branch
      ↓              ↓                  ↓                    ↓
  理解需求      创建实施计划      批量执行任务        完成开发分支
```

### 1.3.1 Documentation Decision Tree

**核心原则**：智能判断 + 避免过度生成

在创建/更新任何文档前，遵循此决策流程：

1. **分类变更级别**（使用严格标准）
   - Level 1: 单文件修改、单函数添加、bug修复
   - Level 2: 多文件功能模块、跨模块重构（需影响≥3个文件）
   - Level 3: 系统架构变更、数据库迁移、API重设计

2. **检查文档必要性**
   ```
   Level 1 → 仅代码注释（如逻辑复杂）
   Level 2 → 检查是否有现有模块文档：
             - 有现有docs/MODULE_*.md → 更新它
             - 无现有文档 + 新模块 → 创建docs/MODULE_X.md
             - 无现有文档 + 小改进 → 仅更新函数docstrings
   Level 3 → 必须更新docs/ARCHITECTURE.md
             - 如有架构变化 → 同步更新或创建相关MODULE文档
   ```

3. **避免过度生成**
   - ❌ 不要为临时实验创建文档
   - ❌ 不要重复生成已存在的内容（检查docs/目录）
   - ❌ 不要在Level 1/2时创建ARCHITECTURE.md（除非用户明确要求）
   - ✅ 优先更新现有文档而非创建新文档
   - ✅ 使用Glob/Read检查docs/目录避免重复

4. **特殊情况处理**
   - Superpowers规划文档（`docs/plans/YYYY-MM-DD-*.md`）：仅在使用writing-plans skill时生成
   - 项目README：仅在新项目初始化或用户明确要求时创建
   - 临时计划：使用`.claude/plans/`（不提交git）或TaskCreate工具

**智能判断示例**：
- "修复登录bug" → Level 1 → 仅代码注释
- "重构auth模块（3个文件）" → Level 2 → 更新existing docs/AUTH_MODULE.md（如存在）
- "添加OAuth支持（跨多模块）" → Level 2/3边界 → 检查docs/是否有AUTH文档，更新或创建
- "迁移到微服务架构" → Level 3 → 必须更新docs/ARCHITECTURE.md

### 1.3.2 Project Documentation Modes (可选)

项目可以在`.claude/system-instructions.txt`中声明文档偏好：

**模式说明**：
- **strict**（严格）：只更新existing docs，永不自动创建新文档
- **standard**（标准）：遵循Section 1.3.1决策树（推荐）
- **comprehensive**（全面）：Level 2+时主动创建完整文档

**声明方式**（在项目`.claude/system-instructions.txt`顶部）：
```txt
# Documentation Mode: standard
```

**默认行为**：如果项目未声明，默认使用**standard模式**。

**模式行为对照**：

| 场景 | strict | standard | comprehensive |
|------|--------|----------|---------------|
| Level 1 bug修复 | 仅代码注释 | 仅代码注释 | 仅代码注释 |
| Level 2无existing文档 | 跳过创建 | 根据决策树判断 | 创建MODULE文档 |
| Level 2有existing文档 | 更新 | 更新 | 更新+扩展 |
| Level 3架构变更 | 询问用户 | 更新ARCHITECTURE.md | 创建完整文档集 |

### 1.4 Planning Document Structure

**双轨规划系统**:

Claude Code 支持两套互补的规划系统，根据场景选择：

#### Option A: Superpowers 工作流（推荐用于实施计划）

**适用场景**: Level 3 系统级架构变更，需要详细的逐步实施计划

**位置**: `<project>/docs/plans/YYYY-MM-DD-<feature>.md`

**工作流**:
```
brainstorming → using-git-worktrees → writing-plans → executing-plans
```

**优势**:
- 任务粒度细（2-5分钟/任务）
- 完整代码示例和命令
- 强制 TDD、DRY、YAGNI
- 集成 git worktree 隔离

**使用方法**: 调用 `brainstorming` skill 开始

---

#### Option B: 架构规划文档（用于高层设计）

**适用场景**: Level 3 系统级架构设计，需要记录架构决策和长期维护

**位置**: `<project>/docs/ARCHITECTURE.md` 或 `<project>/ARCHITECTURE.md`

**推荐**: `<project>/docs/ARCHITECTURE.md`（与其他文档一起，便于查看和版本控制）

**目录结构**:
```
<project>/
├── .claude/
│   ├── system-instructions.txt  # 项目特定规则（推荐，如 csfilter）
│   ├── settings.local.json      # 权限配置
│   └── plans/                   # （可选）临时规划，不提交到 git
├── docs/
│   ├── ARCHITECTURE.md          # 架构文档（推荐位置）
│   ├── MODULE_A.md              # 模块文档（如 csfilter 的 COLLECTOR_ARCHITECTURE.md）
│   └── plans/                   # Superpowers 实施计划（提交到 git）
│       └── 2026-02-02-feature.md
└── src/
```

**必需内容**:
1. **元信息**: 日期、状态、优先级
2. **目标概述**: 清晰具体的目标
3. **架构设计**:
   - 系统架构（高层设计和组件关系）
   - 技术栈和工具
   - 数据流
   - API/接口规范（函数签名、类设计）
4. **TodoList**: 按状态分类的任务分解
5. **工作流步骤**: 详细执行计划
6. **设计决策记录**: 关键技术选择的理由
7. **成功标准**: 如何判断完成
8. **历史**: 变更日志

**规划工作流**:
```
Create Plan → Get Confirmation → Implement → Update Progress → Archive
     ↓              ↓                  ↓            ↓             ↓
  Use template   User approves    Write code    Update doc    Move to archive/
```

**逐步指南**:

1. **Create Plan**
   - 复制模板到 `<project>/.claude/plans/active/your-project.md`
   - 填写所有必需章节
   - 在 `PLANS_INDEX.md` 中添加引用

2. **Get Confirmation**
   - 向用户呈现设计
   - 明确批准后再继续
   - 处理任何疑虑或变更

3. **Implement**
   - 首先阅读架构文档
   - 使用 TaskCreate 跟踪任务
   - 遵循文档化的设计决策
   - 随着实施更新文档

4. **Update Documentation**
   - 更新 docs/ARCHITECTURE.md 反映架构变更
   - 创建或更新模块文档（如 docs/MODULE_NAME.md）
   - 记录关键设计决策

---

#### 选择哪个系统？

| 标准 | Superpowers (`docs/plans/`) | 架构文档 (`docs/`) |
|------|---------------------------|---------------------------|
| **目标** | 逐步实施指南 | 架构决策记录 |
| **粒度** | 细粒度任务（2-5分钟） | 高层设计和模块说明 |
| **代码** | 完整代码示例 | 接口和签名 |
| **执行** | executing-plans skill | 手动实施 |
| **隔离** | Git worktree | 当前分支 |
| **版本控制** | 提交到 git | 提交到 git |
| **最佳用途** | 新功能实施 | 系统设计文档化 |
| **示例** | `docs/plans/2026-02-02-auth.md` | `docs/ARCHITECTURE.md`<br>`docs/COLLECTOR_ARCHITECTURE.md` |

**推荐组合**（参考 csfilter）:
- 架构文档：`docs/ARCHITECTURE.md`（总架构）+ `docs/MODULE_*.md`（模块文档）
- 实施计划：`docs/plans/YYYY-MM-DD-feature.md`（Superpowers 生成）
- 项目规则：`.claude/system-instructions.txt`（项目特定执行准则）

### 1.5 Execution Rules

- **Read before edit**: 总是先读取目标文件
- **Confirm when needed**: 对架构级变更或需求不明确时征求确认
- **Sync Docs**: 如果更改逻辑，更新说明（注释/文档）
- **Avoid "Ghost" Plans**: 除非被要求，否则避免为琐碎任务创建完整计划文件
- **Check before documenting**: 使用Glob检查docs/目录避免重复创建文档
- **Follow decision tree**: 严格遵循Section 1.3.1的文档决策树
- **Default to standard**: 项目未声明模式时使用standard模式

---

## 2. Code Quality Standards

### 2.1 Python Code Style

When generating Python code:

**Mandatory**:
- Follow PEP 8 guidelines
- Use type hints for function parameters and return values
- Include docstrings for functions and classes (Google-style format)
- Use descriptive variable names (snake_case)
- Limit line length to 88 characters (Black default)

**Workflow**:
- After generating or modifying Python code, automatically run `python-style` skill
- Ensure PEP 8 compliance before considering code complete

### 2.2 Quality Gates

代码**建议**在两个层次通过自动化检查：

#### Local Checks (Pre-commit Hooks)
在每次 `git commit` 时自动运行：
- `ruff format .` - 代码格式化
- `ruff check --fix .` - Linting
- 快速检查（< 30秒）

#### Remote Checks (CI/CD Pipeline)
在每次 `git push` 到远程仓库时自动运行：
- 所有本地检查 PLUS:
- `mypy .` - 类型检查
- `pytest --cov` - 完整测试套件和覆盖率报告
- Security scanning - 依赖和代码漏洞
- **所有检查应通过后才能合并请求**

**支持的 CI/CD 平台**:
- GitHub Actions
- GitLab CI
- Jenkins
- CircleCI
- 其他支持 Git hooks 的平台

#### Compliance Rules
- ✓ 确保代码在完成前能通过所有检查
- ✓ 如果检查失败，立即修复
- ✓ 避免绕过或禁用质量门控

### 2.3 Testing Requirements

**For New Functionality**:
- Write precise test cases before implementing
- Ensure all tests pass before considering implementation complete
- Test coverage must be comprehensive and meaningful
- **Target test coverage based on context**:
  - Critical logic (auth, payment, data integrity): 90%+
  - Business logic: 70-80%
  - Utilities and helpers: 60%+
  - UI components: Case-by-case

**For Existing Code**:
- Run existing test suite to verify no regressions
- All previous tests must pass
- Never break existing features

---

## 3. Development Best Practices

### 3.1 Backward Compatibility

**Principles**:
- Preserve existing functionality whenever possible
- Non-breaking changes should be the default approach
- Maintain API stability and data compatibility

**When Breaking Changes Are Necessary**:
- Clearly document breaking changes in planning document
- Provide migration guide if applicable
- Justify why breaking change is required

### 3.2 Error Handling and Logging

**Error Handling**:
- Always handle exceptions appropriately (never silently fail)
- Validate all inputs from external sources (user input, API calls, files)
- Provide meaningful error messages to users (not stack traces in production)

**Logging**:
- Use structured logging with appropriate levels:
  - **DEBUG**: Detailed diagnostic information
  - **INFO**: General informational messages
  - **WARNING**: Something unexpected but recoverable
  - **ERROR**: Error occurred but application continues
- Log critical operations: user actions, data changes, errors

### 3.3 Commit Messages

**Standard**: Google's convention style

**How to Apply**:
- Use `commit` skill to generate commit messages
- Do not manually craft commit messages

---

## 4. Integration with Claude Code Tools

### 4.1 Task Management Tools

**Purpose**: 从规划文档跟踪任务

**Available Tools**:
- **TaskCreate**: 创建新任务
- **TaskUpdate**: 更新任务状态（pending/in_progress/completed）
- **TaskList**: 列出所有任务
- **TaskGet**: 获取特定任务详情

**Best Practices**:
- 与规划文档的 TodoList 章节同步任务
- 实时标记任务为 in_progress/completed
- 同时只有一个任务应为 in_progress
- 完成后立即标记任务为 completed（不要批量处理）
- 如果任务失败或被阻塞，保持 in_progress 并为阻塞项创建新任务

**When to Use**:
- 多步骤任务（3个或更多步骤）
- 非琐碎的复杂任务
- 用户明确请求待办列表
- 用户提供多个任务

**When NOT to Use**:
- 单一、直接的任务（< 3步完成）
- 纯会话或信息性任务

**Example Usage**:
```javascript
// Create task
TaskCreate({
  subject: "Implement JWT authentication",
  description: "Add JWT token validation to auth.py",
  activeForm: "Implementing JWT authentication"
})

// Update to in_progress when starting
TaskUpdate({
  taskId: "1",
  status: "in_progress"
})

// Mark completed when done
TaskUpdate({
  taskId: "1",
  status: "completed"
})
```

### 4.2 Superpowers Skills Integration

**Purpose**: 增强工作流的专业技能

**Core Skills**:
- **brainstorming**: Level 3 架构变更前**必需**使用
- **writing-plans**: 在 brainstorming 后创建详细实施计划
- **executing-plans**: 在独立会话中批量执行计划
- **subagent-driven-development**: 在当前会话中通过子代理执行计划
- **using-git-worktrees**: 为功能工作创建隔离工作树
- **finishing-a-development-branch**: 完成开发分支（合并/PR/清理）

**Workflow Integration**:
```
Level 1 (文件级): 直接实施
Level 2 (模块级): 可选使用 brainstorming
Level 3 (系统级): brainstorming → writing-plans → executing-plans → finishing
```

**When to Use Each**:
- **brainstorming**: 创建功能、构建组件、添加功能或修改行为之前
- **writing-plans**: 有规范或多步骤任务需求时
- **executing-plans**: 有书面实施计划需在独立会话执行时
- **using-git-worktrees**: 开始需要与当前工作区隔离的功能工作前

详细说明见 Section 7: Superpowers Integration

### 4.3 AskUserQuestion Tool

**Purpose**: Gather requirements and clarify ambiguity

**When to Use**:
- Multiple valid approaches exist for implementation
- User preferences matter for the implementation
- Requirements are unclear or ambiguous
- Need to choose between architectural options

**How to Use**:
- Present 2-4 options with clear descriptions
- Use multiSelect when choices are not mutually exclusive
- Always provide "Other" option for custom input

### 4.4 Read/Edit Tools

**Purpose**: 管理规划文档和代码

**Workflow**:
- **Read** 规划文档后再编写任何代码
- **Edit** 规划文档随决策演变
- **Read** 现有代码后再建议修改
- **Edit** 现有代码文件（优于创建新文件）
- **Write** 新文件仅在明确需要时

**Best Practice**: 在提出代码变更前先读取文件

---

## 5. Project vs Global Configuration

### 5.1 This Document (Global CLAUDE.md)

位置: `~/.claude/CLAUDE.md`

适用于**所有项目**:
- 开发工作流原则（Level 1/2/3）
- 代码质量标准
- 开发最佳实践
- 工具使用指南
- Superpowers 技能整合

### 5.2 Project-Specific Configuration

每个项目可能有自己的配置文件：

#### Option 1: 完整 CLAUDE.md
位置: `<project>/.claude/CLAUDE.md`

包含:
- 项目特定目标和范围
- 详细的项目系统架构
- 模块分解和接口
- 项目特定的设计决策
- 覆盖全局默认值的自定义规则

#### Option 2: system-instructions.txt
位置: `<project>/.claude/system-instructions.txt`

包含:
- 简化的项目特定指令
- 不需要完整 CLAUDE.md 的轻量级替代方案

#### Option 3: settings.local.json + ARCHITECTURE.md
位置:
- `<project>/.claude/settings.local.json`
- `<project>/ARCHITECTURE.md` 或 `<project>/docs/ARCHITECTURE.md`

包含:
- JSON 中的 Claude Code 设置
- Markdown 中的架构文档

**Configuration Hierarchy**:
```
Global ~/.claude/CLAUDE.md (默认)
    ↓ (覆盖)
Project .claude/CLAUDE.md
    ↓ (如果不存在，则回退到)
Project .claude/system-instructions.txt
    ↓ (补充)
Project ARCHITECTURE.md
```

**Relationship**:
- Global CLAUDE.md 定义**如何**工作（流程、标准、工具）
- Project CLAUDE.md/system-instructions.txt 定义**什么**构建（特定实施）
- 使用规划系统创建项目 ARCHITECTURE.md

---

## 6. Common Workflows

### 6.1 Starting a New Project

**Option A: Using Superpowers (Recommended)**
1. 使用 `brainstorming` skill 理解需求
2. 使用 `using-git-worktrees` 创建隔离工作区
3. 使用 `writing-plans` 创建实施计划到 `docs/plans/YYYY-MM-DD-project.md`
4. 使用 `executing-plans` 或 `subagent-driven-development` 执行
5. 使用 `finishing-a-development-branch` 完成并合并

**Option B: Using Architecture Documentation**
1. 创建 `<project>/docs/ARCHITECTURE.md`（总架构）
2. 填写架构设计（目标、技术栈、模块、数据流）
3. 获取用户对设计的确认
4. 创建 `.claude/system-instructions.txt`（项目特定规则）
5. 使用 TaskCreate 跟踪实施任务
6. 随进展创建模块文档（`docs/MODULE_*.md`）

### 6.2 Adding a Feature to Existing Project

**Option A: Using Superpowers (For Complex Features)**
1. 使用 `brainstorming` skill 探索功能设计
2. 使用 `using-git-worktrees` 创建功能分支
3. 使用 `writing-plans` 创建实施计划
4. 使用 `executing-plans` 执行
5. 使用 `finishing-a-development-branch` 完成

**Option B: Direct Implementation (For Simple Features)**
1. 读取现有 `docs/ARCHITECTURE.md` 和相关模块文档
2. 确保新功能符合现有架构
3. 如需要获取用户确认
4. 直接实施
5. 更新 `docs/ARCHITECTURE.md` 或创建 `docs/MODULE_*.md`

### 6.3 Fixing a Bug

**Level 1 (Simple Bug)**:
1. 使用 `debug` skill 分析（可选）
2. 读取受影响代码后提出修复
3. 实施修复
4. 添加测试防止回归

**Level 2/3 (Complex Bug)**:
1. 使用 `debug` skill 进行系统性调试
2. 如 bug 修复复杂则创建最小规划文档
3. 读取受影响代码后提出修复
4. 实施修复
5. 添加测试防止回归
6. 如需要更新规划文档

---

## 7. Superpowers Skills Integration

Claude Code 与 Superpowers 技能生态深度集成，提供增强的工作流能力。

### 7.1 Complete Development Lifecycle

```
brainstorming → using-git-worktrees → writing-plans → executing-plans → finishing-a-development-branch
      ↓                  ↓                   ↓                ↓                     ↓
  理解需求        创建隔离工作区      创建实施计划      批量执行任务           完成开发分支
```

### 7.2 Skill-by-Skill Guide

#### brainstorming
**何时使用**: 创建功能、构建组件、添加功能或修改行为之前（Level 3 **必需**）

**功能**:
- 通过自然协作对话将想法转化为设计
- 一次探索一个问题以细化想法
- 提出 2-3 种不同方法及权衡
- 将验证的设计写入 `docs/plans/YYYY-MM-DD-<topic>-design.md`

**输出**:
- 设计文档在 `docs/plans/`
- 继续到 writing-plans 的选项

#### using-git-worktrees
**何时使用**: 开始需要与当前工作区隔离的功能工作或执行实施计划之前

**功能**:
- 创建隔离的 git worktree
- 智能目录选择和安全验证
- 保持主工作区清洁

**推荐**: 在调用 writing-plans 前使用

#### writing-plans
**何时使用**: 有规范或多步骤任务需求时，在接触代码前

**功能**:
- 创建全面的实施计划
- 细粒度任务（每个 2-5 分钟）
- 包含完整代码示例、测试和命令
- 强制 TDD、DRY、YAGNI

**位置**: `docs/plans/YYYY-MM-DD-<feature>.md`

**输出**:
- 实施计划文档
- 选项 1: subagent-driven-development（当前会话）
- 选项 2: executing-plans（独立会话）

#### executing-plans
**何时使用**: 有书面实施计划需在独立会话中通过审查检查点执行时

**功能**:
- 加载计划、批判性审查、批量执行任务
- 默认批次：前 3 个任务
- 批次间检查点进行架构师审查

**流程**:
1. 加载和审查计划
2. 执行批次（前 3 个任务）
3. 报告并等待反馈
4. 继续直到完成
5. 使用 finishing-a-development-branch 完成

#### subagent-driven-development
**何时使用**: 在当前会话中执行有独立任务的实施计划时

**功能**:
- 为每个任务分派新鲜子代理
- 任务间代码审查
- 快速迭代

**对比 executing-plans**:
- subagent-driven: 当前会话，任务间审查
- executing-plans: 独立会话，批次间审查

#### finishing-a-development-branch
**何时使用**: 实施完成、所有测试通过且需要决定如何集成工作时

**功能**:
- 验证测试通过
- 呈现结构化选项：合并、PR 或清理
- 指导开发工作完成

### 7.3 Level-Based Skill Usage

| Level | Required Skills | Optional Skills | Workflow |
|-------|----------------|-----------------|----------|
| **Level 1** | - | debug | Direct implementation |
| **Level 2** | - | brainstorming, debug | brainstorming → Direct implementation |
| **Level 3** | brainstorming, writing-plans | using-git-worktrees, executing-plans, subagent-driven-development, finishing-a-development-branch | Full Superpowers workflow |

### 7.4 Planning System Comparison

| Aspect | Superpowers (`docs/plans/`) | Architecture Docs (`docs/`) |
|--------|---------------------------|----------------------------------------|
| **Created By** | writing-plans skill | Manual (inspired by csfilter) |
| **Granularity** | Fine-grained (2-5 min tasks) | High-level modules |
| **Code Examples** | Complete code snippets | Interface signatures |
| **Execution** | executing-plans skill | Manual implementation |
| **TDD Enforcement** | Yes (forced) | Recommended |
| **Git Integration** | Worktree-based | Current branch |
| **File Location** | `docs/plans/2026-02-02-*.md` | `docs/ARCHITECTURE.md`<br>`docs/MODULE_*.md` |
| **Best For** | Feature implementation | System design documentation |

### 7.5 Choosing the Right Approach

**Use Superpowers When**:
- Building new features from requirements
- Need step-by-step implementation guidance
- Want TDD enforcement
- Prefer isolated worktree development
- Need frequent checkpoints

**Use Architecture Docs When**:
- Documenting system design long-term
- Recording architectural decisions
- Need high-level design overview
- Want persistent design documentation
- Building modular systems (like csfilter)

**Use Both When**:
- Large system-level changes (Level 3)
- Strategy: Create `docs/ARCHITECTURE.md` for design → Use Superpowers for implementation (`docs/plans/2026-02-02-*.md`)

---

## 8. Personal Knowledge Base (Obsidian)

**Vault 路径**: `~/Documents/obsidian/mixiaomi`

- 知识库操作（写入、检索、综合、洞察、浏览）→ 使用 `kb` skill
- X/Twitter 链接保存 → 使用 `x2md` skill
- 两个 skill 共享同一套分类体系和 frontmatter 规范

---

**Version**: 3.1.0
**Last Updated**: 2026-02-05
**Major Changes**:
- 文档控制增强：新增Section 1.3.1文档决策树，防止过度生成文档
- 文档模式系统：新增Section 1.3.2项目文档模式（strict/standard/comprehensive）
- 智能判断规则：明确Level分类标准和文档必要性检查流程
- 执行规则更新：新增"Check before documenting"等3条规则

**Version History**:
- 3.1.0 (2026-02-05): 文档控制增强
- 3.0.0 (2026-02-02): 项目导向化、平台通用化、语言人性化、工具修正、Superpowers整合、双轨系统
