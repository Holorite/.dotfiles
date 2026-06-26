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

The stow step always runs at the end and links `nvim zsh git tmux bin zk` into `$HOME` (plus `claude` on non-`home` envs). The `bin/` package holds standalone helper scripts that land on `$PATH` via `bin/.local/bin/` (e.g. `browser-open`, the `$BROWSER` wrapper, and `open-file`, which opens an NFS path in the laptop's Explorer — both route by env and share the lemonade tunnel; see below). The `zk/` package holds the global zk config (`zk/.config/zk/` → `~/.config/zk/`); see the **work-vault** section.

## DOTFILES_ENV

First run prompts for an environment and writes the choice to `~/.dotfiles_env`. Valid values: `work-argos`, `work-devcompute`, `home`. The variable is exported before installers run, sourced by `.zshrc`, and read by `nvim/.config/nvim/init.lua`. Behavior gated on it:

- `install/lib.sh:ensure_brew` — Linuxbrew is bootstrapped/used only when `use_brew` returns true (currently `home`). `try_brew` returns 1 elsewhere so installers fall back to `eget`.
- `.utils.sh` (repo root, non-stowed) defines `use_brew()` — the canonical brew-vs-fallback gate. Sourced by both `install/lib.sh` and `zsh/.zshrc` so installers and the live shell agree. Use it instead of inlining the env check.
- `.utils.sh` also defines `workspace_dir()` — the canonical big-disk root for the env (home is small on work hosts): `/local/mnt/workspace/juliray` (devcompute), `/prj/qct/mlsys/markham/scratch/juliray` (argos), `$HOME` elsewhere. Park large/regenerable data here and derive specific paths from it rather than re-checking the env. Built on it: `nvm_dir()` → `$(workspace_dir)/.nvm` (used by `install/nvm/install.sh` and `zsh/conf.d/nvm.zsh`); `zsh/conf.d/python.zsh` exports `PIP_CACHE_DIR`, `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR` under `$(workspace_dir)` to keep pip/uv off home.
- `.utils.sh` also defines `work_vault_dir()` (→ `$(workspace_dir)/work-vault`, override `$WORK_VAULT_DIR`) and `work_vault_remote()` (→ a private personal repo on GHE, `github.qualcomm.com/juliray/work-vault`, override `$WORK_VAULT_REMOTE`) — the seams for the **work-vault** (see its own section below). Lives under `workspace_dir` so the vault stays off the small home partition on work hosts; on the laptop / any `home` env `workspace_dir` is already `$HOME`, so it lands at `$HOME/work-vault` there. The local path may thus differ per host — harmless, since the git remote (not the path) is what ties every clone together. `zsh/conf.d/vault.zsh` exports `WORK_VAULT_DIR` from the seam so the `vault` helper, the slash commands, and the `vault-explorer` agent all resolve the same path.
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

A git-synced zk notebook that doubles as Claude's structured working-context store and a home for regular notes. It exists to solve two coupled problems: scattered, undiscoverable handoff markdown, and main-context bloat when several explorations finish. **Three stores, clean boundary:** the vault (live, connected working-context) vs. `notes/` (decisions about *this* repo, committed with it) vs. Claude `memory/` (durable atomic facts).

- **Repo + location.** Dedicated private repo `github.qualcomm.com/juliray/work-vault` on GHE — the corp-hosted platform, which is the CCI-correct home for the vault's Yellow/Red content (external `github.com` cloud is not). A *personal* repo is fine while the vault is single-user; CCI requires a GHE org + N2K team only if it must be shared with multiple users (a personal repo can't attach an N2K team). Cloned to `$(workspace_dir)/work-vault` on each work host (off the small home partition) and to `$HOME/work-vault` on the laptop / `home` env (where `workspace_dir` is `$HOME`). Created/cloned by `install/work-vault/install.sh` (work-gated). Seams: `work_vault_dir()` / `work_vault_remote()` in `.utils.sh`, `WORK_VAULT_DIR` and `ZK_NOTEBOOK_DIR` exported by `zsh/conf.d/vault.zsh`.
- **Layout** = flat project directories, indexed by zk: `index.md` (top MOC) → `projects/<slug>/index.md` (per-project MOC) → linked `projects/<slug>/<topic>.md` notes. A note's **kind** (exploration / plan / task) is a frontmatter **tag** (`tags: [plan]`), not a subdirectory — so a note's kind is fluid (retag, don't move → wikilinks never break), tags compose, and `zk list --tag plan` / the `all-{explorations,plans,tasks}` named filters give cross-project views. Freeform personal notes live at the vault root (untagged) and wikilink into the same graph. The only required frontmatter is the kind tag (template-generated, never hand-typed); everything else stays plain — the first paragraph is the "lead" (gist), the `# heading` is the title, the directory determines the project.
- **zk (`.zk/`)** — Go CLI + built-in LSP server (`zk lsp`), installed at the end of `install/work-vault/install.sh` (there is no `install/zk/`). The zk config (`config.toml` + `templates/`) lives in the dotfiles **`zk` stow package** → `~/.config/zk/`, which zk reads as its *global* config and every notebook inherits — so the vault itself keeps only an **empty `.zk/` marker dir** (zk recognizes a notebook only by the presence of `.zk/`; config/templates resolve from the global dir). Edit `zk/.config/zk/config.toml` in dotfiles, not the vault. `config.toml` defines groups (exploration, plan, task, project — the three kind groups all share `paths = ["projects"]` and one `kinded.md` template, differing only in the name the note-creation alias selects via `-g`), wiki link format, the `all-*` named filters, and **aliases**. Note creation, search, relations, and MOC-ensure are zk aliases (not `vault` subcommands): `zk exploration|plan|task "<title>"` (create a flat kinded note in the current project — slug from `$ZK_CWD`, MOC ensured, `--extra` feeds the template's `tags:`; a **body piped on stdin** is captured into the note via the template's `{{content}}`, so `printf 'body' | zk plan "Title"` is a one-shot create-and-write — the `-i` flag is added automatically when stdin isn't a tty, leaving the interactive nvim flow untouched), `zk find <query>` (full-text → `path<TAB>title<TAB>lead` lines; for inline reading of a single match prefer `vault find`), `zk related <path>` (`--related` ∪ unlinked mentions, MOC rows dropped), `zk moc <slug>` (idempotent project-MOC ensure). The composed logic lives in zk, not bash. `~/.config/zk/templates/` holds the Handlebars templates (`default.md`, `kinded.md`, `note.md`, `task.md`, `project-moc.md`); the kind templates render `{{content}}` (the stdin body, empty in the interactive flow). The SQLite index (`notebook.db`, gitignored, lives in the vault's `.zk/`) is rebuilt per-host via `zk index`. zk-nvim provides Neovim integration (completions on `[[`, go-to-definition, dead-link diagnostics, backlinks).
- **`bin/.local/bin/vault`** — thin CLI holding only what zk has no native equivalent for: `dir` (print vault path, error if absent), `slug` (derive project key from cwd's git remote, fallback dir name — the seam the `zk slug`/note-creation aliases call back into), `find [-p] <query>` (locate a note by **title or filename** substring — *not* a full-text body search, which would match far too much; query and haystack are both normalized so `zk mcp`/`zk-mcp`/`ZK MCP` all match, and MOC `index.md` rows are dropped. A **single** match prints the note **body** to stdout for inline reading — the `@`-mention resolver that saves a Read round-trip; `>1` prints `path<TAB>title` lines; `0` exits 1; `-p` forces the path list even on a single match), `reindex` (regenerate every MOC's link lists + the top index via `zk list` queries; cd's to the vault so its cwd-relative root-notes query is stable), `sync "<msg>"` (reindex, then add+commit+push, push failure non-fatal). Note creation / search / relations / MOC-ensure moved to zk aliases (see the zk bullet above).
- **Script-managed navigation.** Each MOC and `index.md` has a single `<!-- auto:content -->` … `<!-- /auto:content -->` region that `reindex` rewrites in full (section headings + bullet lists). `reindex` runs one `zk list --tag <kind>` query per bucket (`## Explorations`/`## Plans`/`## Tasks`, plus a `## Notes` bucket for notes carrying none of those tags), formatting each bullet straight from zk: `{{link}}` yields the wikilink (honoring the notebook's link-format, so no path/stem reconstruction in bash) and `{{lead}}` (first paragraph, newline-collapsed + first-sentence-trimmed) is the bullet text — a heading appears only when that bucket is non-empty. Prose outside the markers is preserved. The `## Tasks` bucket is special: it's rendered by `render_tasks` in `vault` — a bash loop over `zk list`, not a `bullets-*` format alias — because each task expands to a parent bullet plus its **open sub-tasks** (body checkboxes, re-indented) and a `(done/total)` tracker. At the **top `index.md`** that bucket also groups tasks under a `### <project>` sub-heading and shows **open tasks only** (`status: done` hidden — the top index is an actionable dashboard); per-project MOCs list every task flat. `sync` reindexes first, so every save/explore self-heals navigation in the same commit. Consequence: note-writers (the `vault-explorer` agent) just drop a correctly-tagged file with a lead paragraph and never touch the MOC. MOC/index titles carry a `MOC:` prefix (template + seed).
- **Stowed Claude customization** (`claude/` package, work envs only): `claude/.claude/agents/vault-explorer.md` (explores a subtopic in its own context, writes full findings to the vault, returns only a short summary + path — the actual fix for context-waste, since slash commands run *in* main context and can't evict) and `claude/.claude/commands/{explore,act,improve}.md`. When adding more Claude commands/agents, put them under `claude/.claude/{commands,agents}/` so they version-control and stow.

## Neovim layout

`nvim/.config/nvim/` is stow-ed to `~/.config/nvim`. `init.lua` sets options/keymaps and bootstraps `lazy.nvim` via `lua/config/lazy.lua`; each plugin spec is its own file under `lua/plugins/`. `lazy-lock.json` is committed.

## Repo-specific git config

`install.sh` pins `user.email = julian.r8y@gmail.com` on this repo (overrides any work email a global gitconfig might set). `git/.gitconfig` sets `status.showUntrackedFiles = no`, so `git status` here hides untracked files by default — use `git status -u` when you need to see them.

## Files that aren't stow-ed

`.stow-local-ignore` (top-level and per-package) excludes things like `install.sh`, `.git`, `.zsh_secrets`, and `.gitconfig.local` from symlinking. Adding a new file at a package root that *shouldn't* land in `$HOME` requires adding it to the relevant `.stow-local-ignore`.
Any file that is sourced in a stowed module via a direct path to the dotfiles folder should not be stowed.
