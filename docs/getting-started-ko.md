# Claude Docker 시작하기

Docker에서 Claude Code를 실행하는 빠른 가이드입니다.

## 빠른 시작

```bash
docker pull ghcr.io/jyje/claude-docker

docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

## 환경 변수

| 변수 | 필수 | 설명 |
|------|------|------|
| `ANTHROPIC_API_KEY` | 예 | [console.anthropic.com](https://console.anthropic.com/)에서 발급 |
| `ANTHROPIC_BASE_URL` | 아니오 | 커스텀 엔드포인트 (로컬 모델, 프록시 등) |

`.env` 파일 사용:
```bash
# .env
ANTHROPIC_API_KEY=sk-ant-api03-xxxx...

docker run --rm -it --env-file .env -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

## 빠른 테스트

Headless 모드 동작 확인:

```bash
curl -O https://raw.githubusercontent.com/jyje/claude-docker/main/test.sh
chmod +x test.sh
echo "sk-ant-api03-your-key" > api-key

./test.sh
./test.sh "이 코드 분석" "./output.txt"
```

자동화 템플릿: [test.sh](../test.sh)

## 사용 변형

**커스텀 Base URL** (로컬 모델/프록시):
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -e ANTHROPIC_BASE_URL=http://localhost:12434 -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

**특정 버전:**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker:v2.1.23
```

**Claude 직접 실행:**
```bash
docker run --rm -it -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker claude
```

버전 목록: [GitHub Container Registry](https://github.com/jyje/claude-docker/pkgs/container/claude-docker)

## API 키 인증 (로그인 불필요)

OAuth 브라우저 로그인 없이 API 키만 사용—headless/CI 환경에 필수입니다.

**설정** (컨테이너 내부, 최초 1회):
```bash
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

Claude가 이 helper를 통해 키를 읽어 OAuth를 우회합니다. 커스텀 이미지 예제는 [Headless CLI 파이프라인](headless-pipeline-ko.md) 참조.

## 네트워크 샌드박스

선택 사항: [공식 방화벽 스크립트](https://github.com/anthropics/claude-code/tree/main/.devcontainer)로 네트워크 격리:

```bash
docker run --rm -it --cap-add=NET_ADMIN --cap-add=NET_RAW -e ANTHROPIC_API_KEY -v $(pwd):/workspace ghcr.io/jyje/claude-docker

# 컨테이너 내부:
sudo /usr/local/bin/init-firewall.sh
```

## 고급: Kubernetes, CI/CD, Argo Workflows

Kubernetes 사이드카, Argo Workflows, Jobs, CronJobs, CI/CD 통합은 [Headless CLI 파이프라인](headless-pipeline-ko.md) 가이드를 참조하세요.

## 다음 단계

- [MCP 연결](../readme-ko.md#mcp-model-context-protocol-연결) – 외부 도구
- [사전 설치 유틸리티](../readme-ko.md#사전-설치된-유틸리티) – 이미지 구성
- [DevContainer 지원](../readme-ko.md#devcontainer-지원) – VS Code
- [CI 파이프라인](../readme-ko.md#ci-파이프라인) – 자동 빌드
