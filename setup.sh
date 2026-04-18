#!/bin/bash

# Finde den exakten Ordner heraus, in dem DIESES Skript gerade liegt
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Bootstrapping 'myterm' environment from: $REPO_DIR"
echo "------------------------------------------------------------------"

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed."
fi

# 2. Install Core Dependencies & Fonts
echo "📥 Installing core packages..."
brew install git zsh neovim ripgrep fd tree-sitter-cli node opencode fzf
brew install --cask ghostty 

# Install Meslo Nerd Font (Required for Powerlevel10k icons)
echo "🔤 Installing Meslo Nerd Font..."
brew install --cask font-meslo-lg-nerd-font

# 3. Install Zsh Plugins (Powerlevel10k)
echo "🔌 Setting up Zsh Plugins..."
if [ ! -d "$HOME/.powerlevel10k" ]; then
    # Clone Powerlevel10k into a hidden folder in the home directory (standard practice)
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
fi

# 4. Create Target Directories
echo "📁 Preparing system directories..."
mkdir -p ~/.config/ghostty

# 5. Create Symlinks (Die Brücken bauen)
echo "🔗 Symlinking configuration files..."

# Ghostty
if [ -f ~/.config/ghostty/config ] && [ ! -L ~/.config/ghostty/config ]; then
    mv ~/.config/ghostty/config ~/.config/ghostty/config.backup
    echo "  -> Backed up existing Ghostty config to config.backup"
fi
ln -sf "$REPO_DIR/ghostty/config" ~/.config/ghostty/config
echo "  -> Linked Ghostty config"

# Neovim
mkdir -p ~/.config/nvim
if [ -f ~/.config/nvim/init.lua ] && [ ! -L ~/.config/nvim/init.lua ]; then
    mv ~/.config/nvim/init.lua ~/.config/nvim/init.lua.backup
    echo "  -> Backed up existing Neovim init.lua to init.lua.backup"
fi
ln -sf "$REPO_DIR/nvim/init.lua" ~/.config/nvim/init.lua
echo "  -> Linked Neovim config (Kickstart)"

# Zsh
if [ -f ~/.zshrc ] && [ ! -L ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.backup
    echo "  -> Backed up existing ~/.zshrc to ~/.zshrc.backup"
fi
ln -sf "$REPO_DIR/zsh/.zshrc" ~/.zshrc
echo "  -> Linked Zsh config"

# Powerlevel10k
if [ -f ~/.p10k.zsh ] && [ ! -L ~/.p10k.zsh ]; then
    mv ~/.p10k.zsh ~/.p10k.zsh.backup
    echo "  -> Backed up existing ~/.p10k.zsh to ~/.p10k.zsh.backup"
fi
ln -sf "$REPO_DIR/zsh/.p10k.zsh" ~/.p10k.zsh
echo "  -> Linked Powerlevel10k config"

# OpenCode Agent
mkdir -p ~/.config/opencode

if [ -f ~/.config/opencode/opencode.json ] && [ ! -L ~/.config/opencode/opencode.json ]; then
    mv ~/.config/opencode/opencode.json ~/.config/opencode/opencode.json.backup
fi
ln -sf "$REPO_DIR/agent-coding/opencode/opencode.json" ~/.config/opencode/opencode.json

if [ -f ~/.config/opencode/AGENTS.md ] && [ ! -L ~/.config/opencode/AGENTS.md ]; then
    mv ~/.config/opencode/AGENTS.md ~/.config/opencode/AGENTS.md.backup
fi
ln -sf "$REPO_DIR/agent-coding/AGENTS.md" ~/.config/opencode/AGENTS.md
ln -sf "$REPO_DIR/agent-coding/tools.md" ~/.config/opencode/tools.md
ln -sf "$REPO_DIR/agent-coding/.opencodeignore" ~/.config/opencode/.opencodeignore

if [ -d ~/.config/opencode/skills ] && [ ! -L ~/.config/opencode/skills ]; then
    mv ~/.config/opencode/skills ~/.config/opencode/skills.backup
fi
# Using -n to ensure we link the directory correctly instead of putting a link inside an existing one
ln -sfn "$REPO_DIR/agent-coding/skills" ~/.config/opencode/skills

echo "  -> Linked OpenCode configuration and skills"

# Secrets
if [ -f ~/.secrets ] && [ ! -L ~/.secrets ]; then
    mv ~/.secrets ~/.secrets.backup
    echo "  -> Backed up existing ~/.secrets to ~/.secrets.backup"
fi

if [ ! -f "$REPO_DIR/zsh/.secrets" ]; then
    echo "# Add your API keys and secrets here" > "$REPO_DIR/zsh/.secrets"
    echo "  -> Created empty .secrets file in repo"
fi
# CRITICAL SECURITY: Restrict file permissions so other users cannot read the secrets
chmod 600 "$REPO_DIR/zsh/.secrets"

ln -sf "$REPO_DIR/zsh/.secrets" ~/.secrets
echo "  -> Linked Secrets file"

# 6. Make Zsh the default shell
CURRENT_SHELL=$(dscl . -read /Users/"$USER" UserShell | awk '{print $2}')
if [ "$CURRENT_SHELL" != "/bin/zsh" ]; then
    echo "🔄 Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
fi

echo "------------------------------------------------------------------"
echo "✅ Setup complete! Restart your terminal."