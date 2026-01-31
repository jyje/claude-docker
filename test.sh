#!/bin/bash
# Minimal headless CLI automation template for Docker pipelines
# Usage: ./test-docker.sh [prompt] [output-file]

set -e

# Configuration
PROMPT="${1:-Hello Claude, respond with just 'OK' to confirm you are working.}"
OUTPUT_FILE="${2:-./test-output.txt}"
LOG_FILE="./test-docker.log"
IMAGE="${CLAUDE_DOCKER_IMAGE:-ghcr.io/jyje/claude-docker:latest}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Step 1: Load API key
log "Loading API key..."
if [ -f "./api-key" ]; then
    export ANTHROPIC_API_KEY=$(cat ./api-key)
elif [ -n "$ANTHROPIC_API_KEY" ]; then
    log "Using API key from environment"
else
    echo -e "${RED}Error: No API key found${NC}"
    echo "Please provide API key via:"
    echo "  1. ./api-key file, or"
    echo "  2. ANTHROPIC_API_KEY environment variable"
    exit 1
fi

# Step 2: Run Claude Code in Docker
log "Running Claude Code in Docker..."
log "Image: $IMAGE"
log "Prompt: $PROMPT"

docker run --rm \
    -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    -v "$(pwd):/workspace" \
    "$IMAGE" \
    bash -c "
        # Setup headless configuration
        mkdir -p ~/.claude
        cat > ~/.claude/settings.json <<'EOF'
{
  \"apiKeyHelper\": \"printf %s \\\"\\\$ANTHROPIC_API_KEY\\\"\"
}
EOF
        
        # Run Claude Code
        cd /workspace
        claude \"$PROMPT\" > \"$OUTPUT_FILE\" 2>&1
        echo \"Exit code: \$?\"
    " 2>&1 | tee -a "$LOG_FILE"

# Step 3: Check results
if [ -f "$OUTPUT_FILE" ]; then
    log "✓ Claude Code executed successfully"
    
    # Display output
    echo -e "${GREEN}Output:${NC}"
    cat "$OUTPUT_FILE"
    echo ""
    
    log "Output saved to: $OUTPUT_FILE"
    log "Log saved to: $LOG_FILE"
    
    exit 0
else
    echo -e "${RED}✗ Claude Code execution failed${NC}"
    echo "Check log file: $LOG_FILE"
    exit 1
fi
