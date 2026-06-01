#!/usr/bin/env bash
# fzf popup of live Claude Code panes; switches to the selection.
# Bound to prefix+S via `display-popup -E`.
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-tmux-agents"
[[ -d "$cache_dir" ]] || { echo "No Claude agents tracked." >&2; exit 0; }

shopt -s nullglob
files=("$cache_dir"/*)
[[ ${#files[@]} -eq 0 ]] && { echo "No Claude agents tracked." >&2; exit 0; }

# Sort by mtime descending so most-recent activity appears first.
mapfile -t files < <(cd "$cache_dir" && ls -t -- "${files[@]##*/}" | while read -r n; do printf '%s/%s\n' "$cache_dir" "$n"; done)

live_ids=$(tmux list-panes -a -F '#{pane_id}' 2>/dev/null) || { echo "tmux not running." >&2; exit 0; }
# pane_id<TAB>pane_title — used to surface Claude's current task subject
declare -A pane_title
while IFS=$'\t' read -r pid title; do
    pane_title[$pid]=$title
done < <(tmux list-panes -a -F '#{pane_id}'$'\t''#{pane_title}' 2>/dev/null)

lines=()
for f in "${files[@]}"; do
    pane_id=$(basename "$f")
    if ! grep -Fxq "$pane_id" <<<"$live_ids"; then
        rm -f "$f"
        continue
    fi
    IFS=$'\t' read -r state epoch cwd target <"$f" || continue
    case "$state" in
        working) icon='⚡' ;;
        waiting) icon='⏸' ;;
        done)    icon='✓' ;;
        *)       icon='?' ;;
    esac
    short="${cwd/#$HOME/~}"
    title="${pane_title[$pane_id]:-}"
    lines+=("$(printf '%s %-7s\t%s\t%s\t%s' "$icon" "$state" "$target" "$title" "$short")")
done

[[ ${#lines[@]} -eq 0 ]] && { echo "No live Claude agents." >&2; exit 0; }

selected=$(printf '%s\n' "${lines[@]}" | fzf \
    --layout=reverse \
    --no-sort \
    --disabled \
    --prompt='claude > ' \
    --header='j/k nav · i filter · / search · enter switch · q quit' \
    --delimiter=$'\t' --with-nth=1.. \
    --bind 'j:down' \
    --bind 'k:up' \
    --bind 'g:first' \
    --bind 'G:last' \
    --bind 'q:abort' \
    --bind 'i:enable-search+change-prompt(filter > )+unbind(j,k,g,G,q,i)+rebind(esc)' \
    --bind '/:enable-search+change-prompt(filter > )+unbind(j,k,g,G,q,i,/)+rebind(esc)' \
    --bind 'esc:disable-search+change-prompt(claude > )+clear-query+rebind(j,k,g,G,q,i,/)+unbind(esc)' \
) || exit 0

target=$(printf '%s' "$selected" | cut -f2)

tmux switch-client -t "$target"
