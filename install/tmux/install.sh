#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# ── tmux ───────────────────────────────────────────────────────────────────────
if should_install tmux tmux -V; then
    info "Installing tmux..."
    ensure_eget
    "$EGET" nelsonenzo/tmux-appimage --to "$BIN_DIR/tmux"
    chmod +x "$BIN_DIR/tmux"
    info "tmux installed"
fi

# ── tpm ────────────────────────────────────────────────────────────────────────
if should_install_path tpm ~/.tmux/plugins/tpm; then
    info "Installing tpm..."
    rm -rf ~/.tmux/plugins/tpm
    git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm \
        || error "Failed to clone tpm"
    info "tpm installed"
fi

# ── Catppuccin tmux theme ──────────────────────────────────────────────────────
if should_install_path "catppuccin tmux theme" ~/.config/tmux/plugins/catppuccin/tmux; then
    info "Installing catppuccin tmux theme..."
    rm -rf ~/.config/tmux/plugins/catppuccin/tmux
    mkdir -p ~/.config/tmux/plugins/catppuccin
    git clone --depth=1 -b v2.1.3 https://github.com/catppuccin/tmux.git \
        ~/.config/tmux/plugins/catppuccin/tmux \
        || error "Failed to clone catppuccin/tmux"
    info "catppuccin tmux theme installed"
fi
