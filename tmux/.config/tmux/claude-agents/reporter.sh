#!/usr/bin/env bash
# Update Claude Code agent state for the current tmux pane.
# Invoked by hooks in ~/.claude/settings.json with $1 = working|waiting|done.
set -euo pipefail

state="${1:-}"
[[ -z "$state" ]] && exit 0
[[ -z "${TMUX_PANE:-}" ]] && exit 0

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude-tmux-agents"
mkdir -p "$cache_dir"

target=$(tmux display -p -t "$TMUX_PANE" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null) || exit 0

printf '%s\t%s\t%s\t%s\n' "$state" "$(date +%s)" "$PWD" "$target" >"$cache_dir/$TMUX_PANE"

tmux refresh-client -S 2>/dev/null || true
