#!/bin/bash

# Exit immediately on errors, unset variables, or failed pipeline segments.
set -euo pipefail

# Resolve the directory that contains this script.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Bootstrapping 'myterm' environment (Ubuntu/Linux) from: $REPO_DIR"
echo "------------------------------------------------------------------"
echo "This script installs packages, links dotfiles, configures Codex, and creates ~/.secrets if needed."
echo "Existing regular config files are backed up with a .backup suffix before replacement."
echo "------------------------------------------------------------------"

# 1. Update package sources.
echo "🔄 Updating package sources..."
sudo apt-get update -y

# 2. Add PPAs for current Neovim and Ghostty packages.
echo "📦 Adding repositories for Neovim and Ghostty..."
sudo apt-get install -y software-properties-common curl wget unzip fontconfig
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu -y
sudo apt-get update -y

# 3. Install core dependencies via apt.
echo "📥 Installing core packages (Git, Zsh, Neovim, Ghostty, i3, Node.js, etc.)..."
sudo apt-get install -y git zsh neovim ghostty i3 ripgrep fd-find nodejs npm fzf

# Ubuntu package names the fd binary fdfind, while many tools expect fd.
mkdir -p "$HOME/.local/bin"
if command -v fdfind > /dev/null 2>&1 && [ ! -L ~/.local/bin/fd ]; then
    ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo "🔧 Created fd symlink."
fi
export PATH="$HOME/.local/bin:$PATH"

# 4. Install Meslo Nerd Font.
echo "🔤 Installing Meslo Nerd Font..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
if ! fc-list | grep -qi "Meslo"; then
    wget -qO /tmp/Meslo.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    unzip -qo /tmp/Meslo.zip -d "$FONT_DIR"
    fc-cache -fv
    rm /tmp/Meslo.zip
    echo "✅ Meslo Nerd Font installed."
else
    echo "✅ Meslo Nerd Font is already installed."
fi

# 5. Install Zsh plugins.
echo "🔌 Setting up Zsh Plugins (Powerlevel10k)..."
if [ ! -d "$HOME/.powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
fi

# 6. Create target directories.
echo "📁 Preparing system directories..."
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.config/i3"
mkdir -p "$HOME/.codex/scripts"
mkdir -p "$HOME/.agents/skills"

# 7. Link configuration files.
echo "🔗 Symlinking configuration files..."

backup_file() {
    local dest=$1
    if [ -e "$dest" ] && [ ! -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "ERROR: $dest exists but is not a regular file or symlink."
        exit 1
    fi

    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        local backup="${dest}.backup"
        if [ -e "$backup" ]; then
            backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        fi
        mv "$dest" "$backup"
        echo "  -> Backed up existing file: $backup"
    fi
}

link_file() {
    local src=$1
    local dest=$2
    backup_file "$dest"
    ln -sfn "$src" "$dest"
    echo "  -> Linked $dest"
}

link_codex_skills() {
    for skill_dir in "$REPO_DIR"/.agents/skills/*; do
        [ -d "$skill_dir" ] || continue

        local skill_name
        local target
        skill_name="$(basename "$skill_dir")"
        target="$HOME/.agents/skills/$skill_name"

        if [ -e "$target" ] && [ ! -L "$target" ]; then
            local backup="${target}.backup"
            if [ -e "$backup" ]; then
                backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
            fi
            mv "$target" "$backup"
            echo "  -> Backed up existing Codex skill: $backup"
        fi

        ln -sfn "$skill_dir" "$target"
        echo "  -> Linked Codex skill: $skill_name"
    done
}

setup_secrets() {
    local secrets_file="$HOME/.secrets"
    local legacy_repo_secrets="$REPO_DIR/zsh/.secrets"

    if [ -L "$secrets_file" ]; then
        local target
        target="$(readlink "$secrets_file")"
        if [ "$target" = "$legacy_repo_secrets" ] && [ -f "$legacy_repo_secrets" ]; then
            rm "$secrets_file"
            cp "$legacy_repo_secrets" "$secrets_file"
            chmod 600 "$secrets_file"
            echo "  -> Migrated legacy repo-linked ~/.secrets to a real home file"
        else
            echo "  -> Existing ~/.secrets symlink found; leaving it untouched"
        fi
        return
    fi

    if [ -e "$secrets_file" ] && [ ! -f "$secrets_file" ]; then
        echo "  -> Existing ~/.secrets is not a regular file; leaving it untouched"
        return
    fi

    if [ ! -f "$secrets_file" ]; then
        cp "$REPO_DIR/zsh/.secrets.example" "$secrets_file"
        echo "  -> Created ~/.secrets from template"
    else
        echo "  -> Found existing ~/.secrets"
    fi

    chmod 600 "$secrets_file"
    echo "  -> Restricted ~/.secrets permissions to owner-only"
}

# Ghostty, i3, Neovim, Zsh, P10k
link_file "$REPO_DIR/ghostty/config" "$HOME/.config/ghostty/config"
link_file "$REPO_DIR/i3/config" "$HOME/.config/i3/config"
link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link_file "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
link_file "$REPO_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"

# Codex Global Configuration
echo "🔗 Symlinking Codex configuration..."
if [ -L "$HOME/agent-coding" ]; then
    rm "$HOME/agent-coding"
    echo "  -> Removed legacy ~/agent-coding symlink"
elif [ -d "$HOME/agent-coding" ]; then
    echo "  -> Found legacy ~/agent-coding directory; leaving it untouched"
fi

link_file "$REPO_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$REPO_DIR/codex/scripts/safe_commit.sh" "$HOME/.codex/scripts/safe_commit.sh"
link_codex_skills

# Secrets
setup_secrets

# 8. Make Zsh the default shell
if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
    echo "🔄 Changing default shell to Zsh..."
    chsh -s "$(command -v zsh)"
fi

echo "------------------------------------------------------------------"
echo "✅ Ubuntu/Linux setup complete. Log out and back in, or restart, so the new Zsh shell and fonts are picked up."
