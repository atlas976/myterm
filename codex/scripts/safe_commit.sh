#!/bin/bash
# Codex helper: verify staged files before creating a commit.

set -euo pipefail

CWD=$(pwd)
echo "[Codex] Analyzing staged files in $CWD for security violations..."

STAGED_FILES=()
while IFS= read -r -d '' file; do
    STAGED_FILES+=("$file")
done < <(git diff --cached --name-only --diff-filter=d -z)

if [ "${#STAGED_FILES[@]}" -gt 0 ]; then
    SECRET_PATTERN='[[:alnum:]_]*(api[_-]?key|password|secret|token)[[:alnum:]_]*[[:space:]]*=|-----BEGIN [A-Z ]*PRIVATE KEY-----'
    if git grep --cached -n -I -E "$SECRET_PATTERN" -- "${STAGED_FILES[@]}"; then
        echo "ERROR: Potential credentials found in staged files. Commit blocked."
        exit 1
    fi
fi

IGNORED_STAGED=()
while IFS= read -r -d '' file; do
    IGNORED_STAGED+=("$file")
done < <(git ls-files --ignored --exclude-standard --cached -z)

if [ "${#IGNORED_STAGED[@]}" -gt 0 ]; then
    echo "ERROR: Ignored files are staged:"
    printf '  %s\n' "${IGNORED_STAGED[@]}"
    exit 1
fi

echo "Security check passed. No credentials or ignored files detected."
exit 0
