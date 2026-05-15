function tablegrep() {
    grep "$@" | awk -f "${DOTFILES_ZSH}/format_grep.awk" | column -t -s $'\t'
}
