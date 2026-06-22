# Export the work-vault location so the `work-vault` helper, the Claude slash
# commands, and the vault-explorer agent all resolve the same path without
# re-deriving it. work_vault_dir() is the canonical seam (.utils.sh). The
# directory only exists on work envs (created by install/work-vault); elsewhere
# this just exports a path that nothing uses.
export WORK_VAULT_DIR="$(work_vault_dir)"
