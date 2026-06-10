export NVM_DIR="$(nvm_dir)"

# Put the latest nvm-installed node on PATH without sourcing nvm.sh
# (sourcing nvm.sh runs nvm_auto and adds ~1.3s to shell startup).
# Run `nvm-load` if you actually need the nvm CLI.
_nvm_versions=("$NVM_DIR"/versions/node/v*(N/))
if (( ${#_nvm_versions} )); then
    path=("${_nvm_versions[-1]}/bin" $path)
fi
unset _nvm_versions

nvm-load() {
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
}
