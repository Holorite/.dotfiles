#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

if should_install fzf fzf --version; then
    info "Installing fzf..."
    if try_brew fzf; then
        # brew installs the binary; the install script wires up shell integration
        # (creates ~/.fzf.zsh which our zshrc sources).
        "$("$BREW" --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc \
            || error "fzf shell integration setup failed"
    else
        rm -rf ~/.fzf
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
            || error "Failed to clone fzf"
        ~/.fzf/install || error "fzf install script failed"
    fi
    info "fzf installed"
fi
