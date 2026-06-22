---
description: Load a saved note from the work-vault back into the conversation
allowed-tools: Bash, Read, Glob
argument-hint: "<topic-or-fuzzy-match>"
---

Rehydrate a previously-saved work-vault note into the current conversation.

Argument: `$ARGUMENTS` — a topic slug or fuzzy fragment to match.

## Steps

1. `vault="$(vault dir)"` — if it errors, tell the user the vault isn't
   installed here and stop.

2. **Find candidates**: search `$vault` for notes whose filename or `topic:`
   frontmatter matches `$ARGUMENTS` (case-insensitive, substring). Prefer the
   current project's slug (`vault slug`) when disambiguating.
   - 0 matches → list what *is* available for this project (read
     `$vault/projects/<slug>.md`) and ask the user to pick.
   - >1 match → show the matches (path + one-line gist) and ask which.

3. **Read** the chosen note and summarize its key points inline, then state that
   the full note is loaded and you're ready to continue from it. Follow any
   `[[wikilinks]]` only if the user asks — don't auto-expand the whole graph.
