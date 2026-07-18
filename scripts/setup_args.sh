#!/usr/bin/env bash

# Setup argument parsing and user-facing setup header.
# shellcheck disable=SC2034
DRY_RUN=false
NO_SHELL_CHANGE=false
PROFILE_OVERRIDE=auto
usage() {
    local script_name
    script_name=$(basename "$0")

    cat <<EOF
Usage: ./$script_name [--dry-run] [--no-shell-change] [--profile auto|desktop|server|headless|raspberrypi]

Options:
  --dry-run          Print actions without changing files or installing packages.
  --no-shell-change  Do not change the user's default shell.
  --profile          Override automatic profile detection.
  --headless         Compatibility alias for --profile server on Ubuntu.
  -h, --help         Show this help.
EOF
}

parse_setup_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --no-shell-change)
                NO_SHELL_CHANGE=true
                ;;
            --headless)
                PROFILE_OVERRIDE=headless
                ;;
            --profile)
                if [ "$#" -lt 2 ]; then
                    echo "ERROR: --profile needs a value." >&2
                    usage >&2
                    exit 2
                fi
                PROFILE_OVERRIDE=$2
                shift
                ;;
            --profile=*)
                PROFILE_OVERRIDE=${1#*=}
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                echo "ERROR: Unknown option: $1" >&2
                usage >&2
                exit 2
                ;;
        esac
        shift
    done
}

print_setup_header() {
    local label=$1

    echo "Bootstrapping 'myterm' environment ($label) from: $REPO_DIR"
    echo "------------------------------------------------------------------"
    echo "This script installs packages, links dotfiles, configures Codex, and creates ~/.secrets if needed."
    echo "Existing regular config files are backed up with a .backup suffix before replacement."
    if [ -n "$PACKAGE_MANAGER" ]; then
        echo "Package manager: $PACKAGE_MANAGER"
    fi
    if [ -n "$ACTIVE_PACKAGE_PROFILES" ]; then
        echo "Package profiles: $ACTIVE_PACKAGE_PROFILES"
    fi
    if [ "$DRY_RUN" != true ]; then
        echo "Install log: $SETUP_LOG_FILE"
    fi
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: no files, packages, or shell settings will be changed."
    fi
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "NO SHELL CHANGE: default shell changes will be skipped."
    fi
    if [ "$SETUP_PROFILE" = ubuntu-server ] || [ "$SETUP_PROFILE" = raspberrypi-headless ]; then
        echo "HEADLESS: GUI packages, fonts, and desktop configs will be skipped where supported."
    fi
    echo "------------------------------------------------------------------"
}
