# myterm - Personal Terminal Environment ⚡

Welcome to `myterm`, a meticulously crafted, blazingly fast, and keyboard-centric development environment for macOS (Apple Silicon). This is basically just a dotfile repo.

## 🧰 Current Stack
* **Terminal:** [Ghostty](https://ghostty.org/) (GPU-accelerated via Metal, zero input latency, native macOS feel).
* **Window Manager (macOS):** [AeroSpace](https://nikitabobko.github.io/AeroSpace/guide) (i3-inspired tiling window manager for macOS).
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

## 🧭 AeroSpace Window Rules
The system automatically organizes your workspace:
*   **Workspace 1:** Default for all general applications.
*   **Workspace 2:** **Vivaldi** (Full Screen).
*   **Workspace 3:** **Ghostty** (Maximized/Full Screen).
*   **Workspace 4:** **Slack** (Full Screen).
*   **Workspace 5:** **Spotify** (Full Screen).

## Shortcuts:

**Explorer:**

1. a – Add: Erstellt eine neue Datei oder einen neuen Ordner (Tipp: Setze einen / ans Ende des Namens, um einen Ordner zu erstellen).
2. r – Rename: Benennt die Datei oder den Ordner unter dem Cursor um.
3. d – Delete: Löscht die ausgewählte Datei oder den Ordner (du wirst meistens noch um Bestätigung gebeten).
4. c – Copy: Kopiert die Datei/den Ordner in die Zwischenablage des Explorers.
5. x – Cut: Schneidet die Datei/den Ordner aus (Ausschneiden).
6. p – Paste: Fügt die zuvor kopierte oder ausgeschnittene Datei an der aktuellen Position ein.
7. y – Yank: Kopiert den Dateinamen (oder bei manchen Konfigurationen den absoluten Dateipfad) in deine System-Zwischenablage.

     *Dateien öffnen:*
8. <Enter> (oder o) – Open: Öffnet die Datei im Hauptfenster oder klappt einen Ordner auf/zu.
9. v – Vertical Split: Öffnet die Datei in einem neuen vertikalen Fenster (Split).
10. s – Split: Öffnet die Datei in einem neuen horizontalen Fenster (Split).
11. t – Tab: Öffnet die Datei in einem neuen Neovim-Tab.

     *Ansicht und Navigation:*
12. R – Refresh: Lädt den Datei-Explorer neu (hilfreich, wenn Dateien außerhalb von Neovim geändert wurden).
13. H – Hidden: Blendet versteckte Dateien (Dotfiles wie .gitignore oder .cache) ein oder aus.
14. I – Ignore: Blendet Dateien ein oder aus, die in der .gitignore stehen (z.B. der build/ Ordner).
15. W – Collapse All: Klappt alle geöffneten Ordner auf einmal zu.

**AeroSpace (macOS Window Manager):**

1. `alt` + `1-5` – Switch to Workspace 1-5
2. `alt` + `shift` + `1-5` – Move window to Workspace 1-5
3. `alt` + `h/j/k/l` – Focus window (Left, Down, Up, Right)
4. `alt` + `shift` + `h/j/k/l` – Move window (Left, Down, Up, Right)
5. `alt` + `/` – Toggle tiling layout (Horizontal/Vertical)
6. `alt` + `,` – Toggle accordion layout
7. `alt` + `shift` + `r` – Reload AeroSpace configuration

*Note: Automated window rules move Vivaldi (2), Ghostty (3), Slack (4), and Spotify (5) to dedicated workspaces.*

*Documented and built with intention. Ready for Tmux next.*
