#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install shellcheck shellcheck --version; then
    info "Installing shellcheck..."
    if ! try_brew shellcheck; then
        ensure_eget
        eget_install koalaman/shellcheck --asset ^.xz --to "$BIN_DIR" \
            || error "Failed to install shellcheck"
    fi
    info "shellcheck installed"
fi
