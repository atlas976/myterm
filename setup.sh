#!/bin/bash

set -euo pipefail

# Resolve the directory that contains this script.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Bootstrapping 'myterm' environment from: $REPO_DIR"
echo "------------------------------------------------------------------"
echo "This script installs packages, links dotfiles, configures Codex, and creates ~/.secrets if needed."
echo "Existing regular config files are backed up with a .backup suffix before replacement."
echo "------------------------------------------------------------------"

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

link_dir() {
    local src=$1
    local dest=$2
    if [ -e "$dest" ] && [ ! -d "$dest" ] && [ ! -L "$dest" ]; then
        echo "ERROR: $dest exists but is not a directory or symlink."
        exit 1
    fi

    if [ -d "$dest" ] && [ ! -L "$dest" ]; then
        local backup="${dest}.backup"
        if [ -e "$backup" ]; then
            backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        fi
        mv "$dest" "$backup"
        echo "  -> Backed up existing directory: $backup"
    fi

    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    ln -s "$src" "$dest"
    echo "  -> Linked $dest"
}

copy_file() {
    local src=$1
    local dest=$2
    backup_file "$dest"
    if [ -L "$dest" ]; then
        rm "$dest"
    fi
    cp "$src" "$dest"
    echo "  -> Copied $dest"
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

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
    echo "📦 Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "✅ Homebrew is already installed."
fi

# 2. Install core dependencies and fonts
echo "📥 Installing core packages..."
brew install git zsh neovim ripgrep fd tree-sitter-cli node fzf
brew install --cask ghostty
brew install --cask nikitabobko/tap/aerospace
brew install --cask karabiner-elements

# Install Meslo Nerd Font. Powerlevel10k uses it for prompt symbols.
echo "🔤 Installing Meslo Nerd Font..."
brew install --cask font-meslo-lg-nerd-font

# 3. Install Zsh plugins
echo "🔌 Setting up Zsh Plugins..."
if [ ! -d "$HOME/.powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
fi

# 4. Create target directories
echo "📁 Preparing system directories..."
mkdir -p "$HOME/.config/ghostty"
mkdir -p "$HOME/.config/aerospace"
mkdir -p "$HOME/.config/karabiner/assets/complex_modifications"
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/.codex/scripts"
mkdir -p "$HOME/.agents/skills"

# 5. Link configuration files
echo "🔗 Symlinking configuration files..."

# Karabiner-Elements reloads can replace symlinks, so copy this file.
copy_file "$REPO_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
link_file "$REPO_DIR/ghostty/config" "$HOME/.config/ghostty/config"
link_file "$REPO_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
link_dir "$REPO_DIR/nvim/lua" "$HOME/.config/nvim/lua"
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

# 6. Make Zsh the default shell
CURRENT_SHELL=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
if [ "$CURRENT_SHELL" != "/bin/zsh" ]; then
    echo "🔄 Changing default shell to Zsh..."
    chsh -s "$(command -v zsh)"
fi

echo "------------------------------------------------------------------"
echo "✅ Setup complete! Restart your terminal."
