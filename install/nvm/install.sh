#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# nvm is a shell function, not a binary — guard on its install dir.
if should_install_path nvm ~/.nvm; then
    info "Installing nvm..."
    rm -rf ~/.nvm
    PROFILE=/dev/null bash -c \
        'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash' \
        || error "nvm install failed"
    info "nvm installed"
fi

# Source nvm into this shell so we can use it to install node.
export NVM_DIR="$HOME/.nvm"
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
command -v nvm &>/dev/null || error "nvm not available — check $NVM_DIR/nvm.sh"

if should_install node node --version; then
    info "Installing latest node via nvm..."
    nvm install node || error "Failed to install node"
    info "node $(node --version) installed"
fi

