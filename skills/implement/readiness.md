# Ticket readiness

Step 0 decides whether a ticket can be built without guessing. A ticket that
fails stops the run before anything is created: no worktree, no tracker change.
With a PR, only the fetch runs.

## Fetch

With the tracker's tools that `## Tickets` names (for Jira, the Atlassian MCP
tools; for GitHub Issues, `gh issue view`), fetch:

- the ticket: summary, description, status, labels, assignee, and every comment.
- every linked ticket: parent, epic, `blocks`, `is blocked by`, `relates to`.
  Each one's full description and status.

Keep all of it **verbatim**. The planner and the reviewer have no tracker
access, so what you pass them is all they see. Fetch it again on `--continue`;
never rebuild it from the ledger.

If the tracker's tools are not available in this session, stop and say which
ones `## Tickets` needs.

## Quick pass

The ticket is ready when **both** hold:

- it carries the ready mark `## Tickets` names (a label such as
  `ready-for-agent`, or a comment heading). No mark named → skip to the full
  check.
- no `is blocked by` link points at a ticket that is not done.

The mark is a triage mark, not the tracker's ready status. Step 2 moves the
status.

## Full check

Otherwise, hold the ticket to the brief `## Tickets` names, if it names one (for
example `.agents/skills/triage/AGENT-BRIEF.md`). If it names none, hold the
ticket to the table below alone. Every item must hold:

| Check               | Fails when                                                                            |
| ------------------- | ------------------------------------------------------------------------------------- |
| Behaviour described | The ticket says what to change in the code, but not what the user or system should do |
| Acceptance criteria | Missing, or one cannot be checked on its own ("works correctly")                      |
| Scope               | No line on what is out of scope, and an adjacent feature is plausibly in              |
| Open questions      | A comment asks a product question nobody answered                                     |
| Blockers            | An `is blocked by` ticket is not done                                                 |

Comments count. A decision or an answered question in a comment closes the gap.

## When it is not ready

Stop. Print the gaps as a table: **check** · **gap**, one row each. Suggest
filling them on the ticket, then starting again. If `## Skills` names a
`readiness-fix` skill, name it, for example:

> Run `/triage PROJ-123` to fill these gaps, then start this again.

Write nothing to the tracker. Do not reproduce a bug either; the ticket is
trusted as written.
