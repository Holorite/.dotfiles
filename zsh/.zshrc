DOTFILES_ZSH="$(dirname "$(readlink -f "$HOME/.zshrc")")"
DOTFILES_DIR="$(dirname "$DOTFILES_ZSH")"

# ── Environment ──────────────────────────────────────────────
if [[ -f "$HOME/.dotfiles_env" ]]; then
    export DOTFILES_ENV="$(<"$HOME/.dotfiles_env")"
else
    export DOTFILES_ENV="default"
fi

# ── Utils ────────────────────────────────────────────────────
source "$DOTFILES_DIR/.utils.sh"

# ── Path ─────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Plugins ──────────────────────────────────────────────────
# Static-file fast path: rebundle only when .zsh_plugins.txt changes.

zvm_after_init_commands+=('[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh')
zvm_after_init_commands+=('source <(fzf --zsh)')

zsh_plugins_txt="$DOTFILES_ZSH/.zsh_plugins.txt"
zsh_plugins_zsh="$HOME/.zsh_plugins.zsh"

# Lazy-load antidote from its functions directory.
if use_brew; then
    fpath=(/home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/functions $fpath)
else
    fpath=("$HOME/.antidote/functions" $fpath)
fi
autoload -Uz antidote

# Rebuild bundle when missing or when the plugin list is newer.
if [[ ! "$zsh_plugins_zsh" -nt "$zsh_plugins_txt" ]]; then
    antidote bundle <"$zsh_plugins_txt" >|"$zsh_plugins_zsh"
fi

source "$zsh_plugins_zsh"
unset zsh_plugins_txt zsh_plugins_zsh

# ── Config ----------─────────────────────────────────────────

# Secrets
[[ -f "$DOTFILES_ZSH/.zsh_secrets" ]] && source "$DOTFILES_ZSH/.zsh_secrets"

# Config fragments
for fragment in "$DOTFILES_ZSH"/conf.d/*.zsh; do
    source "$fragment"
done
unset fragment

# Environment overrides
env_file="$DOTFILES_ZSH/env/$DOTFILES_ENV.zsh"
[[ -f "$env_file" ]] && source "$env_file"
unset env_file

# ── Prompt ───────────────────────────────────────────────────
eval "$(starship init zsh)"
