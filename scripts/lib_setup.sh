#!/usr/bin/env bash

# Shared setup helpers for the unified macOS and Linux bootstrap script.
# The entrypoint must set REPO_DIR before sourcing this file.

DRY_RUN=false
NO_INSTALL=false
NO_SHELL_CHANGE=false
PROFILE_OVERRIDE=auto

SETUP_PLATFORM=
PACKAGE_MANAGER=
SETUP_PROFILE=
ACTIVE_PACKAGE_PROFILES=
IS_RASPBERRY_PI=false

SETUP_LOG_DIR="${SETUP_LOG_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/myterm}"
SETUP_LOG_FILE="${SETUP_LOG_FILE:-$SETUP_LOG_DIR/setup.log}"
SETUP_STATE_FILE="${SETUP_STATE_FILE:-$SETUP_LOG_DIR/setup-state}"

usage() {
    local script_name
    script_name=$(basename "$0")

    cat <<EOF
Usage: ./$script_name [--dry-run] [--no-install] [--no-shell-change] [--profile auto|desktop|headless|raspberrypi]

Options:
  --dry-run          Print actions without changing files or installing packages.
  --no-install       Skip package manager, font, and plugin installation steps.
  --no-shell-change  Do not change the user's default shell.
  --profile          Override automatic profile detection.
  --headless         Compatibility alias for --profile headless.
  -h, --help         Show this help.
EOF
}

parse_setup_args() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                ;;
            --no-install)
                NO_INSTALL=true
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
    if [ "$NO_INSTALL" = true ]; then
        echo "NO INSTALL: package manager, font, and plugin installation steps will be skipped."
    fi
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "NO SHELL CHANGE: default shell changes will be skipped."
    fi
    if [ "$SETUP_PROFILE" = linux-headless ]; then
        echo "HEADLESS: GUI packages, fonts, and desktop configs will be skipped where supported."
    fi
    echo "------------------------------------------------------------------"
}

timestamp_utc() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

init_setup_logging() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi

    mkdir -p "$SETUP_LOG_DIR"
    : > "$SETUP_LOG_FILE"
    {
        echo "started_at=$(timestamp_utc)"
        echo "platform=$SETUP_PLATFORM"
        echo "package_manager=$PACKAGE_MANAGER"
        echo "profile=$SETUP_PROFILE"
        echo "active_profiles=$ACTIVE_PACKAGE_PROFILES"
    } > "$SETUP_STATE_FILE"
    printf '%s START setup platform=%s manager=%s profile=%s\n' "$(timestamp_utc)" "$SETUP_PLATFORM" "$PACKAGE_MANAGER" "$SETUP_PROFILE" >> "$SETUP_LOG_FILE"
}

log_setup() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    fi

    printf '%s %s\n' "$(timestamp_utc)" "$*" >> "$SETUP_LOG_FILE"
}

record_setup_state() {
    local key=$1
    local value=$2

    if [ "$DRY_RUN" = true ]; then
        return 0
    fi

    printf '%s=%s\n' "$key" "$value" >> "$SETUP_STATE_FILE"
}

format_command() {
    printf '%q ' "$@"
}

fatal() {
    local message=$1
    local code=${2:-1}

    echo "ERROR: $message" >&2
    log_setup "FATAL $message"
    record_setup_state "failed_step" "$message"
    exit "$code"
}

run_step() {
    local label=$1
    shift

    if [ "$DRY_RUN" = true ]; then
        printf '  -> Would run:'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    log_setup "BEGIN $label"
    log_setup "COMMAND $(format_command "$@")"

    local status=0
    "$@" || status=$?
    if [ "$status" -eq 0 ]; then
        log_setup "OK $label"
        record_setup_state "last_successful_step" "$label"
        return 0
    fi

    log_setup "FAIL $label exit_code=$status"
    record_setup_state "failed_step" "$label"
    record_setup_state "failed_exit_code" "$status"
    echo "ERROR: $label failed" >&2
    echo "Command: $(format_command "$@")" >&2
    echo "Exit code: $status" >&2
    echo "Log: $SETUP_LOG_FILE" >&2
    echo "State: $SETUP_STATE_FILE" >&2
    echo "Next: fix the command above, then rerun ./setup.sh. Use ./setup.sh --no-install to skip package installation." >&2
    exit "$status"
}

run_cmd() {
    run_step "Run command: $(format_command "$@")" "$@"
}

run_shell() {
    local command=$1

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would run: $command"
        return 0
    fi

    run_step "Run shell: $command" bash -o pipefail -c "$command"
}

command_exists() {
    command -v "$1" > /dev/null 2>&1
}

is_graphical_session() {
    if [ "${MYTERM_TEST_GRAPHICAL:-}" = "1" ]; then
        return 0
    fi
    if [ "${MYTERM_TEST_GRAPHICAL:-}" = "0" ]; then
        return 1
    fi

    [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${XDG_CURRENT_DESKTOP:-}" ]
}

detect_raspberry_pi() {
    if [ "${MYTERM_TEST_RASPBERRY_PI:-}" = "1" ]; then
        return 0
    fi
    if [ "${MYTERM_TEST_RASPBERRY_PI:-}" = "0" ]; then
        return 1
    fi

    if [ -r /proc/device-tree/model ] && grep -qi "Raspberry Pi" /proc/device-tree/model 2> /dev/null; then
        return 0
    fi

    return 1
}

detect_linux_package_manager() {
    if [ -n "${MYTERM_TEST_PACKAGE_MANAGER:-}" ]; then
        PACKAGE_MANAGER=$MYTERM_TEST_PACKAGE_MANAGER
        return 0
    fi

    if command_exists apt-get; then
        PACKAGE_MANAGER=apt
    elif command_exists pacman; then
        PACKAGE_MANAGER=pacman
    elif command_exists dnf; then
        PACKAGE_MANAGER=dnf
    else
        fatal "Unsupported Linux package manager. Supported managers: apt, pacman, dnf."
    fi
}

normalize_linux_profile() {
    case "$PROFILE_OVERRIDE" in
        auto)
            if is_graphical_session; then
                SETUP_PROFILE=linux-desktop
            else
                SETUP_PROFILE=linux-headless
            fi
            ;;
        desktop|linux-desktop)
            SETUP_PROFILE=linux-desktop
            ;;
        headless|linux-headless)
            SETUP_PROFILE=linux-headless
            ;;
        raspberrypi)
            SETUP_PROFILE=linux-headless
            IS_RASPBERRY_PI=true
            ;;
        macos)
            fatal "--profile macos cannot be used on Linux." 2
            ;;
        *)
            fatal "Unknown profile '$PROFILE_OVERRIDE'. Use auto, desktop, headless, or raspberrypi." 2
            ;;
    esac
}

detect_setup_platform() {
    local uname_value
    uname_value="${MYTERM_TEST_UNAME:-$(uname -s)}"

    case "$uname_value" in
        Darwin)
            SETUP_PLATFORM=macos
            PACKAGE_MANAGER=brew
            case "$PROFILE_OVERRIDE" in
                auto|desktop|macos)
                    SETUP_PROFILE=macos
                    ;;
                *)
                    fatal "--profile $PROFILE_OVERRIDE is not valid on macOS." 2
                    ;;
            esac
            ACTIVE_PACKAGE_PROFILES=macos
            ;;
        Linux)
            SETUP_PLATFORM=linux
            detect_linux_package_manager
            if detect_raspberry_pi; then
                IS_RASPBERRY_PI=true
            fi
            normalize_linux_profile
            ACTIVE_PACKAGE_PROFILES=$SETUP_PROFILE
            if [ "$IS_RASPBERRY_PI" = true ]; then
                ACTIVE_PACKAGE_PROFILES="$ACTIVE_PACKAGE_PROFILES,raspberrypi"
            fi

            ;;
        *)
            fatal "Unsupported operating system: $uname_value"
            ;;
    esac
}

setup_label() {
    case "$SETUP_PLATFORM:$SETUP_PROFILE:$IS_RASPBERRY_PI" in
        macos:macos:*)
            echo "macOS"
            ;;
        linux:linux-desktop:true)
            echo "Raspberry Pi Linux desktop"
            ;;
        linux:linux-desktop:false)
            echo "Linux desktop"
            ;;
        linux:linux-headless:true)
            echo "Raspberry Pi Linux headless"
            ;;
        linux:linux-headless:false)
            echo "Linux headless"
            ;;
        *)
            echo "$SETUP_PLATFORM $SETUP_PROFILE"
            ;;
    esac
}

validate_manifest() {
    local manifest=$1

    if [ ! -f "$manifest" ]; then
        fatal "Package manifest not found: $manifest"
    fi

    if render_package_plan "$manifest" "$PACKAGE_MANAGER" "$ACTIVE_PACKAGE_PROFILES" > /dev/null; then
        return 0
    fi

    fatal "Package manifest is invalid: $manifest"
}

preflight_setup() {
    if [ "$NO_INSTALL" = true ]; then
        return 0
    fi

    validate_manifest "$REPO_DIR/packages.tsv"

    if [ "$SETUP_PLATFORM" = linux ] && ! command_exists sudo; then
        fatal "sudo is required for Linux package installation. Rerun with --no-install after installing packages manually."
    fi
}

ensure_homebrew() {
    if command_exists brew; then
        echo "Homebrew is already installed."
        return 0
    fi

    echo "Homebrew not found. Installing Homebrew..."
    run_shell 'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | /bin/bash'
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
}

prepare_apt_repositories() {
    echo "Updating apt package sources..."
    run_step "Update apt package sources" sudo apt-get update -y

    if [ "$SETUP_PROFILE" != linux-desktop ]; then
        return 0
    fi

    echo "Adding apt repositories for Neovim, Ghostty, and Node.js..."
    run_step "Install apt repository prerequisites" sudo apt-get install -y software-properties-common curl wget unzip fontconfig ca-certificates gnupg
    run_step "Add Neovim apt repository" sudo add-apt-repository ppa:neovim-ppa/stable -y
    run_step "Add Ghostty apt repository" sudo add-apt-repository ppa:mkasberg/ghostty-ubuntu -y
    run_shell 'curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -'
    run_step "Refresh apt package sources" sudo apt-get update -y
}

prepare_package_manager() {
    if [ "$SETUP_PLATFORM" = macos ]; then
        ensure_homebrew
        return 0
    fi

    case "$PACKAGE_MANAGER" in
        apt)
            prepare_apt_repositories
            ;;
        pacman|dnf)
            ;;
        *)
            fatal "Unsupported package manager: $PACKAGE_MANAGER"
            ;;
    esac
}

PACKAGE_INSTALL_IDS=()
PACKAGE_ALREADY_IDS=()
PACKAGE_SKIP_IDS=()
PACKAGE_UNSUPPORTED_IDS=()
BREW_PACKAGES=()
BREW_CASK_PACKAGES=()
APT_PACKAGES=()
PACMAN_PACKAGES=()
DNF_PACKAGES=()
NPM_GLOBAL_PACKAGES=()

reset_package_plan() {
    PACKAGE_INSTALL_IDS=()
    PACKAGE_ALREADY_IDS=()
    PACKAGE_SKIP_IDS=()
    PACKAGE_UNSUPPORTED_IDS=()
    BREW_PACKAGES=()
    BREW_CASK_PACKAGES=()
    APT_PACKAGES=()
    PACMAN_PACKAGES=()
    DNF_PACKAGES=()
    NPM_GLOBAL_PACKAGES=()
}

checks_satisfied() {
    local checks=$1
    local check

    [ "$checks" != "-" ] || return 1

    for check in $checks; do
        if command_exists "$check"; then
            return 0
        fi
    done

    return 1
}

tsv_value_to_words() {
    local value=$1

    if [ "$value" = "-" ] || [ -z "$value" ]; then
        return 0
    fi

    printf '%s\n' "${value//,/ }"
}

csv_contains_any() {
    local values=$1
    local candidates=$2
    local value
    local candidate
    local IFS=,

    if [ "$values" = "-" ] || [ -z "$values" ]; then
        return 0
    fi

    IFS=,
    for value in $values; do
        for candidate in $candidates; do
            if [ "$value" = "$candidate" ]; then
                return 0
            fi
        done
    done

    return 1
}

emit_package_plan_record() {
    local action=$1
    local kind=$2
    local package_id=$3
    local packages=$4
    local checks=$5

    printf '%s\t%s\t%s\t%s\t%s\n' "$action" "$kind" "$package_id" "$packages" "$checks"
}

choose_package_implementation() {
    local manager=$1
    local brew=$2
    local brew_cask=$3
    local apt=$4
    local pacman=$5
    local dnf=$6
    local npm_global=$7
    local kind_var=$8
    local packages_var=$9
    local selected_kind=
    local selected_packages=

    case "$manager" in
        brew)
            if [ "$brew" != "-" ]; then
                selected_kind=brew
                selected_packages=$brew
            elif [ "$brew_cask" != "-" ]; then
                selected_kind=brew_cask
                selected_packages=$brew_cask
            elif [ "$npm_global" != "-" ]; then
                selected_kind=npm_global
                selected_packages=$npm_global
            fi
            ;;
        apt)
            if [ "$apt" != "-" ]; then
                selected_kind=apt
                selected_packages=$apt
            elif [ "$npm_global" != "-" ]; then
                selected_kind=npm_global
                selected_packages=$npm_global
            fi
            ;;
        pacman)
            if [ "$pacman" != "-" ]; then
                selected_kind=pacman
                selected_packages=$pacman
            elif [ "$npm_global" != "-" ]; then
                selected_kind=npm_global
                selected_packages=$npm_global
            fi
            ;;
        dnf)
            if [ "$dnf" != "-" ]; then
                selected_kind=dnf
                selected_packages=$dnf
            elif [ "$npm_global" != "-" ]; then
                selected_kind=npm_global
                selected_packages=$npm_global
            fi
            ;;
        *)
            return 1
            ;;
    esac

    if [ -z "$selected_kind" ]; then
        return 1
    fi

    printf -v "$kind_var" '%s' "$selected_kind"
    printf -v "$packages_var" '%s' "$(tsv_value_to_words "$selected_packages")"
    return 0
}

render_package_plan() {
    local manifest=$1
    local manager=$2
    local active_profiles=$3
    local line_number=0
    local id
    local profiles
    local checks
    local brew
    local brew_cask
    local apt
    local pacman
    local dnf
    local npm_global
    local kind
    local packages
    local checks_text

    while IFS=$'\t' read -r id profiles checks brew brew_cask apt pacman dnf npm_global; do
        line_number=$((line_number + 1))

        case "$id" in
            ""|\#*)
                continue
                ;;
        esac

        if [ -z "${npm_global+x}" ]; then
            echo "ERROR: $manifest:$line_number must have 9 tab-separated fields." >&2
            return 2
        fi

        if ! csv_contains_any "$profiles" "$active_profiles"; then
            emit_package_plan_record "skip_profile" "-" "$id" "-" "-"
            continue
        fi

        checks_text="$(tsv_value_to_words "$checks")"
        if [ -z "$checks_text" ]; then
            checks_text=-
        fi

        if choose_package_implementation "$manager" "$brew" "$brew_cask" "$apt" "$pacman" "$dnf" "$npm_global" kind packages; then
            emit_package_plan_record "install" "$kind" "$id" "$packages" "$checks_text"
        else
            emit_package_plan_record "unsupported" "-" "$id" "-" "-"
        fi
    done < "$manifest"
}

append_install_packages() {
    local kind=$1
    shift

    case "$kind" in
        brew)
            BREW_PACKAGES+=("$@")
            ;;
        brew_cask)
            BREW_CASK_PACKAGES+=("$@")
            ;;
        apt)
            APT_PACKAGES+=("$@")
            ;;
        pacman)
            PACMAN_PACKAGES+=("$@")
            ;;
        dnf)
            DNF_PACKAGES+=("$@")
            ;;
        npm_global)
            NPM_GLOBAL_PACKAGES+=("$@")
            ;;
        *)
            fatal "Unsupported install kind from package plan: $kind"
            ;;
    esac
}

collect_package_plan() {
    local action
    local kind
    local package_id
    local packages
    local checks
    local package_names

    reset_package_plan
    while IFS=$'\t' read -r action kind package_id packages checks; do
        case "$action" in
            install)
                if checks_satisfied "$checks"; then
                    PACKAGE_ALREADY_IDS+=("$package_id")
                    continue
                fi

                # shellcheck disable=SC2206
                package_names=($packages)
                append_install_packages "$kind" "${package_names[@]}"
                PACKAGE_INSTALL_IDS+=("$package_id")
                ;;
            skip_profile)
                PACKAGE_SKIP_IDS+=("$package_id")
                ;;
            unsupported)
                PACKAGE_UNSUPPORTED_IDS+=("$package_id")
                ;;
            "")
                ;;
            *)
                fatal "Unknown package plan action: $action"
                ;;
        esac
    done < <(render_package_plan "$REPO_DIR/packages.tsv" "$PACKAGE_MANAGER" "$ACTIVE_PACKAGE_PROFILES")
}

print_package_list() {
    local label=$1
    shift

    if [ "$#" -eq 0 ]; then
        return 0
    fi

    echo "  $label:"
    printf '    %s\n' "$@"
}

print_package_summary() {
    echo "Package plan:"
    if [ "${#PACKAGE_INSTALL_IDS[@]}" -gt 0 ]; then
        print_package_list "install" "${PACKAGE_INSTALL_IDS[@]}"
    fi
    if [ "${#PACKAGE_ALREADY_IDS[@]}" -gt 0 ]; then
        print_package_list "already present" "${PACKAGE_ALREADY_IDS[@]}"
    fi
    if [ "${#PACKAGE_SKIP_IDS[@]}" -gt 0 ]; then
        print_package_list "skipped by profile" "${PACKAGE_SKIP_IDS[@]}"
    fi
    if [ "${#PACKAGE_UNSUPPORTED_IDS[@]}" -gt 0 ]; then
        print_package_list "unsupported on $PACKAGE_MANAGER" "${PACKAGE_UNSUPPORTED_IDS[@]}"
    fi
}

install_package_groups() {
    if [ "${#BREW_PACKAGES[@]}" -gt 0 ]; then
        run_step "Install Homebrew packages" brew install "${BREW_PACKAGES[@]}"
    fi
    if [ "${#BREW_CASK_PACKAGES[@]}" -gt 0 ]; then
        run_step "Install Homebrew casks" brew install --cask "${BREW_CASK_PACKAGES[@]}"
    fi
    if [ "${#APT_PACKAGES[@]}" -gt 0 ]; then
        run_step "Install apt packages" sudo apt-get install -y "${APT_PACKAGES[@]}"
    fi
    if [ "${#PACMAN_PACKAGES[@]}" -gt 0 ]; then
        run_step "Install pacman packages" sudo pacman -Syu --needed "${PACMAN_PACKAGES[@]}"
    fi
    if [ "${#DNF_PACKAGES[@]}" -gt 0 ]; then
        run_step "Install dnf packages" sudo dnf install -y "${DNF_PACKAGES[@]}"
    fi
    if [ "${#NPM_GLOBAL_PACKAGES[@]}" -gt 0 ]; then
        if ! command_exists npm; then
            fatal "npm is required to install global npm packages: ${NPM_GLOBAL_PACKAGES[*]}"
        fi
        run_step "Install global npm packages" sudo npm install -g "${NPM_GLOBAL_PACKAGES[@]}"
    fi
}

install_manifest_packages() {
    if [ "$NO_INSTALL" = true ]; then
        echo "Skipping package installation."
        return 0
    fi

    prepare_package_manager
    collect_package_plan
    print_package_summary
    install_package_groups
    ensure_powerlevel10k
}

ensure_dir() {
    local dir=$1

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would create directory: $dir"
        return 0
    fi

    run_step "Create directory $dir" mkdir -p "$dir"
}

backup_file() {
    local dest=$1

    if [ -e "$dest" ] && [ ! -f "$dest" ] && [ ! -L "$dest" ]; then
        fatal "$dest exists but is not a regular file or symlink."
    fi

    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        local backup="${dest}.backup"
        if [ -e "$backup" ]; then
            backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would back up existing file: $dest -> $backup"
            return 0
        fi

        run_step "Back up existing file $dest" mv "$dest" "$backup"
        echo "  -> Backed up existing file: $backup"
    fi
}

link_file() {
    local src=$1
    local dest=$2

    backup_file "$dest"
    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would link $dest -> $src"
        return 0
    fi

    run_step "Link $dest" ln -sfn "$src" "$dest"
    echo "  -> Linked $dest"
}

link_dir() {
    local src=$1
    local dest=$2

    if [ -e "$dest" ] && [ ! -d "$dest" ] && [ ! -L "$dest" ]; then
        fatal "$dest exists but is not a directory or symlink."
    fi

    if [ -d "$dest" ] && [ ! -L "$dest" ]; then
        local backup="${dest}.backup"
        if [ -e "$backup" ]; then
            backup="${dest}.backup.$(date +%Y%m%d%H%M%S)"
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would back up existing directory: $dest -> $backup"
            echo "  -> Would link $dest -> $src"
            return 0
        fi

        run_step "Back up existing directory $dest" mv "$dest" "$backup"
        echo "  -> Backed up existing directory: $backup"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would link $dest -> $src"
        return 0
    fi

    if [ -L "$dest" ]; then
        run_step "Remove existing symlink $dest" rm "$dest"
    fi

    run_step "Link directory $dest" ln -s "$src" "$dest"
    echo "  -> Linked $dest"
}

copy_file() {
    local src=$1
    local dest=$2

    backup_file "$dest"
    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would copy $src -> $dest"
        return 0
    fi

    if [ -L "$dest" ]; then
        run_step "Remove existing symlink $dest" rm "$dest"
    fi
    run_step "Copy $dest" cp "$src" "$dest"
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

            if [ "$DRY_RUN" = true ]; then
                echo "  -> Would back up existing Codex skill: $target -> $backup"
                echo "  -> Would link Codex skill: $skill_name"
                continue
            fi

            run_step "Back up existing Codex skill $skill_name" mv "$target" "$backup"
            echo "  -> Backed up existing Codex skill: $backup"
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would link Codex skill: $skill_name"
            continue
        fi

        run_step "Link Codex skill $skill_name" ln -sfn "$skill_dir" "$target"
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
            if [ "$DRY_RUN" = true ]; then
                echo "  -> Would migrate legacy repo-linked ~/.secrets to a real home file"
                return 0
            fi

            run_step "Remove legacy ~/.secrets symlink" rm "$secrets_file"
            run_step "Copy legacy ~/.secrets into home" cp "$legacy_repo_secrets" "$secrets_file"
            run_step "Restrict ~/.secrets permissions" chmod 600 "$secrets_file"
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
        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would create ~/.secrets from template"
        else
            run_step "Create ~/.secrets from template" cp "$REPO_DIR/zsh/.secrets.example" "$secrets_file"
            echo "  -> Created ~/.secrets from template"
        fi
    else
        echo "  -> Found existing ~/.secrets"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would restrict ~/.secrets permissions to owner-only"
    else
        run_step "Restrict ~/.secrets permissions" chmod 600 "$secrets_file"
        echo "  -> Restricted ~/.secrets permissions to owner-only"
    fi
}

create_common_dirs() {
    echo "Preparing common directories..."
    ensure_dir "$HOME/.local/bin"
    ensure_dir "$HOME/.config/ghostty"
    ensure_dir "$HOME/.config/nvim"
    ensure_dir "$HOME/.codex/scripts"
    ensure_dir "$HOME/.agents/skills"
}

create_cli_dirs() {
    echo "Preparing CLI directories..."
    ensure_dir "$HOME/.local/bin"
    ensure_dir "$HOME/.config/nvim"
    ensure_dir "$HOME/.codex/scripts"
    ensure_dir "$HOME/.agents/skills"
}

link_common_configs() {
    echo "Linking common configuration files..."
    link_file "$REPO_DIR/ghostty/config" "$HOME/.config/ghostty/config"
    link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    link_dir "$REPO_DIR/nvim/lua" "$HOME/.config/nvim/lua"
    link_file "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
    link_file "$REPO_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
}

link_cli_configs() {
    echo "Linking CLI configuration files..."
    link_file "$REPO_DIR/nvim/init.lua" "$HOME/.config/nvim/init.lua"
    link_dir "$REPO_DIR/nvim/lua" "$HOME/.config/nvim/lua"
    link_file "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"
    link_file "$REPO_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
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
        fatal "zsh is not available on PATH; install it or rerun without --no-install."
    fi

    if [ "$current_shell" != "$zsh_path" ]; then
        echo "Changing default shell to Zsh..."
        run_step "Change default shell to Zsh" chsh -s "$zsh_path"
    fi
}

install_linux_fd_compat() {
    echo "Checking fd compatibility..."
    ensure_dir "$HOME/.local/bin"

    if command_exists fdfind && [ ! -e "$HOME/.local/bin/fd" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would create fd symlink."
        else
            run_step "Create fd compatibility symlink" ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
            echo "  -> Created fd symlink."
        fi
    fi

    export PATH="$HOME/.local/bin:$PATH"
}

install_linux_font() {
    if [ "$SETUP_PROFILE" != linux-desktop ]; then
        return 0
    fi

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

    run_step "Download Meslo Nerd Font" wget -qO /tmp/Meslo.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip"
    run_step "Install Meslo Nerd Font files" unzip -qo /tmp/Meslo.zip -d "$font_dir"
    run_step "Refresh font cache" fc-cache -fv
    run_step "Remove Meslo Nerd Font archive" rm /tmp/Meslo.zip
}

create_linux_dirs() {
    echo "Preparing Linux desktop directories..."
    ensure_dir "$HOME/.config/i3"
}

link_linux_configs() {
    echo "Linking Linux desktop configuration files..."
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
        fatal "zsh is not available on PATH; install it or rerun without --no-install."
    fi

    if [ "${SHELL:-}" != "$zsh_path" ]; then
        echo "Changing default shell to Zsh..."
        run_step "Change default shell to Zsh" chsh -s "$zsh_path"
    fi
}

link_codex_config() {
    echo "Linking Codex configuration..."

    if [ -L "$HOME/agent-coding" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would remove legacy ~/agent-coding symlink"
        else
            run_step "Remove legacy ~/agent-coding symlink" rm "$HOME/agent-coding"
            echo "  -> Removed legacy ~/agent-coding symlink"
        fi
    elif [ -d "$HOME/agent-coding" ]; then
        echo "  -> Found legacy ~/agent-coding directory; leaving it untouched"
    fi

    copy_file "$REPO_DIR/codex/config.toml" "$HOME/.codex/config.toml"
    link_file "$REPO_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
    link_file "$REPO_DIR/codex/scripts/safe_commit.sh" "$HOME/.codex/scripts/safe_commit.sh"
    link_codex_skills
}

ensure_powerlevel10k() {
    echo "Setting up Zsh plugins..."
    if [ -d "$HOME/.powerlevel10k" ]; then
        echo "  -> Powerlevel10k is already installed."
        return 0
    fi

    run_cmd git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.powerlevel10k"
}
