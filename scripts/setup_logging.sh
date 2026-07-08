#!/usr/bin/env bash

# Logging, command execution, and common setup primitives.
SETUP_LOG_DIR="${SETUP_LOG_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/myterm}"
SETUP_LOG_FILE="${SETUP_LOG_FILE:-$SETUP_LOG_DIR/setup.log}"
SETUP_STATE_FILE="${SETUP_STATE_FILE:-$SETUP_LOG_DIR/setup-state}"
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
