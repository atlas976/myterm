# myterm - Personal Terminal Environment ⚡

Welcome to `myterm`, a meticulously crafted, blazingly fast, and keyboard-centric development environment for macOS (Apple Silicon). This is basically just a dotfile repo.

## 🧰 Current Stack
* **Terminal:** [Ghostty](https://ghostty.org/) (GPU-accelerated via Metal, zero input latency, native macOS feel).
* **Shell:** Zsh with Powerlevel10k (Extremely fast, Git-aware prompt).
* **Editor:** Neovim with [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) (A starting point for a fast, modern Lua-based IDE).
* **AI Agent:** Agnostic CLI Agent Configuration (e.g., Gemini CLI, Claude Code) with strict sandboxing.
* **Fuzzy Finder:** fzf (Instant command-line search for files and history via `Ctrl+T` / `Ctrl+R`).
* **Theme:** Gruvbox Dark (Warm, earthy tones, easy on the eyes). To see more themes run 
```bash 
ghostty +list-themes
```

## 📂 Structure
**Note:** You have to enter the details in your `.secrets` file after running the setup script.

```text
~/myterm/
├── agent-coding/    # AI Assistant Brain and Rules (Gemini, Claude, etc.)
│   ├── GEMINI.md    # Agent personas and strict security rules
│   ├── .geminiignore # Firewall against reading sensitive data
│   └── skills/      # Modular tools and scripts (e.g., safe_commit.sh)
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




*Documented and built with intention. Ready for Tmux next.*
