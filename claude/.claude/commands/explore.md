---
description: "Explore a topic using vault-explorer agents — research only, no implementation"
allowed-tools: Agent, Bash, Read, AskUserQuestion
argument-hint: "<topic-or-question> [subtopic1, subtopic2, ...]"
---

Fan out vault-explorer agents to research a topic, stashing findings in the
work-vault. This command does NOT implement anything — it only explores and
reports. Use `/act` afterward to implement approved findings.

Argument: `$ARGUMENTS` — the question or topic to research. If the user
provides comma-separated subtopics, fan out one agent per subtopic. If they
give a single broad question, decompose it into 2–5 independent subtopics
yourself and confirm with the user before dispatching.

## Steps

1. **Parse the request.** Identify independent subtopics from `$ARGUMENTS`.
   - If the user gave explicit subtopics, use those directly.
   - If they gave one broad topic, propose a decomposition (2–5 subtopics) and
     ask the user to confirm/modify via `AskUserQuestion` before proceeding.

2. **Fan out vault-explorer agents** — one per subtopic, all in parallel. Each
   agent prompt must be self-contained: state the subtopic, what to look at,
   and (if code-related) give enough repo context that the agent can orient
   itself. Include: `The project slug for the vault is "<slug>".` (run
   `vault slug` to get this).

3. **Collect results.** Each agent returns a short summary + vault path. Present
   ALL summaries to the user in a consolidated list (one section per subtopic:
   heading, the summary lines, and the vault path).

4. **Do NOT implement.** Your job is done after presenting the summaries. Tell
   the user they can:
   - read any note back via its vault path (or `zk find`) to rehydrate it
   - `/act` to pick findings to implement
   - `/improve <topic>` to run explore + act as a single flow

## Agent prompt template

When constructing the vault-explorer agent prompt, include:
- What to explore and why
- Which files/areas to start from (if you know)
- The project slug: `The project slug for the vault is "<slug>".`
- The output expectation: write to `projects/<slug>/<topic>.md` (the agent's
  `zk exploration` handles this, tagging the note `exploration`)
