DOTFILES_ZSH="$(dirname "$(readlink -f "${HOME}/.zshrc")")"
DOTFILES_DIR="$(dirname "$DOTFILES_ZSH")"

# Environment detection
if [[ -f "$HOME/.dotfiles_env" ]]; then
    export DOTFILES_ENV=$(< "$HOME/.dotfiles_env")
else
    export DOTFILES_ENV="default"
fi

# Path
export PATH="$HOME/.local/bin:$PATH"

# Secrets
[[ -f "$DOTFILES_ZSH/.zsh_secrets" ]] && source $DOTFILES_ZSH/.zsh_secrets

# Config fragments
for f in ${DOTFILES_ZSH}/conf.d/*.zsh; do source "$f"; done

# Environment specific overrides
_env_file="${DOTFILES_ZSH}/env/${DOTFILES_ENV}.zsh"
[[ -f "$_env_file" ]] && source "$_env_file"

# Plugins
source $HOME/.antidote/antidote.zsh
zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')
zvm_after_init_commands+=('source <(fzf --zsh)')
antidote load

# Tools
eval "$(starship init zsh)"
