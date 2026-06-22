# Point $BROWSER at the headless/SSH/WSL wrapper (bin/.local/bin/browser-open),
# so `gh browse`, `xdg-open`, `python -m webbrowser`, etc. route the URL to a
# real browser instead of erroring on these displayless hosts.
#
# Only set it when unset: a VS Code / JetBrains remote session installs its own
# $BROWSER forwarder, and a real GUI session has a working default — defer to
# both. The wrapper itself decides wslview vs. lemonade vs. printed-link.
if [[ -z "${BROWSER:-}" ]] && command -v browser-open >/dev/null 2>&1; then
    export BROWSER=browser-open
fi
