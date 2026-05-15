#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# ── tree-sitter CLI ────────────────────────────────────────────────────────────
# Required by nvim-treesitter (main branch, post-1.0) to build parsers.
# Needs >= 0.26.1.
if should_install tree-sitter tree-sitter --version; then
    info "Installing tree-sitter..."
    if ! try_brew tree-sitter; then
        ensure_eget
        eget_install tree-sitter/tree-sitter --to "$BIN_DIR" --asset ^cli --file tree-sitter
    fi
    info "tree-sitter installed"
fi
