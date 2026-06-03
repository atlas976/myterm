# Global Codex Guidance

## Communication and Language

- Write all code, code comments, commit messages, and technical documentation in English.
- Be direct and pragmatic. Prefer concise implementation notes over broad explanations.
- Follow the active repository's `AGENTS.md` and closer nested instructions for project-specific rules.

## Security and Permissions

- Do not read, print, stage, or modify `.env*`, `~/.secrets`, SSH keys, private keys, or ignored secret files.
- `git push` is allowed only after explicit prior permission from the user.
- Ask for approval before destructive actions, broad filesystem changes, network installs, or commands that require elevated permissions.

## Workflow

- Inspect the repository before editing.
- Run relevant checks before handoff.
- Before committing, use `~/.codex/scripts/safe_commit.sh` when it exists.
