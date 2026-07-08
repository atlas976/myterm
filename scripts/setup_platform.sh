#!/usr/bin/env bash

# Platform, package manager, and profile detection.
# shellcheck disable=SC2034
SETUP_PLATFORM=
PACKAGE_MANAGER=
SETUP_PROFILE=
ACTIVE_PACKAGE_PROFILES=
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
