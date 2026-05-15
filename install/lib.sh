# ── Colors ─────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

info()  { echo -e "${GREEN}[info]${NC} $1"; }
error() { echo -e "${RED}[error]${NC} $1"; exit 1; }

# ── Bin dir ────────────────────────────────────────────────────────────────────
BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"

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

# ── Install helpers ────────────────────────────────────────────────────────────
# Returns 0 if the caller should (re)install, 1 to skip.
# Honors REINSTALL=1 to force reinstall without prompting; skips silently
# when stdin isn't a TTY and REINSTALL isn't set.
_should_install_prompt() {
    local name="$1"
    if [[ "${REINSTALL:-}" == "1" ]]; then
        return 0
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
    local name="$1" path="$2"
    if [[ ! -e "$path" ]]; then
        return 0
    fi
    info "$name already installed"
    _should_install_prompt "$name"
}
