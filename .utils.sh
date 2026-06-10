use_brew() {
    [ "${DOTFILES_ENV:-}" = "home" ]
}

# Where nvm (and its large node versions) should live. On work hosts the home
# dir is small, so park nvm on the big workspace/scratch volume instead.
# Canonical gate shared by install/nvm/install.sh and zsh/conf.d/nvm.zsh.
nvm_dir() {
    case "${DOTFILES_ENV:-}" in
        work-devcompute) echo /local/mnt/workspace/juliray/.nvm ;;
        work-argos)      echo /prj/qct/mlsys/markham/scratch/juliray/.nvm ;;
        *)               echo "$HOME/.nvm" ;;
    esac
}
