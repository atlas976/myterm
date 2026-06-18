# myterm

Personal dotfiles for a terminal-first development setup on macOS Apple Silicon and Ubuntu-style Linux.

## Stack

| Area | Tooling |
| --- | --- |
| Terminal | Ghostty |
| Shell | Zsh, Powerlevel10k, fzf |
| Editor | Neovim with Telescope, nvim-tree, LSP, and completion |
| macOS window manager | AeroSpace |
| Linux window manager | i3 |
| macOS keyboard remapping | Karabiner-Elements |
| Agent setup | Codex `AGENTS.md`, `.agents/skills`, and safe commit helper |
| Theme | Gruvbox Dark |

To list available Ghostty themes:

```bash
ghostty +list-themes
```

## What Setup Does

The setup scripts install packages, create config directories, back up existing regular config files with a `.backup` suffix, and link or copy this repo's configs into place. Neovim links both `nvim/init.lua` and the modular `nvim/lua` config directory.

Karabiner config is copied instead of symlinked because Karabiner-Elements can replace symlinks while reloading. If you change `karabiner/karabiner.json`, rerun `./setup.sh`.

Codex setup:
- links `codex/AGENTS.md` to `~/.codex/AGENTS.md`
- links `codex/scripts/safe_commit.sh` to `~/.codex/scripts/safe_commit.sh`
- links `.agents/skills/*` into `~/.agents/skills`

Secrets:
- setup creates `~/.secrets` from `zsh/.secrets.example` on fresh machines
- setup sets `chmod 600 ~/.secrets`
- existing `~/.secrets` files or unrelated symlinks are left untouched
- old `~/.secrets` symlinks to this repo's ignored `zsh/.secrets` are migrated into a real home file

The safe commit helper blocks ignored files, common credential assignments, private key blocks, AWS access key IDs, and common GitHub token prefixes in staged content. It is a guardrail, not a complete secrets scanner.

## Install

Clone the repo anywhere. The scripts resolve paths relative to their own location.

### macOS Apple Silicon

```bash
git clone https://github.com/lukasfuchs/myterm.git && cd myterm
chmod +x setup.sh
./setup.sh
```

### Ubuntu/Linux

```bash
git clone https://github.com/lukasfuchs/myterm.git && cd myterm
chmod +x setup_linux.sh
./setup_linux.sh
```

The Linux script is written for Ubuntu-style systems with `apt` and PPAs.

## Manual macOS Steps

### AeroSpace

- Reset Accessibility permissions if AeroSpace commands stop working: System Settings > Privacy & Security > Accessibility, remove AeroSpace, then add it again.
- Turn off Stage Manager. It conflicts with tiling and workspace management.
- Enable "Displays have separate Spaces" in System Settings > Desktop & Dock.

### Karabiner-Elements

During `./setup.sh`, Homebrew may ask for your password because Karabiner installs a virtual keyboard driver.

After installation:
- open Karabiner-Elements once
- approve the macOS System Extension prompt
- approve Input Monitoring permissions

You do not need to open Karabiner manually after every restart.

## Repository Layout

```text
~/myterm/
├── AGENTS.md                 # Codex instructions for this repository
├── .agents/
│   └── skills/               # Codex skills
├── aerospace/
│   └── aerospace.toml        # AeroSpace config for macOS
├── codex/
│   ├── AGENTS.md             # Global Codex guidance linked to ~/.codex/AGENTS.md
│   └── scripts/              # Codex helper scripts
├── ghostty/
│   └── config                # Ghostty config
├── i3/
│   └── config                # i3 config for Linux
├── nvim/
│   ├── init.lua              # Neovim entry point
│   ├── BEGINNER_TUTORIAL.md  # Neovim help references
│   └── lua/myterm/           # Neovim config modules
├── zsh/
│   ├── .zshrc                # Zsh config
│   ├── .p10k.zsh             # Powerlevel10k config
│   └── .secrets.example      # Template for ~/.secrets
├── setup.sh                  # macOS bootstrap
└── setup_linux.sh            # Ubuntu/Linux bootstrap
```

## Workspace Rules

macOS uses AeroSpace. Ubuntu/Linux uses i3. The workspace model is kept similar across both.

| Workspace | Purpose |
| --- | --- |
| 1 | Vivaldi |
| 2 | Communication apps where app classes match |
| 3 | Ghostty |
| 4 | Spotify |
| 5 | macOS catch-all; manual/general workspace on Linux |

AeroSpace has a macOS catch-all rule. i3 routes only the known app classes listed in `i3/config`; unknown apps stay where they open.

## Shortcuts

### Neovim

1. `\` - Toggle the file tree sidebar.
2. `<Space>sf` - Find files with Telescope.
3. `<Space>sg` - Live grep with Telescope.
4. `<Space><Space>` - Switch buffers with Telescope.
5. `<Space>f` - Format the current buffer.
6. `<Tab>` - Accept the selected completion item.
7. `<Ctrl-j>` / `<Ctrl-k>` - Select the next or previous completion item.

### AeroSpace

Caps Lock is mapped by Karabiner to `cmd` + `alt` + `ctrl` when held and Escape when tapped.

1. `cmd` + `alt` + `ctrl` + `1-9` - Switch workspace.
2. `cmd` + `alt` + `ctrl` + `shift` + `1-9` - Move window to workspace.
3. `cmd` + `alt` + `ctrl` + `h/j/k/l` - Focus left/down/up/right.
4. `cmd` + `alt` + `ctrl` + `shift` + `h/j/k/l` - Move window left/down/up/right.
5. `cmd` + `alt` + `ctrl` + `f` - Toggle fullscreen.
6. `cmd` + `alt` + `ctrl` + `shift` + `space` - Toggle floating/tiling.
7. `cmd` + `alt` + `ctrl` + `,` - Toggle accordion layout.

### i3

1. `Super` + `1-9` - Switch workspace.
2. `Super` + `shift` + `1-9` - Move window to workspace.
3. `Super` + `h/j/k/l` - Focus left/down/up/right.
4. `Super` + `shift` + `h/j/k/l` - Move window left/down/up/right.
5. `Super` + `f` - Toggle fullscreen.
6. `Super` + `shift` + `space` - Toggle floating/tiling.
7. `Super` + `,` - Use tabbed layout.
8. `Super` + `Enter` - Open Ghostty.

## TODO

1. Configure the Codex UI through a symlinked `codex.toml`.
2. Configure a custom terminal command for Copilot activation.
