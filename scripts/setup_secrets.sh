#!/usr/bin/env bash

# ~/.secrets creation and migration.
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
