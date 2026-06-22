# Dotfiles improvement backlog

Findings from a Claude session auditing this repo (2026-06-22). Ordered by leverage.

## 1. Web search via MCP (IN PROGRESS)

**Diagnosis:** Built-in `WebSearch` fails because Anthropic geo-gates it to US-only — *not* a
Canada network block. Confirmed `curl` to google.com and duckduckgo.com both return 200 from
this host. `WebFetch` (fetch a known URL) is not gated the same way and works.

**Fix:** Route search through an MCP server that calls a search API over plain HTTPS.
**Chosen provider: Tavily** (account created). Key lives in `~/.zsh_secrets` (gitignored),
referenced from MCP config so nothing secret is committed.

## 2. `gh browse` / `xdg-open` failing — `$BROWSER` is empty (DONE)

**Diagnosis:** No display server and `$BROWSER` unset, so `xdg-open` has nothing to launch.

**Fix shipped:** `bin/.local/bin/browser-open` (new top-level `bin/` stow package →
`~/.local/bin`, on PATH everywhere) is the `$BROWSER` target, set by
`zsh/conf.d/browser.zsh` *only when `$BROWSER` is unset* (so a VS Code/JetBrains
remote session's own forwarder wins). The wrapper routes by environment:

- **WSL (home):** `wslview` (fallback `explorer.exe`) → real tab in the Windows
  browser. No daemon, no tunnel.
- **Work (SSH):** `lemonade open <url>` → real tab on the laptop, via an `ssh -R`
  tunnel to `lemonade server` running on the laptop. Remote half installed by
  `install/lemonade/install.sh` (work-env-gated; eget fallback).
- **Fallback (lemonade server down / unsupported):** prints an OSC8 clickable
  link **and** copies the URL to the laptop clipboard via OSC52 (tmux passthrough
  aware). Never just errors.

**One-time laptop setup (Windows):** scripted in `windows_setup.ps1` — it
downloads `lemonade.exe`, puts it on the user PATH, registers a `lemonade-server`
scheduled task (`server --allow 127.0.0.1`) that runs at logon, and appends the
`RemoteForward 2489` block to `%USERPROFILE%\.ssh\config` (marker-guarded).

**The SSH chain.** The forward must exist on *every* machine in an ssh chain,
not just the laptop — re-forwarding the *same* port 2489 at each hop plugs into
the previous hop's tunnel, so `gh browse` reaches the laptop at any depth
(laptop → work → another machine → ...). Coverage:
- **Laptop** (chain root): block written by `windows_setup.ps1` (above).
- **Work hosts**: stowed `ssh/` package (`ssh/.ssh/config`, work envs only) — the
  repo is now the canonical owner of the work `~/.ssh/config`; `install.sh` backs
  up any pre-existing real file to `~/.ssh/config.pre-stow.bak` before stowing.
- **Further machines**: covered automatically if they have these dotfiles;
  otherwise add the block there too, or `ssh -R 2489:127.0.0.1:2489` for a one-off.

The forward block is scoped `Host * !github.com !github.qualcomm.com
!github.com-qcom-eng-650` so it applies to every machine you hop to but not the
git remotes (GitHub denies port forwarding and would warn on every push). A
second connection into a host where 2489 is already bound fails the bind
harmlessly (`ExitOnForwardFailure no`) and shares the existing tunnel.

## 2b. `open-file` — open NFS files/folders in the laptop's Explorer (DONE)

**Sibling of `browser-open`** (`bin/.local/bin/open-file`, same `bin/` package, on
PATH everywhere). Where `browser-open` relays *URLs* to the laptop browser, this
relays *filesystem paths* to the laptop's Explorer. Routes by environment:

- **WSL (home):** `wslpath -w` translates the Linux path to a Windows path, then
  `wslview` (fallback `explorer.exe`) opens it. No tunnel, no NFS.
- **Work (SSH):** derives a UNC and relays it over the *same* lemonade tunnel —
  `lemonade open` on Windows is `ShellExecute`, so a `\\host\share\...` path opens
  in Explorer.

**The translation problem (work).** lemonade does *not* remap paths
(`--trans-localfile` only rewrites paths local to the laptop). The work host's
`/prj/...` and the laptop's `\\host\share\...` are the same NetApp volume over
NFS vs SMB, but nothing knows that mapping. We derive it from the live mount
table rather than hardcoding filers:

1. `ls -d` the path first to fire the autofs mount (`findmnt` returns nothing for
   a not-yet-triggered automount).
2. `findmnt -T <path> -t nfs,nfs4,cifs -no SOURCE` walks up to the containing
   filer mount → `10.49.242.206:/prj/qct/mlsys/lasvegas/scratch`. The `-t` filter
   is essential: an autofs trigger is stacked at the *same* mountpoint and
   unfiltered `findmnt` returns that `ldap:...automountMap...` layer first.
3. Reverse-DNS the IP (`getent hosts`) → `mudpie.qualcomm.com` → short `mudpie`.
4. Strip the export root → remainder; backslash it → `\\mudpie\<share>\<remainder>`.

**The one thing not auto-derivable: the SMB share name.** The NFS export root's
last segment is *not* guaranteed to equal the CIFS share (e.g. export
`/prj/qct/mlsys/lasvegas/scratch` is served as share `lasvegas_scratch`, not
`scratch`). A `SHARE_OVERRIDE` table at the top of the script maps
`"<shorthost> <export-root>" → <share>`; add a line when a filer opens to the
wrong `\\host\share` (confirm by pasting `\\host\share` into Explorer's address
bar). The naive guess (last path segment) is the fallback for unmapped filers.

**What can't be opened:** paths on **local disk** (e.g. `/local/mnt/workspace` on
devcompute — the devcompute `workspace_dir`) have no server in the mount table
and no UNC anywhere, and **nonexistent** paths. Both just report the failure
rather than fabricating a UNC. The path is normalized with `realpath -ms` first
so `/./`, `//`, `..`, and trailing slashes don't leak into the UNC.

## 3. Markdown handoff clutter — the real organizational bottleneck (DONE)

**Pattern:** Exploration produces multiple findings -> want to save and segment work into
parts to hand off to other agents. Was scattered across `~/.claude/plans/` (30+
auto-named files), `notes/` in the repo, and ad-hoc `.md` files. Nothing named, organized,
or discoverable. Compounding it: when several explorations finish, their *summaries* pile up
in the main context window and waste it as work moves to the next task.

**Fix shipped: the `work-vault`** — a git-synced Obsidian vault that doubles as Claude's
structured working-context store and a home for regular notes. One connected graph, not a flat
pile. Three stores, clean boundary: **vault** (live working-context graph) vs.
`notes/` (decisions about *this* repo, committed with it) vs. Claude `memory/` (durable
atomic facts). Pieces:

- **The vault repo.** A dedicated private repo on GHE (`github.qualcomm.com`,
  `juliray/work-vault`). GHE is the CCI-correct home — the vault holds Yellow/possibly-Red
  working notes, and that belongs on corp infra, not external `github.com` cloud (an earlier
  detour to a `github.com` EMU org repo was reverted for exactly this reason). A *personal*
  GHE repo is compliant while single-user; sharing it would require a GHE org + N2K team.
  Cloned to `$(workspace_dir)/work-vault` on each work host (off the small home
  partition) and to `$HOME/work-vault` on the laptop — where `workspace_dir` is
  `$HOME` and Obsidian actually opens the graph. Under `workspace_dir` rather than
  a hardcoded home path so the work hosts keep the vault off home; the local path
  may differ per host, but the git remote (not the path) is what ties the clones
  together, so that divergence is harmless. Canonical seams in `.utils.sh`:
  `work_vault_dir()` (override `$WORK_VAULT_DIR`) and `work_vault_remote()`
  (override `$WORK_VAULT_REMOTE`).
- **Layout** = folders by note *type*, files prefixed by project slug so wikilinks stay
  unambiguous: `index.md` (top MOC) → `projects/<slug>.md` (per-project MOC) → linked
  `explorations/<slug>--<topic>.md`, `plans/...`, `tasks/...`. The MOC hierarchy is pure
  wikilinks, so Obsidian's graph view renders project→exploration→plan→task and you navigate it
  on the laptop. Machine-generated notes stay in the type folders; freeform personal notes live
  anywhere else in the same vault and wikilink in.
- **`bin/.local/bin/work-vault`** — thin CLI (`dir`/`slug`/`moc`/`reindex`/`sync`) so commands and the
  agent stay declarative and share one source of truth for the layout + git-sync. `slug` derives
  the project key from the cwd's git remote (fallback: dir name) — that's what makes "point me
  at this project's notes" automatic, no per-project config. **Navigation is filesystem-derived:**
  `reindex` (run automatically inside `sync`) regenerates every project MOC's link lists and the
  top `index.md` project list from the notes on disk — bucketed by each note's `project:`
  frontmatter, described by its `gist:` field — rewriting only marker-bounded (`<!-- auto:NAME -->`)
  regions so freeform prose survives. Note-writers drop a correctly-fronted file and never
  hand-maintain a MOC, so the lists can't drift from the files.
- **`install/work-vault/install.sh`** — work-gated (`case "$DOTFILES_ENV"`, like
  `claude-code`). Idempotent clone-or-pull; if the remote is absent it `gh repo create`s it on
  the internal host (needs a one-time `gh auth login --hostname github.qualcomm.com` — prints
  that and stops gracefully if unauthed), then seeds the skeleton + pushes.

**The context-waste fix specifically:** slash commands run *in* the main context, so they can't
evict anything — the only real fix is keeping big findings *out* of main context to begin with.
That's the **`vault-explorer` agent**: it explores a subtopic in its *own* context, writes full
findings to `explorations/<slug>--<topic>.md` (wikilinked to the MOC), and returns only a
≤8-line summary + the vault path. Fan out N of them → main thread gains N pointers, not N walls
of text; `/vault-load` rehydrates one when its detail is actually needed.

## 4. Zero committed Claude customization (DONE)

Was: `claude/.claude/` tracked only `settings.json` — no `commands/` or `agents/`. Resolved by
item 3's delivery vehicle: committed + stowed under `claude/` (work envs only, alongside `ssh`),
so the reusable agent logic now version-controls. Shipped:

- `claude/.claude/agents/vault-explorer.md` — the stash-to-disk explorer (above).
- `claude/.claude/commands/vault-save.md` — persist current context as a structured, wikilinked
  note (`plan`/`exploration`/`note`).
- `claude/.claude/commands/vault-load.md` — fuzzy-match + rehydrate a saved note.
- `claude/.claude/commands/vault-project.md` — open a project's MOC (the "point me at this
  project's notes" entry point); derives the slug from the cwd repo when omitted.
