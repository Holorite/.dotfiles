# Seed LS_COLORS — eza doesn't set it, but the completion menu (and anything
# else that respects LS_COLORS) reads it. vivid generates a themed palette;
# fall back to dircolors if vivid isn't installed.
if (( $+commands[vivid] )); then
    export LS_COLORS="$(vivid generate catppuccin-mocha)"
elif (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
fi

# Color the completion menu using LS_COLORS.
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:default' list-colors "${(s.:.)LS_COLORS}"

# Case-insensitive + substring matching:
#   m:{a-zA-Z}={A-Za-z}  case-insensitive
#   r:|=*                match at any position (e.g. one<Tab> -> hello_one)
#   l:|=* r:|=*          partial-word fallback
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Arrow-key menu selection.
zstyle ':completion:*' menu select
