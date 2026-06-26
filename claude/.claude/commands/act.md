---
description: "Act on vault findings — prompt per-item, then spawn agents to implement approved changes"
allowed-tools: Agent, Bash, Read, Glob, AskUserQuestion
argument-hint: "[vault-note-or-topic]"
---

Present findings from a previous exploration (or a vault plan) as individual
actionable items, prompt the user for approval on EACH one, then spawn
implementation agents for the approved set. This command does NOT explore — it
acts on existing knowledge.

Argument: `$ARGUMENTS` — a vault note topic slug, a path, or empty (in which
case, look at the most recent explorations for the current project and ask the
user which to act on).

## Steps

1. **Load the source material.**
   - `vault="$(vault dir)"` — stop if the vault isn't present.
   - `slug="$(vault slug)"` — current project.
   - If `$ARGUMENTS` is given, find the matching note(s) with
     `vault find "$ARGUMENTS"`: a single match prints the note body directly (read
     it inline — no extra Read needed), multiple matches print one
     `path<TAB>title` line each (ask the user which), and no match exits non-zero.
   - If `$ARGUMENTS` is empty, list recent explorations/plans for `$slug`
     (`zk list projects/$slug --tag "exploration OR plan" --sort modified`) and
     ask the user to pick.

2. **Read the note(s)** and extract every concrete, actionable item (a fix, a
   change, an addition, a deletion). Each item should be a self-contained unit
   of work: what to change, in which file(s), and why.

3. **Present ALL items to the user** via `AskUserQuestion` (multi-select).
   Group by priority/category if there are many. Each option should be a short
   label (the action) with a description (the file + rationale). Let the user
   select which to approve, reject, or modify.

4. **For each approved item**, decide whether it can be done independently.
   Group truly-dependent items together. Then:
   - Spawn one Agent per independent item (or group). Use `subagent_type`
     appropriate to the work (default general-purpose; use `vault-explorer` only
     for further research, not implementation).
   - Each agent prompt must be fully self-contained: the exact file(s) to edit,
     what to change, why, and any conventions to follow. Include the relevant
     section of CLAUDE.md if it matters.
   - Agents that make code changes should NOT commit — they edit only. You
     commit afterward (if the user wants commits).

5. **After agents complete**, verify the changes are correct (spot-check diffs).
   Then ask the user about committing:
   - Show a summary of what changed
   - Ask: commit (grouped or single), or leave uncommitted for manual review?

6. **Commit per the user's choice.** Use the same grouped-commit style as the
   rest of this repo (descriptive message, Co-Authored-By trailer).

## Key principles

- **Prompt for everything.** The user must approve each item before it's
  implemented. Never silently skip or silently include.
- **Subagents implement, main thread coordinates.** Don't write code in the
  main context — dispatch it.
- **No scope creep.** Only implement what the user approved. Don't "also fix"
  adjacent issues you notice.
