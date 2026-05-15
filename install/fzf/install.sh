#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install fzf fzf --version; then
    info "Installing fzf..."
    rm -rf ~/.fzf
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
        || error "Failed to clone fzf"
    ~/.fzf/install || error "fzf install script failed"
    info "fzf installed"
fi
