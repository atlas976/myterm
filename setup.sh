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
brew install git zsh neovim ripgrep fd tree-sitter-cli node fzf
brew install --cask ghostty 
brew install --cask nikitabobko/tap/aerospace

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
mkdir -p ~/.config/aerospace

# 5. Create Symlinks (Die Brücken bauen)
echo "🔗 Symlinking configuration files..."

# Ghostty
if [ -f ~/.config/ghostty/config ] && [ ! -L ~/.config/ghostty/config ]; then
    mv ~/.config/ghostty/config ~/.config/ghostty/config.backup
    echo "  -> Backed up existing Ghostty config to config.backup"
fi
ln -sf "$REPO_DIR/ghostty/config" ~/.config/ghostty/config
echo "  -> Linked Ghostty config"

# AeroSpace
if [ -f ~/.config/aerospace/aerospace.toml ] && [ ! -L ~/.config/aerospace/aerospace.toml ]; then
    mv ~/.config/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml.backup
    echo "  -> Backed up existing AeroSpace config to aerospace.toml.backup"
fi
ln -sf "$REPO_DIR/aerospace/aerospace.toml" ~/.config/aerospace/aerospace.toml
echo "  -> Linked AeroSpace config"

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

# Agent Global Configuration
echo "🔗 Symlinking agent configuration..."
if [ -d ~/agent-coding ] && [ ! -L ~/agent-coding ]; then
    mv ~/agent-coding ~/agent-coding.backup
    echo "  -> Backed up existing ~/agent-coding directory to ~/agent-coding.backup"
fi
# Symlink the entire agent-coding directory so any CLI agent (Gemini, Claude, Codex)
# can pick up its configuration files globally without hardcoding here.
ln -sfn "$REPO_DIR/agent-coding" ~/agent-coding
echo "  -> Linked generic agent-coding directory"

# Install Agent Skills
echo "🧠 Installing agent skills..."
if command -v gemini &> /dev/null; then
    for skill in "$REPO_DIR"/agent-coding/skills/*.skill; do
        if [ -f "$skill" ]; then
            echo "  -> Installing skill: $(basename "$skill")"
            gemini skills install "$skill" --scope user --consent
        fi
    done
else
    echo "  -> Gemini CLI not found. Skipping automatic skill installation."
fi

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
