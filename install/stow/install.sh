#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install stow stow --version; then
    info "Installing stow..."
    tmp=$(mktemp -d) || error "Failed to create tempdir"
    (
        cd "$tmp"
        curl -LO https://ftp.gnu.org/gnu/stow/stow-latest.tar.gz
        tar xzf stow-latest.tar.gz
        cd stow-*/
        ./configure --prefix="$HOME/.local"
        make install
    ) || { rm -rf "$tmp"; error "stow build failed"; }
    rm -rf "$tmp"
    info "stow installed"
fi
