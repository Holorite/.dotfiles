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

# Init zsh-vi-mode during plugin sourcing rather than via its post-init hook,
# so widget-wrapping plugins (fzf, autosuggestions, sage, ...) load normally
# without needing zvm_after_init_commands workarounds.
ZVM_INIT_MODE=sourcing

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

# Pre-define _sage_orig_<widget> as user widgets pointing at the builtin
# `.widget` form, before zsh-sage initializes. zsh-sage normally creates these
# via `zle -A self-insert _sage_orig_self-insert`, which leaves the widget
# typed `builtin` in $widgets — and fast-syntax-highlighting then generates a
# wrapper that calls `._sage_orig_self-insert`, which isn't a real builtin
# (cue "no such widget" on the first keystroke). Pre-binding as user widgets
# keeps fsh on its `user:*` branch and sage's existence check skips the alias.
for _w in self-insert forward-char forward-word accept-line \
          expand-or-complete backward-kill-word backward-delete-char \
          bracketed-paste; do
    eval "_sage_orig_passthrough_${_w//-/_}() { zle .${_w}; }"
    zle -N "_sage_orig_$_w" "_sage_orig_passthrough_${_w//-/_}"
done
unset _w

# Source the bundle inside an anonymous function so `local_options` applies.
# `no_monitor` suppresses the `[N] PID` job-start line that zsh-sage's coproc
# would otherwise print at first source (it kicks the coproc during init).
() {
    setopt local_options no_monitor
    source "$zsh_plugins_zsh"
}
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

export ZSH_SAGE_AI_ENABLED=true
