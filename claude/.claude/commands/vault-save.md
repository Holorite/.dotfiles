---
description: Save the current working context as a structured note in the work-vault
allowed-tools: Bash, Read, Write, Edit
argument-hint: "[plan|exploration|note] [topic-slug]"
---

Persist the current working context into the **work-vault** as a structured,
wikilinked note, so it survives `/clear` and shows up in the Obsidian graph.

Arguments: `$ARGUMENTS` — optional `<kind>` (`plan` | `exploration` | `note`,
default `plan`) and `<topic-slug>` (short kebab-case; infer one from the work if
omitted).

## Steps

1. **Resolve coordinates** (the `work-vault` helper is on PATH):
   - `vault="$(work-vault dir)"` — if this errors, tell the user the vault isn't
     installed on this host (`./install.sh work-vault`) and stop.
   - `slug="$(work-vault slug)"`, then `work-vault moc "$slug"` to ensure the
     project MOC exists.

2. **Pick the folder** from `<kind>`: `plan`→`plans/`, `exploration`→
   `explorations/`, `note`→ the vault root (freeform notes live alongside the
   user's own). File path: `$vault/<folder>/<slug>--<topic>.md` (for `note`,
   just `<slug>--<topic>.md` at root).

3. **Write the note** with frontmatter (`type`, `project: <slug>`,
   `parent: "[[projects/<slug>]]"`, `topic`, `gist`, `status`) and a body
   opening with `Up: [[projects/<slug>]].` then the actual content — the
   plan/findings/notes from the current conversation. The `gist` is a one-line
   summary; the reindexer uses it as the bullet description in the MOC, so write
   it well. Reference code as `file_path:line`. Wikilink related vault notes
   with `[[...]]`.

4. **Sync**: `work-vault sync "vault: save <slug>/<topic>"`. This regenerates the
   project MOC's link lists (and the top index) from the notes on disk — you do
   **not** hand-edit the MOC; navigation is script-derived from each note's
   `project:`/`gist:` frontmatter.

5. Report the saved path and remind the user it's reloadable with
   `/vault-load <topic>`.
