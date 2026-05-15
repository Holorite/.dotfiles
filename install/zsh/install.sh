#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/../lib.sh"

# ── zsh ────────────────────────────────────────────────────────────────────────
if command -v zsh &>/dev/null; then
    info "zsh already installed ($(zsh --version))"
else
    info "Installing zsh..."
    sudo apt-get update -qq && sudo apt-get install -y zsh || error "Failed to install zsh"
    info "zsh installed"
fi

# ── Antidote ───────────────────────────────────────────────────────────────────
if [[ -d ~/.antidote ]]; then
    info "Antidote already installed"
else
    info "Installing Antidote..."
    git clone --depth=1 https://github.com/mattmc3/antidote ~/.antidote || error "Failed to install Antidote"
    info "Antidote installed"
fi

# ── Starship ───────────────────────────────────────────────────────────────────
if command -v starship &>/dev/null; then
    info "Starship already installed ($(starship --version))"
else
    info "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$BIN_DIR" --yes || error "Failed to install Starship"
    info "Starship installed"
fi

# ── eza ────────────────────────────────────────────────────────────────────────
if command -v eza &>/dev/null; then
    info "eza already installed ($(eza --version | head -1))"
else
    info "Installing eza..."
    curl -sL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" \
        | tar -xz -C $BIN_DIR
    info "eza installed"
fi

info "Done! Open a new shell to get started."
