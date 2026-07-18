#!/usr/bin/env bash

# Platform, distribution, package manager, and profile detection.
# shellcheck disable=SC2034
SETUP_PLATFORM=
PACKAGE_MANAGER=
SETUP_PROFILE=
ACTIVE_PACKAGE_PROFILES=
LINUX_OS_ID=
LINUX_ARCH=
IS_RASPBERRY_PI=false

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

read_linux_os_id() {
    local key
    local value

    if [ -n "${MYTERM_TEST_OS_ID:-}" ]; then
        printf '%s\n' "$MYTERM_TEST_OS_ID"
        return 0
    fi

    if [ ! -r /etc/os-release ]; then
        fatal "Cannot identify Linux distribution because /etc/os-release is unavailable."
    fi

    while IFS='=' read -r key value; do
        if [ "$key" = ID ]; then
            value=${value#\"}
            value=${value%\"}
            value=${value#\'}
            value=${value%\'}
            printf '%s\n' "$value"
            return 0
        fi
    done < /etc/os-release

    fatal "Cannot identify Linux distribution because /etc/os-release has no ID field."
}

detect_linux_package_manager() {
    if [ -n "${MYTERM_TEST_PACKAGE_MANAGER:-}" ]; then
        if [ "$MYTERM_TEST_PACKAGE_MANAGER" != apt ]; then
            fatal "Unsupported Linux package manager '$MYTERM_TEST_PACKAGE_MANAGER'. Only apt is supported."
        fi
        PACKAGE_MANAGER=apt
        return 0
    fi

    if ! command_exists apt-get; then
        fatal "apt is required. Supported Linux targets are Ubuntu and headless Raspberry Pi OS."
    fi

    PACKAGE_MANAGER=apt
}

detect_linux_architecture() {
    local architecture
    architecture="${MYTERM_TEST_ARCH:-$(uname -m)}"

    case "$architecture" in
        x86_64|amd64)
            LINUX_ARCH=x86_64
            ;;
        arm64|aarch64)
            LINUX_ARCH=arm64
            ;;
        *)
            fatal "Unsupported Linux architecture '$architecture'. Supported architectures are x86_64 and arm64."
            ;;
    esac
}

normalize_linux_profile() {
    if [ "$IS_RASPBERRY_PI" = true ]; then
        if is_graphical_session; then
            fatal "Raspberry Pi setup supports headless systems only."
        fi

        case "$PROFILE_OVERRIDE" in
            auto|headless|raspberrypi)
                SETUP_PROFILE=raspberrypi-headless
                ;;
            *)
                fatal "--profile $PROFILE_OVERRIDE is not valid on Raspberry Pi. Use auto, headless, or raspberrypi." 2
                ;;
        esac
        return 0
    fi

    if [ "$LINUX_OS_ID" != ubuntu ]; then
        fatal "Unsupported Linux distribution '$LINUX_OS_ID'. Supported targets are Ubuntu and headless Raspberry Pi OS."
    fi

    case "$PROFILE_OVERRIDE" in
        auto)
            if is_graphical_session; then
                SETUP_PROFILE=ubuntu-desktop
            else
                SETUP_PROFILE=ubuntu-server
            fi
            ;;
        desktop|ubuntu-desktop)
            SETUP_PROFILE=ubuntu-desktop
            ;;
        server|headless|ubuntu-server)
            SETUP_PROFILE=ubuntu-server
            ;;
        raspberrypi)
            fatal "--profile raspberrypi requires Raspberry Pi hardware." 2
            ;;
        macos)
            fatal "--profile macos cannot be used on Linux." 2
            ;;
        *)
            fatal "Unknown profile '$PROFILE_OVERRIDE'. Use auto, desktop, server, headless, or raspberrypi." 2
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
            LINUX_OS_ID="$(read_linux_os_id)"
            detect_linux_package_manager
            detect_linux_architecture
            if detect_raspberry_pi; then
                IS_RASPBERRY_PI=true
            fi
            normalize_linux_profile
            ACTIVE_PACKAGE_PROFILES=$SETUP_PROFILE
            ;;
        *)
            fatal "Unsupported operating system: $uname_value"
            ;;
    esac
}

setup_label() {
    case "$SETUP_PROFILE" in
        macos)
            echo "macOS"
            ;;
        ubuntu-desktop)
            echo "Ubuntu desktop"
            ;;
        ubuntu-server)
            echo "Ubuntu server"
            ;;
        raspberrypi-headless)
            echo "Raspberry Pi headless"
            ;;
        *)
            echo "$SETUP_PLATFORM $SETUP_PROFILE"
            ;;
    esac
}
