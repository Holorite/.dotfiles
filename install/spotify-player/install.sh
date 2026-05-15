#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install spotify_player spotify_player --version; then
    info "Installing spotify_player..."
    ensure_eget
    "$EGET" aome510/spotify-player --to "$BIN_DIR" --file spotify_player
    info "spotify_player installed"
fi
