#!/usr/bin/env bash

# Shared setup helpers for the macOS and Linux bootstrap scripts.
# The entrypoint must set REPO_DIR before sourcing this file.

DRY_RUN=false
NO_INSTALL=false
NO_SHELL_CHANGE=false
HEADLESS=false

usage() {
    local script_name
    script_name=$(basename "$0")

    cat <<EOF
Usage: ./$script_name [--dry-run] [--no-install] [--no-shell-change] [--headless]

Options:
  --dry-run          Print actions without changing files or installing packages.
  --no-install       Skip package manager, font, and plugin installation steps.
  --no-shell-change  Do not change the user's default shell.
  --headless         Linux only: skip GUI packages, fonts, and desktop configs.
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
                HEADLESS=true
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
    if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: no files, packages, or shell settings will be changed."
    fi
    if [ "$NO_INSTALL" = true ]; then
        echo "NO INSTALL: package manager, font, and plugin installation steps will be skipped."
    fi
    if [ "$NO_SHELL_CHANGE" = true ]; then
        echo "NO SHELL CHANGE: default shell changes will be skipped."
    fi
    if [ "$HEADLESS" = true ]; then
        echo "HEADLESS: GUI packages, fonts, and desktop configs will be skipped where supported."
    fi
    echo "------------------------------------------------------------------"
}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        printf '  -> Would run:'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    "$@"
}

run_shell() {
    local command=$1

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would run: $command"
        return 0
    fi

    bash -c "$command"
}

ensure_dir() {
    local dir=$1

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would create directory: $dir"
        return 0
    fi

    mkdir -p "$dir"
}

backup_file() {
    local dest=$1

    if [ -e "$dest" ] && [ ! -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "ERROR: $dest exists but is not a regular file or symlink."
        exit 1
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

        mv "$dest" "$backup"
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

    ln -sfn "$src" "$dest"
    echo "  -> Linked $dest"
}

link_dir() {
    local src=$1
    local dest=$2

    if [ -e "$dest" ] && [ ! -d "$dest" ] && [ ! -L "$dest" ]; then
        echo "ERROR: $dest exists but is not a directory or symlink."
        exit 1
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

        mv "$dest" "$backup"
        echo "  -> Backed up existing directory: $backup"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would link $dest -> $src"
        return 0
    fi

    if [ -L "$dest" ]; then
        rm "$dest"
    fi

    ln -s "$src" "$dest"
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
        rm "$dest"
    fi
    cp "$src" "$dest"
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

            mv "$target" "$backup"
            echo "  -> Backed up existing Codex skill: $backup"
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would link Codex skill: $skill_name"
            continue
        fi

        ln -sfn "$skill_dir" "$target"
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

            rm "$secrets_file"
            cp "$legacy_repo_secrets" "$secrets_file"
            chmod 600 "$secrets_file"
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
            cp "$REPO_DIR/zsh/.secrets.example" "$secrets_file"
            echo "  -> Created ~/.secrets from template"
        fi
    else
        echo "  -> Found existing ~/.secrets"
    fi

    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would restrict ~/.secrets permissions to owner-only"
    else
        chmod 600 "$secrets_file"
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

link_codex_config() {
    echo "Linking Codex configuration..."

    if [ -L "$HOME/agent-coding" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would remove legacy ~/agent-coding symlink"
        else
            rm "$HOME/agent-coding"
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
