#!/usr/bin/env bash
#
# Usage:
#   install.sh                  # stow only (default)
#   install.sh list             # list available installers and exit
#   install.sh <name>           # run install/<name>/install.sh, then stow
#   install.sh all              # run every installer, then stow
#   install.sh all-confirm      # prompt Y/n for each installer, then stow
#
# Installers can branch on DOTFILES_ENV; this script sets it before
# dispatching to them.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/install/lib.sh"

# ── DOTFILES_ENV ───────────────────────────────────────────────────────────────
if [[ ! -f ~/.dotfiles_env ]]; then
    echo "Select DOTFILES_ENV:"
    echo "  1) work-argos"
    echo "  2) work-devcompute"
    echo "  3) home"
    printf "Choice [1-3]: "
    read -r env_choice
    case "$env_choice" in
        1) echo "work-argos"      > ~/.dotfiles_env ;;
        2) echo "work-devcompute" > ~/.dotfiles_env ;;
        3) echo "home"            > ~/.dotfiles_env ;;
        *) error "Invalid choice" ;;
    esac
fi
DOTFILES_ENV=$(cat ~/.dotfiles_env)
export DOTFILES_ENV
info "DOTFILES_ENV=$DOTFILES_ENV"

# Bootstrap brew up-front on home so subsequent installers find it on PATH.
ensure_brew || true

# ── Installers ─────────────────────────────────────────────────────────────────
INSTALLERS=()
for dir in "$SCRIPT_DIR"/install/*/; do
    name=$(basename "$dir")
    [[ -x "$dir/install.sh" ]] && INSTALLERS+=("$name")
done

run_installer() {
    local name="$1"
    local script="$SCRIPT_DIR/install/$name/install.sh"
    [[ -x "$script" ]] || error "Unknown installer: $name (no $script)"
    info "── $name ──────────────────────────────────────"
    "$script"
}

# ── Dispatch ───────────────────────────────────────────────────────────────────
target="${1:-}"
case "$target" in
    "")
        ;;
    list)
        echo "Available installers:"
        for name in "${INSTALLERS[@]}"; do
            echo "  $name"
        done
        exit 0
        ;;
    all)
        for name in "${INSTALLERS[@]}"; do
            run_installer "$name"
        done
        ;;
    missing)
        for name in "${INSTALLERS[@]}"; do
            REINSTALL=0 run_installer "$name"
        done
        ;;
    all-confirm)
        for name in "${INSTALLERS[@]}"; do
            printf "Install %s? [Y/n] " "$name"
            read -r ans
            if [[ -z "$ans" || "$ans" =~ ^[Yy]$ ]]; then
                run_installer "$name"
            fi
        done
        ;;
    *)
        run_installer "$target"
        ;;
esac

# ── stow guard ─────────────────────────────────────────────────────────────────
if ! command -v stow &>/dev/null; then
    info "stow not found — bootstrapping..."
    run_installer stow
    command -v stow &>/dev/null || error "stow still not on PATH after install"
fi

# ── stow ───────────────────────────────────────────────────────────────────────
stow -d "$SCRIPT_DIR" -t "$HOME" nvim zsh git tmux bin zk
if [[ "$DOTFILES_ENV" != "home" ]]; then
    # Back up hand-edited files that stow will replace with symlinks.
    for f in ~/.ssh/config ~/.claude/CLAUDE.md; do
        if [[ -e "$f" && ! -L "$f" ]]; then
            mv "$f" "${f}.pre-stow.bak"
            info "Backed up $f → ${f}.pre-stow.bak"
        fi
    done
    stow -d "$SCRIPT_DIR" -t "$HOME" claude ssh
fi

# ── Env-specific gitconfig ─────────────────────────────────────────────────────
if [[ -f "$SCRIPT_DIR/git/.gitconfig.$DOTFILES_ENV" ]]; then
    ln -sf "$SCRIPT_DIR/git/.gitconfig.$DOTFILES_ENV" ~/.gitconfig.local
    info "Linked ~/.gitconfig.local → git/.gitconfig.$DOTFILES_ENV"
fi

# Personal email for the dotfiles repo itself
git -C "$SCRIPT_DIR" config user.email julian.r8y@gmail.com

# Tracked git hooks (pre-commit shellcheck lint) for this repo
git -C "$SCRIPT_DIR" config core.hooksPath githooks

