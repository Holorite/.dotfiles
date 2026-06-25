# Export the work-vault location so the `vault` helper, the Claude slash
# commands, and the vault-explorer agent all resolve the same path without
# re-deriving it. work_vault_dir() is the canonical seam (.utils.sh). The
# directory only exists on work envs (created by install/work-vault); elsewhere
# this just exports a path that nothing uses.
export WORK_VAULT_DIR="$(work_vault_dir)"
export ZK_NOTEBOOK_DIR="$WORK_VAULT_DIR"

# zk runs aliases with cwd chdir'd to the notebook root and exposes no record of
# the original invocation directory (only ZK_NOTEBOOK_DIR and friends). Stamp the
# real cwd into ZK_CWD so project-aware aliases (slug, plan) can `cd "$ZK_CWD"`
# back to where you actually ran `zk` — without it, `vault slug` always resolves
# to the vault itself instead of the project you were standing in.
zk() { ZK_CWD="$PWD" command zk "$@"; }
