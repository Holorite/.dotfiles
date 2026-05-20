#
# Auto-activate the catppuccin-mocha fast-syntax-highlighting theme once.
# fsh loads via `kind:defer`, so its `fast-theme` function isn't available
# at conf.d source time — queue the call on `zsh-defer` (FIFO with fsh's
# own deferred load). fast-theme persists the choice to
# ~/.cache/fast-syntax-highlighting/current_theme.zsh, so subsequent shells
# skip this entirely.
#

(( $+functions[zsh-defer] )) || return
[[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fsh/catppuccin-mocha.ini" ]] || return
[[ ! -f "${XDG_CACHE_HOME:-$HOME/.cache}/fast-syntax-highlighting/current_theme.zsh" ]] || return

zsh-defer eval 'fast-theme XDG:catppuccin-mocha &>/dev/null'
