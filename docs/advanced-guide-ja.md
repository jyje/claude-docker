<!-- Translated from docs/advanced-guide.md at 4892c7a -->
# 上級ガイド

難易度順に並べた、Claude Docker のパイプライン連携ガイドです。

> [!NOTE]
> この翻訳は AI の支援で作成したもので、ネイティブスピーカーによるレビューはまだ受けていません。修正の PR を歓迎します。コードブロックの内容（コメントを含む）は英語のままにしています。内容に差異がある場合は、英語版の [advanced-guide.md](advanced-guide.md) が正です。


---

## 目次

- [ヘッドレスでの使い方](#ヘッドレスでの使い方) ← ここから始めてください
- [前提条件](#前提条件)
- [レベル 1：CI/CD 連携](#レベル-1cicd-連携)
- [レベル 2：Kubernetes Job](#レベル-2kubernetes-job)
- [レベル 3：Argo Workflows](#レベル-3argo-workflows)
- [レベル 4：リアルタイムログ分析](#レベル-4リアルタイムログ分析)
- [レベル 4：高度なパターン](#レベル-4高度なパターン)
- [ベストプラクティス](#ベストプラクティス)
- [トラブルシューティング](#トラブルシューティング)

---


---

## ヘッドレスでの使い方

**ヘッドレス（Headless）** とは、対話的なログインなしで Claude Code を実行することです。API キーだけを使うため、パイプライン、CI/CD、自動化に最適です。

### 考え方

1. `ANTHROPIC_API_KEY` を環境変数として設定する
2. `~/.claude/settings.json` に `apiKeyHelper` を設定してキーを読み取らせる
3. Claude は OAuth を回避し、非対話モードで実行される

### 基本的な Docker の例

```bash
# Single command
docker run --rm \
  -e ANTHROPIC_API_KEY="sk-ant-api03-..." \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker \
  bash -c 'mkdir -p ~/.claude && echo "{\"apiKeyHelper\": \"printf %s \\\"$ANTHROPIC_API_KEY\\\"\"}" > ~/.claude/settings.json && claude "Analyze the code in /workspace"'

# Piped input
echo "Explain this code: $(cat main.py)" | docker run --rm -i \
  -e ANTHROPIC_API_KEY \
  -v $(pwd):/workspace \
  ghcr.io/jyje/claude-docker \
  bash -c 'mkdir -p ~/.claude && echo "{\"apiKeyHelper\": \"printf %s \\\"$ANTHROPIC_API_KEY\\\"\"}" > ~/.claude/settings.json && claude'
```

最小限の自動化テンプレートとして [test.sh](../test.sh) を使えます。

---


---

## 前提条件

### API キーの設定

ヘッドレス環境では、API キー helper を設定して OAuth ログインを回避します。

```bash
mkdir -p ~/.claude
cat > ~/.claude/settings.json <<'JSON'
{
  "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
}
JSON
```

カスタムイメージに組み込むことも、実行時に設定することもできます。

---


---

## レベル 1：CI/CD 連携

最もシンプルな連携です。既存のパイプラインに Claude を追加します。

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


---

## レベル 2：Kubernetes Job

### 単発のコード分析 Job

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
          # Setup API key helper
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          # Navigate to code
          cd /workspace/repo
          
          # Run analysis with Claude
          claude "Analyze this codebase and provide a summary of its architecture and key components" \
            > /workspace/analysis-report.txt
          
          # Output results
          echo "=== Analysis Complete ==="
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

### 結果の保存に PVC を使う Job

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
          
          echo "Report saved to: $REPORT_FILE"
        
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

## レベル 2：Kubernetes CronJob

### 定期的なコード分析

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: claude-daily-analysis
spec:
  schedule: "0 2 * * *"  # Run at 2 AM daily
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
              
              # Optional: Upload to S3, send to Slack, etc.
              echo "Analysis complete for ${DATE}"
            
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

## レベル 3：Argo Workflows

### シンプルな Workflow テンプレート

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
        # Setup API key helper
        mkdir -p /home/node/.claude
        cp /claude-config/settings.json /home/node/.claude/settings.json
        
        # Clone repository
        cd /workspace
        git clone {{inputs.parameters.repository}} repo
        cd repo
        
        # Run Claude Code analysis
        claude "{{inputs.parameters.prompt}}" > /workspace/analysis-report.txt
        
        # Output results
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

### DAG を使った複数ステップの Workflow

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
        echo "=== Consolidated Code Review Report ===" | cat - /workspace/final-report.txt > temp && mv temp /workspace/final-report.txt
    
    outputs:
      artifacts:
      - name: final-report
        path: /workspace/final-report.txt
```


---

## レベル 4：リアルタイムログ分析

### ログ分析サイドカー

Claude をサイドカーコンテナとして使い、アプリケーションのログをリアルタイムで監視して異常を検出します。

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
      # Main application
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
          # Application writes logs to /var/log/app/app.log
          while true; do
            echo "[$(date)] INFO: Processing request..." >> /var/log/app/app.log
            sleep 5
          done
      
      # Claude log analyzer sidecar
      - name: log-analyzer
        image: ghcr.io/jyje/claude-docker:latest
        command: ["/bin/bash", "-c"]
        args:
        - |
          # Setup API key helper
          mkdir -p /home/node/.claude
          cp /claude-config/settings.json /home/node/.claude/settings.json
          
          # Wait for log file to be created
          while [ ! -f /var/log/app/app.log ]; do
            echo "Waiting for log file..."
            sleep 2
          done
          
          echo "Starting real-time log analysis..."
          
          # Tail logs and analyze in batches
          tail -f /var/log/app/app.log | while IFS= read -r line; do
            echo "$line" >> /tmp/log-buffer.txt
            
            # Analyze every 50 lines
            if [ $(wc -l < /tmp/log-buffer.txt) -ge 50 ]; then
              echo "Analyzing batch of logs..."
              
              ANALYSIS=$(claude "Analyze these application logs and identify any errors, warnings, or anomalies. Provide a brief summary: $(cat /tmp/log-buffer.txt)")
              
              # Output analysis
              echo "=== Log Analysis $(date) ==="
              echo "$ANALYSIS"
              echo "=============================="
              
              # Clear buffer
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

### 時間ベースのログ分析サイドカー

行数ではなく、一定の時間間隔でログを分析します。

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
          ANALYSIS_INTERVAL=300  # 5 minutes
          
          echo "Starting periodic log analysis (every ${ANALYSIS_INTERVAL}s)..."
          
          while true; do
            if [ -f "$LOG_FILE" ]; then
              # Get logs from last N minutes
              RECENT_LOGS=$(tail -n 1000 "$LOG_FILE")
              
              if [ -n "$RECENT_LOGS" ]; then
                TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
                
                echo "[$TIMESTAMP] Analyzing recent logs..."
                
                ANALYSIS=$(claude "Analyze these application logs from the last 5 minutes. Identify critical issues, errors, and provide actionable insights: $RECENT_LOGS")
                
                echo "=== Log Analysis: $TIMESTAMP ==="
                echo "$ANALYSIS"
                echo "================================="
                
                # Optional: Send alerts if critical issues found
                if echo "$ANALYSIS" | grep -qi "critical\|error\|failure"; then
                  echo "⚠️ Critical issues detected! Sending alert..."
                  # Add alerting logic here (Slack, PagerDuty, etc.)
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

### Fluentd/Fluent Bit による集中ログ分析

ログ集約システムが収集したログを分析します。

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
    # Read JSON log from stdin
    LOG_ENTRY=$(cat)
    
    # Analyze with Claude every N logs (implement batching)
    echo "$LOG_ENTRY" >> /tmp/log-batch.txt
    
    if [ $(wc -l < /tmp/log-batch.txt) -ge 100 ]; then
      export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
      
      mkdir -p ~/.claude
      echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
      
      ANALYSIS=$(claude "Analyze these Kubernetes logs and identify any issues: $(cat /tmp/log-batch.txt)")
      
      echo "$ANALYSIS" > /tmp/analysis-$(date +%s).txt
      > /tmp/log-batch.txt
    fi
    
    # Pass through original log
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
          
          # Monitor analysis results and send alerts
          while true; do
            for file in /tmp/analysis-*.txt; do
              if [ -f "$file" ]; then
                cat "$file"
                # Send to monitoring/alerting system
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

### Kafka によるストリーム処理

Kafka のストリームからのログをリアルタイムで分析します。

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
          
          # Install kafka consumer (if not in base image)
          npm install -g kafkajs
          
          # Create Node.js consumer script
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
              `claude "Analyze these logs and identify anomalies: ${logsText}"`
            );
            console.log('=== Analysis Result ===');
            console.log(stdout);
            console.log('=======================');
          }
          
          const run = async () => {
            await consumer.connect();
            await consumer.subscribe({ topic: 'application-logs', fromBeginning: false });
            
            await consumer.run({
              eachMessage: async ({ topic, partition, message }) => {
                const log = message.value.toString();
                console.log(`Received log: ${log}`);
                
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
          
          # Run consumer
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

### アラート連携の例

ログを分析し、Claude の分析結果に基づいてアラートを発火します。

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
                # Analyze logs
                ANALYSIS=$(claude "Analyze these logs. Rate the severity (LOW/MEDIUM/HIGH/CRITICAL) and explain any issues: $RECENT_LOGS")
                
                echo "Analysis: $ANALYSIS"
                
                # Check severity and send alerts
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
                
                # Send to Slack
                if [ "$SEVERITY" != "low" ]; then
                  curl -X POST "$SLACK_WEBHOOK_URL" \
                    -H 'Content-Type: application/json' \
                    -d "{
                      \"attachments\": [{
                        \"color\": \"$COLOR\",
                        \"title\": \"$EMOJI Log Analysis Alert - $SEVERITY\",
                        \"text\": \"$ANALYSIS\",
                        \"footer\": \"Claude Log Analyzer\",
                        \"ts\": $(date +%s)
                      }]
                    }"
                  
                  echo "Alert sent for $SEVERITY severity"
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


---

## レベル 4：高度なパターン

### 複数のプロンプトによる並列分析

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
          
          # Determine which analysis to run based on JOB_COMPLETION_INDEX
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
          echo "Completed: $OUTPUT"
        
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

### 通知システムとの連携

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
          
          # Run analysis
          REPORT=$(claude "Analyze recent changes and summarize findings")
          
          # Send to Slack
          curl -X POST "$SLACK_WEBHOOK_URL" \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"Claude Code Analysis Complete\",\"blocks\":[{\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$REPORT\"}}]}"
          
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

## ベストプラクティス

1. **API キーの管理**
   - API キーには必ず Kubernetes Secret を使う
   - YAML ファイルに認証情報を直接書き込まない
   - 外部のシークレット管理（Vault、AWS Secrets Manager）の利用を検討する

2. **リソース制限**
   - 適切なメモリ（512Mi-1Gi）と CPU（250m-500m）の制限を設定する
   - 実際の使用量を監視し、それに応じて調整する

3. **エラー処理**
   - 一時的なエラーには `restartPolicy: OnFailure` を使う
   - スクリプトにリトライ処理を実装する
   - デバッグのために、出力を永続ストレージに記録する

4. **出力の管理**
   - 結果を永続化するには、Argo Workflows のアーティファクトを使う
   - レポートは PVC や外部ストレージ（S3、GCS）に保存する
   - 出力を保存する際は、サイズの上限を考慮する

5. **パフォーマンス**
   - 重い処理（git clone など）には init コンテナを使う
   - 独立した分析は並列で実行する
   - 可能ならリポジトリをキャッシュする


---

## トラブルシューティング

### よくある問題

**問題**：ヘッドレス環境で OAuth ログインのプロンプトが表示される
```bash
# Solution: Ensure API key helper is properly configured
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

**問題**：Permission denied（権限拒否）エラーが発生する
```bash
# Solution: Ensure proper user and file permissions
chown -R node:node /workspace /home/node/.claude
```

**問題**：タイムアウトエラーが発生する
```bash
# Solution: Increase timeout and add retry logic
timeout 300 claude "your prompt" || echo "Timeout or error occurred"
```


---

## 参考資料

- [クイックスタートガイド](getting-started-ja.md)
- [Argo Workflows のドキュメント](https://argoproj.github.io/workflows/)
- [Kubernetes Job のドキュメント](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Claude Code 公式ドキュメント](https://code.claude.com/docs)
