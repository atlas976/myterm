#!/bin/bash
# OpenCode Skill: safe_commit.sh
# Description: Intercepts Git commits to ensure no secrets or .gitignore violations occur.

CWD=$(pwd)
echo "[OpenCode Skill] Analyzing staged files in $CWD for security violations..."

# 1. Check for basic API key patterns in staged files (using ripgrep)
STAGED_FILES=$(git diff --cached --name-only --diff-filter=d)
if [ -n "$STAGED_FILES" ]; then
    if echo "$STAGED_FILES" | xargs -I {} rg -i "api_key|password|secret|token" {}; then
        echo "🚨 ERROR: Potential secrets found in staged files! Commit blocked by OpenCode Sandbox."
        exit 1
    fi
fi

# 2. Ensure no ignored files are forcibly staged
IGNORED_STAGED=$(git ls-files --ignored --exclude-standard --cached)
if [ -n "$IGNORED_STAGED" ]; then
    echo "🚨 ERROR: .gitignore violation! You have staged ignored files:"
    echo "$IGNORED_STAGED"
    exit 1
fi

echo "✅ Security check passed. No secrets or .gitignore violations detected."
exit 0
