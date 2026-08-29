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

🤖 이 레포지토리는 커뮤니티가 제공하는 [Claude Code](https://code.claude.com/docs) 도커 이미지입니다. Node.js 26 기반으로 빌드되었습니다. 지원 아키텍처: `linux/amd64`, `linux/arm64`.

> [!IMPORTANT]
> 이 레포지토리는 Anthropic과 제휴 관계가 없습니다. Claude Code 사용자를 위한 도커 이미지를 제공하는 커뮤니티 프로젝트입니다. 공식 정보는 [code.claude.com/docs](https://code.claude.com/docs)를 참조하세요.

> [!NOTE]
> **Anthropic 공식 Dockerfile 기반**  
> 이 도커 이미지는 [Anthropic 공식 Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile)을 기반으로 하며, Node.js 26, 자동화된 CI/CD 파이프라인, 멀티 아키텍처 지원 등 커뮤니티 사용을 위한 개선사항이 추가되었습니다.

## 📚 문서

**시작하기**
- [한국어 시작 가이드](docs/getting-started-ko.md) - 빠른 시작, 환경 설정, 기본 사용법, 인증, 빠른 테스트

**고급 가이드**
- [고급 가이드](docs/advanced-guide-ko.md) - Argo Workflows, Kubernetes Jobs/CronJobs, CI/CD 통합

## 환경 변수

아래 변수는 이 이미지를 Docker, 쿠버네티스, CI에서 실행할 때 가장 중요한 것들입니다. Claude Code는 이보다 훨씬 많은 변수를 인식합니다. 여기 없는 나머지는 **[전체 환경 변수 레퍼런스](https://code.claude.com/docs/en/env-vars)**를 참조하세요.

**인증 및 엔드포인트**

| 변수 | 설명 |
|------|------|
| `ANTHROPIC_API_KEY` | **필수.** Anthropic API 키. [console.anthropic.com](https://console.anthropic.com/)에서 발급. 비밀 값으로 취급하세요. |
| `ANTHROPIC_AUTH_TOKEN` | `x-api-key` 대신 `Authorization` 헤더로 전달되는 베어러 토큰. 게이트웨이를 통한 인증에 표준적으로 쓰입니다. 이 값도 비밀로 취급하세요. |
| `ANTHROPIC_BASE_URL` | 커스텀 API 엔드포인트 URL. 로컬 모델(예: Docker Model Runner) 또는 자체 호스팅 게이트웨이 사용 시. |
| `ANTHROPIC_CUSTOM_HEADERS` | 모든 API 요청에 추가할 헤더. 줄마다 `Header: value` 형식으로 지정합니다. |
| `ANTHROPIC_BETAS` | `anthropic-beta` 헤더로 요청할 추가 베타 기능 플래그 목록(쉼표 구분). 아래 `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS`와 짝을 이룹니다. |

**모델 선택**

| 변수 | 설명 |
|------|------|
| `ANTHROPIC_MODEL` | Claude Code가 사용할 모델을 재정의합니다. |
| `ANTHROPIC_DEFAULT_MODEL` | 별도로 모델을 지정하지 않았을 때 사용할 기본 모델. |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | Opus 등급 별칭에 사용할 모델. |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | Sonnet 등급 별칭에 사용할 모델. |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | Haiku 등급 별칭에 사용할 모델. |

**클라우드 제공자**

| 변수 | 설명 |
|------|------|
| `CLAUDE_CODE_USE_BEDROCK` | Anthropic API 대신 Amazon Bedrock을 통해 요청을 라우팅합니다. |
| `CLAUDE_CODE_USE_VERTEX` | Anthropic API 대신 Google Vertex AI를 통해 요청을 라우팅합니다. |
| `ANTHROPIC_VERTEX_PROJECT_ID` | Vertex AI에 사용할 GCP 프로젝트 ID. |
| `ANTHROPIC_BEDROCK_BASE_URL` | Bedrock 엔드포인트 URL을 재정의합니다. |
| `ANTHROPIC_VERTEX_BASE_URL` | Vertex AI 엔드포인트 URL을 재정의합니다. |

**네트워크, 프록시, 게이트웨이 호환성**

| 변수 | 설명 |
|------|------|
| `HTTP_PROXY` | 일반 HTTP 요청에 사용할 표준 프록시. |
| `HTTPS_PROXY` | HTTPS 요청에 사용할 표준 프록시. |
| `NO_PROXY` | 설정된 프록시를 우회할 호스트 목록. |
| `API_TIMEOUT_MS` | API 요청 타임아웃(밀리초)을 재정의합니다. |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | 베타 헤더와 베타 도구 스키마 필드를 제거합니다. 자체 호스팅 게이트웨이가 `anthropic-beta` 헤더가 붙은 요청을 거부할 때 유용합니다. 설정 시 MCP 도구 검색도 비활성화되어 모든 MCP 도구를 사전에 한꺼번에 로드하며, 아래 [MCP 섹션](#mcp-model-context-protocol-연결)과 관련이 있습니다. |

**실행 제한 및 토큰 예산**

| 변수 | 설명 |
|------|------|
| `BASH_DEFAULT_TIMEOUT_MS` | Bash 도구 명령의 기본 타임아웃. |
| `BASH_MAX_TIMEOUT_MS` | 명령이 요청할 수 있는 타임아웃의 상한값. |
| `BASH_MAX_OUTPUT_LENGTH` | 잘라내기 전에 유지할 Bash 출력의 최대 문자 수. |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 모델 응답 1회당 최대 토큰 수. |
| `MAX_THINKING_TOKENS` | 확장 사고(extended thinking)에 할당할 토큰 예산. |
| `MCP_TIMEOUT` | MCP 서버 시작을 기다리는 타임아웃(밀리초). |
| `MAX_MCP_OUTPUT_TOKENS` | MCP 도구 출력에서 유지할 최대 토큰 수. |

**컨테이너 운영, 업데이트, 프라이버시**

| 변수 | 설명 |
|------|------|
| `CLAUDE_CONFIG_DIR` | 설정 디렉터리(기본값 `~/.claude`)를 재정의합니다. 아래 [MCP 섹션](#mcp-model-context-protocol-연결)에서 `claude-mcp-config` 볼륨으로 마운트하는 바로 그 디렉터리입니다. |
| `DISABLE_AUTOUPDATER` | 백그라운드 자동 업데이트 확인을 비활성화합니다. 이 이미지는 Claude Code 버전을 고정해 배포하므로, 컨테이너 내부의 자동 업데이트는 그 고정을 깨뜨릴 수 있어 중요합니다. |
| `DISABLE_UPDATES` | `DISABLE_AUTOUPDATER`보다 더 엄격합니다: 수동 `claude update`, `claude install`까지 차단합니다. GHCR로 배포되는 버전 고정 이미지에는 보통 이 옵션이 적합합니다. |
| `DISABLE_TELEMETRY` | 텔레메트리를 비활성화합니다. **빈 문자열이 아닌 값이면 무엇이든(`0`, `false` 포함) 비활성화됩니다** — 다시 켜는 유일한 방법은 이 변수를 아예 설정하지 않는 것입니다. 기능 플래그 조회도 함께 비활성화되어 Remote Control 등 플래그 기반 기능을 사용할 수 없게 됩니다. |
| `DO_NOT_TRACK` | 텔레메트리 옵트아웃을 위한 도구 간 공통 관례입니다. `DISABLE_TELEMETRY`와 달리 일반적인 불리언처럼 동작합니다 — `DO_NOT_TRACK=0`은 텔레메트리를 켠 상태로 유지하고, `DO_NOT_TRACK=1`이어야 꺼집니다. 설정 시 기능 플래그 조회도 비활성화됩니다. |
| `DISABLE_ERROR_REPORTING` | 오류 리포트를 비활성화합니다. `DISABLE_TELEMETRY`와 동일하게 "빈 문자열이 아니면 비활성화" 규칙이 적용됩니다 — `0`, `false`도 비활성화로 처리됩니다. |
| `CLAUDECODE` | Claude Code 세션 내부에서 실행 중일 때 자동으로 `1`로 설정됩니다. 중첩 실행 여부를 감지할 때 유용합니다. |

> [!TIP]
> Docker, 쿠버네티스, API 키 인증을 포함한 자세한 사용 예제는 **[시작 가이드](docs/getting-started-ko.md)**를 참조하세요.

## 사전 설치된 유틸리티

이 이미지는 다음 유틸리티가 사전 설치되어 있습니다:

```
- @anthropic-ai/claude-code (최신 또는 지정된 버전)
- node 26
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
