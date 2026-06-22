#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# lemonade: relays `open <url>` (and copy/paste) from this remote host to a
# server running on the laptop, over an ssh -R tunnel. Used by the $BROWSER
# wrapper (bin/.local/bin/browser-open) so `gh browse` opens a tab on the
# laptop. Work envs only — at home (WSL) the wrapper uses wslview instead and
# needs no daemon or tunnel, so lemonade would be dead weight there.
#
# This installs only the REMOTE half. The one-time laptop setup (install
# lemonade on Windows, run `lemonade server`, add `RemoteForward 2489
# 127.0.0.1:2489` to ~/.ssh/config) is documented in notes/improvements.md.

case "${DOTFILES_ENV:-}" in
    work-argos|work-devcompute) ;;
    *) info "lemonade: skipping (DOTFILES_ENV='${DOTFILES_ENV:-}' is not a work env)"; exit 0 ;;
esac

if should_install lemonade lemonade --help; then
    info "Installing lemonade..."
    if ! try_brew lemonade; then
        ensure_eget
        eget_install lemonade-command/lemonade --to "$BIN_DIR"
    fi
    info "lemonade installed"
fi
