---
description: "Explore a topic then act on findings — the full explore→prompt→implement cycle"
allowed-tools: Agent, Bash, Read, Glob, AskUserQuestion
argument-hint: "<topic-or-question> [subtopic1, subtopic2, ...]"
---

The combined flow: explore a topic via vault-explorer agents, present findings,
prompt the user per-item, then implement approved changes via subagents.
Equivalent to `/explore` followed by `/act`, but in one invocation.

Argument: `$ARGUMENTS` — same as `/explore` (the question or topic, optionally
with comma-separated subtopics).

## Phase 1: Explore (same as /explore)

1. **Parse the request.** Identify independent subtopics from `$ARGUMENTS`.
   - If the user gave explicit subtopics, use those directly.
   - If they gave one broad topic, propose a decomposition (2–5 subtopics) and
     ask the user to confirm/modify via `AskUserQuestion` before dispatching.

2. **Fan out vault-explorer agents** — one per subtopic, all in parallel. Each
   agent prompt must be self-contained. Include: `The project slug for the vault
   is "<slug>".` (run `vault slug` to get this).

3. **Collect and present** all summaries to the user (one section per subtopic:
   heading, summary lines, vault path).

## Phase 2: Act (same as /act)

4. **Extract actionable items** from the exploration results. Each item = one
   self-contained unit of work (what to change, where, why).

5. **Present ALL items to the user** via `AskUserQuestion` (multi-select).
   The user approves, rejects, or modifies each item individually.

6. **Spawn implementation agents** for approved items — one per independent
   item, parallel where possible. Each agent prompt is fully self-contained
   (file paths, what to change, conventions). Agents edit only — no commits.

7. **Verify and commit** per the user's preference (grouped commits, single
   commit, or leave uncommitted).

## Key principles

- **Two prompt gates.** The user is prompted (a) before exploration dispatches
  (subtopic confirmation) and (b) before implementation (per-item approval).
- **Subagents do the work.** The main thread is a coordinator — it prompts,
  dispatches, and verifies, but doesn't implement directly.
- **No scope creep.** Only implement what the user explicitly approved.
- **Vault-first.** All research lands in the vault. Implementation is informed
  by vault notes, not ephemeral conversation context.
