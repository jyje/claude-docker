<div align="center">
  
  # jyje/claude-docker
  
  <!-- center logo -->
  <img width="150" src="https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/light/claude-color.png" alt="Claude" title="Claude"/>
  
  Claude Code: Community-Powered Docker Image

  [![release](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml/badge.svg?branch=main)](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml)
  [![test](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml/badge.svg?branch=develop)](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml)
  [![cron](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml/badge.svg)](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml)
  [![GitHub Repo stars](https://img.shields.io/github/stars/jyje/claude-docker)](https://github.com/jyje/claude-docker)

  [English](readme.md) / [한국어](readme-ko.md)

</div>

⭐ **If you found this project useful, please consider giving it a star on GitHub!**

🤖 This repository provides [Claude Code](https://code.claude.com/docs) Docker images powered by community. Built with Node.js 26. Supported architectures are `linux/amd64`, `linux/arm64`.

> [!IMPORTANT]
> This repository is not affiliated with Anthropic. This is a community-maintained project that provides a Docker image for Claude Code users. For official information, visit [code.claude.com/docs](https://code.claude.com/docs).

> [!NOTE]
> **Based on Official Anthropic Dockerfile**  
> This Docker image is built upon the [official Anthropic Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile), with enhancements for community use including Node.js 26, automated CI/CD pipelines, and multi-architecture support.

## 📚 Documentation

**Getting Started**
- [Quick Start & Basic Usage](docs/getting-started.md) - Environment setup, Docker usage, API authentication, Quick Test

**Advanced Guides**
- [Advanced Guide](docs/advanced-guide.md) - Argo Workflows, Kubernetes Jobs/CronJobs, CI/CD integration

## Environment Variables

The variables below are the ones that matter most when running this image in Docker, Kubernetes, or CI. Claude Code recognizes far more; see the **[full environment variable reference](https://code.claude.com/docs/en/env-vars)** for everything not listed here.

**Authentication and endpoint**

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_API_KEY` | **Required.** Your Anthropic API key. Get one at [console.anthropic.com](https://console.anthropic.com/). Treat it as a secret. |
| `ANTHROPIC_AUTH_TOKEN` | Bearer token sent as the `Authorization` header instead of `x-api-key`, the standard way to authenticate through a gateway. Also a secret. |
| `ANTHROPIC_BASE_URL` | Custom API endpoint URL. Use for local models (e.g., Docker Model Runner) or a self-hosted gateway. |
| `ANTHROPIC_CUSTOM_HEADERS` | Extra headers to attach to every API request, one `Header: value` pair per line. |
| `ANTHROPIC_BETAS` | Comma-separated list of extra beta feature flags to request via the `anthropic-beta` header. Counterpart to `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` below. |

**Model selection**

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_MODEL` | Override the model Claude Code uses. |
| `ANTHROPIC_DEFAULT_MODEL` | Default model when no explicit model is selected. |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Model used for the Opus tier alias. |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Model used for the Sonnet tier alias. |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Model used for the Haiku tier alias. |

**Cloud providers**

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_USE_BEDROCK` | Route requests through Amazon Bedrock instead of the Anthropic API. |
| `CLAUDE_CODE_USE_VERTEX` | Route requests through Google Vertex AI instead of the Anthropic API. |
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP project ID to use with Vertex AI. |
| `ANTHROPIC_BEDROCK_BASE_URL` | Override the Bedrock endpoint URL. |
| `ANTHROPIC_VERTEX_BASE_URL` | Override the Vertex AI endpoint URL. |

**Network, proxy, and gateway compatibility**

| Variable | Description |
|----------|-------------|
| `HTTP_PROXY` | Standard proxy for plain HTTP requests. |
| `HTTPS_PROXY` | Standard proxy for HTTPS requests. |
| `NO_PROXY` | Hosts that should bypass the configured proxy. |
| `API_TIMEOUT_MS` | Override the API request timeout, in milliseconds. |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | Strips beta headers and beta tool-schema fields, useful when a self-hosted gateway rejects requests carrying `anthropic-beta`. Also disables MCP tool search and loads all MCP tools upfront instead, which interacts with the [MCP section](#mcp-model-context-protocol-connection) below. |

**Execution limits and token budgets**

| Variable | Description |
|----------|-------------|
| `BASH_DEFAULT_TIMEOUT_MS` | Default timeout for Bash tool commands. |
| `BASH_MAX_TIMEOUT_MS` | Upper bound on the timeout a command can request. |
| `BASH_MAX_OUTPUT_LENGTH` | Max characters of Bash output kept before truncation. |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Max tokens in a single model response. |
| `MAX_THINKING_TOKENS` | Token budget for extended thinking. |
| `MCP_TIMEOUT` | Timeout, in milliseconds, for an MCP server to start up. |
| `MAX_MCP_OUTPUT_TOKENS` | Max tokens kept from an MCP tool's output. |

**Container operations, updates, and privacy**

| Variable | Description |
|----------|-------------|
| `CLAUDE_CONFIG_DIR` | Overrides the config directory (default `~/.claude`). This is exactly the directory the [MCP section](#mcp-model-context-protocol-connection) below mounts as the `claude-mcp-config` volume. |
| `DISABLE_AUTOUPDATER` | Disables the background auto-update check. Matters here because this image ships pinned Claude Code versions; an in-container auto-update would break that pinning. |
| `DISABLE_UPDATES` | Stricter than `DISABLE_AUTOUPDATER`: also blocks manual `claude update` and `claude install`, usually the right choice for a pinned image distributed through GHCR. |
| `DISABLE_TELEMETRY` | Opts out of telemetry. **Any non-empty value opts out, including `0` or `false`** — the only way to re-enable telemetry is to leave the variable unset. Also disables feature-flag fetching (Remote Control and other flag-gated features become unavailable). |
| `DO_NOT_TRACK` | The cross-tool convention for opting out of telemetry. Unlike `DISABLE_TELEMETRY`, this behaves as a normal boolean — `DO_NOT_TRACK=0` leaves telemetry on, `DO_NOT_TRACK=1` turns it off. Also disables feature-flag fetching when set. |
| `DISABLE_ERROR_REPORTING` | Opts out of error reporting. Same "any non-empty value" semantics as `DISABLE_TELEMETRY` — `0` and `false` still opt out. |
| `CLAUDECODE` | Set to `1` automatically while running inside a Claude Code session; useful for detecting nested invocations. |

> [!TIP]
> For detailed usage examples including Docker, Kubernetes, and API key authentication, see the **[Getting Started Guide](docs/getting-started.md)**.

## Pre-installed Utilities

This image provides the following utilities pre-installed:

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

This repository builds and manages Claude Code Docker images through an automated CI pipeline supporting two main deployment strategies:

### `main` Branch (Production Releases)
- **Automated Execution**: Commits to the `main` branch automatically build and publish release images.
- **Tagging Strategy**: Generates standard version tags (e.g., `v2.0.0`). The `latest` and `major`/`minor` tags are only applied if the version is the absolute newest, preventing older patch releases from overriding current deployments.
- **Release Notes**: Auto-generates GitHub Releases with a detailed changelog.

### `develop` Branch (Development Builds)
- **Automated Execution**: Commits to the `develop` branch automatically build and publish testing images.
- **Tagging Strategy**: Uses `-dev:[20-character SHA]` and `-dev:latest` tags to completely eliminate hash collisions.
- **Storage Management**: Implements an automated Garbage Collection (GC) that retains only the 20 most recent dev images in GHCR to optimize storage.

### Common Capabilities
- **Multi-architecture**: Builds support both `linux/amd64` and `linux/arm64`.
- **Auto-update**: A cron job checks for new Claude Code versions every 6 hours and automatically creates Pull Requests.
- **Opt-out**: You can skip the CI pipeline for any commit by including the `--no-ci` flag in the commit message.

## Contributing

Please see [Contributing Guidelines](contributing.md) for details on how to contribute to this project.

## License

This project is licensed under the MIT License. See [license.md](license.md) for details.

Claude Code is a product of [Anthropic](https://www.anthropic.com/). This project is not affiliated with Anthropic.
