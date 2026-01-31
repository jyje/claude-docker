<div align="center">
  
  # jyje/claude-docker
  
  <!-- center logo -->
  <img width="250" src="https://www.anthropic.com/_next/image?url=https%3A%2F%2Fwww-cdn.anthropic.com%2Fimages%2F4zrzovbb%2Fwebsite%2F30f875f5a86900e58245d55d0e1d4f7f6456ac73-2560x1440.png&w=3840&q=75" alt="Claude" title="Claude"/>
  
  Claude Code: 커뮤니티 도커 이미지

  [![release](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml/badge.svg?branch=main)](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml)
  [![test](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml/badge.svg?branch=develop)](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml)
  [![cron](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml/badge.svg)](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml)
  [![GitHub Repo stars](https://img.shields.io/github/stars/jyje/claude-docker)](https://github.com/jyje/claude-docker)

  [English](readme.md) / [한국어](readme-ko.md)

</div>

🤖 이 레포지토리는 커뮤니티가 제공하는 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 도커 이미지입니다. Node.js 24 기반으로 빌드되었습니다. 지원 아키텍처: `linux/amd64`, `linux/arm64`.

> [!IMPORTANT]
> 이 레포지토리는 Anthropic과 제휴 관계가 없습니다. Claude Code 사용자를 위한 도커 이미지를 제공하는 커뮤니티 프로젝트입니다. 공식 정보는 [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code)을 참조하세요.

## 📚 문서

- **[Getting Started Guide](getting-started.md)** - Quick start, environment setup, basic usage, and authentication
- **[한국어 시작 가이드](getting-started-ko.md)** - 빠른 시작, 환경 설정, 기본 사용법 및 인증

## 환경 변수

| 변수 | 필수 | 설명 |
|------|------|------|
| `ANTHROPIC_API_KEY` | 예 | Anthropic API 키. [console.anthropic.com](https://console.anthropic.com/)에서 발급 |
| `ANTHROPIC_BASE_URL` | 아니오 | 커스텀 API 엔드포인트 URL. 로컬 모델(예: Docker Model Runner) 또는 커스텀 엔드포인트 사용 시 |

> [!TIP]
> Docker, 쿠버네티스, API 키 인증을 포함한 자세한 사용 예제는 **[시작 가이드](getting-started-ko.md)**를 참조하세요.

## 사전 설치된 유틸리티

이 이미지는 다음 유틸리티가 사전 설치되어 있습니다:

```
- @anthropic-ai/claude-code (최신 또는 지정된 버전)
- node 24
- npm

- git + git-delta (diff 뷰어)
- zsh + powerline10k 테마
- fzf (퍼지 파인더)
- gh (GitHub CLI)
- jq, curl, wget
- nano, vim
- iptables, ipset, iproute2 (네트워크 샌드박스용)
```

## MCP (Model Context Protocol) 연결

Claude Code는 [MCP](https://modelcontextprotocol.io/)를 통해 GitHub, 데이터베이스, API 등 외부 도구와 데이터 소스에 연결할 수 있습니다.

### 컨테이너 내부에서 MCP 서버 추가

```bash
# 컨테이너 시작
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  -v claude-mcp-config:/home/node/.claude \
  ghcr.io/jyje/claude-docker

# 컨테이너 내부: MCP 서버 추가
claude mcp add --transport http github https://api.githubcopilot.com/mcp/
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp
claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://user:pass@host:5432/db"

# 설정된 서버 목록 확인
claude mcp list

# 서버 상태 확인
/mcp
```

### .mcp.json 설정 파일 사용

팀 공유용 MCP 설정을 위해 프로젝트 루트에 `.mcp.json`을 생성하세요:

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

마운트하여 실행:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  -v $(pwd):/workspace \
  -v $(pwd)/.mcp.json:/home/node/.mcp.json:ro \
  ghcr.io/jyje/claude-docker
```

### 인기 MCP 서버

| 서버 | 명령어 |
|------|--------|
| GitHub | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| Sentry | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| PostgreSQL | `claude mcp add --transport stdio postgres -- npx -y @bytebase/dbhub --dsn "postgresql://..."` |
| Filesystem | `claude mcp add --transport stdio fs -- npx -y @modelcontextprotocol/server-filesystem /workspace` |

더 많은 MCP 서버는 [GitHub의 MCP Servers](https://github.com/modelcontextprotocol/servers)를 참조하세요.

## DevContainer 지원

이 레포지토리는 VS Code Dev Containers를 위한 `.devcontainer` 구성을 포함합니다:

1. [Dev Containers 확장](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 설치
2. 이 레포지토리 클론
3. 호스트에 `ANTHROPIC_API_KEY` 환경 변수 설정
4. VS Code에서 열고 "Reopen in Container" 클릭

devcontainer는 자동으로:
- 네트워크 샌드박스 (방화벽) 설정
- powerline10k와 함께 zsh 구성
- `/workspace`에 워크스페이스 마운트
- 명령 기록 및 Claude 설정 유지

## CI 파이프라인

이 레포지토리는 자동화된 CI 파이프라인을 통해 Claude Code 도커 이미지를 빌드하고 관리합니다:

- **자동 빌드**: `main` 브랜치에 커밋되면 도커 이미지가 자동으로 빌드됩니다
- **멀티 아키텍처 지원**: `linux/amd64`와 `linux/arm64` 아키텍처 모두 지원
- **버전 관리**: Claude Code npm 패키지 버전을 기반으로 자동 버전 관리
- **자동 업데이트**: 크론 작업이 12시간마다 새 Claude Code 버전을 확인하고 PR을 자동 생성
- **품질 보증**: 빌드된 이미지는 자동 테스트를 거칩니다

커밋 메시지에 `--no-ci` 플래그를 포함하면 CI 파이프라인을 건너뛸 수 있습니다.

## 기여하기

프로젝트에 기여하는 방법은 [기여 가이드라인](contributing.md)을 참조하세요.

## 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다. 자세한 내용은 [license.md](license.md)를 참조하세요.

Claude Code는 [Anthropic](https://www.anthropic.com/)의 제품입니다. 이 프로젝트는 Anthropic과 제휴 관계가 없습니다.
