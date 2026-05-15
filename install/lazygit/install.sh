#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install lazygit lazygit --version; then
    info "Installing lazygit..."
    if ! try_brew lazygit; then
        ensure_eget
        eget_install jesseduffield/lazygit --to "$BIN_DIR" --file lazygit
    fi
    info "lazygit installed"
fi
