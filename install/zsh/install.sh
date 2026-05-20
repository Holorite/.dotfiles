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
    if ! try_brew antidote; then
        rm -rf ~/.antidote
        git clone --depth=1 https://github.com/mattmc3/antidote ~/.antidote \
            || error "Failed to install Antidote"
    fi
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

# ── vivid ──────────────────────────────────────────────────────────────────────
# Generates LS_COLORS themes so the zsh completion menu matches eza's coloring
# (see zsh/conf.d/completion.zsh).
if should_install vivid vivid --version; then
    info "Installing vivid..."
    if ! try_brew vivid; then
        ensure_eget
        eget_install sharkdp/vivid --asset gnu --to "$BIN_DIR" \
            || error "Failed to install vivid"
    fi
    info "vivid installed"
fi

# ── catppuccin theme for fast-syntax-highlighting ──────────────────────────────
# Drops the four flavor .ini files into ~/.config/fsh/. Activation happens
# lazily on first shell start (see zsh/conf.d/fsh.zsh).
if should_install_path "catppuccin fsh theme" ~/.config/fsh/catppuccin-mocha.ini; then
    info "Installing catppuccin fsh theme..."
    mkdir -p ~/.config/fsh
    tmp=$(mktemp -d) || error "Failed to create tempdir"
    git clone --depth=1 https://github.com/catppuccin/zsh-fsh.git "$tmp" \
        || { rm -rf "$tmp"; error "Failed to clone catppuccin/zsh-fsh"; }
    cp "$tmp"/themes/catppuccin-*.ini ~/.config/fsh/ \
        || { rm -rf "$tmp"; error "Failed to copy fsh themes"; }
    rm -rf "$tmp"
    info "catppuccin fsh theme installed"
fi

info "Done! Open a new shell to get started."
