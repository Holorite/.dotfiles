#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install spotify_player spotify_player --version; then
    info "Installing spotify_player..."
    if ! try_brew spotify_player; then
        ensure_eget
        eget_install aome510/spotify-player --to "$BIN_DIR" --file spotify_player
    fi
    info "spotify_player installed"
fi
