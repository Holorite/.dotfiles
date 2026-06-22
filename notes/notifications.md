# Cross-environment notifications via ntfy

Plan and progress for getting real desktop toasts from any SSH/tmux depth, with eventual click-to-navigate back to the originating WT window / tmux pane.

## Pipeline

`Windows -> Windows Terminal -> SSH -> Debian -> tmux -> [optional nested SSH] -> command`

Notifications must originate from the innermost shell and surface as Windows toasts (and Linux toasts later, if/when desktop Linux returns to the picture).

## Why ntfy

Considered: ntfy, Gotify, Pushover, Pushbullet, Apprise, Telegram/Slack/Discord, BEL/OSC sequences, BurntToast direct.

Decision: **self-hosted ntfy**. Reasons:

- Self-hostable single Go binary; no third-party data hosting once deployed.
- Action buttons supported (multiple click handlers per notification, including `view` URL, `http` request, `broadcast` Android intent). Gotify lacks this — its open issue for actions is stale.
- Cross-platform clients including a web subscriber and Android app; Linux subscribers are trivial via `ntfy subscribe ... | notify-send`.
- The `Click` header gives single-URL click handling out of the box, which is enough for the click-navigate plan via custom URL scheme.

Ruled out:

- **OSC 9 / OSC 777 escape sequences -> Windows Terminal toasts.** WT 1.24 does NOT render desktop toasts from these. It only honors a narrow set of OSC 9 sub-sequences (CWD, progress bar). Earlier assumption was wrong.
- **WT BEL + `bellStyle: "window"`.** Works for tab/taskbar flash, but not a real toast. Useful as a cheap visual fallback only. Both `Windows PowerShell` and `Ubuntu` profiles in `windows/terminal/settings.json` override `bellStyle` to `"none"`; the `defaults` block sets `"window"`. Remove the per-profile overrides if reviving this fallback.
- **Telegram/Slack/Discord/email.** Click handling lands in the chat/mail client, not in a registered desktop URL handler. Bad fit for click-to-navigate.
- **Gotify.** Same self-host story but no action buttons and no iOS app (irrelevant here, but signals smaller scope).

## Architecture

Three layers, each with options:

1. **Detection** - knowing when to fire. Options: `tmux-notify` (rickstaa, watches pane content for prompt return), `undistract-me`, `zsh-notify`, or explicit user-driven `notify` calls. Detection is best-effort and breaks inside TUIs (vim/less); explicit wrappers don't.
2. **Transport** - HTTP POST to ntfy. Single shared mechanism across hosts.
3. **Receive + navigate** - per-OS subscriber. Toast on receive; on click, dispatch via custom URL scheme to a handler script that focuses WT and (eventually) navigates tmux.

The `notify` shell function is the transport. `tmux-notify` is configured to call it via `@tnotify-custom-cmd`. Anything else that wants to ping (cron, CI, scripts) calls the function directly.

## Click-to-navigate, future plan

Roughly increasing fidelity:

- **Click-to-window.** Capture WT window name at send time. Custom URL scheme `tmuxnav://` registered in `HKCU\Software\Classes\tmuxnav\shell\open\command` on Windows. Click -> handler script -> `wt.exe -w <name> focus-tab`. Requires `WT_SESSION` propagation through SSH (`SendEnv WT_SESSION` in `~/.ssh/config` + `AcceptEnv WT_SESSION` in remote `sshd_config`).
- **Click-to-pane.** Add SSH `ControlMaster auto` / `ControlPath` for fast reconnect. Handler walks the host chain and runs `tmux switch-client -t session:win.pane` on the right remote.

Hard parts:

- WT has no `wt focus --session-id <WT_SESSION>` - have to use window names/indices, requires a naming convention.
- Nested SSH needs ControlMaster set up at every hop, otherwise re-auth on every click.
- Detection of the originating WT window from inside tmux requires either env propagation or a per-pane convention.

## Current state

- **Transport validated** (task #4 done). `curl -d "msg" https://ntfy.sh/<topic>` works from:
    - Windows PowerShell (with `--ssl-no-revoke` flag on this network — corporate cert revocation endpoint blocked; not a real security issue for our use case)
    - Debian over SSH
    - Inside tmux on Debian
- **Topic:** stored in `~/.zsh_secrets` as `NTFY_TOPIC`. Treat the topic name like a password until self-hosting lands - public ntfy.sh topics are world-readable if guessed.
- **`notify` shell function** at `zsh/conf.d/notify.zsh:1`. Captures `$?` as first action so exit-code awareness works (`false; notify "msg"` -> priority high, title includes exit code). Default message is `done`. Returns 1 with stderr message if `NTFY_TOPIC` unset.
- **Browser subscriber** at `https://ntfy.sh/<topic>` is the only receiver so far. No native desktop toasts yet.

## Tasks (matches harness task list)

| # | Status | What |
|---|---|---|
| 1 | done | Add `notify` shell function (zsh/conf.d/notify.zsh) |
| 4 | done | Validate ntfy transport end-to-end |
| 5 | pending | Windows BurntToast subscriber - PowerShell streams ntfy JSON, calls `New-BurntToastNotification`. Run on login or as scheduled task. **Most valuable next step** - this is what turns the browser tab into real toasts. |
| 7 | pending | Wire up `tmux-notify` to use `notify` via `@tnotify-custom-cmd 'notify'`. Handles auto-detection inside tmux. Cheap once #5 is in. |
| 6 | pending | Self-host ntfy server. Single Go binary. Pick a host, expose HTTPS, add basic auth so the topic is no longer world-publishable. Switch `NTFY_URL` and re-validate. |
| 2 | pending | Click-to-WT-window navigation. Register `tmuxnav://` scheme handler. Capture WT window name + `WT_SESSION` and embed in `Click:` header on send. SSH env propagation required. |
| 3 | pending | Click-to-tmux-pane navigation. ControlMaster, host chain walking, remote `tmux switch-client`. |

## Quirks worth remembering

- **Windows curl + corporate networks.** schannel CRL/OCSP check fails with `CRYPT_E_NO_REVOCATION_CHECK`. Use `--ssl-no-revoke` or switch to `Invoke-RestMethod` (different TLS stack).
- **`local exit_code=$?` must be the first line of `notify`.** Anything earlier resets `$?` to that command's status.
- **`tmux-notify` won't fire from inside TUIs** (vim, less) because prompt-detection breaks - explicit `notify` calls handle that gap.
- **Per-profile `bellStyle: "none"` overrides** in WT settings would re-suppress BEL fallbacks if we ever wanted them back.
- **OSC 9/777 are dead ends** in WT 1.24. Don't waste time retrying.

## File index

- `zsh/conf.d/notify.zsh` - the `notify` function
- `zsh/.zshrc` - sources `.zsh_secrets` then `conf.d/*.zsh`, so `NTFY_TOPIC` is available before the function is defined
- `tmux/.tmux.conf:14` - `set -g allow-passthrough on` (was relevant for the abandoned OSC plan, harmless to leave)
- `windows/terminal/settings.json` - WT settings (NOT stowed; the live file is in `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_*\LocalState\settings.json`)
