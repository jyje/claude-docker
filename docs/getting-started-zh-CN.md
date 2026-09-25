<!-- Translated from docs/getting-started.md at 4892c7a -->
# Claude Docker 快速上手

在 Docker 中运行 Claude Code 的快速指南。

> [!NOTE]
> 本译文由 AI 辅助完成，尚未经过母语者审校，欢迎通过 PR 提出修改。如与英文版有出入，以英文版 [getting-started.md](getting-started.md) 为准。

## 快速开始

```bash
docker pull ghcr.io/jyje/claude-docker

docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

## 环境变量

开始使用时，只需要 `ANTHROPIC_API_KEY` 这一个变量。可在 [console.anthropic.com](https://console.anthropic.com/) 获取。

其余所有变量（模型选择、代理、云服务提供商、执行限制、遥测退出等），请参阅 **[README 中的环境变量部分](../readme-zh-CN.md#环境变量)**。

使用 `.env` 文件：

```bash
# .env
ANTHROPIC_API_KEY=sk-ant-api03-xxxx...

docker run --rm -it --env-file .env -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

## 快速测试

验证无头（headless）模式可以正常工作：

```bash
curl -O https://raw.githubusercontent.com/jyje/claude-docker/main/test.sh
chmod +x test.sh
echo "sk-ant-api03-your-key" > api-key

./test.sh
./test.sh "Analyze this code" "./output.txt"
```

自动化模板请参阅 [test.sh](../test.sh)。

## 用法变体

**自定义 Base URL**（本地模型/代理）：
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -e ANTHROPIC_BASE_URL=http://localhost:12434 -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

**指定版本：**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker:v2.1.23
```

**直接运行 Claude：**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker claude
```

可用版本：[GitHub Container Registry](https://github.com/jyje/claude-docker/pkgs/container/claude-docker)

## API 密钥认证（无需登录）

无需通过浏览器进行 OAuth 登录，直接使用 API 密钥。无头/CI 场景必须这样做。

**设置**（一次性，在容器内执行）：
```bash
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

Claude 会通过这个 helper 读取密钥，从而绕过 OAuth。自定义镜像的 Dockerfile 示例请参阅[进阶指南](advanced-guide.md)（英文）。

## 网络沙箱

可选的网络隔离，使用[官方防火墙脚本](https://github.com/anthropics/claude-code/tree/main/.devcontainer)：

```bash
docker run --rm -it --cap-add=NET_ADMIN --cap-add=NET_RAW -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker

# Inside container:
sudo /usr/local/bin/init-firewall.sh
```

## 进阶：Kubernetes、CI/CD、Argo Workflows

关于 Kubernetes sidecar、Argo Workflows、Job、CronJob 以及 CI/CD 集成，请参阅[进阶指南](advanced-guide.md)（英文）。

## 后续步骤

- [MCP 连接](../readme-zh-CN.md#mcp-model-context-protocol-连接) – 外部工具
- [预装工具](../readme-zh-CN.md#预装工具) – 镜像内容
- [DevContainer 支持](../readme-zh-CN.md#devcontainer-支持) – VS Code
- [CI 流水线](../readme-zh-CN.md#ci-流水线) – 自动化构建
