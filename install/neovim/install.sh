#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install nvim nvim --version; then
    info "Installing neovim..."
    ensure_eget
    "$EGET" neovim/neovim --asset appimage --to "$BIN_DIR/nvim"
    chmod +x "$BIN_DIR/nvim"
    info "neovim installed"
fi
