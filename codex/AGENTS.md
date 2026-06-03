# Global Codex Guidance

## Communication and Code

- Write code, comments, commits, and technical documentation in English.
- Be direct and pragmatic. Prefer concise implementation notes over broad explanations.
- Follow the active repository's `AGENTS.md` and closer nested instructions.

## Security

- Never read, print, stage, or modify `.env*`, `~/.secrets`, SSH keys, private keys, or ignored secret files.
- Do not run `git push`.
- Ask for approval before destructive actions, broad filesystem changes, network installs, or commands that require elevated permissions.

## Workflow

- Inspect the repository before editing.
- Prefer existing project patterns over new abstractions.
- Run relevant checks before handoff.
- Before committing, use `~/.codex/scripts/safe_commit.sh` when it exists.
