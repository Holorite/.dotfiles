#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# Perfetto trace_processor — the native accelerator for viewing traces in the
# Perfetto UI. Work envs only: this is a work-host need (traces live on the big
# work disks, viewed from the laptop browser over an ssh tunnel — see the
# `ptrace` helper in zsh/conf.d/perfetto.zsh for the end-to-end flow).
#
# Not a GitHub release, so not eget: get.perfetto.dev/trace_processor is a
# self-contained Python wrapper that downloads and caches the real ~14MB binary
# under ~/.local/share/perfetto/prebuilts/ on first invocation. We install the
# wrapper into $BIN_DIR and warm it up once so the real binary is cached at
# install time rather than on the first `ptrace`.

case "${DOTFILES_ENV:-}" in
    work-argos|work-devcompute) ;;
    *) info "perfetto: skipping (DOTFILES_ENV='${DOTFILES_ENV:-}' is not a work env)"; exit 0 ;;
esac

WRAPPER_URL="https://get.perfetto.dev/trace_processor"

if should_install trace_processor trace_processor --version; then
    info "Installing Perfetto trace_processor..."
    curl -fsSL "$WRAPPER_URL" -o "$BIN_DIR/trace_processor" \
        || error "perfetto: download failed ($WRAPPER_URL)"
    chmod +x "$BIN_DIR/trace_processor"

    # Warm-up: the wrapper fetches+caches the real binary on first run. Do it now
    # (non-fatal) so `ptrace` is instant later. hash -r first — bash caches the
    # command lookup, and this may be a fresh install.
    hash -r
    info "Caching the trace_processor binary (first run downloads ~14MB)..."
    trace_processor --version >/dev/null 2>&1 \
        || info "perfetto: warm-up run failed (network?) — will cache on first use"
    info "trace_processor installed at $BIN_DIR/trace_processor"
fi
