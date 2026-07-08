#!/usr/bin/env bash

# Codex configuration and skill linking.
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

            run_step "Back up existing Codex skill $skill_name" mv "$target" "$backup"
            echo "  -> Backed up existing Codex skill: $backup"
        fi

        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would link Codex skill: $skill_name"
            continue
        fi

        run_step "Link Codex skill $skill_name" ln -sfn "$skill_dir" "$target"
        echo "  -> Linked Codex skill: $skill_name"
    done
}

link_codex_config() {
    echo "Linking Codex configuration..."

    if [ -L "$HOME/agent-coding" ]; then
        if [ "$DRY_RUN" = true ]; then
            echo "  -> Would remove legacy ~/agent-coding symlink"
        else
            run_step "Remove legacy ~/agent-coding symlink" rm "$HOME/agent-coding"
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
