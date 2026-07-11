#!/usr/bin/env bash

# Shared loader for the unified macOS and Linux bootstrap script.
# The entrypoint should set REPO_DIR before sourcing this file.

if [ -z "${REPO_DIR:-}" ]; then
    REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

MYTERM_SETUP_SCRIPT_DIR="$REPO_DIR/scripts"

# shellcheck source=scripts/setup_logging.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_logging.sh"
# shellcheck source=scripts/setup_args.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_args.sh"
# shellcheck source=scripts/setup_platform.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_platform.sh"
# shellcheck source=scripts/setup_files.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_files.sh"
# shellcheck source=scripts/setup_shell.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_shell.sh"
# shellcheck source=scripts/setup_packages.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_packages.sh"
# shellcheck source=scripts/setup_assets.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_assets.sh"
# shellcheck source=scripts/setup_codex.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_codex.sh"
# shellcheck source=scripts/setup_secrets.sh
source "$MYTERM_SETUP_SCRIPT_DIR/setup_secrets.sh"
