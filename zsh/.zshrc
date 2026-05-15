DOTFILES_ZSH="$(dirname "$(readlink -f "${HOME}/.zshrc")")"
DOTFILES_DIR="$(dirname "$DOTFILES_ZSH")"

# Environment detection
if [[ -f "$HOME/.dotfiles_env" ]]; then
    export DOTFILES_ENV=$(< "$HOME/.dotfiles_env")
else
    export DOTFILES_ENV="default"
fi

# Utils
source "$DOTFILES_DIR/.utils.sh"

# Path
export PATH="$HOME/.local/bin:$PATH"

# Secrets
[[ -f "$DOTFILES_ZSH/.zsh_secrets" ]] && source $DOTFILES_ZSH/.zsh_secrets

# Plugins (static-file fast path: regenerate only when .zsh_plugins.txt changes)
zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')
zvm_after_init_commands+=('source <(fzf --zsh)')

zsh_plugins_txt="$DOTFILES_ZSH/.zsh_plugins.txt"
zsh_plugins_zsh="$HOME/.zsh_plugins.zsh"

# Lazy-load antidote from its functions directory.
if use_brew; then
    fpath=(/home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/functions $fpath)
else
    fpath=($HOME/.antidote/functions $fpath)
fi
autoload -Uz antidote

# Rebuild bundle on missing or .txt change
if [[ ! ${zsh_plugins_zsh} -nt ${zsh_plugins_txt} ]]; then
    antidote bundle <${zsh_plugins_txt} >|${zsh_plugins_zsh}
fi

# Source bundle
source ${zsh_plugins_zsh}
unset zsh_plugins_txt zsh_plugins_zsh

# Config fragments
for f in ${DOTFILES_ZSH}/conf.d/*.zsh; do source "$f"; done

# Environment specific overrides
_env_file="${DOTFILES_ZSH}/env/${DOTFILES_ENV}.zsh"
[[ -f "$_env_file" ]] && source "$_env_file"

# Tools
eval "$(starship init zsh)"
