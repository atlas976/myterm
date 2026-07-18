#!/usr/bin/env bash

# Default shell setup and shell plugin bootstrap.
POWERLEVEL10K_COMMIT=604f19a9eaa18e76db2e60b8d446d5f879065f90

ensure_macos_shell_allowed() {
    local zsh_path=$1

    if grep -Fqx "$zsh_path" /etc/shells; then
        return 0
    fi

    echo "Registering $zsh_path as an allowed login shell..."
    # shellcheck disable=SC2016 # $1 is expanded by the privileged child shell.
    run_step "Register Zsh in /etc/shells" sudo sh -c 'printf "%s\n" "$1" >> /etc/shells' sh "$zsh_path"
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
        fatal "zsh is not available on PATH after package installation; fix the installation, then rerun ./setup.sh."
    fi

    if [ "$current_shell" != "$zsh_path" ]; then
        ensure_macos_shell_allowed "$zsh_path"
        echo "Changing default shell to Zsh..."
        run_step "Change default shell to Zsh" chsh -s "$zsh_path"
    fi
}

set_linux_shell() {
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "Skipping default shell change."
        return 0
    fi

    if [ "$DRY_RUN" = true ] && ! command_exists zsh; then
        echo "  -> Would change default shell to Zsh after installation."
        return 0
    fi

    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [ -z "$zsh_path" ]; then
        fatal "zsh is not available on PATH after package installation; fix the installation, then rerun ./setup.sh."
    fi

    if [ "${SHELL:-}" != "$zsh_path" ]; then
        echo "Changing default shell to Zsh..."
        run_step "Change default shell to Zsh" chsh -s "$zsh_path"
    fi
}

set_platform_shell() {
    case "$SETUP_PLATFORM" in
        macos)
            set_macos_shell
            ;;
        linux)
            set_linux_shell
            ;;
        *)
            fatal "No shell setup path for $SETUP_PLATFORM"
            ;;
    esac
}

ensure_powerlevel10k() {
    local checkout_root
    local checkout_dir
    local repository=https://github.com/romkatv/powerlevel10k.git

    echo "Setting up Zsh plugins..."
    if [ -d "$HOME/.powerlevel10k" ]; then
        echo "  -> Powerlevel10k is already installed."
        return 0
    fi

    if [ -e "$HOME/.powerlevel10k" ]; then
        fatal "$HOME/.powerlevel10k exists but is not a directory."
    fi

    if [ "$DRY_RUN" = true ]; then
        run_step "Clone Powerlevel10k" git clone --no-checkout "$repository" "$HOME/.powerlevel10k"
        run_step "Check out pinned Powerlevel10k" git -C "$HOME/.powerlevel10k" checkout --detach "$POWERLEVEL10K_COMMIT"
        return 0
    fi

    checkout_root="$(mktemp -d "$SETUP_LOG_DIR/powerlevel10k.XXXXXX")"
    checkout_dir="$checkout_root/repository"
    run_step "Clone Powerlevel10k" git clone --no-checkout "$repository" "$checkout_dir"
    run_step "Check out pinned Powerlevel10k" git -C "$checkout_dir" checkout --detach "$POWERLEVEL10K_COMMIT"
    run_step "Install pinned Powerlevel10k" mv "$checkout_dir" "$HOME/.powerlevel10k"
    run_step "Remove Powerlevel10k temporary directory" rmdir "$checkout_root"
}
