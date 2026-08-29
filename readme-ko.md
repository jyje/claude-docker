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
> 이 레포지토리는 Anthropic과 제휴 관계가 없습니다. Claude Code 사용자를 위한 도커 이미지를 제공하는 커뮤니티 프로젝트입니다. 공식 정보는 [code.claude.com/docs](https://code.claude.com/docs)을 참조하세요.

> [!NOTE]
> **Anthropic 공식 Dockerfile 기반**  
> 이 도커 이미지는 [Anthropic 공식 Claude Code devcontainer Dockerfile](https://github.com/anthropics/claude-code/blob/main/.devcontainer/Dockerfile)을 기반으로 하며, Node.js 26, 자동화된 CI/CD 파이프라인, 멀티 아키텍처 지원 등 커뮤니티 사용을 위한 개선사항이 추가되었습니다.

## 📚 문서

**시작하기**
- [한국어 시작 가이드](docs/getting-started-ko.md) - 빠른 시작, 환경 설정, 기본 사용법, 인증, 빠른 테스트

**고급 가이드**
- [고급 가이드](docs/advanced-guide-ko.md) - Argo Workflows, Kubernetes Jobs/CronJobs, CI/CD 통합

## 환경 변수

Claude Code는 많은 환경 변수를 지원합니다. 아래 표는 이 이미지를 Docker, 쿠버네티스, CI에서 실행할 때 특히 중요한 것들을 정리한 것입니다.

> [!NOTE]
> 지원되는 전체 환경 변수 목록은 공식 문서를 참조하세요: **[Claude Code 환경 변수](https://code.claude.com/docs/en/env-vars)**

### 인증 및 엔드포인트

| 변수 | 필수 | 설명 |
|------|------|------|
| `ANTHROPIC_API_KEY` | 예\* | `X-Api-Key` 헤더로 전송되는 API 키. [console.anthropic.com](https://console.anthropic.com/)에서 발급 |
| `ANTHROPIC_AUTH_TOKEN` | 아니오 | `Authorization` 헤더에 사용할 값. 자동으로 `Bearer ` 접두사가 붙습니다. 게이트웨이 경유 인증 시 주로 사용 |
| `ANTHROPIC_BASE_URL` | 아니오 | 프록시나 게이트웨이로 요청을 라우팅. 로컬 모델(예: Docker Model Runner)에도 사용 |
| `ANTHROPIC_CUSTOM_HEADERS` | 아니오 | 추가 요청 헤더. `Name: Value` 형식이며 여러 개는 줄바꿈으로 구분 |
| `ANTHROPIC_BETAS` | 아니오 | 쉼표로 구분된 `anthropic-beta` 값. Claude Code가 정식 지원하기 전에 API 베타를 미리 사용할 때 |

\* 구독 로그인, 게이트웨이 토큰, 아래의 클라우드 프로바이더 등 다른 방식으로 인증한다면 필수가 아닙니다.

> [!CAUTION]
> `ANTHROPIC_API_KEY`와 `ANTHROPIC_AUTH_TOKEN`은 시크릿입니다. 셸에서 값을 읽는 `-e VAR` 형식이나 `--env-file`로 전달하고, `Dockerfile`이나 커밋되는 compose 파일에 값을 직접 넣지 마세요.

### 모델 선택

| 변수 | 설명 |
|------|------|
| `ANTHROPIC_MODEL` | 세션에서 사용할 모델 |
| `ANTHROPIC_DEFAULT_MODEL` | 새 세션이 기본으로 시작할 모델 (Claude Code v2.1.236 이상 필요) |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `opus` 별칭이 가리킬 모델 ID |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `sonnet` 별칭이 가리킬 모델 ID |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `haiku` 별칭이 가리킬 모델 ID. 백그라운드 작업에도 사용 |

### 클라우드 프로바이더

| 변수 | 설명 |
|------|------|
| `CLAUDE_CODE_USE_BEDROCK` | [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock) 사용 |
| `CLAUDE_CODE_USE_VERTEX` | [Google Cloud Agent Platform](https://code.claude.com/docs/en/google-vertex-ai) 사용 |
| `ANTHROPIC_VERTEX_PROJECT_ID` | GCP 프로젝트 ID. `GCLOUD_PROJECT`, `GOOGLE_CLOUD_PROJECT` 또는 인증 파일의 프로젝트가 우선합니다 |
| `ANTHROPIC_BEDROCK_BASE_URL` | Amazon Bedrock 엔드포인트 재정의. 커스텀 엔드포인트나 LLM 게이트웨이 경유 시 |
| `ANTHROPIC_VERTEX_BASE_URL` | Google Cloud 엔드포인트 재정의. 커스텀 엔드포인트나 LLM 게이트웨이 경유 시 |

### 네트워크, 프록시, 게이트웨이 호환성

| 변수 | 설명 |
|------|------|
| `HTTP_PROXY` | 네트워크 연결에 사용할 HTTP 프록시 서버 |
| `HTTPS_PROXY` | 네트워크 연결에 사용할 HTTPS 프록시 서버 |
| `NO_PROXY` | 프록시를 우회해 직접 연결할 도메인 및 IP 목록 |
| `API_TIMEOUT_MS` | API 요청 타임아웃(밀리초, 기본값 `600000` = 10분). 느린 네트워크나 프록시 경유 시 늘리세요 |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | `1`로 설정하면 요청에서 `anthropic-beta` 헤더와 베타 도구 스키마 필드를 제거합니다. 게이트웨이가 이를 거부할 때 사용하세요. `ANTHROPIC_BETAS`와 짝을 이루며, MCP 도구 검색도 함께 비활성화됩니다 |

> [!TIP]
> 네트워크 샌드박스(`--cap-add=NET_ADMIN --cap-add=NET_RAW`)와 함께 실행한다면 `init-firewall.sh`가 아웃바운드 트래픽을 제한한다는 점에 유의하세요. 여기 설정한 프록시 호스트도 그 방화벽을 통과할 수 있어야 합니다.

### 실행 제한 및 토큰 예산

| 변수 | 설명 |
|------|------|
| `BASH_DEFAULT_TIMEOUT_MS` | 장시간 실행되는 bash 명령의 기본 타임아웃 (기본값 `120000` = 2분) |
| `BASH_MAX_TIMEOUT_MS` | 모델이 bash 명령에 설정할 수 있는 최대 타임아웃 (기본값 `600000` = 10분) |
| `BASH_MAX_OUTPUT_LENGTH` | 결과로 읽어들이는 bash 출력의 최대 문자 수 (기본값 `30000`, 최대 `150000`) |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | 대부분 요청의 최대 출력 토큰 수. 기본값과 상한은 모델마다 다릅니다 |
| `MAX_THINKING_TOKENS` | 확장 사고(extended thinking)에 할당할 고정 토큰 예산 |
| `MCP_TIMEOUT` | MCP 서버 시작 타임아웃(밀리초, 기본값 `30000` = 30초) |
| `MAX_MCP_OUTPUT_TOKENS` | MCP 도구 응답에 허용되는 최대 토큰 수 |

CI에서 비대화형(`claude -p`)으로 실행할 때 조정할 가치가 있는 값들입니다. 긴 빌드나 느린 MCP 서버에는 기본값이 빠듯한 경우가 많습니다.

### 컨테이너 운영, 업데이트, 프라이버시

| 변수 | 설명 |
|------|------|
| `CLAUDE_CONFIG_DIR` | 설정 디렉터리 재정의 (기본값 `~/.claude`). 설정, 세션 기록, 플러그인이 이 경로에 저장되므로 볼륨 마운트 대상도 여기로 맞추세요 |
| `DISABLE_AUTOUPDATER` | `1`로 설정하면 백그라운드 자동 업데이트를 끕니다. 수동 `claude update`는 계속 동작합니다 |
| `DISABLE_UPDATES` | `1`로 설정하면 수동 `claude update`를 포함한 모든 업데이트를 차단합니다. `DISABLE_AUTOUPDATER`보다 엄격하며, 버전이 고정된 이미지에는 보통 이쪽이 적합합니다 |
| `DISABLE_TELEMETRY` | 텔레메트리 수집 거부. 아래 경고를 참조하세요 |
| `DO_NOT_TRACK` | `1`로 설정하면 텔레메트리를 거부하며 `DISABLE_TELEMETRY`와 효과가 같습니다. 일반 불리언으로 읽히므로 `0`이면 텔레메트리가 켜진 상태로 유지됩니다 |
| `DISABLE_ERROR_REPORTING` | 오류 리포팅 거부. 아래 경고를 참조하세요 |
| `CLAUDECODE` | Claude Code가 생성하는 하위 프로세스에 `1`로 설정됩니다. 스크립트가 Claude Code 아래에서 실행 중인지 감지할 때 사용 |

> [!WARNING]
> `DISABLE_TELEMETRY`와 `DISABLE_ERROR_REPORTING`은 **`0`과 `false`를 포함해 비어 있지 않은 모든 값에 대해 거부로 동작합니다.** `-e DISABLE_TELEMETRY=0`을 전달해도 다시 켜지지 않고 꺼진 상태가 유지됩니다. 다시 활성화하려면 변수를 아예 설정하지 않아야 합니다. `DO_NOT_TRACK`은 예외로 일반 불리언으로 읽히므로 `DO_NOT_TRACK=0`이면 텔레메트리가 실제로 켜집니다.
>
> 두 텔레메트리 거부 설정 모두 기능 플래그 조회도 함께 비활성화하므로, Remote Control을 비롯해 기능 플래그에 의존하는 기능들을 사용할 수 없게 됩니다.

> [!TIP]
> 이 이미지는 버전이 고정된 형태로 배포되므로, `DISABLE_UPDATES=1`을 설정하면 Claude Code가 런타임에 스스로 업데이트하는 것을 막아 태그의 재현성을 유지할 수 있습니다.

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
