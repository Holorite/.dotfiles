#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install colorscript; then
    info "Installing colorscript..."
    tmp=$(mktemp -d) || error "Failed to create tempdir"
    (
        cd "$tmp"
        git clone git@github.com:Holorite/shell-color-scripts-local-install.git
        cd shell-color-scripts-local-install
        make install
    ) || { rm -rf "$tmp"; error "colorscript install failed"; }
    rm -rf "$tmp"
    info "colorscript installed"
fi
