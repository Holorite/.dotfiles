#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install lazygit lazygit --version; then
    info "Installing lazygit..."
    ensure_eget
    "$EGET" jesseduffield/lazygit --to "$BIN_DIR" --file lazygit
    info "lazygit installed"
fi
