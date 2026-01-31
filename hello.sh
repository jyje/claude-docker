#!/bin/bash

echo "=================================================="
echo "🤖 jyje/claude-docker: Community Claude Code Image"
echo ""
echo "Welcome to the Claude Code community image! This is a community-maintained"
echo "project that provides a Docker image for Claude Code users. Based on the"
echo "official Anthropic devcontainer configuration."
echo ""
echo "📚 For more information:"
echo "  - This project: https://github.com/jyje/claude-docker"
echo "  - Official docs: https://docs.anthropic.com/en/docs/claude-code"
echo "  - NPM package: https://www.npmjs.com/package/@anthropic-ai/claude-code"
echo "=================================================="
echo ""

echo "🛠️  Pre-installed tools:"
echo "=================================================="
echo "  - git, git-delta (diff viewer)"
echo "  - zsh + powerline10k theme"
echo "  - fzf (fuzzy finder)"
echo "  - gh (GitHub CLI)"
echo "  - jq, curl, wget, vim, nano"
echo "  - iptables, ipset (for network sandbox)"
echo "=================================================="
echo ""

echo "ℹ️  Installed Claude Code version:"
echo "=================================================="
claude --version
echo "=================================================="
echo ""

echo "🔑 Environment variables:"
echo "=================================================="
if [ -n "$ANTHROPIC_API_KEY" ]; then
  echo "  ANTHROPIC_API_KEY: (set)"
else
  echo "  ANTHROPIC_API_KEY: (not set) - Required for Claude Code"
fi
if [ -n "$ANTHROPIC_BASE_URL" ]; then
  echo "  ANTHROPIC_BASE_URL: $ANTHROPIC_BASE_URL"
else
  echo "  ANTHROPIC_BASE_URL: (not set) - Using default Anthropic API"
fi
echo "=================================================="
echo ""

echo "💡 Suggested commands:"
echo "=================================================="
echo "  - claude          : Start Claude Code interactive session"
echo "  - claude --help   : Show Claude Code help"
echo "  - sudo /usr/local/bin/init-firewall.sh : Enable network sandbox"
echo "=================================================="
echo ""

# If arguments are passed, execute them
# Otherwise, start an interactive shell
if [ $# -gt 0 ]; then
  exec "$@"
else
  exec zsh
fi
