#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# Claude Code (via Qualcomm's internal qgenie installer) plus the Tavily search
# MCP. Work envs only: the installer pulls from github.qualcomm.com and wires up
# the qgenie API endpoint, which only resolves on the corporate network; and the
# built-in WebSearch tool is geo-gated to the US, so work hosts route search
# through Tavily instead.

case "${DOTFILES_ENV:-}" in
    work-argos|work-devcompute) ;;
    *) info "claude-code: skipping (DOTFILES_ENV='${DOTFILES_ENV:-}' is not a work env)"; exit 0 ;;
esac

# ── Claude Code ────────────────────────────────────────────────────────────────
# Both of the installer's profile-mutating behaviors are suppressed:
#   --no-path           ~/.local/bin is already on PATH (zsh/.zshrc)
#   --no-qgenie-profile ~/.qgenie/.exports is already sourced by
#                       zsh/env/work-{argos,devcompute}.zsh
# This keeps shell config owned by the repo instead of appended in place.
INSTALLER_URL="https://github.qualcomm.com/qgenie-contrib/claude-code-installer/releases/latest/download/install-claude-code.sh"

if should_install claude claude --version; then
    info "Installing Claude Code via qgenie installer..."
    curl -fsSL "$INSTALLER_URL" | bash -s -- --no-path --no-qgenie-profile \
        || error "claude-code: installer failed"
    info "Claude Code installed"
fi

# ── Tavily search MCP ───────────────────────────────────────────────────────────
# Registered at user scope so it's available in every Claude session regardless
# of cwd. The Bearer header stores the *literal* string ${TAVILY_API_KEY} (note
# the single quotes — the shell must NOT expand it). Claude expands it at runtime
# from the environment, so the resolved key never lands in ~/.claude.json; it
# lives only in ~/.zsh_secrets.
# Make a freshly-installed claude visible: the qgenie installer drops the
# binary into ~/.local/bin (== $BIN_DIR, already on PATH via lib.sh), but bash
# caches command lookups, so rehash before checking. Only error if it's
# genuinely missing from disk.
hash -r
command -v claude &>/dev/null \
    || error "claude-code: 'claude' not found after install (looked in $BIN_DIR)"

if [[ -z "${TAVILY_API_KEY:-}" ]]; then
    info "tavily: warning — TAVILY_API_KEY not set in this shell; add it to ~/.zsh_secrets or search will fail at runtime"
fi

# Idempotency: reuse the REINSTALL/TTY semantics from lib.sh's prompt helper.
if claude mcp get tavily &>/dev/null; then
    info "tavily MCP already configured"
    if _should_install_prompt "tavily"; then
        claude mcp remove --scope user tavily &>/dev/null || true
    fi
fi

if ! claude mcp get tavily &>/dev/null; then
    info "Registering tavily MCP (user scope)..."
    # shellcheck disable=SC2016  # literal ${TAVILY_API_KEY} must reach config unexpanded
    claude mcp add --scope user --transport http tavily \
        https://mcp.tavily.com/mcp/ \
        --header 'Authorization: Bearer ${TAVILY_API_KEY}' \
        || error "tavily: 'claude mcp add' failed"
    info "tavily MCP registered"
fi
