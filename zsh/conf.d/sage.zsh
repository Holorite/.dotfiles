#
# zsh-sage workarounds
#
# Sage's `bindkey '^N' sage-cycle` lands in `main`, but zvm's viins/vicmd
# keymaps don't pick it up; right-arrow may also be bound to a non-`forward-char`
# widget by zvm, so sage's accept never fires. Re-bind in the vi keymaps.
# (Coproc `[N] PID` notification is suppressed by sourcing the bundle with
# `no_monitor` in .zshrc — no patch needed here for that.)
#

# Skip if sage isn't loaded.
(( $+functions[_sage_widget_init] )) || return

# ── Catppuccin Mocha confidence colors ──────────────────────────
# Sage reads these at every keystroke so setting them after init is fine.
ZSH_SAGE_COLOR_HIGH='#f2cdcd'   # flamingo
ZSH_SAGE_COLOR_MED='#a6adc8'    # subtext0
ZSH_SAGE_COLOR_LOW='#585b70'    # surface2

# Runs after both zvm and sage have sourced (this fragment loads after the
# antidote bundle), so zvm's keymaps and sage's widgets both exist.
if [[ -n "${ZVM_VERSION-}" ]] || (( $+functions[zvm_init] )); then
    bindkey -M viins '^N' sage-cycle
    bindkey -M vicmd '^N' sage-cycle
    # Ctrl-E accepts the full suggestion; Ctrl-F accepts one word.
    bindkey -M viins '^E' forward-char
    bindkey -M viins '^F' forward-word
fi

