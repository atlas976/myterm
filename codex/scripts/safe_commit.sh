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
    SECRET_PATTERN='(^|[^[:alnum:]_])((api[_-]?key|password|secret|token|client[_-]?secret|access[_-]?token|refresh[_-]?token)[[:space:]]*=|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9_]{36,}|-----BEGIN [A-Z ]*PRIVATE KEY-----)'
    MATCHING_LOCATIONS=()
    while IFS=: read -r file line _; do
        MATCHING_LOCATIONS+=("$file:$line")
    done < <(git grep --cached -n -I -E "$SECRET_PATTERN" -- "${STAGED_FILES[@]}" || true)

    if [ "${#MATCHING_LOCATIONS[@]}" -gt 0 ]; then
        echo "ERROR: Potential credentials found in staged files. Commit blocked."
        printf '  %s [content redacted]\n' "${MATCHING_LOCATIONS[@]}"
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
