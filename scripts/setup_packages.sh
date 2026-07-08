#!/usr/bin/env bash

# Package manifest planning and package installation.
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

run_platform_post_install() {
    if [ "$NO_INSTALL" = true ]; then
        return 0
    fi

    if [ "$SETUP_PLATFORM" = linux ]; then
        install_linux_fd_compat
        install_linux_font
    fi
}
