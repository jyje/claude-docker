<!-- Translated from readme.md at 4892c7a -->
<div align="center">
  
  # jyje/claude-docker
  
  <!-- center logo -->
  <img width="150" src="https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/light/claude-color.png" alt="Claude" title="Claude"/>
  
  Claude Code：社区驱动的 Docker 镜像

  [![release](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml/badge.svg?branch=main)](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml)
  [![test](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml/badge.svg?branch=develop)](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml)
  [![cron](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml/badge.svg)](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml)
  [![GitHub Repo stars](https://img.shields.io/github/stars/jyje/claude-docker)](https://github.com/jyje/claude-docker)

  [English](readme.md) / [한국어](readme-ko.md) / [简体中文](readme-zh-CN.md) / [日本語](readme-ja.md)

</div>

> [!NOTE]
> 本译文由 AI 辅助完成，尚未经过母语者审校，欢迎通过 PR 提出修改。如与英文版有出入，以英文版 [readme.md](readme.md) 为准。

⭐ **如果这个项目对你有帮助，欢迎在 GitHub 上点个 Star！**

🤖 本仓库提供由社区维护的 [Claude Code](https://code.claude.com/docs) Docker 镜像，基于 Node.js 26 构建，支持 `linux/amd64` 和 `linux/arm64` 架构。

> [!IMPORTANT]
> 本仓库与 Anthropic 没有任何关联，是由社区维护、面向 Claude Code 用户的 Docker 镜像项目。官方信息请访问 [code.claude.com/docs](https://code.claude.com/docs)。

> [!NOTE]
> **基于 Anthropic 官方 Dockerfile**  
> 本 Docker 镜像基于 [Anthropic 官方 Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile) 构建，并为社区使用做了增强，包括 Node.js 26、自动化 CI/CD 流水线以及多架构支持。

## 📚 文档

**快速上手**
- [快速开始与基本用法](docs/getting-started-zh-CN.md) - 环境配置、Docker 用法、API 认证、快速测试

**进阶指南**
- [进阶指南](docs/advanced-guide-zh-CN.md) - Argo Workflows、Kubernetes Job/CronJob、CI/CD 集成

## 环境变量

Claude Code 会读取很多环境变量。下面的表格列出了在 Docker、Kubernetes 或 CI 中运行本镜像时最重要的那些。

> [!NOTE]
> 完整的受支持变量列表，请参阅官方文档：**[Claude Code 环境变量](https://code.claude.com/docs/en/env-vars)**。

### 认证与端点

| 变量 | 是否必需 | 说明 |
|------|----------|------|
| `ANTHROPIC_API_KEY` | 是\* | 以 `X-Api-Key` 请求头发送的 API 密钥。可在 [console.anthropic.com](https://console.anthropic.com/) 获取 |
| `ANTHROPIC_AUTH_TOKEN` | 否 | 自定义 `Authorization` 请求头的值，会自动加上 `Bearer ` 前缀。通过网关认证时很常用 |
| `ANTHROPIC_BASE_URL` | 否 | 让请求经由代理或网关转发。也用于本地模型（例如 Docker Model Runner） |
| `ANTHROPIC_CUSTOM_HEADERS` | 否 | 额外的请求头，格式为 `Name: Value`，多个请求头用换行分隔 |
| `ANTHROPIC_BETAS` | 否 | 以逗号分隔的 `anthropic-beta` 值，用于在 Claude Code 原生支持之前提前启用某个 API 测试版功能 |

\* 除非你使用其他方式认证，例如订阅账号登录、网关令牌，或下文的某个云服务提供商，否则为必需。

> [!CAUTION]
> `ANTHROPIC_API_KEY` 和 `ANTHROPIC_AUTH_TOKEN` 都是机密信息。请使用 `-e VAR`（从当前 shell 读取）或 `--env-file` 传入，切勿把值硬编码到 `Dockerfile` 或提交进仓库的 compose 文件里。

### 模型选择

| 变量 | 说明 |
|------|------|
| `ANTHROPIC_MODEL` | 本次会话使用的模型 |
| `ANTHROPIC_DEFAULT_MODEL` | 新会话默认启动时使用的模型（需要 Claude Code v2.1.236 或更高版本） |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `opus` 别名所对应的模型 ID |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `sonnet` 别名所对应的模型 ID |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `haiku` 别名所对应的模型 ID，也用于后台功能 |

### 云服务提供商

| 变量 | 说明 |
|------|------|
| `CLAUDE_CODE_USE_BEDROCK` | 使用 [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock) |
| `CLAUDE_CODE_USE_VERTEX` | 使用 [Google Cloud 的 Agent Platform](https://code.claude.com/docs/en/google-vertex-ai) |
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP 项目 ID。会被 `GCLOUD_PROJECT`、`GOOGLE_CLOUD_PROJECT` 或凭据文件中的项目覆盖 |
| `ANTHROPIC_BEDROCK_BASE_URL` | 覆盖 Amazon Bedrock 端点，用于自定义端点或 LLM 网关 |
| `ANTHROPIC_VERTEX_BASE_URL` | 覆盖 Google Cloud 端点，用于自定义端点或 LLM 网关 |

### 网络、代理与网关兼容性

| 变量 | 说明 |
|------|------|
| `HTTP_PROXY` | 网络连接使用的 HTTP 代理服务器 |
| `HTTPS_PROXY` | 网络连接使用的 HTTPS 代理服务器 |
| `NO_PROXY` | 需要绕过代理、直接访问的域名和 IP |
| `API_TIMEOUT_MS` | API 请求超时时间，单位为毫秒（默认 `600000`，即 10 分钟）。在网络较慢或经由代理转发时可以调大 |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | 设为 `1` 时，会从请求中去掉 `anthropic-beta` 请求头和测试版工具 schema 字段。网关拒绝这些内容时使用。与 `ANTHROPIC_BETAS` 相对应，并且会同时禁用 MCP 工具搜索 |

> [!TIP]
> 如果你用网络沙箱（`--cap-add=NET_ADMIN --cap-add=NET_RAW`）运行本镜像，请注意 `init-firewall.sh` 会限制出站流量。这里配置的代理主机也必须能通过该防火墙访问。

### 执行限制与 Token 预算

| 变量 | 说明 |
|------|------|
| `BASH_DEFAULT_TIMEOUT_MS` | 长时间运行的 bash 命令的默认超时时间（默认 `120000`，即 2 分钟） |
| `BASH_MAX_TIMEOUT_MS` | 模型可为 bash 命令设置的最长超时时间（默认 `600000`，即 10 分钟） |
| `BASH_MAX_OUTPUT_LENGTH` | 读回结果中保留的 bash 输出最大字符数（默认 `30000`，上限 `150000`） |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 大多数请求的最大输出 token 数。默认值和上限因模型而异 |
| `MAX_THINKING_TOKENS` | 扩展思考的固定 token 预算 |
| `MCP_TIMEOUT` | MCP 服务器启动超时时间，单位为毫秒（默认 `30000`，即 30 秒） |
| `MAX_MCP_OUTPUT_TOKENS` | MCP 工具响应允许的最大 token 数 |

在 CI 中运行非交互模式（`claude -p`）时，这些变量值得调整，因为默认值对于耗时较长的构建或响应较慢的 MCP 服务器往往过紧。

### 容器运维、更新与隐私

| 变量 | 说明 |
|------|------|
| `CLAUDE_CONFIG_DIR` | 覆盖配置目录（默认 `~/.claude`）。设置、会话历史和插件都保存在这里，因此请把卷挂载指向这个路径 |
| `DISABLE_AUTOUPDATER` | 设为 `1` 可禁用后台自动更新。手动执行 `claude update` 仍然有效 |
| `DISABLE_UPDATES` | 设为 `1` 会阻止所有更新，包括手动执行 `claude update`。比 `DISABLE_AUTOUPDATER` 更严格，对于固定版本的镜像通常正是你想要的 |
| `DISABLE_TELEMETRY` | 退出遥测。请参阅下方警告 |
| `DO_NOT_TRACK` | 设为 `1` 可退出遥测，效果与 `DISABLE_TELEMETRY` 相同。它按普通布尔值解析，因此 `0` 会保持遥测开启 |
| `DISABLE_ERROR_REPORTING` | 退出错误上报。请参阅下方警告 |
| `CLAUDECODE` | 由 Claude Code 在它所启动的子进程中设为 `1`。可用它判断脚本是否运行在 Claude Code 之下 |

> [!WARNING]
> `DISABLE_TELEMETRY` 和 `DISABLE_ERROR_REPORTING` 只要设置了**任何非空值就会退出，包括 `0` 和 `false`**。传入 `-e DISABLE_TELEMETRY=0` 并不会重新开启遥测，遥测仍然是关闭的。要重新开启，必须完全不设置该变量。`DO_NOT_TRACK` 是例外：它按普通布尔值解析，所以 `DO_NOT_TRACK=0` 确实会保持遥测开启。
>
> 这两个遥测退出选项同时也会禁用功能开关（feature flag）的拉取，导致 Remote Control 等依赖功能开关的功能不可用。

> [!TIP]
> 由于本镜像发布的是固定版本，设置 `DISABLE_UPDATES=1` 可以防止 Claude Code 在运行时自我更新，从而让带标签的镜像保持可复现。

> [!TIP]
> 关于 Docker、Kubernetes 和 API 密钥认证的详细用法示例，请参阅**[快速开始指南](docs/getting-started-zh-CN.md)**。

## 预装工具

本镜像预装了以下工具：

```
- @anthropic-ai/claude-code (latest or specified version)
- node 26
- npm

- git + git-delta (diff viewer)
- zsh + powerline10k theme
- fzf (fuzzy finder)
- gh (GitHub CLI)
- jq, curl, wget
- nano, vim
- iptables, ipset, iproute2 (for network sandbox)
```

## MCP (Model Context Protocol) 连接

Claude Code 支持 [MCP](https://modelcontextprotocol.io/)，可以连接 GitHub、数据库和各类 API 等外部工具与数据源。

### 在容器内添加 MCP 服务器

```bash
# Start container
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  -v claude-mcp-config:/home/node/.claude \
  ghcr.io/jyje/claude-docker

# Inside container: Add MCP servers
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://user:pass@host:5432/db"

# List configured servers
claude mcp list

# Check server status
/mcp
```

### 使用 .mcp.json 配置

在项目根目录创建 `.mcp.json`，即可与团队共享 MCP 配置：

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    },
    "postgres": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@bytebase/dbhub", "--dsn", "${DATABASE_URL}"],
      "env": {
        "DATABASE_URL": "${DATABASE_URL}"
      }
    },
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/workspace"]
    }
  }
}
```

然后将其挂载进容器：

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -v $(pwd):/workspace \
  -v $(pwd)/.mcp.json:/home/node/.mcp.json:ro \
  ghcr.io/jyje/claude-docker
```

### 常用 MCP 服务器

| 服务器 | 命令 |
|--------|------|
| GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| PostgreSQL | `claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://..."` |
| Filesystem | `claude mcp add --transport stdio fs -- npx -y @modelcontextprotocol/server-filesystem /workspace` |

更多 MCP 服务器请参阅 [GitHub 上的 MCP Servers](https://github.com/modelcontextprotocol/servers)。

## DevContainer 支持

本仓库包含适用于 VS Code Dev Containers 的 `.devcontainer` 配置。使用方法：

1. 安装 [Dev Containers 扩展](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. 克隆本仓库
3. 在宿主机上设置 `ANTHROPIC_API_KEY` 环境变量
4. 用 VS Code 打开，然后点击 "Reopen in Container"

devcontainer 会自动完成：
- 配置网络沙箱（防火墙）
- 配置 zsh 和 powerline10k
- 将你的工作区挂载到 `/workspace`
- 持久化命令历史和 Claude 配置

## CI 流水线

本仓库通过自动化 CI 流水线构建并管理 Claude Code Docker 镜像，支持两种主要的部署策略：

### `main` 分支（正式发布）
- **自动执行**：提交到 `main` 分支会自动构建并发布正式镜像。
- **标签策略**：生成标准版本标签（例如 `v2.0.0`）。只有当该版本是绝对最新的版本时，才会同时打上 `latest` 以及 `major`/`minor` 标签，避免较旧的补丁版本覆盖当前的部署。
- **发布说明**：自动生成带有详细更新日志的 GitHub Release。

### `develop` 分支（开发构建）
- **自动执行**：提交到 `develop` 分支会自动构建并发布测试镜像。
- **标签策略**：使用 `-dev:[20 位 SHA]` 和 `-dev:latest` 标签，彻底避免哈希冲突。
- **存储管理**：实现了自动垃圾回收（GC），只在 GHCR 中保留最近的 20 个开发镜像，以优化存储空间。

### 通用能力
- **多架构**：构建同时支持 `linux/amd64` 和 `linux/arm64`。
- **自动更新**：定时任务每 6 小时检查一次 Claude Code 的新版本，并自动创建 Pull Request。每次发布完成后它也会立即再运行一次，因此积压的版本会逐个 PR 依次处理。每个 PR 都会在两个平台上原生构建，并报告 `version-check` 状态，合并始终由人工完成。
- **跳过 CI**：在提交信息中加入 `--no-ci` 标志，即可让该提交跳过 CI 流水线。

## 参与贡献

有关如何为本项目做贡献，请参阅[贡献指南](contributing.md)。

## 许可证

本项目基于 MIT 许可证发布。详情请参阅 [license.md](license.md)。

Claude Code 是 [Anthropic](https://www.anthropic.com/) 的产品。本项目与 Anthropic 没有任何关联。
