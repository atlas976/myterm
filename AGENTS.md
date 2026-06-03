# Codex Instructions for myterm

## Repository Scope

This repository is a personal dotfiles and bootstrap environment for terminal-first development on macOS and Linux. Keep changes focused on configuration files, setup scripts, documentation, and Codex workflow files.

## Working Rules

- Write code, comments, commit messages, and technical documentation in English.
- Do not read, print, stage, or modify `zsh/.secrets`, `~/.secrets`, `.env*`, private keys, or ignored secret files.
- Do not run `git push`.
- Use the existing toolchain and conventions. Do not replace package managers, shells, terminal apps, window managers, or editor foundations without explicit user approval.
- Treat macOS and Linux setup separately: AeroSpace and Karabiner are macOS-only; i3 is Linux-only.

## Verification

- For shell script changes, run `bash -n` and `shellcheck` when available.
- For Karabiner JSON changes, run `jq empty`.
- For Neovim Lua changes, run `luac -p nvim/init.lua` when available.
- For AeroSpace TOML changes, parse `aerospace/aerospace.toml` with a TOML parser when available.
- Before committing, run `codex/scripts/safe_commit.sh`.

## Git Hygiene

- Preserve user changes already present in the worktree.
- Stage only files related to the requested task.
- Commit only when the user explicitly asks for a commit.
