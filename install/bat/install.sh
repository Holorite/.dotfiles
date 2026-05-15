#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# ── bat ────────────────────────────────────────────────────────────────────────
if command -v bat &>/dev/null; then
    info "bat already installed ($(bat --version))"
else
    info "Installing bat..."
    link=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | jq -r '.assets[] | select(.name? | match("tar.gz$")) | .browser_download_url' | grep "$(uname -m).*gnu")
    [[ -z "$link" ]] && error "Failed to fetch bat release URL"

    curl -sL $link | tar -xz -C $BIN_DIR --strip-components=1 --no-same-owner --wildcards '*/bat'
    info "bat installed"
fi

# ── Tokyo Night theme ──────────────────────────────────────────────────────────
info "Setting up Tokyo Night theme..."
mkdir -p "$("$BIN_DIR/bat" --config-dir)/themes"
curl -sL -o "$("$BIN_DIR/bat" --config-dir)/themes/tokyonight_night.tmTheme" \
    https://raw.githubusercontent.com/folke/tokyonight.nvim/main/extras/sublime/tokyonight_night.tmTheme
"$BIN_DIR/bat" cache --build
echo '--theme="tokyonight_night"' >> "$("$BIN_DIR/bat" --config-dir)/config"
info "Tokyo Night theme installed"
