# myterm

Personal dotfiles for a terminal-first development setup on macOS Apple Silicon, Ubuntu, and headless 64-bit Raspberry Pi OS.

## Stack

| Area | Tooling |
| --- | --- |
| Terminal | Ghostty |
| Shell | Zsh, Powerlevel10k, fzf |
| Editor | Neovim with Telescope, nvim-tree, LSP, completion, and optional Copilot |
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

The setup script installs packages, creates config directories, backs up existing regular config files with a `.backup` suffix, and links or copies this repo's configs into place. Neovim links both `nvim/init.lua` and the modular `nvim/lua` config directory.

Karabiner config is copied instead of symlinked because Karabiner-Elements can replace symlinks while reloading. If you change `karabiner/karabiner.json`, rerun `./setup.sh`.

Setup flags:
- `--dry-run` prints the actions without installing packages, changing files, or changing the default shell
- `--no-shell-change` skips the default shell change
- `--profile auto|desktop|server|headless|raspberrypi` overrides automatic profile detection
- `--headless` is a compatibility alias for `--profile server` on Ubuntu

Package setup:
- detects macOS or Linux automatically
- supports Ubuntu desktop and Ubuntu Server on x86_64 or arm64, plus headless Raspberry Pi OS on arm64
- rejects unsupported Linux distributions, package managers, architectures, and graphical Raspberry Pi systems before package installation
- detects graphical Ubuntu sessions and selects `ubuntu-desktop`; otherwise it selects `ubuntu-server`
- detects Raspberry Pi hardware and selects `raspberrypi-headless`
- reads package mappings from `packages.tsv`
- parses the package manifest directly in Bash, so a fresh minimal machine does not need Python just to start setup
- keeps Homebrew casks explicit, so casks are selected only for macOS
- skips GUI packages such as Ghostty and i3 on Ubuntu Server and Raspberry Pi
- uses an existing Node.js 22+ installation with working npm on Linux; otherwise installs checksum-verified Node.js `v22.23.1` locally
- uses an existing Neovim 0.11+ installation on Linux; otherwise installs checksum-verified Neovim `v0.12.4` locally
- installs fresh Powerlevel10k only through setup at a verified commit while leaving existing installations untouched; Zsh startup only loads it when present
- backs up any existing unmanaged `~/.p10k.zsh` file or symlink before activating this repo's Powerlevel10k configuration
- captures command diagnostics in `~/.cache/myterm/setup.log` and writes running, failure, and completion state to `~/.cache/myterm/setup-state`

The package manifest has seven TSV fields: ID, profiles, command checks, Homebrew formula, Homebrew cask, apt package, and npm global package. Use `-` for an empty field and commas for multiple values.

Setup validates its platform, manifest, architecture, and required source files before installing packages. Package-manager changes are not rolled back automatically; failures include the command, exit code, log, state file, and rerun guidance.

Codex setup:
- copies `codex/config.toml` to `~/.codex/config.toml`
- links `codex/AGENTS.md` to `~/.codex/AGENTS.md`
- links `codex/scripts/safe_commit.sh` to `~/.codex/scripts/safe_commit.sh`
- links `.agents/skills/*` into `~/.agents/skills`
- enables Codex UI and app capabilities by default, including live web search, goals, apps/connectors, plugins, in-app browser and browser use, Computer Use, image generation, memories, multi-agent workflows, tool suggestions, notifications, animations, and automatic approval review
- keeps Codex sandboxing at `workspace-write`; shell network access remains off by default, while the Codex web search tool uses `web_search = "live"`
- Browser, Computer Use, connectors, and plugins may still require one-time app installation, sign-in, or OS permissions inside Codex

Copilot setup:
- the optional Copilot toggle is controlled inside Neovim with `:mycp enable|disable|toggle|status`
- stores Copilot on/off state outside the repo at `~/.config/myterm/copilot-enabled`

Neovim plugin versions:
- lazy.nvim writes plugin pins to `nvim/lazy-lock.json`
- after intentional plugin updates with `:Lazy update`, commit the lockfile if Neovim still works as expected
- on a fresh machine, use `:Lazy restore` to install the locked plugin revisions

Secrets:
- setup creates `~/.secrets` from `zsh/.secrets.example` on fresh machines
- setup sets `chmod 600 ~/.secrets`
- existing `~/.secrets` files or unrelated symlinks are left untouched
- old `~/.secrets` symlinks to this repo's ignored `zsh/.secrets` are migrated into a real home file

The safe commit helper blocks ignored files, common credential assignments, private key blocks, AWS access key IDs, and common GitHub token prefixes in staged content. Detected content is redacted; only file and line locations are printed. It is a guardrail, not a complete secrets scanner.

## Install

Clone the repo anywhere. The scripts resolve paths relative to their own location.

### macOS Apple Silicon

```bash
git clone https://github.com/atlas976/myterm.git && cd myterm
chmod +x setup.sh
./setup.sh
```

### Ubuntu Desktop

```bash
git clone https://github.com/atlas976/myterm.git && cd myterm
chmod +x setup.sh
./setup.sh
```

Ubuntu desktop setup adds the Ghostty Ubuntu PPA before installing packages. It installs i3, dmenu, i3status, checksum-verified Node.js `v22.23.1`, the Nerd Fonts `v3.4.0` Meslo archive, and desktop configuration.

### Ubuntu Server

```bash
git clone https://github.com/atlas976/myterm.git && cd myterm
./setup.sh --profile server
```

Ubuntu Server installs CLI packages plus checksum-verified Node.js and Neovim releases, then links Zsh, Neovim, Codex, skills, and secrets configuration. It does not add desktop repositories or install Ghostty, i3, fonts, or desktop configs. `--profile headless` and `--headless` select the same Ubuntu Server path.

### Raspberry Pi OS

Use a headless 64-bit Raspberry Pi OS installation:

```bash
git clone https://github.com/atlas976/myterm.git && cd myterm
./setup.sh --profile raspberrypi
```

Raspberry Pi setup supports arm64 without a graphical session. It uses apt packages plus the checksum-verified Neovim arm64 release and links CLI configuration only. Graphical and 32-bit Raspberry Pi installations are rejected explicitly.

Other Linux distributions and package managers are not supported. Setup exits before installation instead of guessing package mappings.

## Verification

The test suite runs real config installation into isolated temporary homes and validates symlinks, copied files, permissions, profile state, failure logs, and completion state for Ubuntu desktop, Ubuntu Server, and Raspberry Pi. Package installation orchestration is exercised with fake commands, so tests do not modify the host or use the network.

```bash
bash -n setup.sh scripts/*.sh tests/*.sh codex/scripts/*.sh
shellcheck setup.sh scripts/*.sh tests/*.sh codex/scripts/*.sh
bash tests/run_setup_tests.sh
```

The Neovim regression test executes the LSP configuration with stubbed plugin adapters and verifies that every custom server config is registered and enabled through the current Neovim API.

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
│   ├── config.toml           # Codex UI/app defaults copied to ~/.codex/config.toml
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
├── scripts/
│   ├── lib_setup.sh          # Shared setup module loader
│   ├── setup_args.sh         # Setup flags and user-facing header
│   ├── setup_assets.sh       # Pinned Linux runtimes, compatibility links, and fonts
│   ├── setup_codex.sh        # Codex config and skill linking
│   ├── setup_files.sh        # Directories, backups, symlinks, and copies
│   ├── setup_logging.sh      # Logging, command execution, and failure state
│   ├── setup_packages.sh     # TSV package planner and installers
│   ├── setup_platform.sh     # OS, package manager, and profile detection
│   ├── setup_secrets.sh      # ~/.secrets setup and migration
│   └── setup_shell.sh        # Default shell and shell plugin setup
├── tests/
│   └── run_setup_tests.sh    # Setup test harness
├── zsh/
│   ├── .zshrc                # Zsh config
│   ├── .p10k.zsh             # Powerlevel10k config
│   └── .secrets.example      # Template for ~/.secrets
├── packages.tsv              # Homebrew and apt package mappings by profile
└── setup.sh                  # Unified macOS/Linux bootstrap
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
8. `<Ctrl-l>` - Accept a Copilot inline suggestion when Copilot is enabled.
9. `<Ctrl-]>` - Dismiss the visible Copilot suggestion.

### Optional Copilot

The Copilot config is present but opt-in. Use the Neovim command to enable or disable it:

```vim
:mycp enable
:mycp disable
:mycp toggle
:mycp status
```

Neovim stores this internally as `:Mycp` because custom commands must start with an uppercase letter. Typing `:mycp ...` in the command line expands to `:Mycp ...`.

First-time use still requires Neovim authentication:

```vim
:Copilot auth
```

Copilot requires a GitHub Copilot plan or available free quota. The toggle state lives outside this repo at `~/.config/myterm/copilot-enabled`, so it cannot be committed by accident.

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

- Add proper skills for agents and refine them.
- Add disposable Ubuntu and Raspberry Pi VM install checks for release validation.
- Add a tmux config.
- Add a theme switch and build it more or less maintainable.
