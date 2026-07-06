#!/usr/bin/env bash

set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILURES=0

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

test_manifest_is_shell_only_tsv() {
    if [ ! -f "$ROOT_DIR/packages.tsv" ]; then
        fail "packages.tsv should exist"
    fi
    if [ -f "$ROOT_DIR/packages.toml" ]; then
        fail "packages.toml should be removed"
    fi
    if [ -f "$ROOT_DIR/scripts/package_plan.py" ]; then
        fail "Python package planner should be removed"
    fi
}

test_headless_apt_skips_gui_packages() {
    local output
    output="$(package_plan --manager apt --profiles linux-headless)"

    assert_contains "$output" $'install\tapt\tgit\tgit\tgit' "headless apt includes git"
    assert_contains "$output" $'install\tnpm_global\ttree-sitter-cli\ttree-sitter-cli\ttree-sitter' "headless apt installs tree-sitter through npm"
    assert_contains "$output" $'skip_profile\t-\tghostty\t-\t-' "headless apt skips Ghostty by profile"
    assert_not_contains "$output" $'install\tapt\tghostty\tghostty' "headless apt does not install Ghostty"
    assert_not_contains "$output" $'install\tapt\ti3\ti3' "headless apt does not install i3"
}

test_macos_plan_keeps_casks_explicit() {
    local output
    output="$(package_plan --manager brew --profiles macos)"

    assert_contains "$output" $'install\tbrew\tgit\tgit\tgit' "macOS plan includes brew formula"
    assert_contains "$output" $'install\tbrew_cask\tghostty\tghostty\tghostty' "macOS plan includes Ghostty as cask"
    assert_contains "$output" $'install\tbrew_cask\taerospace\tnikitabobko/tap/aerospace\taerospace' "macOS plan includes AeroSpace as cask"
    assert_not_contains "$output" $'install\tapt\t' "macOS plan does not include apt packages"
}

test_arch_reports_unsupported_desktop_packages() {
    local output
    output="$(package_plan --manager pacman --profiles linux-desktop)"

    assert_contains "$output" $'install\tpacman\ti3\ti3-wm\ti3' "Arch desktop includes i3 mapping"
    assert_contains "$output" $'unsupported\t-\tghostty\t-\t-' "Arch desktop reports Ghostty unsupported"
}

test_detects_linux_headless_profile() {
    local output
    output="$(
        REPO_DIR="$ROOT_DIR" \
        MYTERM_TEST_UNAME=Linux \
        MYTERM_TEST_PACKAGE_MANAGER=apt \
        MYTERM_TEST_GRAPHICAL=0 \
        bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; detect_setup_platform; printf "%s|%s|%s|%s" "$SETUP_PLATFORM" "$PACKAGE_MANAGER" "$SETUP_PROFILE" "$ACTIVE_PACKAGE_PROFILES"'
    )"

    assert_eq "linux|apt|linux-headless|linux-headless" "$output" "Linux headless detection"
}

test_run_step_logs_failures() {
    local temp_dir
    local output
    local status
    temp_dir="$(mktemp -d)"

    set +e
    output="$(
        REPO_DIR="$ROOT_DIR" \
        SETUP_LOG_DIR="$temp_dir" \
        bash -c 'source "$REPO_DIR/scripts/lib_setup.sh"; init_setup_logging; run_step "Intentional failure" false' 2>&1
    )"
    status=$?
    set +e

    if [ "$status" -eq 0 ]; then
        fail "run_step failure should return non-zero"
    fi

    assert_contains "$output" "ERROR: Intentional failure failed" "run_step prints failure"
    if [ ! -f "$temp_dir/setup.log" ]; then
        fail "run_step should write setup.log"
    else
        assert_contains "$(cat "$temp_dir/setup.log")" "FAIL Intentional failure" "run_step logs failure"
    fi
    if [ ! -f "$temp_dir/setup-state" ]; then
        fail "run_step should write setup-state"
    else
        assert_contains "$(cat "$temp_dir/setup-state")" "failed_step=Intentional failure" "run_step records failed step"
    fi
}

test_unified_setup_dry_run_headless_path() {
    local temp_dir
    local output
    temp_dir="$(mktemp -d)"

    output="$(
        HOME="$temp_dir/home" \
        MYTERM_TEST_UNAME=Linux \
        MYTERM_TEST_PACKAGE_MANAGER=apt \
        MYTERM_TEST_GRAPHICAL=0 \
        bash "$ROOT_DIR/setup.sh" --dry-run --no-install --no-shell-change 2>&1
    )"

    assert_contains "$output" "Bootstrapping 'myterm' environment (Linux headless" "unified setup reports Linux headless"
    assert_contains "$output" "Linking CLI configuration files" "unified setup uses CLI config path"
    assert_not_contains "$output" "Linking macOS configuration files" "unified setup does not use macOS config path"
}

run_test "manifest is shell-only TSV" test_manifest_is_shell_only_tsv
run_test "headless apt skips GUI packages" test_headless_apt_skips_gui_packages
run_test "macOS keeps casks explicit" test_macos_plan_keeps_casks_explicit
run_test "Arch reports unsupported desktop packages" test_arch_reports_unsupported_desktop_packages
run_test "detects Linux headless profile" test_detects_linux_headless_profile
run_test "run_step logs failures" test_run_step_logs_failures
run_test "unified setup dry-run headless path" test_unified_setup_dry_run_headless_path

if [ "$FAILURES" -gt 0 ]; then
    echo "$FAILURES test failure(s)"
    exit 1
fi

echo "All setup tests passed."
