#!/usr/bin/env bash

# Pinned Linux runtime assets, compatibility links, and desktop font setup.
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

NEOVIM_VERSION=v0.12.4
NEOVIM_X86_64_SHA256=012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628
NEOVIM_ARM64_SHA256=ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f

linux_neovim_asset() {
    local architecture=$1

    case "$architecture" in
        x86_64)
            printf '%s|%s\n' "nvim-linux-x86_64.tar.gz" "$NEOVIM_X86_64_SHA256"
            ;;
        arm64)
            printf '%s|%s\n' "nvim-linux-arm64.tar.gz" "$NEOVIM_ARM64_SHA256"
            ;;
        *)
            fatal "Unsupported Linux architecture '$architecture'. Supported architectures are x86_64 and arm64."
            ;;
    esac
}

neovim_version_supported() {
    local version_line=$1
    local version
    local major
    local minor

    version=${version_line#NVIM v}
    major=${version%%.*}
    version=${version#*.}
    minor=${version%%.*}

    [[ "$major" =~ ^[0-9]+$ ]] || return 1
    [[ "$minor" =~ ^[0-9]+$ ]] || return 1
    [ "$major" -gt 0 ] || [ "$minor" -ge 11 ]
}

verify_sha256() {
    local path=$1
    local expected=$2
    local actual

    actual="$(sha256sum "$path" | awk '{print $1}')"
    if [ "$actual" != "$expected" ]; then
        echo "SHA-256 mismatch for $path: expected $expected, got $actual" >&2
        return 1
    fi
}

ensure_linux_neovim() {
    local version_line
    local asset_info
    local asset
    local expected_sha256
    local archive
    local install_dir
    local download_url

    if command_exists nvim; then
        version_line="$(nvim --version 2> /dev/null | sed -n '1p')" || version_line=
        if neovim_version_supported "$version_line"; then
            echo "Neovim is already compatible: $version_line"
            return 0
        fi
        echo "Installed Neovim is older than 0.11; installing $NEOVIM_VERSION locally."
    else
        echo "Installing Neovim $NEOVIM_VERSION locally..."
    fi

    asset_info="$(linux_neovim_asset "$LINUX_ARCH")"
    asset=${asset_info%%|*}
    expected_sha256=${asset_info#*|}
    archive="$SETUP_LOG_DIR/$asset"
    install_dir="$HOME/.local/opt/nvim-$NEOVIM_VERSION"
    download_url="https://github.com/neovim/neovim/releases/download/$NEOVIM_VERSION/$asset"

    ensure_dir "$HOME/.local/opt"
    ensure_dir "$install_dir"
    run_step "Download Neovim $NEOVIM_VERSION" curl -fL "$download_url" -o "$archive"
    run_step "Verify Neovim $NEOVIM_VERSION checksum" verify_sha256 "$archive" "$expected_sha256"
    run_step "Extract Neovim $NEOVIM_VERSION" tar -xzf "$archive" --strip-components=1 -C "$install_dir"
    link_file "$install_dir/bin/nvim" "$HOME/.local/bin/nvim"
    run_step "Remove Neovim archive" rm -f "$archive"
    export PATH="$HOME/.local/bin:$PATH"
}

NODE_VERSION=v22.23.1
NODE_X86_64_SHA256=7a8cb04b4a1df4eaf432125324b81b29a088e73570a23259a8de1c65d07fc129
NODE_ARM64_SHA256=543fa39e57d4c07855939459a323f4deb9a79dd1bb45e6e99458b0f2de10db8d

linux_node_asset() {
    local architecture=$1

    case "$architecture" in
        x86_64)
            printf '%s|%s\n' "node-$NODE_VERSION-linux-x64.tar.gz" "$NODE_X86_64_SHA256"
            ;;
        arm64)
            printf '%s|%s\n' "node-$NODE_VERSION-linux-arm64.tar.gz" "$NODE_ARM64_SHA256"
            ;;
        *)
            fatal "Unsupported Linux architecture '$architecture'. Supported architectures are x86_64 and arm64."
            ;;
    esac
}

node_version_supported() {
    local version=$1
    local major

    version=${version#v}
    major=${version%%.*}
    [[ "$major" =~ ^[0-9]+$ ]] || return 1
    [ "$major" -ge 22 ]
}

ensure_linux_node() {
    local version
    local asset_info
    local asset
    local expected_sha256
    local archive
    local install_dir
    local download_url
    local binary
    local install_dir="$HOME/.local/opt/node-$NODE_VERSION"

    ensure_dir "$HOME/.local/bin"

    if [ -x "$install_dir/bin/node" ] \
        && [ -x "$install_dir/bin/npm" ] \
        && [ -x "$install_dir/bin/npx" ] \
        && [ -x "$install_dir/bin/corepack" ]; then
        version="$("$install_dir/bin/node" --version 2> /dev/null)" || version=
        if node_version_supported "$version"; then
            echo "Pinned Node.js is already installed: $version"
            for binary in node npm npx corepack; do
                link_file "$install_dir/bin/$binary" "$HOME/.local/bin/$binary"
            done
            export PATH="$HOME/.local/bin:$PATH"
            return 0
        fi
    fi

    echo "Installing Node.js $NODE_VERSION locally..."

    asset_info="$(linux_node_asset "$LINUX_ARCH")"
    asset=${asset_info%%|*}
    expected_sha256=${asset_info#*|}
    archive="$SETUP_LOG_DIR/$asset"
    download_url="https://nodejs.org/download/release/$NODE_VERSION/$asset"

    ensure_dir "$HOME/.local/opt"
    ensure_dir "$install_dir"
    run_step "Download Node.js $NODE_VERSION" curl -fL "$download_url" -o "$archive"
    run_step "Verify Node.js $NODE_VERSION checksum" verify_sha256 "$archive" "$expected_sha256"
    run_step "Extract Node.js $NODE_VERSION" tar -xzf "$archive" --strip-components=1 -C "$install_dir"
    for binary in node npm npx corepack; do
        link_file "$install_dir/bin/$binary" "$HOME/.local/bin/$binary"
    done
    run_step "Remove Node.js archive" rm -f "$archive"
    export PATH="$HOME/.local/bin:$PATH"
}

NERD_FONT_VERSION=v3.4.0
MESLO_SHA256=13b502ac8c2bd9d3161018064560e23cd42b175bb730780a270975265a19ad57

install_linux_font() {
    if [ "$SETUP_PROFILE" != ubuntu-desktop ]; then
        return 0
    fi

    echo "Installing Meslo Nerd Font..."
    local font_dir="$HOME/.local/share/fonts"
    local archive="$SETUP_LOG_DIR/Meslo-$NERD_FONT_VERSION.zip"
    local download_url="https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONT_VERSION/Meslo.zip"

    ensure_dir "$font_dir"
    if [ "$DRY_RUN" = true ]; then
        echo "  -> Would check whether Meslo Nerd Font is installed."
        run_step "Download Meslo Nerd Font $NERD_FONT_VERSION" wget -qO "$archive" "$download_url"
        run_step "Verify Meslo Nerd Font $NERD_FONT_VERSION checksum" verify_sha256 "$archive" "$MESLO_SHA256"
        run_step "Install Meslo Nerd Font files" unzip -qo "$archive" -d "$font_dir"
        run_cmd fc-cache -fv
        run_step "Remove Meslo Nerd Font archive" rm -f "$archive"
        return 0
    fi

    if grep -qi "Meslo" < <(fc-list); then
        echo "  -> Meslo Nerd Font is already installed."
        return 0
    fi

    run_step "Download Meslo Nerd Font $NERD_FONT_VERSION" wget -qO "$archive" "$download_url"
    run_step "Verify Meslo Nerd Font $NERD_FONT_VERSION checksum" verify_sha256 "$archive" "$MESLO_SHA256"
    run_step "Install Meslo Nerd Font files" unzip -qo "$archive" -d "$font_dir"
    run_step "Refresh font cache" fc-cache -fv
    run_step "Remove Meslo Nerd Font archive" rm -f "$archive"
}

run_platform_post_install() {
    if [ "$NO_INSTALL" = true ]; then
        return 0
    fi

    if [ "$SETUP_PLATFORM" = linux ]; then
        ensure_linux_neovim
        install_linux_fd_compat
        install_linux_font
    fi
}
