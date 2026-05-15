#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install nvim nvim --version; then
    info "Installing neovim..."
    if ! try_brew neovim; then
        ensure_eget
        "$EGET" neovim/neovim --asset appimage --to "$BIN_DIR/nvim"
        chmod +x "$BIN_DIR/nvim"
    fi
    info "neovim installed"
fi
