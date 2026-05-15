#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install gotop gotop -V; then
    info "Installing gotop..."
    ensure_eget
    "$EGET" xxxserxxx/gotop --to "$BIN_DIR" --file gotop
    info "gotop installed"
fi
