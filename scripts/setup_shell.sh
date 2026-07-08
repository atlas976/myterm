#!/usr/bin/env bash

# Default shell setup and shell plugin bootstrap.
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
        fatal "zsh is not available on PATH; install it or rerun without --no-install."
    fi

    if [ "$current_shell" != "$zsh_path" ]; then
        echo "Changing default shell to Zsh..."
        run_step "Change default shell to Zsh" chsh -s "$zsh_path"
    fi
}

set_linux_shell() {
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "Skipping default shell change."
        return 0
    fi

    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [ -z "$zsh_path" ]; then
        fatal "zsh is not available on PATH; install it or rerun without --no-install."
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
    echo "Setting up Zsh plugins..."
    if [ -d "$HOME/.powerlevel10k" ]; then
        echo "  -> Powerlevel10k is already installed."
        return 0
    fi

    run_cmd git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
}
