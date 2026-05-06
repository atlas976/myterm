#!/bin/bash

# Beendet das Skript sofort, falls ein kritischer Fehler auftritt
set -e

# Finde den exakten Ordner heraus, in dem DIESES Skript gerade liegt
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Bootstrapping 'myterm' environment (Ubuntu/Linux) from: $REPO_DIR"
echo "------------------------------------------------------------------"

# 1. System und Paketquellen aktualisieren
echo "🔄 Aktualisiere Paketquellen..."
sudo apt-get update -y

# 2. PPAs hinzufügen für aktuelle Versionen von Neovim und Ghostty
echo "📦 Füge Repositories für Neovim und Ghostty hinzu..."
sudo apt-get install -y software-properties-common curl wget unzip fontconfig
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu -y
sudo apt-get update -y

# 3. Core Dependencies über apt installieren
echo "📥 Installiere Basis-Pakete (Git, Zsh, Neovim, Ghostty, Node.js etc.)..."
sudo apt-get install -y git zsh neovim ghostty ripgrep fd-find nodejs npm fzf

# Ubuntu-spezifischer Fix für fd-find (Neovim erwartet oft den Befehl 'fd')
mkdir -p ~/.local/bin
if [ -x "$(command -v fdfind)" ] && [ ! -L ~/.local/bin/fd ]; then
    ln -s $(which fdfind) ~/.local/bin/fd
    echo "🔧 Symlink für 'fd' erstellt."
fi
export PATH="$HOME/.local/bin:$PATH"

# 4. Meslo Nerd Font installieren (Linux-nativ)
echo "🔤 Installiere Meslo Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ! fc-list | grep -qi "Meslo"; then
    wget -qO /tmp/Meslo.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    unzip -qo /tmp/Meslo.zip -d "$FONT_DIR"
    fc-cache -fv
    rm /tmp/Meslo.zip
    echo "✅ Meslo Nerd Font installiert."
else
    echo "✅ Meslo Nerd Font ist bereits installiert."
fi

# 5. Install Zsh Plugins (Powerlevel10k)
echo "🔌 Setting up Zsh Plugins (Powerlevel10k)..."
if [ ! -d "$HOME/.powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.powerlevel10k
fi

# 6. Target Directories erstellen
echo "📁 Preparing system directories..."
mkdir -p ~/.config/ghostty
mkdir -p ~/.config/nvim

# 7. Symlinks erstellen (mit Helfer-Funktion für sauberen Code)
echo "🔗 Symlinking configuration files..."

link_file() {
    local src=$1
    local dest=$2
    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        mv "$dest" "${dest}.backup"
        echo "  -> Backed up existing file: $dest"
    fi
    ln -sf "$src" "$dest"
}

# Ghostty, Neovim, Zsh, P10k
link_file "$REPO_DIR/ghostty/config" ~/.config/ghostty/config
link_file "$REPO_DIR/nvim/init.lua" ~/.config/nvim/init.lua
link_file "$REPO_DIR/zsh/.zshrc" ~/.zshrc
link_file "$REPO_DIR/zsh/.p10k.zsh" ~/.p10k.zsh

# Agent Global Configuration
# Symlink the entire agent-coding directory so any CLI agent (Gemini, Claude, Codex)
# can pick up its configuration files globally without hardcoding here.
if [ -d ~/agent-coding ] && [ ! -L ~/agent-coding ]; then
    mv ~/agent-coding ~/agent-coding.backup
    echo "  -> Backed up existing ~/agent-coding directory to ~/agent-coding.backup"
fi
ln -sfn "$REPO_DIR/agent-coding" ~/agent-coding
echo "  -> Linked generic agent-coding directory"

# Secrets
if [ ! -f "$REPO_DIR/zsh/.secrets" ]; then
    echo "# Add your API keys and secrets here" > "$REPO_DIR/zsh/.secrets"
    chmod 600 "$REPO_DIR/zsh/.secrets"
fi
link_file "$REPO_DIR/zsh/.secrets" ~/.secrets

# 8. Make Zsh the default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔄 Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
fi

echo "------------------------------------------------------------------"
echo "✅ Linux setup complete! Wichtig: Logge dich einmal aus und wieder ein oder starte den Rechner neu, damit die neue Zsh-Shell und die Fonts greifen."