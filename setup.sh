#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_setup.sh
source "$REPO_DIR/scripts/lib_setup.sh"

link_platform_configs() {
    case "$SETUP_PLATFORM:$SETUP_PROFILE" in
        macos:macos)
            create_common_dirs
            create_macos_dirs
            link_common_configs
            link_macos_configs
            ;;
        linux:linux-desktop)
            create_common_dirs
            create_linux_dirs
            link_common_configs
            link_linux_configs
            ;;
        linux:linux-headless)
            create_cli_dirs
            link_cli_configs
            ;;
        *)
            fatal "No config linking path for $SETUP_PLATFORM/$SETUP_PROFILE"
            ;;
    esac
}

run_platform_post_install() {
    if [ "$NO_INSTALL" = true ]; then
        return 0
    fi

    if [ "$SETUP_PLATFORM" = linux ]; then
        install_linux_fd_compat
        install_linux_font
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

parse_setup_args "$@"
detect_setup_platform
init_setup_logging
print_setup_header "$(setup_label)"

preflight_setup
install_manifest_packages
run_platform_post_install
link_platform_configs
link_codex_config
setup_secrets
set_platform_shell

echo "------------------------------------------------------------------"
echo "Setup complete. Restart your terminal or log out and back in if the default shell changed."
