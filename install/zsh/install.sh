#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# ── zsh ────────────────────────────────────────────────────────────────────────
if should_install zsh zsh --version; then
    info "Installing zsh..."
    if ! try_brew zsh; then
        sudo apt-get update -qq && sudo apt-get install -y zsh \
            || error "Failed to install zsh"
    fi
    info "zsh installed"
fi

# ── Antidote ───────────────────────────────────────────────────────────────────
if should_install_path Antidote ~/.antidote; then
    info "Installing Antidote..."
    rm -rf ~/.antidote
    git clone --depth=1 https://github.com/mattmc3/antidote ~/.antidote \
        || error "Failed to install Antidote"
    info "Antidote installed"
fi

# ── Starship ───────────────────────────────────────────────────────────────────
if should_install starship starship --version; then
    info "Installing Starship..."
    if ! try_brew starship; then
        curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$BIN_DIR" --yes \
            || error "Failed to install Starship"
    fi
    info "Starship installed"
fi

# ── eza ────────────────────────────────────────────────────────────────────────
if should_install eza eza --version; then
    info "Installing eza..."
    if ! try_brew eza; then
        curl -sL "https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz" \
            | tar -xz -C "$BIN_DIR" || error "Failed to install eza"
    fi
    info "eza installed"
fi

info "Done! Open a new shell to get started."
