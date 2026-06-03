#!/bin/bash
# OpenCode Skill: safe_commit.sh
# Description: Intercepts Git commits to ensure no secrets or .gitignore violations occur.

set -euo pipefail

CWD=$(pwd)
echo "[OpenCode Skill] Analyzing staged files in $CWD for security violations..."

# 1. Check staged content, not the working tree, for common credential assignments.
STAGED_FILES=()
while IFS= read -r -d '' file; do
    STAGED_FILES+=("$file")
done < <(git diff --cached --name-only --diff-filter=d -z)
if [ "${#STAGED_FILES[@]}" -gt 0 ]; then
    SECRET_PATTERN='[[:alnum:]_]*(api[_-]?key|password|secret|token)[[:alnum:]_]*[[:space:]]*=|-----BEGIN [A-Z ]*PRIVATE KEY-----'
    if git grep --cached -n -I -E "$SECRET_PATTERN" -- "${STAGED_FILES[@]}"; then
        echo "🚨 ERROR: Potential credentials found in staged files! Commit blocked by OpenCode Sandbox."
        exit 1
    fi
fi

# 2. Ensure no ignored files are forcibly staged.
IGNORED_STAGED=()
while IFS= read -r -d '' file; do
    IGNORED_STAGED+=("$file")
done < <(git ls-files --ignored --exclude-standard --cached -z)
if [ "${#IGNORED_STAGED[@]}" -gt 0 ]; then
    echo "🚨 ERROR: .gitignore violation! You have staged ignored files:"
    printf '  %s\n' "${IGNORED_STAGED[@]}"
    exit 1
fi

echo "✅ Security check passed. No credentials or .gitignore violations detected."
exit 0
