<div align="center">
  
  # jyje/claude-docker
  
  <!-- center logo -->
  <img width="150" src="https://raw.githubusercontent.com/lobehub/lobe-icons/refs/heads/master/packages/static-png/light/claude-color.png" alt="Claude" title="Claude"/>
  
  Claude Code: 커뮤니티 도커 이미지

  [![release](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml/badge.svg?branch=main)](https://github.com/jyje/claude-docker/actions/workflows/ci-main.yaml)
  [![test](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml/badge.svg?branch=develop)](https://github.com/jyje/claude-docker/actions/workflows/ci-develop.yaml)
  [![cron](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml/badge.svg)](https://github.com/jyje/claude-docker/actions/workflows/cron-fetch-npm.yaml)
  [![GitHub Repo stars](https://img.shields.io/github/stars/jyje/claude-docker)](https://github.com/jyje/claude-docker)

  [English](readme.md) / [한국어](readme-ko.md)

</div>

⭐ **이 프로젝트가 유용하셨다면 GitHub Star(⭐)를 부탁드립니다!**

🤖 이 레포지토리는 커뮤니티가 제공하는 [Claude Code](https://docs.anthropic.com/en/docs/claude-code) 도커 이미지입니다. Node.js 24 기반으로 빌드되었습니다. 지원 아키텍처: `linux/amd64`, `linux/arm64`.

> [!IMPORTANT]
> 이 레포지토리는 Anthropic과 제휴 관계가 없습니다. Claude Code 사용자를 위한 도커 이미지를 제공하는 커뮤니티 프로젝트입니다. 공식 정보는 [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code)을 참조하세요.

> [!NOTE]
> **Anthropic 공식 Dockerfile 기반**  
> 이 도커 이미지는 [Anthropic 공식 Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile)을 기반으로 하며, Node.js 24, 자동화된 CI/CD 파이프라인, 멀티 아키텍처 지원 등 커뮤니티 사용을 위한 개선사항이 추가되었습니다.

## 📚 문서

**시작하기**
- [한국어 시작 가이드](docs/getting-started-ko.md) - 빠른 시작, 환경 설정, 기본 사용법, 인증, 빠른 테스트

**고급 가이드**
- [고급 가이드](docs/advanced-guide-ko.md) - Argo Workflows, Kubernetes Jobs/CronJobs, CI/CD 통합

## 환경 변수

| 변수 | 필수 | 설명 |
|------|------|------|
| `ANTHROPIC_API_KEY` | 예 | Anthropic API 키. [console.anthropic.com](https://console.anthropic.com/)에서 발급 |
| `ANTHROPIC_BASE_URL` | 아니오 | 커스텀 API 엔드포인트 URL. 로컬 모델(예: Docker Model Runner) 또는 커스텀 엔드포인트 사용 시 |

> [!TIP]
> Docker, 쿠버네티스, API 키 인증을 포함한 자세한 사용 예제는 **[시작 가이드](docs/getting-started-ko.md)**를 참조하세요.

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

이 레포지토리는 자동화된 CI 파이프라인을 통해 두 가지 주요 배포 전략으로 Claude Code 도커 이미지를 빌드하고 관리합니다:

### `main` 브랜치 (프로덕션 릴리즈)
- **자동 실행**: `main` 브랜치에 커밋되면 릴리즈 이미지가 자동으로 빌드 및 배포됩니다.
- **태그 전략**: 표준 버전 태그(예: `v2.0.0`)를 생성합니다. 구 버전 패치가 현재 배포된 최신 버전을 덮어쓰는 것을 방지하기 위해, 현재 빌드 대상이 절대적인 최신 버전일 때만 `latest` 및 `major`/`minor` 태그를 적용합니다.
- **릴리즈 노트**: 상세한 변경 사항(Changelog)과 함께 GitHub Release를 자동으로 생성합니다.

### `develop` 브랜치 (개발용 빌드)
- **자동 실행**: `develop` 브랜치에 커밋되면 테스트용 이미지가 자동으로 빌드 및 배포됩니다.
- **태그 전략**: 해시 충돌을 완전히 제거하기 위해 `-dev:[20자리 SHA]` 및 `-dev:latest` 태그를 사용합니다.
- **스토리지 관리**: 스토리지 공간 최적화를 위해 GHCR에 가장 최근의 개발 이미지 20개만 유지하는 자동 가비지 컬렉션(GC)을 구현했습니다.

### 공통 기능
- **멀티 아키텍처 지원**: `linux/amd64`와 `linux/arm64` 아키텍처 모두를 지원합니다.
- **자동 업데이트**: 크론 작업이 6시간마다 새 Claude Code 버전을 확인하고 Pull Request를 자동 생성합니다.
- **파이프라인 건너뛰기**: 커밋 메시지에 `--no-ci` 플래그를 포함하면 해당 커밋에 대해 CI 파이프라인 실행을 건너뛸 수 있습니다.

## 기여하기

프로젝트에 기여하는 방법은 [기여 가이드라인](contributing.md)을 참조하세요.

## 라이선스

이 프로젝트는 MIT 라이선스로 배포됩니다. 자세한 내용은 [license.md](license.md)를 참조하세요.

Claude Code는 [Anthropic](https://www.anthropic.com/)의 제품입니다. 이 프로젝트는 Anthropic과 제휴 관계가 없습니다.
