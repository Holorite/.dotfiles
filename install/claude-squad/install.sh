#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if [[ "${DOTFILES_ENV:-}" == "home" ]]; then
    info "Skipping claude-squad (home env)"
    exit 0
fi

if should_install cs cs --version; then
    info "Installing claude-squad..."
    ensure_eget
    eget_install smtg-ai/claude-squad --to "$BIN_DIR/cs"
    info "claude-squad installed (binary: cs)"
fi
