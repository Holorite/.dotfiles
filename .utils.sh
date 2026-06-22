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

# Where nvm (and its large node versions) should live.
# Shared by install/nvm/install.sh and zsh/conf.d/nvm.zsh.
nvm_dir() {
    echo "$(workspace_dir)/.nvm"
}
