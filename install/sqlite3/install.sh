#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# ── sqlite3 ────────────────────────────────────────────────────────────────────
# Required by zsh-sage. sqlite.org doesn't publish GitHub releases, so the
# non-brew fallback scrapes the current linux-x64 tools zip from download.html.
if should_install sqlite3 sqlite3 --version; then
    info "Installing sqlite3..."
    if ! try_brew sqlite; then
        info "Fetching sqlite-tools release from sqlite.org..."
        rel=$(curl -fsSL https://www.sqlite.org/download.html \
            | grep -oE '[0-9]{4}/sqlite-tools-linux-x64-[0-9]+\.zip' \
            | head -1) \
            || error "Failed to locate sqlite-tools-linux-x64 release"
        [[ -n "$rel" ]] || error "Failed to locate sqlite-tools-linux-x64 release"
        tmp=$(mktemp -d) || error "Failed to create tempdir"
        trap 'rm -rf "$tmp"' EXIT
        curl -fsSL "https://www.sqlite.org/$rel" -o "$tmp/tools.zip" \
            || error "Failed to download $rel"
        unzip -j -o "$tmp/tools.zip" '*sqlite3' -d "$BIN_DIR" >/dev/null \
            || error "Failed to extract sqlite3 from $rel"
        chmod +x "$BIN_DIR/sqlite3"
    fi
    info "sqlite3 installed"
fi
