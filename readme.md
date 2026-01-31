<div align="center">
  
  # jyje/claude-docker
  
  <!-- center logo -->
  <img width="250" src="https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/light/claude-color.png" alt="Claude" title="Claude"/>
  
  Claude Code: Community-Powered Docker Image

  [![release](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml/badge.svg?branch=main)](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml)
  [![test](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml/badge.svg?branch=develop)](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml)
  [![cron](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml/badge.svg)](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml)
  [![GitHub Repo stars](https://img.shields.io/github/stars/jyje/claude-docker)](https://github.com/jyje/claude-docker)

  [English](readme.md) / [한국어](readme-ko.md)

</div>

🤖 This repository provides [Claude Code](https://docs.anthropic.com/en/docs/claude-code) Docker images powered by community. Built with Node.js 24. Supported architectures are `linux/amd64`, `linux/arm64`.

> [!IMPORTANT]
> This repository is not affiliated with Anthropic. This is a community-maintained project that provides a Docker image for Claude Code users. For official information, visit [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code).

> [!NOTE]
> **Based on Official Anthropic Dockerfile**  
> This Docker image is built upon the [official Anthropic Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile), with enhancements for community use including Node.js 24, automated CI/CD pipelines, and multi-architecture support.

## 📚 Documentation

- **[Getting Started Guide](getting-started.md)** - Quick start, environment setup, basic usage, and authentication
- **[한국어 시작 가이드](getting-started-ko.md)** - 빠른 시작, 환경 설정, 기본 사용법 및 인증

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Your Anthropic API key. Get one at [console.anthropic.com](https://console.anthropic.com/) |
| `ANTHROPIC_BASE_URL` | No | Custom API endpoint URL. Use for local models (e.g., Docker Model Runner) or custom endpoints |

> [!TIP]
> For detailed usage examples including Docker, Kubernetes, and API key authentication, see the **[Getting Started Guide](getting-started.md)**.

## Pre-installed Utilities

This image provides the following utilities pre-installed:

```
- @anthropic-ai/claude-code (latest or specified version)
- node 24
- npm

- git + git-delta (diff viewer)
- zsh + powerline10k theme
- fzf (fuzzy finder)
- gh (GitHub CLI)
- jq, curl, wget
- nano, vim
- iptables, ipset, iproute2 (for network sandbox)
```

## MCP (Model Context Protocol) Connection

Claude Code supports [MCP](https://modelcontextprotocol.io/) to connect to external tools and data sources like GitHub, databases, and APIs.

### Adding MCP Servers Inside Container

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

### Using .mcp.json Configuration

Create `.mcp.json` in your project root for team-shared MCP configuration:

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

Then mount it:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -v $(pwd):/workspace \
  -v $(pwd)/.mcp.json:/home/node/.mcp.json:ro \
  ghcr.io/jyje/claude-docker
```

### Popular MCP Servers

| Server | Command |
|--------|---------|
| GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| PostgreSQL | `claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://..."` |
| Filesystem | `claude mcp add --transport stdio fs -- npx -y @modelcontextprotocol/server-filesystem /workspace` |

For more MCP servers, see [MCP Servers on GitHub](https://github.com/modelcontextprotocol/servers).

## DevContainer Support

This repository includes a `.devcontainer` configuration for VS Code Dev Containers. To use it:

1. Install the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
2. Clone this repository
3. Set your `ANTHROPIC_API_KEY` environment variable on your host
4. Open in VS Code and click "Reopen in Container"

The devcontainer automatically:
- Sets up the network sandbox (firewall)
- Configures zsh with powerline10k
- Mounts your workspace to `/workspace`
- Persists command history and Claude config

## CI Pipeline

This repository builds and manages Claude Code Docker images through an automated CI pipeline:

- **Automated Build**: Docker images are automatically built when commits are made to the `main` branch
- **Multi-architecture Support**: Supports both `linux/amd64` and `linux/arm64` architectures
- **Version Control**: Each build is automatically versioned based on Claude Code npm package version
- **Auto-update**: A cron job checks for new Claude Code versions every 12 hours and creates PRs automatically
- **Quality Assurance**: Built images undergo automated testing

You can skip the CI pipeline by including the `--no-ci` flag in your commit message.

## Contributing

Please see [Contributing Guidelines](contributing.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License. See [license.md](license.md) for details.

Claude Code is a product of [Anthropic](https://www.anthropic.com/). This project is not affiliated with Anthropic.
