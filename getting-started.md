# Getting Started with Claude Docker

This guide will help you get started with the Claude Code community Docker image.

## Quick Start

Pull the image from GitHub Container Registry:

```bash
docker pull ghcr.io/jyje/claude-docker
```

Run with your API key:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `ANTHROPIC_API_KEY` | Yes | Your Anthropic API key. Get one at [console.anthropic.com](https://console.anthropic.com/) |
| `ANTHROPIC_BASE_URL` | No | Custom API endpoint URL. Use for local models (e.g., Docker Model Runner) or custom endpoints |

### Using .env File

Create a `.env` file in your project directory:

```bash
# .env
# Required: Anthropic API Key
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Optional: Custom API Base URL (for local models or proxies)
# ANTHROPIC_BASE_URL=http://localhost:12434
# ANTHROPIC_BASE_URL=https://your-proxy.company.com/v1
```

Run with `--env-file`:

```bash
docker run --rm -it --env-file .env -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

## Basic Usage

### With API Key from Environment

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

### With Custom Base URL

For local models or proxies:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e ANTHROPIC_BASE_URL=http://localhost:12434 \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

### Using Specific Version

```bash
docker pull ghcr.io/jyje/claude-docker:v2.1.23

docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker:v2.1.23
```

The list of available versions can be found on the [GitHub Container Registry](https://github.com/jyje/claude-docker/pkgs/container/claude-docker).

### Start Claude Code Interactive Session

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker \
  claude
```

## API Key Authentication (No Login Required)

Claude Code can use your API key directly without OAuth browser login. This is the most stable approach for Docker containers.

### Setup API Key Helper

Create a settings file that tells Claude Code to use the `ANTHROPIC_API_KEY` environment variable:

```bash
# Inside the container (or add to Dockerfile)
mkdir -p ~/.claude

cat > ~/.claude/settings.json <<'JSON'
{
  "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
}
JSON
```

### Complete Example

```bash
# 1. Export your API key on host
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 2. Run container with API key
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker bash

# 3. Inside container, setup API key helper (one-time)
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json

# 4. Run Claude Code - no login required!
claude
```

### Why This Works

- Claude Code reads the `apiKeyHelper` command from `~/.claude/settings.json`
- The helper command outputs the value of `$ANTHROPIC_API_KEY`
- This bypasses OAuth login flow entirely
- Ideal for CI/CD, containers, and headless environments

### Dockerfile Integration

To bake this into your own image based on `jyje/claude-docker`:

```dockerfile
FROM ghcr.io/jyje/claude-docker:latest

# Pre-configure API key helper for node user
USER node
RUN mkdir -p /home/node/.claude && \
    echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > /home/node/.claude/settings.json

# Your additional setup...
```

## Network Sandbox (Firewall)

For enhanced security with network isolation:

```bash
docker run --rm -it \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker

# Inside the container, run:
sudo /usr/local/bin/init-firewall.sh
```

The firewall script (`init-firewall.sh`) is from the [official Anthropic devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer) and provides network sandboxing for Claude Code execution.

## Kubernetes Sidecar Configuration

Use Claude Code as a sidecar container in Kubernetes pods with automatic API key authentication.

### Minimal Example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: claude-api-key
type: Opaque
stringData:
  ANTHROPIC_API_KEY: "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: claude-settings
data:
  settings.json: |
    {
      "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
    }
---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-claude
spec:
  containers:
  - name: app
    image: your-app:latest
    volumeMounts:
    - name: workspace
      mountPath: /workspace
  
  - name: claude-code
    image: ghcr.io/jyje/claude-docker:latest
    command: ["/bin/bash", "-c"]
    args:
    - |
      mkdir -p /home/node/.claude
      cp /claude-config/settings.json /home/node/.claude/settings.json
      tail -f /dev/null
    env:
    - name: ANTHROPIC_API_KEY
      valueFrom:
        secretKeyRef:
          name: claude-api-key
          key: ANTHROPIC_API_KEY
    volumeMounts:
    - name: workspace
      mountPath: /workspace
    - name: claude-settings
      mountPath: /claude-config
  
  volumes:
  - name: workspace
    emptyDir: {}
  - name: claude-settings
    configMap:
      name: claude-settings
```

### Usage

```bash
# Execute Claude Code in the sidecar
kubectl exec -it app-with-claude -c claude-code -- claude

# Access shared workspace
kubectl exec -it app-with-claude -c claude-code -- ls /workspace
```

For more detailed Kubernetes configurations including persistent storage and deployments, see the [main README](readme.md#kubernetes-sidecar-configuration).

## Next Steps

- Learn about [MCP (Model Context Protocol) Connection](readme.md#mcp-model-context-protocol-connection) for connecting to external tools
- Check [Pre-installed Utilities](readme.md#pre-installed-utilities) available in the image
- Explore [DevContainer Support](readme.md#devcontainer-support) for VS Code integration
- Review [CI Pipeline](readme.md#ci-pipeline) for automated builds and updates

## References

- [Docker AI Sandboxes: Claude Code](https://docs.docker.com/ai/sandboxes/claude-code/)
- [Stack Overflow: Using Claude Code with API Key](https://stackoverflow.com/questions/79629224/how-do-i-use-claude-code-with-an-existing-anthropic-api-key)
- [Anthropic API Documentation](https://docs.n8n.io/integrations/builtin/credentials/anthropic/)
- [Official Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
