# MCP Servers

## 服务器列表

| 名称 | 用途 | 安装方式 | 需要的密钥 |
|------|------|---------|-----------|
| tavily | 搜索/抓取 API | npx (npm) | TAVILY_API_KEY |
| ucal | 跨平台内容抓取（浏览器） | uv run (本地项目) | 无（需 ~/projects/ucal） |
| lark-mcp | 飞书文档/消息/多维表格 | npx (npm) | Lark App ID + Secret |
| yunxiao | 阿里云云效 DevOps | npx (npm) | YUNXIAO_ACCESS_TOKEN |

## 新机器配置步骤

1. 运行 `cc-sync pull` — MCP 配置自动合并，密钥为占位符
2. 打开 `~/.claude.json`，搜索 `YOUR_` 找到占位符
3. 按下表填入真实密钥：

| 占位符 | 获取方式 |
|--------|---------|
| YOUR_TAVILY_API_KEY_HERE | tavily.com 控制台 |
| YOUR_LARK_APP_ID | 飞书开放平台 → 应用 → App ID |
| YOUR_LARK_APP_SECRET | 飞书开放平台 → 应用 → App Secret |
| YOUR_YUNXIAO_ACCESS_TOKEN_HERE | 云效 → 个人设置 → 个人访问令牌 |

4. ucal 需额外操作：
   ```bash
   git clone git@github.com:Mixiaomiupup/ucal.git ~/projects/ucal
   ```
