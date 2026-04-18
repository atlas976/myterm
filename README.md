# myterm - Personal Terminal Environment ⚡

Welcome to `myterm`, a meticulously crafted, blazingly fast, and keyboard-centric development environment for macOS (Apple Silicon). This is basically just a dotfile repo.

## 🧰 Current Stack
* **Terminal:** [Ghostty](https://ghostty.org/) (GPU-accelerated via Metal, zero input latency, native macOS feel).
* **Shell:** Zsh with Powerlevel10k (Extremely fast, Git-aware prompt).
* **Editor:** Neovim with [Kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) (A starting point for a fast, modern Lua-based IDE).
* **AI Agent:** OpenCode (Strictly sandboxed, modular terminal coding assistant).
* **Fuzzy Finder:** fzf (Instant command-line search for files and history via `Ctrl+T` / `Ctrl+R`).
* **Theme:** Gruvbox Dark (Warm, earthy tones, easy on the eyes). To see more themes run 
```bash 
ghostty +list-themes
```

## 📂 Structure
**Note:** You have to enter the details in your `.secrets` file after running the setup script.

```text
~/myterm/
├── agent-coding/    # OpenCode AI Assistant Brain
│   ├── AGENTS.md    # Agent personas and strict security rules
│   ├── tools.md     # Strict definition of allowed tools
│   ├── .opencodeignore # Firewall against reading sensitive data
│   ├── opencode/    # OpenCode JSON configurations
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
*Documented and built with intention. Ready for Tmux next.*
