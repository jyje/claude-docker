# Advanced Guide

Pipeline integration guide for Claude Docker, ordered by difficulty.


---

## Table of Contents

- [Headless Usage](#headless-usage) ← Start here
- [Prerequisites](#prerequisites)
- [Level 1: CI/CD Integration](#level-1-cicd-integration)
- [Level 2: Kubernetes Jobs](#level-2-kubernetes-jobs)
- [Level 3: Argo Workflows](#level-3-argo-workflows)
- [Level 4: Real-time Log Analysis](#level-4-real-time-log-analysis)
- [Level 4: Advanced Patterns](#level-4-advanced-patterns)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---


---

## Headless Usage

**Headless** means running Claude Code without interactive login—using API key only, ideal for pipelines, CI/CD, and automation.

### Concept

1. Set `ANTHROPIC_API_KEY` as environment variable
2. Configure `~/.claude/settings.json` with `apiKeyHelper` to read the key
3. Claude bypasses OAuth and runs non-interactively

### Basic Docker Example

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

Use [test.sh](../test.sh) for a minimal automation template.

---


---

## Prerequisites

### API Key Configuration

For headless environments, configure the API key helper to bypass OAuth login:

```bash
mkdir -p ~/.claude
cat > ~/.claude/settings.json <<'JSON'
{
  "apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""
}
JSON
```

This can be baked into your custom image or configured at runtime.

---


---

## Level 1: CI/CD Integration

Simplest integration—add Claude to existing pipelines.

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

## Level 2: Kubernetes Jobs

### One-time Code Analysis Job

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

### Job with PVC for Result Storage

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

## Level 2: Kubernetes CronJob

### Scheduled Code Analysis

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

## Level 3: Argo Workflows

### Simple Workflow Template

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

### Multi-Step Workflow with DAG

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

## Level 4: Real-time Log Analysis

### Log Analysis Sidecar

Monitor application logs in real-time and detect anomalies using Claude as a sidecar container.

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

### Time-based Log Analysis Sidecar

Analyze logs at regular intervals instead of by line count:

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

### Centralized Log Analysis with Fluentd/Fluent Bit

Analyze logs collected by log aggregation systems:

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

### Stream Processing with Kafka

Analyze logs from Kafka streams in real-time:

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

### Alert Integration Example

Analyze logs and trigger alerts based on Claude's analysis:

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

## Level 4: Advanced Patterns

### Parallel Analysis with Multiple Prompts

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

### Integration with Notification Systems

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

## Best Practices

1. **API Key Management**
   - Always use Kubernetes Secrets for API keys
   - Never hardcode credentials in YAML files
   - Consider using external secret management (Vault, AWS Secrets Manager)

2. **Resource Limits**
   - Set appropriate memory (512Mi-1Gi) and CPU (250m-500m) limits
   - Monitor actual usage and adjust accordingly

3. **Error Handling**
   - Use `restartPolicy: OnFailure` for transient errors
   - Implement retry logic in scripts
   - Log outputs to persistent storage for debugging

4. **Output Management**
   - Use artifacts in Argo Workflows for result persistence
   - Store reports in PVCs or external storage (S3, GCS)
   - Consider size limits when storing outputs

5. **Performance**
   - Use init containers for heavy operations (git clone)
   - Run independent analyses in parallel
   - Cache repositories when possible


---

## Troubleshooting

### Common Issues

**Issue**: OAuth login prompt in headless environment
```bash
# Solution: Ensure API key helper is properly configured
mkdir -p ~/.claude
echo '{"apiKeyHelper": "printf %s \"$ANTHROPIC_API_KEY\""}' > ~/.claude/settings.json
```

**Issue**: Permission denied errors
```bash
# Solution: Ensure proper user and file permissions
chown -R node:node /workspace /home/node/.claude
```

**Issue**: Timeout errors
```bash
# Solution: Increase timeout and add retry logic
timeout 300 claude "your prompt" || echo "Timeout or error occurred"
```


---

## References

- [Getting Started Guide](getting-started.md)
- [Argo Workflows Documentation](https://argoproj.github.io/workflows/)
- [Kubernetes Jobs Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Claude Code Official Documentation](https://docs.anthropic.com/en/docs/claude-code)
