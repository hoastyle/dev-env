# MCP服务器配置说明

本项目已配置以下MCP（Model Context Protocol）服务器以增强Claude Code的功能。

## 已配置的MCP服务器

### 1. **filesystem** - 文件系统访问
- **功能**: 增强的文件操作能力
- **配置**: 无需API密钥
- **访问路径**: `/home/howie`

### 2. **memory** - 知识图谱记忆
- **功能**: 跨会话持久化记忆，使用知识图谱存储信息
- **配置**: 无需API密钥
- **存储位置**: 自动管理

### 3. **sequential-thinking** - 顺序思考
- **功能**: 增强的问题解决和思考能力
- **配置**: 无需API密钥

### 4. **tavily** - 高级网络搜索
- **功能**: 专为AI代理优化的网络搜索
- **需要API密钥**: [Tavily API Key](https://tavily.com/)
- **获取方式**:
  1. 访问 https://tavily.com/
  2. 注册账号
  3. 获取API密钥
  4. 编辑 `.mcp.json` 文件，在 `tavily.env.TAVILY_API_KEY` 中填入密钥

### 5. **exa** - AI网络搜索
- **功能**: 实时网络搜索和研究能力
- **需要API密钥**: [Exa API Key](https://exa.ai/)
- **获取方式**:
  1. 访问 https://exa.ai/
  2. 注册账号
  3. 获取API密钥
  4. 编辑 `.mcp.json` 文件，在 `exa.env.EXA_API_KEY` 中填入密钥

### 6. **brave-search** - Brave搜索
- **功能**: 使用Brave Search API进行网络搜索
- **需要API密钥**: [Brave Search API Key](https://brave.com/search/api/)
- **获取方式**:
  1. 访问 https://brave.com/search/api/
  2. 注册账号
  3. 获取API密钥
  4. 编辑 `.mcp.json` 文件，在 `brave-search.env.BRAVE_API_KEY` 中填入密钥

### 7. **puppeteer** - 浏览器自动化
- **功能**: 无头浏览器自动化，网页截图和数据抓取
- **配置**: 无需API密钥

## 配置API密钥

编辑项目根目录下的 `.mcp.json` 文件：

```json
{
  "mcpServers": {
    "tavily": {
      "command": "npx",
      "args": ["-y", "tavily-mcp"],
      "env": {
        "TAVILY_API_KEY": "你的Tavily_API密钥"
      }
    },
    "exa": {
      "command": "npx",
      "args": ["-y", "exa-mcp-server"],
      "env": {
        "EXA_API_KEY": "你的Exa_API密钥"
      }
    },
    "brave-search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {
        "BRAVE_API_KEY": "你的Brave_API密钥"
      }
    }
  }
}
```

## 使用方式

MCP服务器会通过以下方式自动加载：

1. **项目级别**: 当前项目的 `.mcp.json` 文件
2. **自动安装**: 使用 `npx -y` 在首次使用时自动下载
3. **无需手动安装**: 配置文件中的服务器会在Claude Code启动时自动连接

## 验证安装

在Claude Code中运行以下命令验证MCP服务器状态：

```bash
# 查看所有MCP服务器
/mcp

# 查看MCP服务器工具
/mcp view <server-name>

# 启用/禁用MCP服务器
/mcp enable <server-name>
/mcp disable <server-name>
```

## 插件状态

以下插件已在 `~/.claude/settings.json` 中启用：

- ✅ **serena** - Serena集成
- ✅ **context7** - 实时文档访问
- ✅ **gitlab** - GitLab集成

## 故障排除

如果MCP服务器无法连接：

1. 检查网络连接
2. 验证API密钥是否正确
3. 使用 `claude --mcp-debug` 启动以查看详细错误信息
4. 检查 `~/.claude/logs/` 中的日志文件

## 安全建议

- 不要将 `.mcp.json` 文件中的真实API密钥提交到公共仓库
- 使用 `.mcp.json.local` 或环境变量管理敏感密钥
- 定期轮换API密钥

## 更多信息

- [MCP官方文档](https://modelcontextprotocol.io/)
- [Claude Code文档](https://code.claude.com/docs/en/plugins)
- [MCP服务器注册表](https://registry.modelcontextprotocol.io/)
