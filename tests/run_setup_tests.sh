#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0
TEST_TEMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/myterm-tests.XXXXXX")"
trap 'rm -rf "$TEST_TEMP_ROOT"' EXIT

fail() {
    echo "FAIL: $1"
    FAILURES=$((FAILURES + 1))
}

assert_eq() {
    local expected=$1
    local actual=$2
    local label=$3

    if [ "$actual" != "$expected" ]; then
        fail "$label: expected '$expected', got '$actual'"
    fi
}

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$label: expected output to contain '$needle'"
    fi
}

assert_not_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    if [[ "$haystack" == *"$needle"* ]]; then
        fail "$label: expected output not to contain '$needle'"
    fi
}

assert_file_exists() {
    local path=$1
    local label=$2

    if [ ! -f "$path" ]; then
        fail "$label: expected file $path"
    fi
}

assert_path_absent() {
    local path=$1
    local label=$2

    if [ -e "$path" ] || [ -L "$path" ]; then
        fail "$label: expected $path to be absent"
    fi
}

assert_symlink_target() {
    local path=$1
    local expected=$2
    local label=$3

    if [ ! -L "$path" ]; then
        fail "$label: expected symlink $path"
        return
    fi

    assert_eq "$expected" "$(readlink "$path")" "$label target"
}

file_mode() {
    local path=$1

    if [ "$(uname -s)" = Darwin ]; then
        stat -f '%Lp' "$path"
    else
        stat -c '%a' "$path"
    fi
}

run_test() {
    local name=$1
    shift

    echo "TEST: $name"
    "$@"
}

package_plan() {
    local manager=
    local profiles=

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --manager)
                manager=$2
                shift
                ;;
            --profiles)
                profiles=$2
                shift
                ;;
        esac
        shift
    done

    REPO_DIR="$ROOT_DIR" bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; render_package_plan "$REPO_DIR/packages.tsv" "$0" "$1"' "$manager" "$profiles"
}

test_manifest_is_reduced_shell_only_tsv() {
    local invalid_lines

    if [ ! -f "$ROOT_DIR/packages.tsv" ]; then
        fail "packages.tsv should exist"
        return
    fi

    invalid_lines="$(awk -F '\t' '!/^#/ && NF != 0 && NF != 7 { print NR }' "$ROOT_DIR/packages.tsv")"
    assert_eq "" "$invalid_lines" "manifest uses seven fields"
    assert_not_contains "$(sed -n '1,20p' "$ROOT_DIR/packages.tsv")" "pacman" "manifest removes pacman support"
    assert_not_contains "$(sed -n '1,20p' "$ROOT_DIR/packages.tsv")" "dnf" "manifest removes dnf support"
}

test_setup_modules_are_split() {
    local module
    local line_count
    local modules=(
        setup_args.sh
        setup_logging.sh
        setup_platform.sh
        setup_packages.sh
        setup_assets.sh
        setup_files.sh
        setup_codex.sh
        setup_secrets.sh
        setup_shell.sh
    )

    for module in "${modules[@]}"; do
        if [ ! -f "$ROOT_DIR/scripts/$module" ]; then
            fail "scripts/$module should exist"
            continue
        fi

        if ! grep -Fq "scripts/$module" "$ROOT_DIR/scripts/lib_setup.sh"; then
            fail "lib_setup.sh should source scripts/$module"
        fi
    done

    line_count=$(wc -l < "$ROOT_DIR/scripts/lib_setup.sh")
    if [ "$line_count" -gt 200 ]; then
        fail "lib_setup.sh should stay a small loader, got $line_count lines"
    fi

    line_count=$(wc -l < "$ROOT_DIR/scripts/setup_packages.sh")
    if [ "$line_count" -gt 400 ]; then
        fail "setup_packages.sh should stay focused on planning/install orchestration, got $line_count lines"
    fi
}

test_ubuntu_server_plan_skips_gui_packages() {
    local output
    output="$(package_plan --manager apt --profiles ubuntu-server)"

    assert_contains "$output" $'install\tapt\tgit\tgit\tgit' "Ubuntu server includes git"
    assert_contains "$output" $'install\tnpm_global\ttree-sitter-cli\ttree-sitter-cli\ttree-sitter' "Ubuntu server installs tree-sitter through npm"
    assert_contains "$output" $'skip_profile\t-\tghostty\t-\t-' "Ubuntu server skips Ghostty"
    assert_not_contains "$output" $'install\tapt\tneovim\t' "Ubuntu server uses pinned Neovim fallback instead of apt"
    assert_not_contains "$output" $'install\tapt\tnodejs\t' "Ubuntu server uses pinned Node.js instead of apt"
    assert_not_contains "$output" $'install\tapt\tnpm\t' "Ubuntu server gets npm from pinned Node.js"
    assert_not_contains "$output" $'install\tapt\ti3\t' "Ubuntu server does not install i3"
}

test_ubuntu_desktop_plan_is_complete() {
    local output
    output="$(package_plan --manager apt --profiles ubuntu-desktop)"

    assert_contains "$output" $'install\tapt\tghostty\tghostty\tghostty' "Ubuntu desktop includes Ghostty"
    assert_contains "$output" $'install\tapt\ti3\ti3\ti3' "Ubuntu desktop includes i3"
    assert_contains "$output" $'install\tapt\tdmenu\tdmenu\tdmenu_run' "Ubuntu desktop includes dmenu"
    assert_contains "$output" $'install\tapt\ti3status\ti3status\ti3status' "Ubuntu desktop includes i3status"
}

test_raspberrypi_plan_skips_gui_packages() {
    local output
    output="$(package_plan --manager apt --profiles raspberrypi-headless)"

    assert_contains "$output" $'install\tapt\tgit\tgit\tgit' "Raspberry Pi includes git"
    assert_not_contains "$output" $'install\tapt\tghostty\t' "Raspberry Pi does not install Ghostty"
    assert_not_contains "$output" $'install\tapt\ti3\t' "Raspberry Pi does not install i3"
}

test_macos_plan_keeps_casks_explicit() {
    local output
    output="$(package_plan --manager brew --profiles macos)"

    assert_contains "$output" $'install\tbrew\tgit\tgit\tgit' "macOS plan includes brew formula"
    assert_contains "$output" $'install\tbrew_cask\tghostty\tghostty\tghostty' "macOS plan includes Ghostty as cask"
    assert_not_contains "$output" $'install\tapt\t' "macOS plan does not include apt packages"
}

detect_platform() {
    local os_id=$1
    local graphical=$2
    local raspberry_pi=$3

    REPO_DIR="$ROOT_DIR" \
    MYTERM_TEST_UNAME=Linux \
    MYTERM_TEST_PACKAGE_MANAGER=apt \
    MYTERM_TEST_OS_ID="$os_id" \
    MYTERM_TEST_ARCH="$([ "$raspberry_pi" = 1 ] && printf aarch64 || printf x86_64)" \
    MYTERM_TEST_GRAPHICAL="$graphical" \
    MYTERM_TEST_RASPBERRY_PI="$raspberry_pi" \
    bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; detect_setup_platform; printf "%s|%s|%s|%s" "$SETUP_PLATFORM" "$PACKAGE_MANAGER" "$SETUP_PROFILE" "$ACTIVE_PACKAGE_PROFILES"'
}

test_detects_supported_linux_profiles() {
    assert_eq "linux|apt|ubuntu-desktop|ubuntu-desktop" "$(detect_platform ubuntu 1 0)" "Ubuntu desktop detection"
    assert_eq "linux|apt|ubuntu-server|ubuntu-server" "$(detect_platform ubuntu 0 0)" "Ubuntu server detection"
    assert_eq "linux|apt|raspberrypi-headless|raspberrypi-headless" "$(detect_platform raspbian 0 1)" "Raspberry Pi detection"
}

test_rejects_unsupported_linux_distribution() {
    local home="$TEST_TEMP_ROOT/unsupported-home"
    local log_dir="$TEST_TEMP_ROOT/unsupported-log"
    local output
    local status
    mkdir -p "$home"

    set +e
    output="$(
        HOME="$home" \
        SETUP_LOG_DIR="$log_dir" \
        MYTERM_TEST_UNAME=Linux \
        MYTERM_TEST_PACKAGE_MANAGER=apt \
        MYTERM_TEST_OS_ID=fedora \
        MYTERM_TEST_GRAPHICAL=0 \
        MYTERM_TEST_RASPBERRY_PI=0 \
        bash "$ROOT_DIR/setup.sh" --no-install --no-shell-change 2>&1
    )"
    status=$?
    set +e

    assert_eq "1" "$status" "unsupported Linux exit status"
    assert_contains "$output" "Unsupported Linux distribution 'fedora'" "unsupported Linux error"
    assert_file_exists "$log_dir/setup.log" "unsupported Linux failure log"
    assert_contains "$(cat "$log_dir/setup.log")" "FATAL Unsupported Linux distribution" "unsupported Linux logged"
}

test_rejects_graphical_raspberry_pi() {
    local home="$TEST_TEMP_ROOT/pi-gui-home"
    local output
    local status
    mkdir -p "$home"

    set +e
    output="$(
        HOME="$home" \
        SETUP_LOG_DIR="$TEST_TEMP_ROOT/pi-gui-log" \
        MYTERM_TEST_UNAME=Linux \
        MYTERM_TEST_PACKAGE_MANAGER=apt \
        MYTERM_TEST_OS_ID=raspbian \
        MYTERM_TEST_ARCH=aarch64 \
        MYTERM_TEST_GRAPHICAL=1 \
        MYTERM_TEST_RASPBERRY_PI=1 \
        bash "$ROOT_DIR/setup.sh" --no-install --no-shell-change 2>&1
    )"
    status=$?
    set +e

    assert_eq "1" "$status" "graphical Raspberry Pi exit status"
    assert_contains "$output" "Raspberry Pi setup supports headless systems only" "graphical Raspberry Pi error"
}

test_rejects_32bit_raspberry_pi() {
    local home="$TEST_TEMP_ROOT/pi-32bit-home"
    local output
    local status
    mkdir -p "$home"

    set +e
    output="$(
        HOME="$home" \
        SETUP_LOG_DIR="$TEST_TEMP_ROOT/pi-32bit-log" \
        MYTERM_TEST_UNAME=Linux \
        MYTERM_TEST_PACKAGE_MANAGER=apt \
        MYTERM_TEST_OS_ID=raspbian \
        MYTERM_TEST_ARCH=armv7l \
        MYTERM_TEST_GRAPHICAL=0 \
        MYTERM_TEST_RASPBERRY_PI=1 \
        bash "$ROOT_DIR/setup.sh" --no-install --no-shell-change 2>&1
    )"
    status=$?
    set +e

    assert_eq "1" "$status" "32-bit Raspberry Pi exit status"
    assert_contains "$output" "Unsupported Linux architecture 'armv7l'" "32-bit Raspberry Pi error"
}

run_linux_e2e() {
    local case_name=$1
    local os_id=$2
    local graphical=$3
    local raspberry_pi=$4
    local home="$TEST_TEMP_ROOT/$case_name/home"
    local log_dir="$TEST_TEMP_ROOT/$case_name/log"
    local output_file="$TEST_TEMP_ROOT/$case_name/output"
    local status_file="$TEST_TEMP_ROOT/$case_name/status"
    mkdir -p "$home"

    set +e
    HOME="$home" \
    SETUP_LOG_DIR="$log_dir" \
    MYTERM_TEST_UNAME=Linux \
    MYTERM_TEST_PACKAGE_MANAGER=apt \
    MYTERM_TEST_OS_ID="$os_id" \
    MYTERM_TEST_ARCH="$([ "$raspberry_pi" = 1 ] && printf aarch64 || printf x86_64)" \
    MYTERM_TEST_GRAPHICAL="$graphical" \
    MYTERM_TEST_RASPBERRY_PI="$raspberry_pi" \
    bash "$ROOT_DIR/setup.sh" --no-install --no-shell-change > "$output_file" 2>&1
    printf '%s' "$?" > "$status_file"
    set +e
}

assert_e2e_common() {
    local case_name=$1
    local expected_profile=$2
    local home="$TEST_TEMP_ROOT/$case_name/home"
    local log_dir="$TEST_TEMP_ROOT/$case_name/log"

    assert_eq "0" "$(cat "$TEST_TEMP_ROOT/$case_name/status")" "$case_name setup status"
    assert_symlink_target "$home/.zshrc" "$ROOT_DIR/zsh/.zshrc" "$case_name zsh config"
    assert_symlink_target "$home/.config/nvim/init.lua" "$ROOT_DIR/nvim/init.lua" "$case_name Neovim config"
    assert_file_exists "$home/.codex/config.toml" "$case_name Codex config"
    assert_file_exists "$home/.secrets" "$case_name secrets template"
    assert_eq "600" "$(file_mode "$home/.secrets")" "$case_name secrets permissions"
    assert_contains "$(cat "$log_dir/setup-state")" "profile=$expected_profile" "$case_name state profile"
    assert_contains "$(cat "$log_dir/setup-state")" "status=complete" "$case_name completed state"
}

test_e2e_ubuntu_desktop_installs_configs() {
    local case_name=ubuntu-desktop
    local home="$TEST_TEMP_ROOT/$case_name/home"
    run_linux_e2e "$case_name" ubuntu 1 0

    assert_e2e_common "$case_name" ubuntu-desktop
    assert_symlink_target "$home/.config/i3/config" "$ROOT_DIR/i3/config" "Ubuntu desktop i3 config"
    assert_symlink_target "$home/.config/ghostty/config" "$ROOT_DIR/ghostty/config" "Ubuntu desktop Ghostty config"
    assert_path_absent "$home/.config/aerospace/aerospace.toml" "Ubuntu desktop macOS config"
}

test_e2e_ubuntu_server_installs_cli_configs_only() {
    local case_name=ubuntu-server
    local home="$TEST_TEMP_ROOT/$case_name/home"
    run_linux_e2e "$case_name" ubuntu 0 0

    assert_e2e_common "$case_name" ubuntu-server
    assert_path_absent "$home/.config/i3/config" "Ubuntu server i3 config"
    assert_path_absent "$home/.config/ghostty/config" "Ubuntu server Ghostty config"
}

test_e2e_raspberrypi_installs_cli_configs_only() {
    local case_name=raspberrypi
    local home="$TEST_TEMP_ROOT/$case_name/home"
    run_linux_e2e "$case_name" raspbian 0 1

    assert_e2e_common "$case_name" raspberrypi-headless
    assert_path_absent "$home/.config/i3/config" "Raspberry Pi i3 config"
    assert_path_absent "$home/.config/ghostty/config" "Raspberry Pi Ghostty config"
}

test_e2e_ubuntu_server_install_orchestration() {
    local case_dir="$TEST_TEMP_ROOT/ubuntu-server-install"
    local home="$case_dir/home"
    local fake_bin="$case_dir/bin"
    local command_log="$case_dir/commands.log"
    local output
    local status
    mkdir -p "$home/.powerlevel10k" "$home/.local/opt/node-v22.23.1/bin" "$fake_bin"

    # shellcheck disable=SC2016
    printf '%s\n' \
        '#!/usr/bin/env bash' \
        'printf "sudo %s\n" "$*" >> "$MYTERM_TEST_COMMAND_LOG"' \
        > "$fake_bin/sudo"
    chmod +x "$fake_bin/sudo"
    printf '%s\n' '#!/usr/bin/env bash' 'echo "NVIM v0.12.4"' > "$fake_bin/nvim"
    chmod +x "$fake_bin/nvim"
    printf '%s\n' '#!/usr/bin/env bash' 'echo "v22.23.1"' > "$fake_bin/node"
    chmod +x "$fake_bin/node"
    # shellcheck disable=SC2016
    printf '%s\n' '#!/usr/bin/env bash' 'printf "npm %s\n" "$*" >> "$MYTERM_TEST_COMMAND_LOG"' > "$fake_bin/npm"
    chmod +x "$fake_bin/npm"
    cp "$fake_bin/node" "$home/.local/opt/node-v22.23.1/bin/node"
    cp "$fake_bin/npm" "$home/.local/opt/node-v22.23.1/bin/npm"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$home/.local/opt/node-v22.23.1/bin/npx"
    printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$home/.local/opt/node-v22.23.1/bin/corepack"
    chmod +x "$home/.local/opt/node-v22.23.1/bin/"*

    set +e
    output="$(
        HOME="$home" \
        PATH="$fake_bin:$PATH" \
        SETUP_LOG_DIR="$case_dir/log" \
        MYTERM_TEST_COMMAND_LOG="$command_log" \
        MYTERM_TEST_MISSING_COMMANDS=git,zsh,rg,fd,fdfind,fzf,tree-sitter,curl \
        MYTERM_TEST_UNAME=Linux \
        MYTERM_TEST_PACKAGE_MANAGER=apt \
        MYTERM_TEST_OS_ID=ubuntu \
        MYTERM_TEST_ARCH=x86_64 \
        MYTERM_TEST_GRAPHICAL=0 \
        MYTERM_TEST_RASPBERRY_PI=0 \
        bash "$ROOT_DIR/setup.sh" --no-shell-change 2>&1
    )"
    status=$?
    set +e

    assert_eq "0" "$status" "Ubuntu server install-mode status"
    assert_contains "$(cat "$command_log")" "sudo apt-get update -y" "Ubuntu server apt update"
    assert_not_contains "$(cat "$command_log")" "neovim-ppa" "Ubuntu server skips moving Neovim repository"
    assert_contains "$(cat "$command_log")" "sudo apt-get install -y" "Ubuntu server package install"
    assert_contains "$(cat "$command_log")" "git" "Ubuntu server installs missing git"
    assert_contains "$(cat "$command_log")" "npm install -g tree-sitter-cli" "Ubuntu server npm tool install"
    assert_not_contains "$(cat "$command_log")" "sudo npm" "Ubuntu server keeps npm tools user-owned"
    assert_not_contains "$(cat "$command_log")" "ghostty-ubuntu" "Ubuntu server skips Ghostty repository"
    assert_not_contains "$output" "deb.nodesource.com" "Ubuntu server skips NodeSource bootstrap"
    assert_contains "$output" "Setup complete" "Ubuntu server reports completion"
    assert_symlink_target "$home/.zshrc" "$ROOT_DIR/zsh/.zshrc" "Ubuntu server install-mode zsh config"
    assert_contains "$(cat "$case_dir/log/setup-state")" "status=complete" "Ubuntu server install-mode completed state"
}

test_linux_neovim_release_is_pinned() {
    local output
    local status

    output="$(
        REPO_DIR="$ROOT_DIR" bash -c '
            source "$REPO_DIR/scripts/lib_setup.sh"
            printf "%s|" "$NEOVIM_VERSION"
            linux_neovim_asset x86_64
            printf "|"
            linux_neovim_asset arm64
        '
    )"
    assert_contains "$output" "v0.12.4|nvim-linux-x86_64.tar.gz|012bf3fcac5ade43914df3f174668bf64d05e049a4f032a388c027b1ebd78628" "pinned x86_64 Neovim release"
    assert_contains "$output" "nvim-linux-arm64.tar.gz|ceb7e88c6b681f0515d135dcdfad54f5eb4373b25ce6172197cd9a69c758063f" "pinned arm64 Neovim release"

    set +e
    output="$(REPO_DIR="$ROOT_DIR" bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; linux_neovim_asset armv7l' 2>&1)"
    status=$?
    set +e
    assert_eq "1" "$status" "unsupported Neovim architecture status"
    assert_contains "$output" "Unsupported Linux architecture 'armv7l'" "unsupported Neovim architecture message"
}

test_linux_node_release_is_pinned() {
    local output
    local status

    output="$(
        REPO_DIR="$ROOT_DIR" bash -c '
            source "$REPO_DIR/scripts/lib_setup.sh"
            printf "%s|" "$NODE_VERSION"
            linux_node_asset x86_64
            printf "|"
            linux_node_asset arm64
        '
    )"
    assert_contains "$output" "v22.23.1|node-v22.23.1-linux-x64.tar.gz|7a8cb04b4a1df4eaf432125324b81b29a088e73570a23259a8de1c65d07fc129" "pinned x86_64 Node.js release"
    assert_contains "$output" "node-v22.23.1-linux-arm64.tar.gz|543fa39e57d4c07855939459a323f4deb9a79dd1bb45e6e99458b0f2de10db8d" "pinned arm64 Node.js release"

    set +e
    output="$(REPO_DIR="$ROOT_DIR" bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; linux_node_asset armv7l' 2>&1)"
    status=$?
    set +e
    assert_eq "1" "$status" "unsupported Node.js architecture status"
    assert_contains "$output" "Unsupported Linux architecture 'armv7l'" "unsupported Node.js architecture message"
}

test_powerlevel10k_install_is_pinned() {
    local output
    local function_body

    output="$(REPO_DIR="$ROOT_DIR" bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; printf "%s" "$POWERLEVEL10K_COMMIT"')"
    assert_eq "604f19a9eaa18e76db2e60b8d446d5f879065f90" "$output" "pinned Powerlevel10k commit"

    function_body="$(sed -n '/ensure_powerlevel10k()/,/^}/p' "$ROOT_DIR/scripts/setup_shell.sh")"
    # shellcheck disable=SC2016
    assert_contains "$function_body" 'checkout --detach "$POWERLEVEL10K_COMMIT"' "Powerlevel10k pinned checkout"
    # shellcheck disable=SC2016
    assert_contains "$function_body" 'mv "$checkout_dir" "$HOME/.powerlevel10k"' "Powerlevel10k atomic install"
}

test_dry_run_does_not_require_planned_commands() {
    local output
    local status

    set +e
    output="$(
        REPO_DIR="$ROOT_DIR" bash -c '
            source "$REPO_DIR/scripts/lib_setup.sh"
            DRY_RUN=true
            NPM_GLOBAL_PACKAGES=(tree-sitter-cli)
            command_exists() { return 1; }
            install_package_groups
            SETUP_PLATFORM=linux
            NO_SHELL_CHANGE=false
            set_linux_shell
        ' 2>&1
    )"
    status=$?
    set +e

    assert_eq "0" "$status" "fresh-machine dry-run status"
    assert_contains "$output" "Would run: npm install -g tree-sitter-cli" "dry-run npm plan"
    assert_contains "$output" "Would change default shell to Zsh after installation" "dry-run shell plan"
}

test_early_fatal_initializes_logging() {
    local home="$TEST_TEMP_ROOT/early-fatal/home"
    local log_dir="$TEST_TEMP_ROOT/early-fatal/log"
    local output
    local status
    mkdir -p "$home"

    set +e
    output="$(
        HOME="$home" \
        SETUP_LOG_DIR="$log_dir" \
        MYTERM_TEST_UNAME=Darwin \
        bash "$ROOT_DIR/setup.sh" --profile headless --no-install --no-shell-change 2>&1
    )"
    status=$?
    set +e

    assert_eq "2" "$status" "invalid profile exit status"
    assert_not_contains "$output" "No such file or directory" "invalid profile logging error"
    assert_file_exists "$log_dir/setup.log" "invalid profile log"
    assert_contains "$(cat "$log_dir/setup.log")" "FATAL --profile headless is not valid on macOS" "invalid profile logged"
    assert_contains "$(cat "$log_dir/setup-state")" "status=failed" "invalid profile failed state"
}

test_run_step_captures_command_output() {
    local log_dir="$TEST_TEMP_ROOT/run-step-log"
    local child_script="$TEST_TEMP_ROOT/run-step-child.sh"
    local output
    local status

    printf '%s\n' '#!/usr/bin/env bash' 'echo child-diagnostic >&2' 'exit 9' > "$child_script"
    chmod +x "$child_script"

    set +e
    output="$(
        REPO_DIR="$ROOT_DIR" \
        SETUP_LOG_DIR="$log_dir" \
        CHILD_SCRIPT="$child_script" \
        bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; init_setup_logging; run_step "Intentional failure" "$CHILD_SCRIPT"' 2>&1
    )"
    status=$?
    set +e

    assert_eq "9" "$status" "run_step preserves exit status"
    assert_contains "$output" "child-diagnostic" "run_step shows child diagnostic"
    assert_contains "$(cat "$log_dir/setup.log")" "child-diagnostic" "run_step logs child diagnostic"
    assert_contains "$(cat "$log_dir/setup-state")" "failed_exit_code=9" "run_step records exit status"
    assert_contains "$(cat "$log_dir/setup-state")" "status=failed" "run_step records failed state"
}

test_font_check_is_idempotent_with_pipefail() {
    local output
    local status

    set +e
    output="$(
        REPO_DIR="$ROOT_DIR" HOME="$TEST_TEMP_ROOT/font-home" bash -o pipefail -c '
            source "$REPO_DIR/scripts/lib_setup.sh"
            DRY_RUN=false
            SETUP_PROFILE=ubuntu-desktop
            ensure_dir() { :; }
            fc-list() {
                local i
                i=0
                while [ "$i" -lt 5000 ]; do
                    echo "MesloLGS NF Regular"
                    i=$((i + 1))
                done
            }
            run_step() { echo "unexpected-install:$1"; }
            install_linux_font
        ' 2>&1
    )"
    status=$?
    set +e

    assert_eq "0" "$status" "font idempotence status"
    assert_contains "$output" "Meslo Nerd Font is already installed" "font detection"
    assert_not_contains "$output" "unexpected-install" "font reinstall"
}

test_linux_font_release_is_pinned() {
    local output

    output="$(
        REPO_DIR="$ROOT_DIR" bash -c '
            source "$REPO_DIR/scripts/lib_setup.sh"
            printf "%s|%s" "$NERD_FONT_VERSION" "$MESLO_SHA256"
        '
    )"

    assert_eq "v3.4.0|13b502ac8c2bd9d3161018064560e23cd42b175bb730780a270975265a19ad57" "$output" "pinned Meslo release"
    assert_not_contains "$(sed -n '/install_linux_font()/,/^}/p' "$ROOT_DIR/scripts/setup_assets.sh")" "/releases/latest/" "Meslo download is not moving latest"
}

test_safe_commit_redacts_detected_credentials() {
    local repo="$TEST_TEMP_ROOT/safe-commit-repo"
    local output
    local status
    mkdir -p "$repo"
    git -C "$repo" init -q
    printf '%s\n' 'password=redaction-test-value' > "$repo/config.txt"
    git -C "$repo" add config.txt

    set +e
    output="$(cd "$repo" && bash "$ROOT_DIR/codex/scripts/safe_commit.sh" 2>&1)"
    status=$?
    set +e

    assert_eq "1" "$status" "safe commit blocks credential"
    assert_contains "$output" "config.txt:1" "safe commit reports location"
    assert_not_contains "$output" "redaction-test-value" "safe commit redacts credential"
}

test_common_private_key_names_are_ignored() {
    local key_name

    for key_name in id_ed25519 id_ecdsa id_dsa; do
        if ! git -C "$ROOT_DIR" check-ignore --no-index -q "$key_name"; then
            fail ".gitignore should ignore $key_name"
        fi
    done
}

test_neovim_lsp_configuration_executes() {
    local output
    local status

    if ! command -v nvim > /dev/null 2>&1; then
        fail "nvim is required for the LSP configuration test"
        return
    fi

    set +e
    output="$(REPO_DIR="$ROOT_DIR" NVIM_LOG_FILE="$TEST_TEMP_ROOT/nvim.log" nvim --headless -u NONE -i NONE -n -c "luafile $ROOT_DIR/tests/nvim_lsp_spec.lua" 2>&1)"
    status=$?
    set +e

    assert_eq "0" "$status" "Neovim LSP configuration status"
    assert_contains "$output" "Neovim LSP configuration test passed" "Neovim LSP configuration result"
}

run_test "manifest is reduced shell-only TSV" test_manifest_is_reduced_shell_only_tsv
run_test "setup modules are split" test_setup_modules_are_split
run_test "Ubuntu server skips GUI packages" test_ubuntu_server_plan_skips_gui_packages
run_test "Ubuntu desktop package plan is complete" test_ubuntu_desktop_plan_is_complete
run_test "Raspberry Pi skips GUI packages" test_raspberrypi_plan_skips_gui_packages
run_test "macOS keeps casks explicit" test_macos_plan_keeps_casks_explicit
run_test "detects supported Linux profiles" test_detects_supported_linux_profiles
run_test "rejects unsupported Linux distributions" test_rejects_unsupported_linux_distribution
run_test "rejects graphical Raspberry Pi" test_rejects_graphical_raspberry_pi
run_test "rejects 32-bit Raspberry Pi" test_rejects_32bit_raspberry_pi
run_test "Ubuntu desktop end-to-end config install" test_e2e_ubuntu_desktop_installs_configs
run_test "Ubuntu server end-to-end config install" test_e2e_ubuntu_server_installs_cli_configs_only
run_test "Raspberry Pi end-to-end config install" test_e2e_raspberrypi_installs_cli_configs_only
run_test "Ubuntu server end-to-end install orchestration" test_e2e_ubuntu_server_install_orchestration
run_test "Linux Neovim release is pinned" test_linux_neovim_release_is_pinned
run_test "Linux Node.js release is pinned" test_linux_node_release_is_pinned
run_test "Powerlevel10k install is pinned" test_powerlevel10k_install_is_pinned
run_test "dry-run tolerates missing planned commands" test_dry_run_does_not_require_planned_commands
run_test "early fatal initializes logging" test_early_fatal_initializes_logging
run_test "run_step captures command output" test_run_step_captures_command_output
run_test "font check is idempotent" test_font_check_is_idempotent_with_pipefail
run_test "Linux font release is pinned" test_linux_font_release_is_pinned
run_test "safe commit redacts credentials" test_safe_commit_redacts_detected_credentials
run_test "common private key names are ignored" test_common_private_key_names_are_ignored
run_test "Neovim LSP configuration executes" test_neovim_lsp_configuration_executes

if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES test failure(s)"
    exit 1
fi

echo "All setup tests passed."
