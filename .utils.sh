# shellcheck shell=bash
use_brew() {
    [ "${DOTFILES_ENV:-}" = "home" ]
}

# Root of the big-disk volume for this env. The home dir is small on work
# hosts, so large/regenerable data (node versions, pip/uv caches) is parked
# here instead. Falls back to $HOME where there is no separate volume.
# Canonical seam — derive specific locations (nvm_dir, pip cache, ...) from it.
workspace_dir() {
    case "${DOTFILES_ENV:-}" in
        work-devcompute) echo /local/mnt/workspace/juliray ;;
        work-argos)      echo /prj/qct/mlsys/markham/scratch/juliray ;;
        *)               echo "$HOME" ;;
    esac
}

# The shared NFS scratch dir for this env — the network-visible big-disk root
# (as opposed to workspace_dir, which may be host-local). On argos the two are
# the same path; on devcompute they differ (workspace_dir is local SSD, scratch
# is the lasvegas NFS mount). Canonical seam — used by the `scratch` alias
# (zsh/env/<env>.zsh) and by `ptrace` HTTP mode to root its file server.
scratch_dir() {
    case "${DOTFILES_ENV:-}" in
        work-argos)      echo /prj/qct/mlsys/markham/scratch/juliray ;;
        work-devcompute) echo /prj/qct/mlsys/lasvegas/scratch/juliray ;;
        *)               echo "$HOME" ;;
    esac
}

# Where nvm (and its large node versions) should live.
# Shared by install/nvm/install.sh and zsh/conf.d/nvm.zsh.
nvm_dir() {
    echo "$(workspace_dir)/.nvm"
}

# The work-vault: a git-synced Obsidian vault that doubles as Claude's
# structured working-context store (explorations/plans/tasks, wikilinked into a
# graph) and as a place for regular notes. Lives under workspace_dir (the
# big-disk volume) so the work hosts keep it off the small home partition; on the
# laptop / any `home` env workspace_dir is already $HOME, so it lands at
# $HOME/work-vault there — which is where Obsidian opens the graph. Local path
# may differ per host; the git remote is what ties every clone together, so the
# divergence is harmless. Work envs only — the remote is corp-network-only;
# elsewhere this is unused.
# Canonical seam — shared by install/work-vault/install.sh and
# zsh/conf.d/work-vault.zsh. Overridable via $WORK_VAULT_DIR.
work_vault_dir() {
    echo "${WORK_VAULT_DIR:-$(workspace_dir)/work-vault}"
}

# The git remote backing the work-vault. Default is a private personal repo on
# GHE (github.qualcomm.com) — the corp-hosted platform, the right home for the
# vault's Yellow/Red CCI content (external github.com cloud is not). A *personal*
# repo is fine while the vault is single-user: CCI requires an org only when a
# repo must be SHARED with multiple users (an N2K team can't attach to a personal
# repo). If you ever share it, move it into a GHE org and attach an N2K team.
# Override via $WORK_VAULT_REMOTE (e.g. from ~/.zsh_secrets). The installer
# clones/creates from this.
work_vault_remote() {
    echo "${WORK_VAULT_REMOTE:-git@github.qualcomm.com:juliray/work-vault.git}"
}
