# 全局配置

这是 mixiaomi 的全局 CLAUDE.md，适用于所有项目。只包含 Claude 无法从代码或 skill 中推断的信息。

---

## 1. 写代码的约定

- Python: PEP 8 + type hints + Google docstrings，细节见 `python-style` skill
- 提交消息: Google convention，用 `commit` skill 生成
- 本地质量检查: `ruff format .` + `ruff check --fix .`（pre-commit 自动跑）
- 架构级变更（新应用、数据库迁移、API 重设计）必须走 brainstorming → writing-plans → executing-plans
- 文档生成遵循 `doc-control` skill，不过度生成

---

## 2. 我的工作流

除了写代码，我日常还有内容创作和项目管理两条线，都通过 skill 串联。

### 内容创作流水线

```
素材获取 → 文章生成 → 配图 → 知识沉淀 → 飞书发布
```

| 环节 | Skill | 一句话说明 |
|------|-------|-----------|
| 跨平台内容分析 | `ucal` | 给链接分析，说"调研XX"搜索综合 |
| X 信息流 | `x-feed` | 关注扩展、热点提取、知识蒸馏 |
| 具身智能资讯 | `embodied-intel` | 机器人行业日报 |
| X 帖子转 MD | `x2md` | X/Twitter URL → Obsidian 笔记 |
| 文章生成 | `article-gen` | 6 种类型：news/architecture/review/tutorial/notes/essay |
| 文章配图 | `article-image` | 封面图和插图，5D 风格系统 |
| AI 图片生成 | `gemini-image` | Gemini Vertex AI 生图/编辑/理解 |
| 知识库 | `kb` | Obsidian 写入/检索/综合/飞书同步/待办 |
| 飞书 API | `feishu` | wiki、文档、多维表格、消息 |

**日报约定**："科技日报" → `x-feed`；"机器人日报" → `embodied-intel`；只说"日报" → 问是哪个

### 项目管理

| Skill | 用途 |
|-------|------|
| `project-sync` | 云效迭代 → 飞书多维表格（数据同步） |
| `notify` | 云效迭代进展 → 飞书私信卡片（按部门/人员推送） |

---

## 3. 搜索和抓取工具

环境里有 3 套工具，能力不同，按场景选：

| 场景 | 首选 | 降级 |
|------|------|------|
| 搜索信息 | tavily_search | WebSearch |
| 读取已知 URL（静态） | tavily_extract | ucal_platform_read(generic) |
| JS 渲染页面 | ucal_platform_read(generic) | ucal_browser_action |
| 中国平台（小红书/知乎/X） | ucal_platform_read(平台名) | - |
| 飞书文档 | lark-mcp | - |
| 爬取多页 | tavily_crawl + tavily_map | - |
| 综合调研 | tavily_research | - |
| GitHub 内容 | gh CLI | tavily_extract |
| 页面交互 | ucal_browser_action | - |

**降级规则**: tavily 空 → ucal; WebFetch 被拦 → tavily → ucal; ucal 地区限制 → tavily

**已知限制**: WebFetch/WebSearch 不稳定; tavily 无 JS 渲染; ucal 慢且海外站不通; 飞书必须用 lark-mcp

---

## 4. Superpowers 路径

CWD 是 `/Users/mixiaomiupup/projects`（父目录），不在任何项目内。brainstorming/writing-plans 中的 `docs/plans/` 指的是**项目内**的目录，不是 CWD 的：

1. 从对话确定目标项目
2. `mkdir -p /Users/mixiaomiupup/projects/<project>/docs/plans`
3. 用绝对路径保存: `/Users/mixiaomiupup/projects/<project>/docs/plans/YYYY-MM-DD-<feature>.md`

无法确定项目时询问用户。不适用于 Claude Code 内置 plan mode 文件（`~/.claude/plans/`）。

---

## 5. Obsidian 知识库

**Vault**: `~/Documents/obsidian/mixiaomi`

- 知识库操作 → `kb` skill
- X/Twitter 链接 → `x2md` skill

---

## 6. Skill 架构维护

修改 `~/.claude/skills/` 下的 SKILL.md 后，判断是否需要同步更新架构文档：

**触发**: 增删 skill、工作流步骤变化、依赖关系变化、API 调用方式变化、新增关键约束
**不触发**: typo、措辞、代码格式、注释补充、流程不变的内容扩充

**更新步骤**: Edit `~/.claude/skills/ARCHITECTURE.md` → 同步 `~/Documents/obsidian/mixiaomi/技术笔记/Skill架构.md` → 如 skill 增删则更新下方索引

### Skill 索引

**内容创作**: article-gen | article-image | gemini-image | x2md | ucal | x-feed | embodied-intel | kb | feishu

**项目管理**: project-sync | notify

**开发工具**: commit | remote-repos | sync-config | server | debug | test | review | refactor | python-style | explain

**独立工具**: youpin | doc-control | skill-creator

**详细架构**: `Read ~/.claude/skills/ARCHITECTURE.md`

---

**Version**: 5.0.0 | **Updated**: 2026-03-21
**Changes**: 重写结构。去掉 Quick Reference 冷启动、去掉自定义 L1/L2/L3 分级（Claude 内置行为）。以"我的约定→我的工作流→我的工具"为主线，读起来像人话。
