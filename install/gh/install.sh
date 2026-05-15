#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install gh gh --version; then
    info "Installing gh..."
    ensure_eget
    "$EGET" cli/cli --to "$BIN_DIR" --file gh
    info "gh installed"
fi
