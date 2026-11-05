# The ledger

The ledger is how a run survives a lost session. It is the only file the
orchestrator writes, apart from the reviewer's long report, gate logs, and QA's
memory.

## Where it lives

`<main checkout>/.claude/plans/<slug>.md`. The slug is the first that applies:

- the ticket key in lower case: `proj-123` (a parent's key, for a ticket set)
- the PR number: `pr-482`
- up to five words of the instruction, in kebab case:
  `change-apply-button-colour`

The slug also names the worktree. It sits in the main checkout, not the
worktree, so `--continue` finds it from where a session starts, and it outlives
the worktree.

It must never be committed. Before the first write:

```bash
cd <main checkout>
git check-ignore -q .claude/plans/<slug>.md || printf '/.claude/plans/\n' >> "$(git rev-parse --path-format=absolute --git-path info/exclude)"
```

Keep it a **flat file**. Some plugins' hooks match `.claude/plans/<dir>/plan.md`
and write into any plan directory they find. A flat file matches none of them.

## Shape

```markdown
# proj-123 — <ticket summary, or the instruction>

**State:** planned **Pace:** per-phase **Base:** <sha> **Branch:** <branch>
**Worktree:** <absolute path> **App:** <app root, relative; `.` in a single repo> **Repo file:** <absolute path of .agents/devteam.md> **Ticket:** PROJ-123 | none **PR:** none **Head:** none **Risk:** none | pending | <level>

**Instruction:** <the user's words, verbatim, or none>

## Tickets

| # | Ticket | Blocked by | Status |
| --- | --- | --- | --- |
| 1 | PROJ-124 | none | In Progress |

## Phase 1 — <title> [api · devteam:builder · PROJ-124] (pending)

Verify: <the phase's verify command>
Acceptance: <one sentence>

- [ ] P1.1 <task> — <expected file>

## Acceptance

- AC1 <criterion>

## Decisions

- D1 Who receives billing emails? → a billing email field on the company (user)
- A1 Billing email stored on Company, not a separate resource (planner)

## Findings

## QA

## Verified

## Commits

## Watches

## Risk
```

- `## Tickets` and the ticket in a phase heading appear only for a ticket set.
  `**Ticket:**` then reads `PROJ-123 (parent of PROJ-124, PROJ-125)`.
- `D` lines are the user's answers to the planner's `decisions_needed`. `A`
  lines are the planner's `assumptions`, verbatim. An assumption the user
  overrules becomes a `D` line marked `(user)`.
- Tick a box with an inline note, so the _why_ survives compaction:
  `- [x] P1.1 Archive action — test first: archived orders hide; status field`
- `## Findings` holds the reviewer's and docs audit's findings, and later OCR's,
  each with its outcome: fixed, declined with the reason, deferred, left alone.
- `## Verified` holds one line per command that passed: directory, command,
  tree id, who ran it, time (UTC). Plus one `gates <mode>` line per passing
  gates run. A command already passed on the same tree id is skipped, not run
  again (SKILL.md § Reusing a verified command).
- `## Commits` holds each commit's sha and subject once made.
- `## Watches` holds one line per watch report: kind, head sha, outcome, what
  the user chose.
- `## Risk` holds one line per classification: head sha, level, matched rules,
  the record's URL, and where the ticket went. `**Risk:**` is `none` when the
  repo file has no `## Risk`, and `pending` after every push.
- Nothing else. If it does not need to survive a `/clear`, it stays in the
  conversation.

Task ids such as `P2.7` are for the ledger only. They never go into committed
code, docs, commit messages or the PR: the ledger is not committed, so a reader
who follows one finds nothing. Cite the ticket key instead, or nothing without a
ticket.

## States

Bump `**State:**` as the run moves:

| State           | Meaning                                              | `--continue` resumes at                                                |
| --------------- | ---------------------------------------------------- | ---------------------------------------------------------------------- |
| `planned`       | Plan written, not approved                           | Step 3, Gate 1. Skip the decisions if `## Decisions` has its `D` lines |
| `building P<n>` | Phase n in progress                                  | Step 4, that phase, its first unchecked box, at the ledger's `Pace`    |
| `built`         | All phases done                                      | The implementation approval at the end of Step 4                       |
| `reviewed`      | Review settled                                       | Step 6                                                                 |
| `qa-failed`     | QA found unmet criteria                              | Step 6's fix path, from `## QA`                                        |
| `qa-passed`     | QA clean                                             | Step 7                                                                 |
| `committed`     | Commits made, not pushed                             | Step 8                                                                 |
| `pr-open`       | PR open, any ticket in review                        | Steps 9–11, against the PR's current head                              |
| `fixing`        | A post-PR fix in progress, any ticket in progress    | The fix, then gates, commit and push                                   |
| `classifying`   | Watches clean, risk not yet recorded for this head   | Step 12, from its first step                                           |
| `done`          | CI green, OCR handled, risk routed when graded       | Print the summary, do nothing else                                     |

A resumed phase may be part-done. Tell the agent which boxes are ticked and that
its work must be idempotent.
