#!/usr/bin/env bash

# Filesystem helpers and dotfile linking.
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

create_linux_dirs() {
    echo "Preparing Ubuntu desktop directories..."
    ensure_dir "$HOME/.config/i3"
}

link_linux_configs() {
    echo "Linking Ubuntu desktop configuration files..."
    link_file "$REPO_DIR/i3/config" "$HOME/.config/i3/config"
}

validate_setup_sources() {
    local source_path
    local required_sources=(
        "$REPO_DIR/packages.tsv"
        "$REPO_DIR/codex/config.toml"
        "$REPO_DIR/codex/AGENTS.md"
        "$REPO_DIR/codex/scripts/safe_commit.sh"
        "$REPO_DIR/nvim/init.lua"
        "$REPO_DIR/nvim/lua"
        "$REPO_DIR/zsh/.zshrc"
        "$REPO_DIR/zsh/.p10k.zsh"
        "$REPO_DIR/zsh/.secrets.example"
    )

    case "$SETUP_PROFILE" in
        macos)
            required_sources+=(
                "$REPO_DIR/ghostty/config"
                "$REPO_DIR/aerospace/aerospace.toml"
                "$REPO_DIR/karabiner/karabiner.json"
            )
            ;;
        ubuntu-desktop)
            required_sources+=(
                "$REPO_DIR/ghostty/config"
                "$REPO_DIR/i3/config"
            )
            ;;
        ubuntu-server|raspberrypi-headless)
            ;;
        *)
            fatal "No source-validation path for $SETUP_PROFILE"
            ;;
    esac

    for source_path in "${required_sources[@]}"; do
        if [ ! -e "$source_path" ]; then
            fatal "Required setup source is missing: $source_path"
        fi
    done
}

link_platform_configs() {
    case "$SETUP_PLATFORM:$SETUP_PROFILE" in
        macos:macos)
            create_common_dirs
            create_macos_dirs
            link_common_configs
            link_macos_configs
            ;;
        linux:ubuntu-desktop)
            create_common_dirs
            create_linux_dirs
            link_common_configs
            link_linux_configs
            ;;
        linux:ubuntu-server|linux:raspberrypi-headless)
            create_cli_dirs
            link_cli_configs
            ;;
        *)
            fatal "No config linking path for $SETUP_PLATFORM/$SETUP_PROFILE"
            ;;
    esac
}
