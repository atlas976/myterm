# myterm - Personal Terminal Environment

Welcome to `myterm`, a meticulously crafted, blazingly fast, and keyboard-centric development environment for macOS (Apple Silicon). This is basically just a dotfile repo.

## 🧰 Current Stack
* **Terminal:** [Ghostty](https://ghostty.org/) (GPU-accelerated via Metal, zero input latency, native macOS feel).
* **Window Manager (macOS):** [AeroSpace](https://nikitabobko.github.io/AeroSpace/guide) (i3-inspired tiling window manager for macOS).
* **Window Manager (Linux):** [i3](https://i3wm.org/) (native tiling window manager with a similar keyboard-first workflow).
* **Keyboard Customizer (macOS):** Karabiner-Elements (Maps Caps Lock to Cmd+Ctrl+Alt / Escape).
* **Shell:** Zsh with Powerlevel10k (Extremely fast, Git-aware prompt).
* **Editor:** Neovim with [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) (A starting point for a fast, modern Lua-based IDE).
* **AI Agent:** Agnostic CLI Agent Configuration (e.g., Gemini CLI, Claude Code) with strict sandboxing.
* **Fuzzy Finder:** fzf (Instant command-line search for files and history via `Ctrl+T` / `Ctrl+R`).
* **Theme:** Gruvbox Dark (Warm, earthy tones, easy on the eyes). To see more themes run 
```bash 
ghostty +list-themes
```

## ⚠️ Important macOS Settings for AeroSpace

**Reset Accessibility Permissions (The #1 fix for dead commands):** macOS updates frequently corrupt or revoke these permissions silently. Go to System Settings > Privacy & Security > Accessibility. Don't just toggle AeroSpace off and on—select it, delete it using the minus (-) button, and then add the app back fresh.

**Turn Off Stage Manager:** Stage Manager fundamentally conflicts with AeroSpace. Stage Manager tries to group and hide windows off-screen, while AeroSpace tries to calculate and tile them across workspaces. If both are running, they will fight each other, resulting in broken window movements.

**Enable "Displays have separate Spaces":** If this setting is disabled, you will experience massive bugs with window movement, focus, and performance. Go to System Settings > Desktop & Dock and ensure this is toggled ON.

## ⚠️ Karabiner-Elements Installation Note
During the initial `./setup.sh` execution, **Homebrew will ask for your Mac password** in the terminal because Karabiner-Elements installs a virtual keyboard driver.
* After installation, you **must open the Karabiner-Elements app once**. macOS will prompt you to allow its System Extension and Input Monitoring permissions. You have to allow these for the Hyper Key to work.
* You do **not** need to open the app manually after restarting your Mac. Karabiner runs quietly in the background automatically as a system daemon.
* **Configuration Updates:** Because Karabiner-Elements breaks symlinks upon reloading, the `setup.sh` script copies (rather than symlinks) the `karabiner.json` file. If you make changes to the `karabiner.json` in this repository, you **must re-run `./setup.sh`** to apply them.

## 📂 Structure
**Note:** You have to enter the details in your `.secrets` file after running the setup script.

```text
~/myterm/
├── agent-coding/    # AI Assistant Brain and Rules (Gemini, Claude, etc.)
│   ├── GEMINI.md    # Agent personas and strict security rules
│   ├── .geminiignore # Firewall against reading sensitive data
│   └── skills/      # Modular tools and scripts (e.g., safe_commit.sh)
├── aerospace/
│   └── aerospace.toml # AeroSpace tiling window manager configuration
├── ghostty/
│   └── config       # Ghostty terminal configuration
├── i3/
│   └── config       # i3 tiling window manager configuration for Linux
├── nvim/
│   └── init.lua     # Neovim (Kickstart) configuration
├── zsh/
│   ├── .zshrc       # Zsh shell configuration
│   └── .p10k.zsh    # Powerlevel10k theme configuration
├── setup.sh         # The automated bootstrap script
└── README.md        # This documentation
```

## 🛠️ Installation on a New Machine
This setup is entirely portable. You can clone this repository to any location on your machine, and the setup scripts will automatically resolve the correct paths.

If you are not familiar with vim/neovim yet, then open the init.lua and follow the steps to learn the basics of vim.

### macOS (Apple Silicon)
```bash
# 1. Clone, navigate and make executable
git clone https://github.com/lukasfuchs/myterm.git && cd myterm
chmod +x setup.sh

# 2. Run the setup
./setup.sh
```

### Linux
```bash
# 1. Clone, navigate and make executable
git clone https://github.com/lukasfuchs/myterm.git && cd myterm
chmod +x setup_linux.sh

# 2. Run the setup
./setup_linux.sh
```

---

## 🧭 Window Rules
macOS uses AeroSpace. Linux uses i3 with equivalent workspace assignments where the Linux application class names are known.

The system organizes the main workspaces like this:
*   **Workspace 1:** **Vivaldi**
*   **Workspace 2:** **Communication Apps** (Outlook, Slack, Teams, Discord, WhatsApp where Linux app classes match)
*   **Workspace 3:** **Ghostty** (Floating across the whole window)
*   **Workspace 4:** **Spotify**
*   **Workspace 5:** General catch-all for other applications on macOS; manual/general workspace on Linux

## Shortcuts:

**Nvim Explorer:**

*File Management:*
1. `a` – Add: Erstellt eine neue Datei oder einen neuen Ordner (Tipp: Setze einen `/` ans Ende des Namens, um einen Ordner zu erstellen).
2. `r` – Rename: Benennt die Datei oder den Ordner unter dem Cursor um.
3. `d` – Delete: Löscht die ausgewählte Datei oder den Ordner (Bestätigung erforderlich).
4. `c` – Copy: Kopiert die Datei/den Ordner in die Zwischenablage des Explorers.
5. `x` – Cut: Schneidet die Datei/den Ordner aus.
6. `p` – Paste: Fügt die zuvor kopierte oder ausgeschnittene Datei an der aktuellen Position ein.
7. `y` – Yank: Kopiert den Dateinamen (oder absoluten Dateipfad) in die System-Zwischenablage.

*Opening Files:*
8. `<Enter>` / `o` – Open: Öffnet die Datei im Hauptfenster oder klappt einen Ordner auf/zu.
9. `v` – Vertical Split: Öffnet die Datei in einem neuen vertikalen Fenster (Split).
10. `s` – Split: Öffnet die Datei in einem neuen horizontalen Fenster (Split).
11. `t` – Tab: Öffnet die Datei in einem neuen Neovim-Tab.

*View and Navigation:*
12. `R` – Refresh: Lädt den Datei-Explorer neu.
13. `H` – Hidden: Blendet versteckte Dateien (Dotfiles wie `.gitignore` oder `.cache`) ein/aus.
14. `I` – Ignore: Blendet Dateien ein/aus, die in der `.gitignore` stehen (z.B. den `build/` Ordner).
15. `W` – Collapse All: Klappt alle geöffneten Ordner auf einmal zu.

**AeroSpace (macOS Window Manager):**
*(Note: Caps Lock is mapped to the Hyper key `cmd`+`alt`+`ctrl` via Karabiner-Elements)*

1. `cmd` + `alt` + `ctrl` + `1-9` – Switch to Workspace 1-9
2. `cmd` + `alt` + `ctrl` + `shift` + `1-9` – Move window to Workspace 1-9
3. `cmd` + `alt` + `ctrl` + `h/j/k/l` – Focus window (Left, Down, Up, Right)
4. `cmd` + `alt` + `ctrl` + `shift` + `h/j/k/l` – Move window (Left, Down, Up, Right)
5. `cmd` + `alt` + `ctrl` + `f` – Toggle Fullscreen
6. `cmd` + `alt` + `ctrl` + `shift` + `space` – Toggle floating / tiling layout
7. `cmd` + `alt` + `ctrl` + `,` – Toggle accordion layout

*Note: AeroSpace has a macOS catch-all rule. i3 routes the known app classes in `i3/config`, and unknown apps stay wherever they open.*

**i3 (Linux Window Manager):**

1. `Super` + `1-9` – Switch to Workspace 1-9
2. `Super` + `shift` + `1-9` – Move window to Workspace 1-9
3. `Super` + `h/j/k/l` – Focus window (Left, Down, Up, Right)
4. `Super` + `shift` + `h/j/k/l` – Move window (Left, Down, Up, Right)
5. `Super` + `f` – Toggle Fullscreen
6. `Super` + `shift` + `space` – Toggle floating / tiling layout
7. `Super` + `,` – Use tabbed layout
8. `Super` + `Enter` – Open Ghostty

*Documented and built with intention.*
