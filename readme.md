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

Claude Code reads many environment variables. The tables below cover the ones that matter most when running this image in Docker, Kubernetes, or CI.

> [!NOTE]
> For the complete list of supported variables, see the official reference: **[Claude Code environment variables](https://code.claude.com/docs/en/env-vars)**.

### Authentication & Endpoint

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes\* | API key sent as the `X-Api-Key` header. Get one at [console.anthropic.com](https://console.anthropic.com/) |
| `ANTHROPIC_AUTH_TOKEN` | No | Custom `Authorization` header value, automatically prefixed with `Bearer `. Common when authenticating through a gateway |
| `ANTHROPIC_BASE_URL` | No | Route requests through a proxy or gateway. Also used for local models (e.g., Docker Model Runner) |
| `ANTHROPIC_CUSTOM_HEADERS` | No | Extra request headers in `Name: Value` format, newline-separated for multiple headers |
| `ANTHROPIC_BETAS` | No | Comma-separated `anthropic-beta` values, to opt into an API beta before Claude Code supports it natively |

\* Required unless you authenticate another way, such as a subscription login, a gateway token, or one of the cloud providers below.

> [!CAUTION]
> `ANTHROPIC_API_KEY` and `ANTHROPIC_AUTH_TOKEN` are secrets. Pass them with `-e VAR` (reading from your shell) or `--env-file`, never by hardcoding the value into a `Dockerfile` or a committed compose file.

### Model Selection

| Variable | Description |
|----------|-------------|
| `ANTHROPIC_MODEL` | Model to use for the session |
| `ANTHROPIC_DEFAULT_MODEL` | Model that new sessions start on by default (requires Claude Code v2.1.236 or later) |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Model ID that the `opus` alias resolves to |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Model ID that the `sonnet` alias resolves to |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Model ID that the `haiku` alias resolves to, also used for background functionality |

### Cloud Providers

| Variable | Description |
|----------|-------------|
| `CLAUDE_CODE_USE_BEDROCK` | Use [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock) |
| `CLAUDE_CODE_USE_VERTEX` | Use [Google Cloud's Agent Platform](https://code.claude.com/docs/en/google-vertex-ai) |
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP project ID. Overridden by `GCLOUD_PROJECT`, `GOOGLE_CLOUD_PROJECT`, or the project in your credential file |
| `ANTHROPIC_BEDROCK_BASE_URL` | Override the Amazon Bedrock endpoint, for custom endpoints or an LLM gateway |
| `ANTHROPIC_VERTEX_BASE_URL` | Override the Google Cloud endpoint, for custom endpoints or an LLM gateway |

### Network, Proxy & Gateway Compatibility

| Variable | Description |
|----------|-------------|
| `HTTP_PROXY` | HTTP proxy server for network connections |
| `HTTPS_PROXY` | HTTPS proxy server for network connections |
| `NO_PROXY` | Domains and IPs to reach directly, bypassing the proxy |
| `API_TIMEOUT_MS` | API request timeout in milliseconds (default: `600000`, 10 minutes). Raise it on slow networks or when routing through a proxy |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | Set to `1` to strip `anthropic-beta` headers and beta tool-schema fields from requests. Use it when a gateway rejects them. Counterpart to `ANTHROPIC_BETAS`, and it also disables MCP tool search |

> [!TIP]
> If you run this image with the network sandbox (`--cap-add=NET_ADMIN --cap-add=NET_RAW`), remember that `init-firewall.sh` restricts outbound traffic. A proxy host set here also has to be reachable through that firewall.

### Execution Limits & Token Budgets

| Variable | Description |
|----------|-------------|
| `BASH_DEFAULT_TIMEOUT_MS` | Default timeout for long-running bash commands (default: `120000`, 2 minutes) |
| `BASH_MAX_TIMEOUT_MS` | Maximum timeout the model can set for bash commands (default: `600000`, 10 minutes) |
| `BASH_MAX_OUTPUT_LENGTH` | Maximum characters of bash output read back into a result (default: `30000`, maximum: `150000`) |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Maximum output tokens for most requests. Defaults and caps vary by model |
| `MAX_THINKING_TOKENS` | Fixed token budget for extended thinking |
| `MCP_TIMEOUT` | MCP server startup timeout in milliseconds (default: `30000`, 30 seconds) |
| `MAX_MCP_OUTPUT_TOKENS` | Maximum tokens allowed in MCP tool responses |

These are the variables worth tuning for non-interactive runs (`claude -p`) in CI, where the defaults are often too tight for long builds or slow MCP servers.

### Container Operations, Updates & Privacy

| Variable | Description |
|----------|-------------|
| `CLAUDE_CONFIG_DIR` | Override the config directory (default: `~/.claude`). Settings, session history, and plugins live here, so point your volume mount at this path |
| `DISABLE_AUTOUPDATER` | Set to `1` to disable automatic background updates. Manual `claude update` still works |
| `DISABLE_UPDATES` | Set to `1` to block all updates, including manual `claude update`. Stricter than `DISABLE_AUTOUPDATER`, and usually what you want for a pinned image |
| `DISABLE_TELEMETRY` | Opt out of telemetry. See the warning below |
| `DO_NOT_TRACK` | Set to `1` to opt out of telemetry, same effect as `DISABLE_TELEMETRY`. Read as a normal boolean, so `0` leaves telemetry on |
| `DISABLE_ERROR_REPORTING` | Opt out of error reporting. See the warning below |
| `CLAUDECODE` | Set to `1` by Claude Code inside the subprocesses it spawns. Use it to detect that a script is running under Claude Code |

> [!WARNING]
> `DISABLE_TELEMETRY` and `DISABLE_ERROR_REPORTING` opt out on **any non-empty value, including `0` and `false`**. Passing `-e DISABLE_TELEMETRY=0` keeps telemetry off rather than turning it back on. To re-enable, leave the variable unset entirely. `DO_NOT_TRACK` is the exception: it is read as a normal boolean, so `DO_NOT_TRACK=0` really does leave telemetry on.
>
> Both telemetry opt-outs also disable feature-flag fetching, which makes Remote Control and other feature-flag dependent features unavailable.

> [!TIP]
> Because this image ships pinned versions, `DISABLE_UPDATES=1` keeps a tagged image reproducible by preventing Claude Code from updating itself at runtime.

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
