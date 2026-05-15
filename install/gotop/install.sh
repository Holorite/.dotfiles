#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install gotop gotop -V; then
    info "Installing gotop..."
    if ! try_brew gotop; then
        ensure_eget
        eget_install xxxserxxx/gotop --to "$BIN_DIR" --file gotop
    fi
    info "gotop installed"
fi
