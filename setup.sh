#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_setup.sh
source "$REPO_DIR/scripts/lib_setup.sh"

install_macos_packages() {
    if [ "$NO_INSTALL" = true ]; then
        echo "Skipping macOS package installation."
        return 0
    fi

    if ! command -v brew > /dev/null 2>&1; then
        echo "Homebrew not found. Installing Homebrew..."
        run_shell 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
        if [ -x /opt/homebrew/bin/brew ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    else
        echo "Homebrew is already installed."
    fi

    echo "Installing core macOS packages..."
    run_cmd brew install git zsh neovim ripgrep fd tree-sitter-cli node fzf
    run_cmd brew install --cask ghostty
    run_cmd brew install --cask nikitabobko/tap/aerospace
    run_cmd brew install --cask karabiner-elements

    echo "Installing Meslo Nerd Font..."
    run_cmd brew install --cask font-meslo-lg-nerd-font

    ensure_powerlevel10k
}

create_macos_dirs() {
    echo "Preparing macOS directories..."
    ensure_dir "$HOME/.config/aerospace"
    ensure_dir "$HOME/.config/karabiner/assets/complex_modifications"
}

link_macos_configs() {
    echo "Linking macOS configuration files..."
    copy_file "$REPO_DIR/karabiner/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
    link_file "$REPO_DIR/aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
}

set_macos_shell() {
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "Skipping default shell change."
        return 0
    fi

    local current_shell
    local zsh_path
    current_shell=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
    zsh_path="$(command -v zsh || true)"
    if [ -z "$zsh_path" ]; then
        echo "ERROR: zsh is not available on PATH; install it or rerun without --no-install." >&2
        exit 1
    fi

    if [ "$current_shell" != "/bin/zsh" ]; then
        echo "Changing default shell to Zsh..."
        run_cmd chsh -s "$zsh_path"
    fi
}

parse_setup_args "$@"
if [ "$HEADLESS" = true ]; then
    echo "ERROR: --headless is only supported by setup_linux.sh." >&2
    exit 2
fi
print_setup_header "macOS"

install_macos_packages
create_common_dirs
create_macos_dirs
link_common_configs
link_macos_configs
link_codex_config
setup_secrets
set_macos_shell

echo "------------------------------------------------------------------"
echo "Setup complete. Restart your terminal."
