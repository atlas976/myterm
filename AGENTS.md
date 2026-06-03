# Codex Instructions for myterm

## Repository Scope

This repository is a personal dotfiles and bootstrap environment for terminal-first development on macOS and Linux. Keep changes focused on configuration files, setup scripts, documentation, and Codex workflow files.

## Platform Boundaries

- Keep macOS and Linux setup separate.
- AeroSpace and Karabiner are macOS-only.
- i3 is Linux-only.
- Do not replace package managers, shells, terminal apps, window managers, or editor foundations without explicit user approval.

## Verification

- For shell script changes, run `bash -n` and `shellcheck` when available.
- For Karabiner JSON changes, run `jq empty`.
- For Neovim Lua changes, run `luac -p nvim/init.lua` when available.
- For AeroSpace TOML changes, parse `aerospace/aerospace.toml` with a TOML parser when available.
- Before committing, run `codex/scripts/safe_commit.sh`.
