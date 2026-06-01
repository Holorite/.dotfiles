#!/usr/bin/env bash
# Print a tmux status-right segment summarizing Claude agent states.
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-tmux-agents"
[[ -d "$cache_dir" ]] || exit 0

shopt -s nullglob
working=0; waiting=0; done_=0

live_ids=$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null) || exit 0

for f in "$cache_dir"/*; do
    pane_id=$(basename "$f")
    if ! grep -Fxq "$pane_id" <<<"$live_ids"; then
        rm -f "$f"
        continue
    fi
    state=$(cut -f1 "$f" 2>/dev/null) || continue
    case "$state" in
        working) working=$((working+1)) ;;
        waiting) waiting=$((waiting+1)) ;;
        done)    done_=$((done_+1)) ;;
    esac
done

out=""
[[ $working -gt 0 ]] && out+="#[fg=yellow]⚡${working} "
[[ $waiting -gt 0 ]] && out+="#[fg=red]⏸ ${waiting} "
[[ $done_ -gt 0 ]]   && out+="#[fg=green]✓${done_} "
printf '%s' "$out"
