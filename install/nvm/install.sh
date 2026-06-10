#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# nvm is a shell function, not a binary — guard on its install dir.
# nvm_dir() (from .utils.sh) parks it on the big workspace volume on work hosts.
NVM_DIR="$(nvm_dir)"
if should_install_path nvm "$NVM_DIR"; then
    info "Installing nvm to $NVM_DIR..."
    rm -rf "$NVM_DIR"
    mkdir -p "$NVM_DIR"
    PROFILE=/dev/null NVM_DIR="$NVM_DIR" bash -c \
        'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash' \
        || error "nvm install failed"
    info "nvm installed"
fi

# Source nvm into this shell so we can use it to install node.
export NVM_DIR
# shellcheck disable=SC1091
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
command -v nvm &>/dev/null || error "nvm not available — check $NVM_DIR/nvm.sh"

if should_install node node --version; then
    info "Installing latest node via nvm..."
    nvm install node || error "Failed to install node"
    info "node $(node --version) installed"
fi

