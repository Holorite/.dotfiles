: ${NTFY_URL:=https://ntfy.sh}

notify() {
    local exit_code=$?
    if [[ -z "${NTFY_TOPIC:-}" ]]; then
        print -u2 "notify: NTFY_TOPIC not set (add to ~/.zsh_secrets)"
        return 1
    fi
    local msg="${*:-done}"
    local title="$HOST"
    local priority="default"
    if (( exit_code != 0 )); then
        title="$HOST (exit $exit_code)"
        priority="high"
    fi
    curl -sf \
        -H "Title: $title" \
        -H "Priority: $priority" \
        -d "$msg" \
        "$NTFY_URL/$NTFY_TOPIC" >/dev/null
}
