#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib.sh"

# work-vault: a git-synced Obsidian vault that doubles as Claude's structured
# working-context store (explorations/plans/tasks wikilinked into a graph) and a
# home for regular notes. Lives under workspace_dir (work_vault_dir) — the
# big-disk volume, so it stays off the small home partition on work hosts; on the
# laptop / home env workspace_dir is $HOME, so it lands at $HOME/work-vault. The
# local path may differ per host; the git remote is what ties the clones
# together, and Obsidian opens the graph wherever the clone lives.
#
# Work envs only: the remote is a private personal repo on GHE
# (github.qualcomm.com), which resolves only on the corporate network. GHE is the
# CCI-correct home for the vault's Yellow/Red content (corp infra, not external
# github.com cloud). Same work-only gating as install/claude-code (a `case` on
# DOTFILES_ENV, not use_brew — the condition is work-only, not home-only).
#
# This installer is the version-controlled recipe for state that can't be
# stowed: the cloned repo itself, and the per-host clone/pull/create dance.

case "${DOTFILES_ENV:-}" in
    work-argos|work-devcompute) ;;
    *) info "work-vault: skipping (DOTFILES_ENV='${DOTFILES_ENV:-}' is not a work env)"; exit 0 ;;
esac

VAULT="$(work_vault_dir)"
REMOTE="$(work_vault_remote)"

# ── Already cloned → pull and exit ──────────────────────────────────────────
if [[ -d "$VAULT/.git" ]]; then
    if should_install_path "work-vault" "$VAULT/.git"; then
        info "work-vault: pulling latest into $VAULT"
        git -C "$VAULT" pull --ff-only || info "work-vault: pull failed (offline?) — continuing"
    fi
    exit 0
fi

# A non-git directory sitting at the vault path is unexpected; don't clobber it.
if [[ -e "$VAULT" && ! -d "$VAULT/.git" ]]; then
    error "work-vault: $VAULT exists but is not a git repo — move it aside and rerun"
fi

# ── Clone if the remote exists; else create it, then clone ──────────────────
# Probe the remote without writing anything.
if git ls-remote "$REMOTE" &>/dev/null; then
    info "work-vault: cloning $REMOTE → $VAULT"
    git clone "$REMOTE" "$VAULT" || error "work-vault: clone failed"
else
    info "work-vault: remote $REMOTE not found — creating it"
    # Derive host + owner/repo from the remote for gh.
    # git@github.qualcomm.com:juliray/work-vault.git → host=github.qualcomm.com, slug=juliray/work-vault
    host="${REMOTE#*@}"; host="${host%%:*}"
    slug="${REMOTE#*:}"; slug="${slug%.git}"
    command -v gh &>/dev/null || error "work-vault: gh not found; create $REMOTE manually and rerun"
    if ! GH_HOST="$host" gh auth status &>/dev/null; then
        error "work-vault: gh not authenticated to $host.
  Run once:  gh auth login --hostname $host
  Then rerun: ./install.sh work-vault"
    fi
    # A *personal* private repo is fine while the vault is single-user (CCI only
    # mandates an org when a repo must be shared via an N2K team). If you later
    # share it, move it into a GHE org and attach an N2K team.
    GH_HOST="$host" gh repo create "$slug" --private --clone --description \
        "Obsidian work-vault: Claude working-context graph + personal notes (CCI: yellow/red — keep private)" \
        2>/dev/null || error "work-vault: gh repo create failed"
    # gh clones into ./<repo>; move it to the canonical path if needed.
    reponame="${slug##*/}"
    if [[ -d "$reponame/.git" && "$PWD/$reponame" != "$VAULT" ]]; then
        mv "$reponame" "$VAULT"
    fi
fi

# ── Seed the skeleton if the repo is empty ──────────────────────────────────
# A freshly-created repo has no commits; a cloned existing one already has the
# layout. Only seed when index.md is absent.
if [[ ! -f "$VAULT/index.md" ]]; then
    info "work-vault: seeding skeleton"
    mkdir -p "$VAULT/projects" "$VAULT/explorations" "$VAULT/plans" \
             "$VAULT/tasks" "$VAULT/.obsidian"

    cat > "$VAULT/index.md" <<'EOF'
---
type: index
---
# Work Vault

Top-level map of content. Each project below links to its own MOC, which in turn
links its explorations, plans, and tasks.

Machine-generated notes (Claude) live under `projects/`, `explorations/`,
`plans/`, `tasks/`. Freeform personal notes can live anywhere else in the vault
and wikilink into the same graph.

## Projects
<!-- auto:projects -->
<!-- /auto:projects -->
EOF

    # Keep otherwise-empty type folders in git so the layout clones intact.
    for d in projects explorations plans tasks; do
        : > "$VAULT/$d/.gitkeep"
    done

    # Minimal Obsidian config: enable the graph view, ignore workspace churn.
    cat > "$VAULT/.obsidian/.gitignore" <<'EOF'
workspace.json
workspace-mobile.json
cache/
EOF

    cat > "$VAULT/.gitignore" <<'EOF'
.DS_Store
EOF

    git -C "$VAULT" add -A
    git -C "$VAULT" commit -q -m "work-vault: seed skeleton" || true
    git -C "$VAULT" push -q -u origin HEAD 2>/dev/null \
        || info "work-vault: initial push failed (offline?) — committed locally"
fi

info "work-vault ready at $VAULT"
