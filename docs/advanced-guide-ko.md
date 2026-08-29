# 고급 가이드

Claude Docker 파이프라인 통합 가이드. 난이도 순으로 구성되어 있습니다.


---

## 목차

- [Headless 사용법](#headless-사용법) ← 여기서 시작
- [사전 요구사항](#사전-요구사항)
- [Level 1: CI/CD 통합](#level-1-cicd-통합)
- [Level 2: Kubernetes Jobs](#level-2-kubernetes-jobs)
- [Level 3: Argo Workflows](#level-3-argo-workflows)
- [Level 4: 실시간 로그 분석](#level-4-실시간-로그-분석)
- [Level 4: 고급 패턴](#level-4-고급-패턴)
- [모범 사례](#모범-사례)
- [문제 해결](#문제-해결)

---


---

## Headless 사용법

**Headless**는 대화형 로그인 없이 API 키만으로 Claude Code를 실행하는 방식입니다. 파이프라인, CI/CD, 자동화에 적합합니다.

### 개념

1. `ANTHROPIC_API_KEY` 환경변수 설정
2. `~/.claude/settings.json`에 `apiKeyHelper`로 키 읽기 설정
3. Claude가 OAuth를 우회하고 비대화형으로 실행

### Docker Run 예제

```bash
# 단일 명령 실행
docker run --rm \
  -e ANTHROPIC_API_KEY="sk-ant-api03-..." \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker \
  bash -c 'mkdir -p ~/.claude && echo "{\"apiKeyHelper\": \"printf %s \\\"$ANTHROPIC_API_KEY\\\"\"}" > ~/.claude/settings.json && claude "Analyze the code in /workspace"'

# 파이프 입력 사용
echo "Explain this code: $(cat main.py)" | docker run --rm -i \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker \
  bash -c 'mkdir -p ~/.claude && echo "{\"apiKeyHelper\": \"printf %s \\\"$ANTHROPIC_API_KEY\\\"\"}" > ~/.claude/settings.json && claude'
```


---

## 사전 요구사항

### API 키 구성

Headless 환경에서는 OAuth 로그인을 우회하도록 API key helper를 구성합니다:

```bash
mkdir -p ~/.claude
cat > ~/.claude/settings.json <<'JSON'
{
  "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
}
JSON
```

이 설정은 커스텀 이미지에 포함시키거나 런타임에 구성할 수 있습니다.


---

## Level 1: CI/CD 통합

가장 단순한 통합—기존 파이프라인에 Claude 추가.

### GitHub Actions

```yaml
name: Claude Code Review

on:
  pull_request:
    branches: [main, develop]

jobs:
  claude-review:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Run Claude Code Review
      run: |
        docker run --rm \
          -e ANTHROPIC_API_KEY="${{ secrets.ANTHROPIC_API_KEY }}" \
          -v $(pwd):/workspace \
          ghcr.io/jyje/claude-docker:latest \
          bash -c '
            mkdir -p ~/.claude
            echo "{\"apiKeyHelper\": \"printf %s \\\"$ANTHROPIC_API_KEY\\\"\"}" > ~/.claude/settings.json
            cd /workspace
            claude "Review the code changes in this PR and suggest improvements" > review-output.txt
            cat review-output.txt
          '
    
    - name: Upload Review Report
      uses: actions/upload-artifact@v4
      with:
        name: claude-review-report
        path: review-output.txt
```

### GitLab CI

```yaml
claude-code-review:
  image: ghcr.io/jyje/claude-docker:latest
  stage: test
  
  variables:
    ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY
  
  before_script:
    - mkdir -p ~/.claude
    - echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
  
  script:
    - claude "Analyze this codebase for potential issues" > analysis-report.txt
    - cat analysis-report.txt
  
  artifacts:
    paths:
      - analysis-report.txt
    expire_in: 1 week
  
  only:
    - merge_requests
```

### Jenkins Pipeline

```groovy
pipeline {
    agent {
        docker {
            image 'ghcr.io/jyje/claude-docker:latest'
            args '-v $PWD:/workspace'
        }
    }
    
    environment {
        ANTHROPIC_API_KEY = credentials('anthropic-api-key')
    }
    
    stages {
        stage('Setup Claude') {
            steps {
                sh '''
                    mkdir -p ~/.claude
                    echo '{"apiKeyHelper": "printf %s \\"$ANTHROPIC_API_KEY\\""}' > ~/.claude/settings.json
                '''
            }
        }
        
        stage('Code Analysis') {
            steps {
                sh '''
                    cd /workspace
                    claude "Perform a comprehensive code review" > analysis-report.txt
                    cat analysis-report.txt
                '''
            }
        }
        
        stage('Archive Results') {
            steps {
                archiveArtifacts artifacts: 'analysis-report.txt', fingerprint: true
            }
        }
    }
}
```


---

## Level 2: Kubernetes Jobs

### 일회성 코드 분석 Job

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
apiVersion: batch/v1
kind: Job
metadata:
  name: claude-code-analysis
spec:
  template:
    spec:
      restartPolicy: Never
      
      initContainers:
      - name: clone-repo
        image: alpine/git
        command: ["/bin/sh", "-c"]
        args:
        - |
          git clone https://github.com/example/repo.git /workspace/repo
        volumeMounts:
        - name: workspace
          mountPath: /workspace
      
      containers:
      - name: claude-analyze
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          # API key helper 설정
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          # 코드로 이동
          cd /workspace/repo
          
          # Claude로 분석 실행
          claude "Analyze this codebase and provide a summary of its architecture and key components" \
            > /workspace/analysis-report.txt
          
          # 결과 출력
          echo "=== 분석 완료 ==="
          cat /workspace/analysis-report.txt
        
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
        
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      
      volumes:
      - name: workspace
        emptyDir: {}
      - name: claude-settings
        configMap:
          name: claude-settings
```

### 결과 저장용 PVC가 있는 Job

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: claude-results
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: batch/v1
kind: Job
metadata:
  name: claude-weekly-review
spec:
  template:
    spec:
      restartPolicy: OnFailure
      
      containers:
      - name: claude-review
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          TIMESTAMP=$(date +%Y%m%d-%H%M%S)
          REPORT_FILE="/results/review-${TIMESTAMP}.txt"
          
          cd /workspace
          git clone https://github.com/example/repo.git repo
          cd repo
          
          claude "Perform a comprehensive code review focusing on recent changes" > "$REPORT_FILE"
          
          echo "보고서 저장됨: $REPORT_FILE"
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        
        volumeMounts:
        - name: workspace
          mountPath: /workspace
        - name: results
          mountPath: /results
        - name: claude-settings
          mountPath: /claude-config
      
      volumes:
      - name: workspace
        emptyDir: {}
      - name: results
        persistentVolumeClaim:
          claimName: claude-results
      - name: claude-settings
        configMap:
          name: claude-settings
```


---

## Level 2: Kubernetes CronJob

### 스케줄된 코드 분석

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: claude-daily-analysis
spec:
  schedule: "0 2 * * *"  # 매일 새벽 2시 실행
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: OnFailure
          
          containers:
          - name: claude-analyze
            image: ghcr.io/jyje/claude-docker:latest
            command: ["/bin/bash", "-c"]
            args:
            - |
              mkdir -p /home/node/.claude
              cp /claude-config/settings.json /home/node/.claude/settings.json
              
              cd /workspace
              git clone https://github.com/example/repo.git repo
              cd repo
              
              DATE=$(date +%Y-%m-%d)
              claude "Analyze code changes from the last 24 hours and summarize key updates" \
                > /workspace/daily-report-${DATE}.txt
              
              # 선택사항: S3 업로드, Slack 전송 등
              echo "${DATE} 분석 완료"
            
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


---

## Level 3: Argo Workflows

### 간단한 워크플로우 템플릿

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: claude-code-analysis-
spec:
  entrypoint: analyze-code
  
  volumes:
  - name: claude-settings
    configMap:
      name: claude-settings
  
  templates:
  - name: analyze-code
    inputs:
      parameters:
      - name: repository
        value: "https://github.com/example/repo.git"
      - name: prompt
        value: "Review this codebase for security issues"
    
    container:
      image: ghcr.io/jyje/claude-docker:latest
      command: ["/bin/bash", "-c"]
      args:
      - |
        # API key helper 설정
        mkdir -p /home/node/.claude
        cp /claude-config/settings.json /home/node/.claude/settings.json
        
        # 저장소 클론
        cd /workspace
        git clone {{inputs.parameters.repository}} repo
        cd repo
        
        # Claude Code 분석 실행
        claude "{{inputs.parameters.prompt}}" > /workspace/analysis-report.txt
        
        # 결과 출력
        cat /workspace/analysis-report.txt
      
      env:
      - name: ANTHROPIC_API_KEY
        valueFrom:
          secretKeyRef:
            name: claude-api-key
            key: ANTHROPIC_API_KEY
      
      volumeMounts:
      - name: claude-settings
        mountPath: /claude-config
      
      workingDir: /workspace
    
    outputs:
      artifacts:
      - name: analysis-report
        path: /workspace/analysis-report.txt
```

### DAG를 사용한 다단계 워크플로우

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  generateName: claude-code-review-pipeline-
spec:
  entrypoint: code-review-pipeline
  
  volumes:
  - name: claude-settings
    configMap:
      name: claude-settings
  
  templates:
  - name: code-review-pipeline
    dag:
      tasks:
      - name: security-scan
        template: claude-analyze
        arguments:
          parameters:
          - name: prompt
            value: "Perform a security audit of this codebase"
          - name: output-file
            value: "security-report.txt"
      
      - name: code-quality
        template: claude-analyze
        arguments:
          parameters:
          - name: prompt
            value: "Review code quality and suggest improvements"
          - name: output-file
            value: "quality-report.txt"
      
      - name: documentation-check
        template: claude-analyze
        arguments:
          parameters:
          - name: prompt
            value: "Check documentation completeness"
          - name: output-file
            value: "docs-report.txt"
      
      - name: consolidate-reports
        dependencies: [security-scan, code-quality, documentation-check]
        template: merge-reports
  
  - name: claude-analyze
    inputs:
      parameters:
      - name: prompt
      - name: output-file
      artifacts:
      - name: source-code
        path: /workspace/code
        git:
          repo: "https://github.com/example/repo.git"
          revision: "main"
    
    container:
      image: ghcr.io/jyje/claude-docker:latest
      command: ["/bin/bash", "-c"]
      args:
      - |
        mkdir -p /home/node/.claude
        cp /claude-config/settings.json /home/node/.claude/settings.json
        cd /workspace/code
        claude "{{inputs.parameters.prompt}}" > /workspace/{{inputs.parameters.output-file}}
      
      env:
      - name: ANTHROPIC_API_KEY
        valueFrom:
          secretKeyRef:
            name: claude-api-key
            key: ANTHROPIC_API_KEY
      
      volumeMounts:
      - name: claude-settings
        mountPath: /claude-config
    
    outputs:
      artifacts:
      - name: report
        path: /workspace/{{inputs.parameters.output-file}}
  
  - name: merge-reports
    inputs:
      artifacts:
      - name: security-report
        path: /workspace/security-report.txt
        from: "{{tasks.security-scan.outputs.artifacts.report}}"
      - name: quality-report
        path: /workspace/quality-report.txt
        from: "{{tasks.code-quality.outputs.artifacts.report}}"
      - name: docs-report
        path: /workspace/docs-report.txt
        from: "{{tasks.documentation-check.outputs.artifacts.report}}"
    
    container:
      image: ghcr.io/jyje/claude-docker:latest
      command: ["/bin/bash", "-c"]
      args:
      - |
        cat /workspace/security-report.txt /workspace/quality-report.txt /workspace/docs-report.txt > /workspace/final-report.txt
        echo "=== 통합 코드 리뷰 보고서 ===" | cat - /workspace/final-report.txt > temp && mv temp /workspace/final-report.txt
    
    outputs:
      artifacts:
      - name: final-report
        path: /workspace/final-report.txt
```


---

## Level 4: 실시간 로그 분석

### 로그 분석 사이드카

사이드카 컨테이너로 Claude를 사용하여 애플리케이션 로그를 실시간으로 모니터링하고 이상 징후를 감지합니다.

```yaml
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
kind: Secret
metadata:
  name: claude-api-key
type: Opaque
stringData:
  ANTHROPIC_API_KEY: "sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-log-analyzer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      # 메인 애플리케이션
      - name: app
        image: your-app:latest
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
        command: ["/bin/sh", "-c"]
        args:
        - |
          # 애플리케이션이 /var/log/app/app.log에 로그 작성
          while true; do
            echo "[$(date)] INFO: Processing request..." >> /var/log/app/app.log
            sleep 5
          done
      
      # Claude 로그 분석 사이드카
      - name: log-analyzer
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          # API key helper 설정
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          # 로그 파일 생성 대기
          while [ ! -f /var/log/app/app.log ]; do
            echo "로그 파일 대기 중..."
            sleep 2
          done
          
          echo "실시간 로그 분석 시작..."
          
          # 로그를 tail하고 배치로 분석
          tail -f /var/log/app/app.log | while IFS= read -r line; do
            echo "$line" >> /tmp/log-buffer.txt
            
            # 50줄마다 분석
            if [ $(wc -l < /tmp/log-buffer.txt) -ge 50 ]; then
              echo "로그 배치 분석 중..."
              
              ANALYSIS=$(claude "다음 애플리케이션 로그를 분석하고 에러, 경고 또는 이상 징후를 식별하세요. 간단한 요약 제공: $(cat /tmp/log-buffer.txt)")
              
              # 분석 결과 출력
              echo "=== 로그 분석 $(date) ==="
              echo "$ANALYSIS"
              echo "=============================="
              
              # 버퍼 초기화
              > /tmp/log-buffer.txt
            fi
          done
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
        - name: claude-settings
          mountPath: /claude-config
        
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      
      volumes:
      - name: logs
        emptyDir: {}
      - name: claude-settings
        configMap:
          name: claude-settings
```

### 시간 기반 로그 분석 사이드카

줄 수 대신 정기적인 간격으로 로그 분석:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-periodic-log-analyzer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: your-app:latest
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
      
      - name: log-analyzer
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          LOG_FILE="/var/log/app/app.log"
          ANALYSIS_INTERVAL=300  # 5분
          
          echo "주기적 로그 분석 시작 (${ANALYSIS_INTERVAL}초마다)..."
          
          while true; do
            if [ -f "$LOG_FILE" ]; then
              # 최근 N분 동안의 로그 가져오기
              RECENT_LOGS=$(tail -n 1000 "$LOG_FILE")
              
              if [ -n "$RECENT_LOGS" ]; then
                TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
                
                echo "[$TIMESTAMP] 최근 로그 분석 중..."
                
                ANALYSIS=$(claude "지난 5분간의 애플리케이션 로그를 분석하세요. 중요한 문제와 에러를 식별하고 실행 가능한 인사이트를 제공하세요: $RECENT_LOGS")
                
                echo "=== 로그 분석: $TIMESTAMP ==="
                echo "$ANALYSIS"
                echo "================================="
                
                # 선택사항: 심각한 문제 발견 시 알림 전송
                if echo "$ANALYSIS" | grep -qi "critical\|error\|failure"; then
                  echo "⚠️ 심각한 문제 감지! 알림 전송 중..."
                  # 알림 로직 추가 (Slack, PagerDuty 등)
                fi
              fi
            fi
            
            sleep $ANALYSIS_INTERVAL
          done
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
        - name: claude-settings
          mountPath: /claude-config
      
      volumes:
      - name: logs
        emptyDir: {}
      - name: claude-settings
        configMap:
          name: claude-settings
```

### Fluentd/Fluent Bit을 사용한 중앙 집중식 로그 분석

로그 수집 시스템에서 수집한 로그 분석:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/containers/*.log
      pos_file /var/log/fluentd-containers.log.pos
      tag kubernetes.*
      format json
    </source>
    
    <match kubernetes.**>
      @type exec_filter
      command /usr/local/bin/claude-analyze.sh
      <format>
        @type json
      </format>
    </match>
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: claude-analyze-script
data:
  claude-analyze.sh: |
    #!/bin/bash
    # stdin에서 JSON 로그 읽기
    LOG_ENTRY=$(cat)
    
    # N개의 로그마다 Claude로 분석 (배치 처리 구현)
    echo "$LOG_ENTRY" >> /tmp/log-batch.txt
    
    if [ $(wc -l < /tmp/log-batch.txt) -ge 100 ]; then
      export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
      
      mkdir -p ~/.claude
      echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
      
      ANALYSIS=$(claude "다음 쿠버네티스 로그를 분석하고 문제를 식별하세요: $(cat /tmp/log-batch.txt)")
      
      echo "$ANALYSIS" > /tmp/analysis-$(date +%s).txt
      > /tmp/log-batch.txt
    fi
    
    # 원본 로그 전달
    echo "$LOG_ENTRY"
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-claude
spec:
  selector:
    matchLabels:
      app: fluentd-claude
  template:
    metadata:
      labels:
        app: fluentd-claude
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:latest
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: fluentd-config
          mountPath: /fluentd/etc
        - name: claude-script
          mountPath: /usr/local/bin/claude-analyze.sh
          subPath: claude-analyze.sh
      
      - name: claude-analyzer
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          # 분석 결과 모니터링 및 알림 전송
          while true; do
            for file in /tmp/analysis-*.txt; do
              if [ -f "$file" ]; then
                cat "$file"
                # 모니터링/알림 시스템으로 전송
                rm "$file"
              fi
            done
            sleep 10
          done
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        
        volumeMounts:
        - name: claude-settings
          mountPath: /claude-config
        - name: tmp
          mountPath: /tmp
      
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: fluentd-config
        configMap:
          name: fluentd-config
      - name: claude-script
        configMap:
          name: claude-analyze-script
          defaultMode: 0755
      - name: claude-settings
        configMap:
          name: claude-settings
      - name: tmp
        emptyDir: {}
```

### Kafka를 사용한 스트림 처리

Kafka 스트림에서 실시간으로 로그 분석:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kafka-log-analyzer
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-analyzer
  template:
    metadata:
      labels:
        app: log-analyzer
    spec:
      containers:
      - name: analyzer
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          # kafka consumer 설치 (베이스 이미지에 없는 경우)
          npm install -g kafkajs
          
          # Node.js consumer 스크립트 생성
          cat > /tmp/kafka-consumer.js <<'EOF'
          const { Kafka } = require('kafkajs');
          const { exec } = require('child_process');
          const util = require('util');
          const execPromise = util.promisify(exec);
          
          const kafka = new Kafka({
            clientId: 'claude-log-analyzer',
            brokers: [process.env.KAFKA_BROKERS]
          });
          
          const consumer = kafka.consumer({ groupId: 'log-analysis-group' });
          
          let logBuffer = [];
          const BATCH_SIZE = 50;
          
          async function analyzeLogs(logs) {
            const logsText = logs.join('\n');
            const { stdout } = await execPromise(
              `claude "다음 로그를 분석하고 이상 징후를 식별하세요: ${logsText}"`
            );
            console.log('=== 분석 결과 ===');
            console.log(stdout);
            console.log('==================');
          }
          
          const run = async () => {
            await consumer.connect();
            await consumer.subscribe({ topic: 'application-logs', fromBeginning: false });
            
            await consumer.run({
              eachMessage: async ({ topic, partition, message }) => {
                const log = message.value.toString();
                console.log(`로그 수신: ${log}`);
                
                logBuffer.push(log);
                
                if (logBuffer.length >= BATCH_SIZE) {
                  await analyzeLogs(logBuffer);
                  logBuffer = [];
                }
              },
            });
          };
          
          run().catch(console.error);
          EOF
          
          # consumer 실행
          node /tmp/kafka-consumer.js
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        - name: KAFKA_BROKERS
          value: "kafka-service:9092"
        
        volumeMounts:
        - name: claude-settings
          mountPath: /claude-config
      
      volumes:
      - name: claude-settings
        configMap:
          name: claude-settings
```

### 알림 통합 예제

로그를 분석하고 Claude의 분석 결과에 따라 알림 트리거:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-analyzer-with-alerts
spec:
  replicas: 1
  selector:
    matchLabels:
      app: log-analyzer
  template:
    metadata:
      labels:
        app: log-analyzer
    spec:
      containers:
      - name: app
        image: your-app:latest
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
      
      - name: analyzer
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          LOG_FILE="/var/log/app/app.log"
          CHECK_INTERVAL=60
          
          while true; do
            if [ -f "$LOG_FILE" ]; then
              RECENT_LOGS=$(tail -n 500 "$LOG_FILE")
              
              if [ -n "$RECENT_LOGS" ]; then
                # 로그 분석
                ANALYSIS=$(claude "다음 로그를 분석하세요. 심각도(LOW/MEDIUM/HIGH/CRITICAL)를 평가하고 문제를 설명하세요: $RECENT_LOGS")
                
                echo "분석: $ANALYSIS"
                
                # 심각도 확인 및 알림 전송
                if echo "$ANALYSIS" | grep -qi "CRITICAL"; then
                  SEVERITY="critical"
                  COLOR="#ff0000"
                  EMOJI="🚨"
                elif echo "$ANALYSIS" | grep -qi "HIGH"; then
                  SEVERITY="high"
                  COLOR="#ff9900"
                  EMOJI="⚠️"
                elif echo "$ANALYSIS" | grep -qi "MEDIUM"; then
                  SEVERITY="medium"
                  COLOR="#ffcc00"
                  EMOJI="⚡"
                else
                  SEVERITY="low"
                  COLOR="#00ff00"
                  EMOJI="✅"
                fi
                
                # Slack으로 전송
                if [ "$SEVERITY" != "low" ]; then
                  curl -X POST "$SLACK_WEBHOOK_URL" \
                    -H 'Content-Type: application/json' \
                    -d "{
                      \"attachments\": [{
                        \"color\": \"$COLOR\",
                        \"title\": \"$EMOJI 로그 분석 알림 - $SEVERITY\",
                        \"text\": \"$ANALYSIS\",
                        \"footer\": \"Claude Log Analyzer\",
                        \"ts\": $(date +%s)
                      }]
                    }"
                  
                  echo "$SEVERITY 심각도 알림 전송됨"
                fi
              fi
            fi
            
            sleep $CHECK_INTERVAL
          done
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        - name: SLACK_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: slack-webhook
              key: url
        
        volumeMounts:
        - name: logs
          mountPath: /var/log/app
        - name: claude-settings
          mountPath: /claude-config
      
      volumes:
      - name: logs
        emptyDir: {}
      - name: claude-settings
        configMap:
          name: claude-settings
```


---

## Level 4: 고급 패턴

### 다중 프롬프트 병렬 분석

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: claude-parallel-analysis
spec:
  parallelism: 3
  completions: 3
  
  template:
    spec:
      restartPolicy: Never
      
      containers:
      - name: claude-analyze
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          cd /workspace
          git clone https://github.com/example/repo.git repo
          cd repo
          
          # JOB_COMPLETION_INDEX에 따라 실행할 분석 결정
          case $JOB_COMPLETION_INDEX in
            0)
              PROMPT="Security audit"
              OUTPUT="security.txt"
              ;;
            1)
              PROMPT="Code quality review"
              OUTPUT="quality.txt"
              ;;
            2)
              PROMPT="Documentation review"
              OUTPUT="documentation.txt"
              ;;
          esac
          
          claude "$PROMPT" > "/workspace/$OUTPUT"
          echo "완료: $OUTPUT"
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        - name: JOB_COMPLETION_INDEX
          valueFrom:
            fieldRef:
              fieldPath: metadata.annotations['batch.kubernetes.io/job-completion-index']
        
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

### 알림 시스템과의 통합

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: claude-analyze-notify
spec:
  template:
    spec:
      restartPolicy: Never
      
      containers:
      - name: claude-analyze
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          cd /workspace
          git clone https://github.com/example/repo.git repo
          cd repo
          
          # 분석 실행
          REPORT=$(claude "Analyze recent changes and summarize findings")
          
          # Slack으로 전송
          curl -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"Claude 코드 분석 완료\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$REPORT\"}}]}"
          
          echo "$REPORT"
        
        env:
        - name: ANTHROPIC_API_KEY
          valueFrom:
            secretKeyRef:
              name: claude-api-key
              key: ANTHROPIC_API_KEY
        - name: SLACK_WEBHOOK_URL
          valueFrom:
            secretKeyRef:
              name: slack-webhook
              key: url
        
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


---

## 모범 사례

1. **API 키 관리**
   - API 키는 항상 Kubernetes Secrets 사용
   - YAML 파일에 자격증명 하드코딩 금지
   - 외부 시크릿 관리 도구 사용 고려 (Vault, AWS Secrets Manager)

2. **리소스 제한**
   - 적절한 메모리(512Mi-1Gi)와 CPU(250m-500m) 제한 설정
   - 실제 사용량 모니터링 후 조정

3. **오류 처리**
   - 일시적 오류에는 `restartPolicy: OnFailure` 사용
   - 스크립트에 재시도 로직 구현
   - 디버깅을 위해 영구 스토리지에 출력 로그 저장

4. **출력 관리**
   - Argo Workflows에서 결과 영속성을 위해 artifacts 사용
   - PVC 또는 외부 스토리지(S3, GCS)에 보고서 저장
   - 출력 저장 시 크기 제한 고려

5. **성능**
   - 무거운 작업(git clone)은 init 컨테이너 사용
   - 독립적인 분석은 병렬 실행
   - 가능한 경우 저장소 캐싱


---

## 문제 해결

### 일반적인 문제

**문제**: Headless 환경에서 OAuth 로그인 프롬프트
```bash
# 해결책: API key helper가 올바르게 구성되었는지 확인
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

**문제**: 권한 거부 오류
```bash
# 해결책: 적절한 사용자 및 파일 권한 확인
chown -R node:node /workspace /home/node/.claude
```

**문제**: 타임아웃 오류
```bash
# 해결책: 타임아웃 증가 및 재시도 로직 추가
timeout 300 claude "your prompt" || echo "타임아웃 또는 오류 발생"
```


---

## 참고 자료

- [시작 가이드](getting-started-ko.md)
- [Argo Workflows 문서](https://argoproj.github.io/workflows/)
- [Kubernetes Jobs 문서](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Claude Code 공식 문서](https://code.claude.com/docs)
