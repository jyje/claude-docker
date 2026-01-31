# Claude Docker 시작하기

이 가이드는 Claude Code 커뮤니티 도커 이미지를 시작하는 데 도움을 드립니다.

## 빠른 시작

GitHub Container Registry에서 이미지를 가져옵니다:

```bash
docker pull ghcr.io/jyje/claude-docker
```

API 키와 함께 실행:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

## 환경 변수

| 변수 | 필수 | 설명 |
|------|------|------|
| `ANTHROPIC_API_KEY` | 예 | Anthropic API 키. [console.anthropic.com](https://console.anthropic.com/)에서 발급 |
| `ANTHROPIC_BASE_URL` | 아니오 | 커스텀 API 엔드포인트 URL. 로컬 모델(예: Docker Model Runner) 또는 커스텀 엔드포인트 사용 시 |

### .env 파일 사용

프로젝트 디렉터리에 `.env` 파일을 생성:

```bash
# .env
# 필수: Anthropic API 키
ANTHROPIC_API_KEY=sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 선택: 커스텀 API Base URL (로컬 모델 또는 프록시용)
# ANTHROPIC_BASE_URL=http://localhost:12434
# ANTHROPIC_BASE_URL=https://your-proxy.company.com/v1
```

`--env-file` 옵션으로 실행:

```bash
docker run --rm -it --env-file .env -v $(pwd):/workspace ghcr.io/jyje/claude-docker
```

## 기본 사용법

### 환경 변수에서 API 키 사용

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

### 커스텀 Base URL 사용

로컬 모델 또는 프록시용:

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -e ANTHROPIC_BASE_URL=http://localhost:12434 \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker
```

### 특정 버전 사용

```bash
docker pull ghcr.io/jyje/claude-docker:v2.1.23

docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker:v2.1.23
```

사용 가능한 버전 목록은 [GitHub Container Registry](https://github.com/jyje/claude-docker/pkgs/container/claude-docker)에서 확인할 수 있습니다.

### Claude Code 대화형 세션 시작

```bash
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker \
  claude
```

## API 키 인증 (로그인 불필요)

Claude Code는 OAuth 브라우저 로그인 없이 API 키만으로 직접 인증할 수 있습니다. 도커 컨테이너 환경에서 가장 안정적인 방식입니다.

### API Key Helper 설정

Claude Code가 `ANTHROPIC_API_KEY` 환경변수를 사용하도록 설정 파일을 생성:

```bash
# 컨테이너 내부에서 실행 (또는 Dockerfile에 추가)
mkdir -p ~/.claude

cat > ~/.claude/settings.json <<'JSON'
{
  "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
}
JSON
```

### 완전한 예제

```bash
# 1. 호스트에서 API 키 export
export ANTHROPIC_API_KEY="sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 2. API 키와 함께 컨테이너 실행
docker run --rm -it \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker bash

# 3. 컨테이너 내부에서 API key helper 설정 (최초 1회)
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json

# 4. Claude Code 실행 - 로그인 불필요!
claude
```

### 동작 원리

- Claude Code는 `~/.claude/settings.json`에서 `apiKeyHelper` 명령을 읽습니다
- Helper 명령이 `$ANTHROPIC_API_KEY`의 값을 출력합니다
- OAuth 로그인 플로우를 완전히 우회합니다
- CI/CD, 컨테이너, headless 환경에 이상적입니다

### Dockerfile 통합

`jyje/claude-docker` 기반으로 자체 이미지를 만들 때:

```dockerfile
FROM ghcr.io/jyje/claude-docker:latest

# node 사용자용 API key helper 사전 구성
USER node
RUN mkdir -p /home/node/.claude && \
    echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > /home/node/.claude/settings.json

# 추가 설정...
```

## 네트워크 샌드박스 (방화벽)

보안 강화를 위한 네트워크 격리:

```bash
docker run --rm -it \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker

# 컨테이너 내부에서 실행:
sudo /usr/local/bin/init-firewall.sh
```

방화벽 스크립트(`init-firewall.sh`)는 [Anthropic 공식 devcontainer](https://github.com/anthropics/claude-code/tree/main/.devcontainer)에서 제공하며 Claude Code 실행을 위한 네트워크 샌드박싱을 제공합니다.

## 쿠버네티스 사이드카 구성

쿠버네티스 Pod에서 Claude Code를 사이드카 컨테이너로 사용하며 자동 API 키 인증을 구성합니다.

### 최소 예제

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

### 사용법

```bash
# 사이드카에서 Claude Code 실행
kubectl exec -it app-with-claude -c claude-code -- claude

# 공유 워크스페이스 접근
kubectl exec -it app-with-claude -c claude-code -- ls /workspace
```

영구 스토리지 및 Deployment를 포함한 더 자세한 쿠버네티스 구성은 [메인 README](readme-ko.md#쿠버네티스-사이드카-구성)를 참조하세요.

## 다음 단계

- 외부 도구 연결을 위한 [MCP (Model Context Protocol) 연결](readme-ko.md#mcp-model-context-protocol-연결) 알아보기
- 이미지에서 사용 가능한 [사전 설치된 유틸리티](readme-ko.md#사전-설치된-유틸리티) 확인
- VS Code 통합을 위한 [DevContainer 지원](readme-ko.md#devcontainer-지원) 탐색
- 자동 빌드 및 업데이트를 위한 [CI 파이프라인](readme-ko.md#ci-파이프라인) 검토

## 참고 자료

- [Docker AI Sandboxes: Claude Code](https://docs.docker.com/ai/sandboxes/claude-code/)
- [Stack Overflow: API 키로 Claude Code 사용하기](https://stackoverflow.com/questions/79629224/how-do-i-use-claude-code-with-an-existing-anthropic-api-key)
- [Anthropic API 문서](https://docs.n8n.io/integrations/builtin/credentials/anthropic/)
- [공식 Claude Code 문서](https://docs.anthropic.com/en/docs/claude-code)
