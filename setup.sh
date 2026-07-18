#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib_setup.sh
source "$REPO_DIR/scripts/lib_setup.sh"

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
complete_setup_logging

echo "------------------------------------------------------------------"
echo "Setup complete. Restart your terminal or log out and back in if the default shell changed."
