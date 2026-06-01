#!/usr/bin/env bash
# Jump to the most-recent Claude pane that needs attention.
# Priority: waiting > done. Skips the current pane.
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-tmux-agents"
[[ -d "$cache_dir" ]] || { tmux display-message "No Claude agents tracked"; exit 0; }

current="${TMUX_PANE:-}"
shopt -s nullglob
files=("$cache_dir"/*)
[[ ${#files[@]} -eq 0 ]] && { tmux display-message "No Claude agents tracked"; exit 0; }

mapfile -t files < <(cd "$cache_dir" && ls -t -- "${files[@]##*/}" | while read -r n; do printf '%s/%s\n' "$cache_dir" "$n"; done)

live_ids=$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null) || exit 0

waiting_targets=()
done_targets=()
for f in "${files[@]}"; do
    pane_id=$(basename "$f")
    [[ "$pane_id" == "$current" ]] && continue
    if ! grep -Fxq "$pane_id" <<<"$live_ids"; then
        rm -f "$f"
        continue
    fi
    IFS=$'\t' read -r state epoch cwd target <"$f" || continue
    case "$state" in
        waiting) waiting_targets+=("$target") ;;
        done)    done_targets+=("$target") ;;
    esac
done

if [[ ${#waiting_targets[@]} -gt 0 ]]; then
    target="${waiting_targets[0]}"
elif [[ ${#done_targets[@]} -gt 0 ]]; then
    target="${done_targets[0]}"
else
    tmux display-message "No ready agents"
    exit 0
fi

session="${target%%:*}"
tmux switch-client -t "$session"
tmux select-pane -t "$target"
