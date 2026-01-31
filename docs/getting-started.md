# Getting Started with Claude Docker

Quick guide to run Claude Code in Docker.

## Quick Start

```bash
docker pull ghcr.io/jyje/claude-docker

docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Get one at [console.anthropic.com](https://console.anthropic.com/) |
| `ANTHROPIC_BASE_URL` | No | Custom endpoint (e.g., local models, proxies) |

Using `.env` file:

```bash
# .env
ANTHROPIC_API_KEY=sk-ant-api03-xxxx...

docker run --rm -it --env-file .env -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

## Quick Test

Verify headless mode works:

```bash
curl -O https://raw.githubusercontent.com/jyje/claude-docker/main/test.sh
chmod +x test.sh
echo "sk-ant-api03-your-key" > api-key

./test.sh
./test.sh "Analyze this code" "./output.txt"
```

See [test.sh](../test.sh) for the automation template.

## Usage Variants

**Custom Base URL** (local models/proxies):
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -e ANTHROPIC_BASE_URL=http://localhost:12434 -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

**Specific version:**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker:v2.1.23
```

**Run Claude directly:**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker claude
```

Available versions: [GitHub Container Registry](https://github.com/jyje/claude-docker/pkgs/container/claude-docker)

## API Key Authentication (No Login)

Use API key without OAuth browser login—required for headless/CI use.

**Setup** (one-time, inside container):
```bash
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

Claude reads the key via this helper, bypassing OAuth. For custom images, see [Headless CLI Pipeline](headless-pipeline.md) for Dockerfile examples.

## Network Sandbox

Optional network isolation using the [official firewall script](https://github.com/anthropics/claude-code/tree/main/.devcontainer):

```bash
docker run --rm -it --cap-add=NET_ADMIN --cap-add=NET_RAW -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker

# Inside container:
sudo /usr/local/bin/init-firewall.sh
```

## Advanced: Kubernetes, CI/CD, Argo Workflows

For Kubernetes sidecars, Argo Workflows, Jobs, CronJobs, and CI/CD integration, see the [Headless CLI Pipeline](headless-pipeline.md) guide.

## Next Steps

- [MCP Connection](../readme.md#mcp-model-context-protocol-connection) – external tools
- [Pre-installed Utilities](../readme.md#pre-installed-utilities) – image contents
- [DevContainer Support](../readme.md#devcontainer-support) – VS Code
- [CI Pipeline](../readme.md#ci-pipeline) – automated builds
