---
description: Show the work-vault map of content for the current (or named) project
allowed-tools: Bash, Read, Glob
argument-hint: "[project-slug]"
---

Open the project's **Map of Content** — the hub note that links every
exploration, plan, and task for it. This is the "point me at this project's
notes" entry point.

Argument: `$ARGUMENTS` — optional project slug. If omitted, derive it from the
current repo via `vault slug`.

## Steps

1. `vault="$(vault dir)"` — if it errors, tell the user the vault isn't
   installed here and stop.

2. `slug="${ARGUMENTS:-$(vault slug)}"`, then `vault moc "$slug"` to
   ensure `$vault/projects/<slug>.md` exists.

3. **Read and present** the MOC: list its linked explorations / plans / tasks
   grouped by section, each with its gist. If the MOC is empty (new project),
   say so and suggest `/vault-save` or fanning out `vault-explorer` agents to
   start populating it.

4. Mention the user can open the same graph in Obsidian on the laptop (the vault
   git-syncs there).
