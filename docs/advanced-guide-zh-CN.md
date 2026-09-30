<!-- Translated from docs/advanced-guide.md at 4892c7a -->
# 进阶指南

按难度排序的 Claude Docker 流水线集成指南。

> [!NOTE]
> 本译文由 AI 辅助完成，尚未经过母语者审校，欢迎通过 PR 提出修改。代码块中的内容（包括注释）保持英文原样。如与英文版有出入，以英文版 [advanced-guide.md](advanced-guide.md) 为准。


---

## 目录

- [无头模式用法](#无头模式用法) ← 从这里开始
- [前置条件](#前置条件)
- [第 1 级：CI/CD 集成](#第-1-级cicd-集成)
- [第 2 级：Kubernetes Job](#第-2-级kubernetes-job)
- [第 3 级：Argo Workflows](#第-3-级argo-workflows)
- [第 4 级：实时日志分析](#第-4-级实时日志分析)
- [第 4 级：高级模式](#第-4-级高级模式)
- [最佳实践](#最佳实践)
- [故障排查](#故障排查)

---


---

## 无头模式用法

**无头（Headless）**指不经过交互式登录来运行 Claude Code，只使用 API 密钥，非常适合流水线、CI/CD 和自动化场景。

### 概念

1. 将 `ANTHROPIC_API_KEY` 设置为环境变量
2. 在 `~/.claude/settings.json` 中配置 `apiKeyHelper` 来读取密钥
3. Claude 绕过 OAuth，以非交互方式运行

### 基础 Docker 示例

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

最小化的自动化模板请参阅 [test.sh](../test.sh)。

---


---

## 前置条件

### API 密钥配置

在无头环境中，配置 API 密钥 helper 以绕过 OAuth 登录：

```bash
mkdir -p ~/.claude
cat > ~/.claude/settings.json <<'JSON'
{
  "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
}
JSON
```

可以把它内置到你的自定义镜像中，也可以在运行时配置。

---


---

## 第 1 级：CI/CD 集成

最简单的集成方式：把 Claude 加入现有的流水线。

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

## 第 2 级：Kubernetes Job

### 一次性代码分析 Job

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

### 使用 PVC 存储结果的 Job

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

## 第 2 级：Kubernetes CronJob

### 定时代码分析

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

## 第 3 级：Argo Workflows

### 简单的 Workflow 模板

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

### 使用 DAG 的多步骤 Workflow

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

## 第 4 级：实时日志分析

### 日志分析 Sidecar

把 Claude 作为 sidecar 容器，实时监控应用日志并检测异常。

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

### 基于时间的日志分析 Sidecar

按固定时间间隔分析日志，而不是按行数：

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

### 使用 Fluentd/Fluent Bit 的集中式日志分析

分析由日志聚合系统收集的日志：

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

### 使用 Kafka 的流处理

实时分析来自 Kafka 流的日志：

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

### 告警集成示例

分析日志，并根据 Claude 的分析结果触发告警：

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

## 第 4 级：高级模式

### 使用多个提示词并行分析

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

### 与通知系统集成

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

## 最佳实践

1. **API 密钥管理**
   - 始终使用 Kubernetes Secret 存放 API 密钥
   - 切勿把凭据硬编码到 YAML 文件中
   - 考虑使用外部密钥管理方案（Vault、AWS Secrets Manager）

2. **资源限制**
   - 设置合适的内存（512Mi-1Gi）和 CPU（250m-500m）限制
   - 监控实际用量并相应调整

3. **错误处理**
   - 对瞬时性错误使用 `restartPolicy: OnFailure`
   - 在脚本中实现重试逻辑
   - 把输出写入持久化存储，便于调试

4. **输出管理**
   - 在 Argo Workflows 中使用 artifact 来持久化结果
   - 把报告存放到 PVC 或外部存储（S3、GCS）
   - 存储输出时注意大小限制

5. **性能**
   - 对耗时较重的操作（如 git clone）使用 init container
   - 并行运行相互独立的分析
   - 尽可能缓存代码仓库


---

## 故障排查

### 常见问题

**问题**：无头环境中出现 OAuth 登录提示
```bash
# Solution: Ensure API key helper is properly configured
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

**问题**：出现 Permission denied（权限被拒绝）错误
```bash
# Solution: Ensure proper user and file permissions
chown -R node:node /workspace /home/node/.claude
```

**问题**：出现超时错误
```bash
# Solution: Increase timeout and add retry logic
timeout 300 claude "your prompt" || echo "Timeout or error occurred"
```


---

## 参考资料

- [快速开始指南](getting-started-zh-CN.md)
- [Argo Workflows 文档](https://argoproj.github.io/workflows/)
- [Kubernetes Job 文档](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Claude Code 官方文档](https://code.claude.com/docs)
