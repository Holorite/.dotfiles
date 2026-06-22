# shellcheck shell=bash
# ── Colors ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${GREEN}[info]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} $1"; exit 1; }

# ── Bin dir ────────────────────────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
[[ ":$PATH:" == *":$BIN_DIR:"* ]] || export PATH="$BIN_DIR:$PATH"

# ── eget ───────────────────────────────────────────────────────────────────────
EGET="$BIN_DIR/eget"

ensure_eget() {
    if [[ -x "$EGET" ]]; then
        return 0
    fi
    info "Bootstrapping eget..."
    local tmp
    tmp=$(mktemp -d) || error "Failed to create tempdir"
    (cd "$tmp" && curl -sSL https://zyedidia.github.io/eget.sh | sh) >/dev/null \
        || { rm -rf "$tmp"; error "Failed to bootstrap eget"; }
    mv "$tmp/eget" "$EGET"
    rm -rf "$tmp"
    info "eget installed at $EGET"
}

# Wrap eget with anti-match filters for distro-package assets we never want
# in ~/.local/bin. Multiple GitHub releases ship .deb/.rpm/.apk alongside the
# portable archive, which would otherwise trip eget's interactive disambig
# prompt. Callers can still pass extra --asset filters on top.
eget_install() {
    "$EGET" --asset ^.deb --asset ^.rpm --asset ^.apk "$@"
}

# ── brew (Linuxbrew, home env only) ────────────────────────────────────────────
source "$(dirname "${BASH_SOURCE[0]}")/../.utils.sh"

export BREW="${BREW:-}"

ensure_brew() {
    use_brew || return 1
    if [[ -n "$BREW" && -x "$BREW" ]]; then
        return 0
    fi
    local candidate
    for candidate in /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
        if [[ -x "$candidate" ]]; then
            BREW="$candidate"
            eval "$("$BREW" shellenv)"
            return 0
        fi
    done
    info "Bootstrapping Linuxbrew..."
    bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || error "brew bootstrap failed"
    BREW=/home/linuxbrew/.linuxbrew/bin/brew
    [[ -x "$BREW" ]] || error "brew not found at $BREW after bootstrap"
    eval "$("$BREW" shellenv)"
}

# Try to install via brew. Returns 0 on success, 1 if env != home (caller falls
# back). brew install failures are fatal — opting into brew with a missing
# formula is a configuration bug, not a transient.
# Args: <formula> [extra brew install args...]
try_brew() {
    ensure_brew || return 1
    "$BREW" install "$@" || error "brew install $* failed"
}

# ── Install helpers ────────────────────────────────────────────────────────────
# Returns 0 if the caller should (re)install, 1 to skip.
# Honors REINSTALL=1 to force reinstall without prompting; skips silently
# when stdin isn't a TTY and REINSTALL isn't set.
_should_install_prompt() {
    local name="$1"
    if [[ "${REINSTALL:-}" == "1" ]]; then
        return 0
    elif [[ "${REINSTALL:-}" == "0" ]]; then
        return 1
    fi
    if [[ ! -t 0 ]]; then
        return 1
    fi
    local ans
    read -rp "Reinstall $name? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

# Decide whether to install a binary tool.
# Args: <cmd> [<version-cmd>...]
should_install() {
    local cmd="$1"
    shift
    if ! command -v "$cmd" &>/dev/null; then
        return 0
    fi
    local version=""
    if [[ $# -gt 0 ]]; then
        version=" ($("$@" 2>&1 | head -1))"
    fi
    info "$cmd already installed$version"
    _should_install_prompt "$cmd"
}

# Decide whether to install something rooted at a path.
# Args: <name> <path>
should_install_path() {
    local name="$1" 
    shift
    paths=("$@")
    local missing=1
    for path in "${paths[@]}"; do
        if [[ -e "$path" ]]; then
            missing=0
            break
        fi
    done
    if [[ $missing -eq 1 ]]; then
        return 0
    fi
    info "$name already installed"
    _should_install_prompt "$name"
}
