# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed with GNU Stow. Top-level package directories (`nvim/`, `zsh/`, `git/`, `tmux/`, `bin/`) mirror `$HOME` layout and are symlinked into place by `stow`. `install/` holds per-tool bootstrap scripts. `windows/` and `windows_setup.ps1` are for the Windows laptop (symlinks the Windows Terminal `settings.json` and installs the `lemonade server` half of the `$BROWSER` setup — see below).

## Common commands

```sh
./install.sh              # stow only (default)
./install.sh list         # list available installers
./install.sh <name>       # run one installer, then stow
./install.sh all          # run every installer, then stow
./install.sh all-confirm  # prompt Y/n per installer, then stow
./install.sh missing      # run every installer non-interactively (REINSTALL=0), installing only what's absent
REINSTALL=1 ./install.sh <name>  # force reinstall a tool that's already present
```

The stow step always runs at the end and links `nvim zsh git tmux bin` into `$HOME` (plus `claude` on non-`home` envs). The `bin/` package holds standalone helper scripts that land on `$PATH` via `bin/.local/bin/` (e.g. `browser-open`, the `$BROWSER` wrapper, and `open-file`, which opens an NFS path in the laptop's Explorer — both route by env and share the lemonade tunnel; see below).

## DOTFILES_ENV

First run prompts for an environment and writes the choice to `~/.dotfiles_env`. Valid values: `work-argos`, `work-devcompute`, `home`. The variable is exported before installers run, sourced by `.zshrc`, and read by `nvim/.config/nvim/init.lua`. Behavior gated on it:

- `install/lib.sh:ensure_brew` — Linuxbrew is bootstrapped/used only when `use_brew` returns true (currently `home`). `try_brew` returns 1 elsewhere so installers fall back to `eget`.
- `.utils.sh` (repo root, non-stowed) defines `use_brew()` — the canonical brew-vs-fallback gate. Sourced by both `install/lib.sh` and `zsh/.zshrc` so installers and the live shell agree. Use it instead of inlining the env check.
- `.utils.sh` also defines `workspace_dir()` — the canonical big-disk root for the env (home is small on work hosts): `/local/mnt/workspace/juliray` (devcompute), `/prj/qct/mlsys/markham/scratch/juliray` (argos), `$HOME` elsewhere. Park large/regenerable data here and derive specific paths from it rather than re-checking the env. Built on it: `nvm_dir()` → `$(workspace_dir)/.nvm` (used by `install/nvm/install.sh` and `zsh/conf.d/nvm.zsh`); `zsh/conf.d/python.zsh` exports `PIP_CACHE_DIR`, `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR` under `$(workspace_dir)` to keep pip/uv off home.
- `.utils.sh` also defines `work_vault_dir()` (→ `$(workspace_dir)/work-vault`, override `$WORK_VAULT_DIR`) and `work_vault_remote()` (→ a private personal repo on GHE, `github.qualcomm.com/juliray/work-vault`, override `$WORK_VAULT_REMOTE`) — the seams for the **work-vault** (see its own section below). Lives under `workspace_dir` so the vault stays off the small home partition on work hosts; on the laptop / any `home` env `workspace_dir` is already `$HOME`, so it lands at `$HOME/work-vault` there (where Obsidian opens the graph). The local path may thus differ per host — harmless, since the git remote (not the path) is what ties every clone together. `zsh/conf.d/work-vault.zsh` exports `WORK_VAULT_DIR` from the seam so the `work-vault` helper, the slash commands, and the `vault-explorer` agent all resolve the same path.
- `zsh/env/<env>.zsh` is sourced after `conf.d/*.zsh` for env-specific paths/aliases.
- `git/.gitconfig.<env>` is symlinked to `~/.gitconfig.local` (included by `git/.gitconfig`).
- The `ssh/` package (`ssh/.ssh/config`) is stowed on the work envs only (alongside `claude`), so the repo owns the work `~/.ssh/config`. Because that path is normally a real hand-edited file, `install.sh` moves any pre-existing non-symlink to `~/.ssh/config.pre-stow.bak` before stowing. It carries the `lemonade` `RemoteForward 2489` block (the `$BROWSER` tunnel — see below); the laptop's equivalent is written by `windows_setup.ps1`, not stowed.
- `init.lua` configures `clangd` to run via `./run-in-docker` on the work envs, plain `clangd` on home.
- `install/claude-code/install.sh` runs only on the work envs (it pulls Claude Code from Qualcomm's internal qgenie installer and registers the Tavily search MCP, both corp-network-only). It gates with an explicit `case "${DOTFILES_ENV:-}"` rather than a `.utils.sh` helper, since the condition (work-only) doesn't match `use_brew`'s home-only sense — follow this `case` pattern for other work-only installers.
- `install/work-vault/install.sh` also runs only on the work envs (same `case` pattern — the vault remote is a private repo on GHE, `github.qualcomm.com`, corp-network-only). Clones/creates the work-vault repo to `$(workspace_dir)/work-vault` — see the **work-vault** section below.

When adding env-conditional logic, follow these existing seams rather than introducing new env checks.

## Installer conventions (`install/<name>/install.sh`)

Every installer sources `install/lib.sh` and follows the same shape. Use the helpers — don't reinvent them:

- `should_install <cmd> [version-cmd...]` / `should_install_path <name> <path>` — gates the install. Honors `REINSTALL=1`; silently skips when stdin isn't a TTY.
- `try_brew <formula>` — installs via brew on `home`, returns 1 elsewhere so callers fall back. brew failures are fatal (treated as a config bug, not transient).
- `ensure_eget` + `eget_install <gh-repo> --to "$BIN_DIR"` — the standard non-brew fallback. The wrapper anti-matches `.deb`/`.rpm`/`.apk` so eget doesn't prompt; pass extra `--asset` flags to disambiguate further (e.g. gnu vs musl, arm64 vs x86_64). Binaries land in `$HOME/.local/bin`.
- `info` / `error` for logging; `error` exits non-zero.

All installer scripts run with `set -euo pipefail`.

New `install/<name>/install.sh` files must be `chmod +x` — the dispatcher in `install.sh` only picks up executable installers (silently skips otherwise).

`install/claude-code/install.sh` shows two non-binary-install patterns worth reusing: (1) it registers a remote MCP server (`claude mcp add --scope user`) whose config lands in `~/.claude.json` — not a stowable file, so the installer *is* the version-controlled recipe; (2) the Tavily key is stored as the literal `${TAVILY_API_KEY}` (single-quoted so the shell doesn't expand it) for Claude to expand at runtime, keeping the secret out of `~/.claude.json` — it lives only in `~/.zsh_secrets`. MCP idempotency uses `claude mcp get <name>` (the binary may need `hash -r` first on a fresh install, since bash caches command lookups).

## Zsh layout

`zsh/.zshrc` is intentionally tiny. It loads, in order: secrets (`zsh/.zsh_secrets`, gitignored) → antidote plugins (`.zsh_plugins.txt`) → every `conf.d/*.zsh` fragment → the matching `env/<DOTFILES_ENV>.zsh` → `starship init`. Add new shell behavior as a fragment in `conf.d/` (general) or `env/` (env-specific), not inline in `.zshrc`.

`zsh/conf.d/notify.zsh` defines `notify [msg]` — POSTs a message to an [ntfy](https://ntfy.sh) topic so a long command can ping your phone/desktop when it finishes (`some-long-build; notify "build done"`). It captures `$?` first, so the title/priority reflect the preceding command's exit status. Config via `~/.zsh_secrets` (gitignored): `NTFY_TOPIC` (required) and `NTFY_URL` (defaults to the public `https://ntfy.sh`). The cross-environment design rationale — why ntfy over OSC escapes / Gotify / chat webhooks, and the eventual click-to-navigate-back plan — lives in `notes/notifications.md`.

## work-vault (Claude working-context + notes)

A git-synced Obsidian vault that doubles as Claude's structured working-context store and a home for regular notes. It exists to solve two coupled problems (see `notes/improvements.md` §3–4): scattered, undiscoverable handoff markdown, and main-context bloat when several explorations finish. **Three stores, clean boundary:** the vault (live, connected working-context) vs. `notes/` (decisions about *this* repo, committed with it) vs. Claude `memory/` (durable atomic facts).

- **Repo + location.** Dedicated private repo `github.qualcomm.com/juliray/work-vault` on GHE — the corp-hosted platform, which is the CCI-correct home for the vault's Yellow/Red content (external `github.com` cloud is not). A *personal* repo is fine while the vault is single-user; CCI requires a GHE org + N2K team only if it must be shared with multiple users (a personal repo can't attach an N2K team). Cloned to `$(workspace_dir)/work-vault` on each work host (off the small home partition) and to `$HOME/work-vault` on the laptop / `home` env (where `workspace_dir` is `$HOME`, and where Obsidian opens the graph). Created/cloned by `install/work-vault/install.sh` (work-gated). Seams: `work_vault_dir()` / `work_vault_remote()` in `.utils.sh`, `WORK_VAULT_DIR` exported by `zsh/conf.d/work-vault.zsh`.
- **Layout** = folders by note *type*, files prefixed by project slug so wikilinks are unambiguous: `index.md` (top MOC) → `projects/<slug>.md` (per-project MOC) → linked `explorations/<slug>--<topic>.md`, `plans/...`, `tasks/...`. Machine-generated notes stay in the type folders; freeform personal notes live anywhere else in the same vault and wikilink in.
- **`bin/.local/bin/work-vault`** — thin CLI all the Claude pieces call so they stay declarative and share one source of truth for the layout + git-sync: `dir` (print vault path, error if absent), `slug` (derive project key from cwd's git remote, fallback dir name), `moc <slug>` (ensure project MOC, idempotent), `reindex` (regenerate every MOC's link lists + the top index from the notes on disk), `sync "<msg>"` (reindex, then add+commit+push, push failure non-fatal).
- **Script-managed navigation.** The MOC link lists (`## Explorations`/`## Plans`/`## Tasks`) and `index.md`'s `## Projects` list are **derived views**, not hand-maintained. `reindex` walks the type folders, buckets notes by their `project:` frontmatter, and rewrites only the marker-bounded regions (`<!-- auto:NAME -->` … `<!-- /auto:NAME -->`), using each note's `gist:` field as the bullet text; prose outside the markers is preserved, and the splice-after-heading path normalizes pre-existing marker-less MOCs. `sync` reindexes first, so every save/explore self-heals navigation in the same commit. Consequence: note-writers (`vault-save`, the `vault-explorer` agent) just drop a correctly-named file carrying `project:` + `gist:` frontmatter and never touch the MOC.
- **Stowed Claude customization** (`claude/` package, work envs only — committing this also closed `notes/improvements.md` §4, which had *zero* version-controlled commands/agents): `claude/.claude/agents/vault-explorer.md` (explores a subtopic in its own context, writes full findings to the vault, returns only a short summary + path — the actual fix for context-waste, since slash commands run *in* main context and can't evict) and `claude/.claude/commands/vault-{save,load,project}.md`. When adding more Claude commands/agents, put them under `claude/.claude/{commands,agents}/` so they version-control and stow.

## Neovim layout

`nvim/.config/nvim/` is stow-ed to `~/.config/nvim`. `init.lua` sets options/keymaps and bootstraps `lazy.nvim` via `lua/config/lazy.lua`; each plugin spec is its own file under `lua/plugins/`. `lazy-lock.json` is committed.

## Repo-specific git config

`install.sh` pins `user.email = julian.r8y@gmail.com` on this repo (overrides any work email a global gitconfig might set). `git/.gitconfig` sets `status.showUntrackedFiles = no`, so `git status` here hides untracked files by default — use `git status -u` when you need to see them.

## Files that aren't stow-ed

`.stow-local-ignore` (top-level and per-package) excludes things like `install.sh`, `.git`, `.zsh_secrets`, and `.gitconfig.local` from symlinking. Adding a new file at a package root that *shouldn't* land in `$HOME` requires adding it to the relevant `.stow-local-ignore`.
Any file that is sourced in a stowed module via a direct path to the dotfiles folder should not be stowed.
