#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_setup.sh
source "$REPO_DIR/scripts/lib_setup.sh"

install_linux_packages() {
    if [ "$NO_INSTALL" = true ]; then
        echo "Skipping Linux package installation."
        return 0
    fi

    if [ "$HEADLESS" = true ]; then
        install_linux_headless_packages
        return 0
    fi

    echo "Updating package sources..."
    run_cmd sudo apt-get update -y

    echo "Adding repositories for Neovim, Ghostty, and Node.js..."
    run_cmd sudo apt-get install -y software-properties-common curl wget unzip fontconfig ca-certificates gnupg
    run_cmd sudo add-apt-repository ppa:neovim-ppa/stable -y
    run_cmd sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu -y
    run_shell 'curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -'
    run_cmd sudo apt-get update -y

    echo "Installing core Linux packages..."
    run_cmd sudo apt-get install -y git zsh neovim ghostty i3 ripgrep fd-find nodejs fzf build-essential

    if ! command -v tree-sitter > /dev/null 2>&1; then
        run_cmd sudo npm install -g tree-sitter-cli
        echo "Installed tree-sitter CLI through npm."
    fi

    install_linux_fd_compat
    install_linux_font
    ensure_powerlevel10k
}

install_linux_headless_packages() {
    if command -v apt-get > /dev/null 2>&1; then
        install_linux_headless_apt_packages
    elif command -v pacman > /dev/null 2>&1; then
        install_linux_headless_pacman_packages
    elif command -v dnf > /dev/null 2>&1; then
        install_linux_headless_dnf_packages
    else
        echo "ERROR: Unsupported headless package manager."
        echo "Install these packages manually, then rerun with --headless --no-install:"
        echo "  git zsh neovim ripgrep fd nodejs npm fzf build tools curl ca-certificates"
        exit 1
    fi

    maybe_install_tree_sitter_cli
    install_linux_fd_compat
    ensure_powerlevel10k
}

install_linux_headless_apt_packages() {
    echo "Detected apt-get. Updating package sources..."
    run_cmd sudo apt-get update -y

    echo "Installing headless CLI packages..."
    run_cmd sudo apt-get install -y git zsh neovim ripgrep fd-find nodejs npm fzf build-essential curl ca-certificates
    echo "Headless mode uses distro Neovim and Node.js packages; update them separately if your distro versions are too old for this config."
}

install_linux_headless_pacman_packages() {
    echo "Detected pacman. Installing headless CLI packages..."
    run_cmd sudo pacman -Syu --needed git zsh neovim ripgrep fd nodejs npm fzf base-devel curl ca-certificates
    echo "Headless mode uses distro Neovim and Node.js packages; update them separately if your distro versions are too old for this config."
}

install_linux_headless_dnf_packages() {
    echo "Detected dnf. Installing headless CLI packages..."
    run_cmd sudo dnf install -y git zsh neovim ripgrep fd-find nodejs npm fzf make gcc gcc-c++ curl ca-certificates
    echo "Headless mode uses distro Neovim and Node.js packages; update them separately if your distro versions are too old for this config."
}

maybe_install_tree_sitter_cli() {
    if ! command -v tree-sitter > /dev/null 2>&1; then
        run_cmd sudo npm install -g tree-sitter-cli
        echo "Installed tree-sitter CLI through npm."
    fi
}

install_linux_fd_compat() {
    echo "Checking fd compatibility..."
    ensure_dir "$HOME/.local/bin"

    if command -v fdfind > /dev/null 2>&1 && [ ! -L "$HOME/.local/bin/fd" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would create fd symlink."
        else
            ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
            echo "  -> Created fd symlink."
        fi
    fi

    export PATH="$HOME/.local/bin:$PATH"
}

install_linux_font() {
    echo "Installing Meslo Nerd Font..."
    local font_dir="$HOME/.local/share/fonts"

    ensure_dir "$font_dir"
    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would check whether Meslo Nerd Font is installed."
        run_cmd wget -qO /tmp/Meslo.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
        run_cmd unzip -qo /tmp/Meslo.zip -d "$font_dir"
        run_cmd fc-cache -fv
        run_cmd rm /tmp/Meslo.zip
        return 0
    fi

    if fc-list | grep -qi "Meslo"; then
        echo "  -> Meslo Nerd Font is already installed."
        return 0
    fi

    run_cmd wget -qO /tmp/Meslo.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    run_cmd unzip -qo /tmp/Meslo.zip -d "$font_dir"
    run_cmd fc-cache -fv
    run_cmd rm /tmp/Meslo.zip
}

create_linux_dirs() {
    echo "Preparing Linux directories..."
    ensure_dir "$HOME/.config/i3"
}

link_linux_configs() {
    echo "Linking Linux configuration files..."
    link_file "$REPO_DIR/i3/config" "$HOME/.config/i3/config"
}

set_linux_shell() {
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "Skipping default shell change."
        return 0
    fi

    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [ -z "$zsh_path" ]; then
        echo "ERROR: zsh is not available on PATH; install it or rerun without --no-install." >&2
        exit 1
    fi

    if [ "${SHELL:-}" != "$zsh_path" ]; then
        echo "Changing default shell to Zsh..."
        run_cmd chsh -s "$zsh_path"
    fi
}

parse_setup_args "$@"
print_setup_header "Ubuntu/Linux"

install_linux_packages
if [ "$HEADLESS" = true ]; then
    create_cli_dirs
    link_cli_configs
else
    create_common_dirs
    create_linux_dirs
    link_common_configs
    link_linux_configs
fi
link_codex_config
setup_secrets
set_linux_shell

echo "------------------------------------------------------------------"
echo "Ubuntu/Linux setup complete. Log out and back in, or restart, so the new Zsh shell and fonts are picked up."
