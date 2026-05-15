#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# ── bat ────────────────────────────────────────────────────────────────────────
if should_install bat bat --version; then
    info "Installing bat..."
    ensure_eget
    "$EGET" sharkdp/bat --to "$BIN_DIR" --file bat
    info "bat installed"
fi

# ── Tokyo Night theme ──────────────────────────────────────────────────────────
config_dir="$("$BIN_DIR/bat" --config-dir)"
theme_path="$config_dir/themes/tokyonight_night.tmTheme"
config_file="$config_dir/config"

if should_install_path "Tokyo Night theme" "$theme_path"; then
    info "Setting up Tokyo Night theme..."
    mkdir -p "$config_dir/themes"
    curl -sL -o "$theme_path" \
        https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme \
        || error "Failed to download Tokyo Night theme"
    "$BIN_DIR/bat" cache --build
    info "Tokyo Night theme installed"
fi

if ! grep -q 'tokyonight_night' "$config_file" 2>/dev/null; then
    echo '--theme="tokyonight_night"' >> "$config_file"
    info "Tokyo Night theme set as default"
fi
