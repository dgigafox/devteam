# Changelog

## 0.4.0 — unreleased

- The planner states the design before the phases: the records and their
  states and which operations use them, the rules more than one operation
  shares and the module that holds them, the lifetime of anything that waits
  on an outside system, and each new mechanism with the alternative rejected.
  Gate 1 shows it first, the ledger keeps it under `## Design`, every builder
  and the reviewer get it verbatim, and the build stops once after the first
  phase that builds it. Why: a run built one operation per phase, each phase
  inherited the last one's mechanism through a handoff line, and the shared
  rules ended up written once per operation with a restart loop nobody had
  approved.
- A shared mechanism is one phase, built before the operations that use it
  (planner rule 9). A handoff may no longer say "reuse the pattern".
- Builders fold before they verify: after the last task, a phase's own
  repetition against the previous phase's contract is removed, inside the
  phase's files. A task coded before its test is reported as `tdd_deviation`
  and becomes a `minor` finding, not a ledger note.
- Findings carry a `kind`. A `design` finding is handed to the builder as
  "change the mechanism", gets one extra re-review round, and comes back
  `changed` when it was patched with another branch.
- A finding that argues with an acceptance criterion is a decision: the old
  and new wording are shown and asked, as at Gate 1, before any fix.
- Two closing jobs after the last phase, named in `## Skills`: `glossary`
  (a new record is a term; the planner's assumptions no longer decide this)
  and `acceptance-tests` (the planner's line is the input, not the answer).
  Without a row, the docs audit and the reviewer keep their checks.
- Per-phase pace is the recommended answer when the planner's risk is `high`.

## 0.3.0 — 2026-11-06

- Skills are set by the repo, not looked up by name. A new `## Skills` table
  in `.agents/devteam.md` names the skill for each job: `worktree`, `tickets`,
  `commit`, `pr`, `readiness-fix` and `after-merge`. Its Notes map devteam's
  ticket events (`ready`, `start`, `resume`, `submit`, `handoff`,
  `parent-start`) to the skill's own. A job with no row is done the built-in
  way, and a named skill that is not installed is asked about, never skipped
  silently. **Breaking:** a repo without `## Skills` no longer uses
  `create-worktree`, `ticket-lifecycle`, `conventional-commit` or `pr` just
  because they are installed. `/devteam:setup` drafts the table from the
  repo's installed skills, from the app up to the git root, and proposes
  your own and plugin skills too, marked `(user-level)`, for you to keep or
  drop.

## 0.2.0 — 2026-11-05

- PR risk, for repos that grade it. A new optional `## Risk` section in
  `.agents/devteam.md` names the rules file, the levels, the PR and ticket
  labels, the record template and the merge-gate check. A new PR opens as
  pending. Once CI and code review are clean, the reviewer grades the final
  diff against the rules (its new `risk` mode), and `/devteam:implement` posts
  the record and sets the labels. A level that hands off moves the ticket to
  QA. Every later push resets the risk to pending. Any missing input keeps it
  pending; it never defaults to the lowest level.
- Ticket sets. With a `Ticket set` line in `## Tickets`, a parent key (such as
  a Story with Sub-tasks) delivers its children in their blocking order. The
  user picks one PR for the parent, or one PR per child, which the run lists
  in order for separate runs. Each child moves when its first phase starts,
  and the parent moves with the first child. No spec is read.
- A verification command that already passed on the same files is skipped,
  not run again. The builder, QA and gates report each command with the
  worktree's tree id, and the ledger's new `## Verified` section records every
  pass. On a clean run, QA and the commit gates reuse the last builder's Fast
  verify, and the push runs only the push-only gates.
- `.agents/devteam.md` can stay untracked. In a worktree with no copy,
  `/devteam:implement` reads it from the same app folder in the main checkout,
  and passes its absolute path to every agent as `repo file`. `/devteam:setup`
  writes it in the main checkout when started in a worktree.
- The builder's memory is now per user, not per repo. Project memory was saved
  inside the target repo, where it could land in the PR or vanish with the
  worktree.

## 0.1.0 — 2026-11-03

First release, moved out of a skill into its own plugin.

- `/devteam:implement` takes a ticket, an open PR or plain instructions to a
  reviewed PR, with checkpoints at the plan, each phase, the commits and the
  push.
- `/devteam:setup` writes `.agents/devteam.md` and never edits `AGENTS.md`.
- Monorepo apps work from their own folder through an app root.
- `create-worktree`, `ticket-lifecycle`, `conventional-commit` and `pr` are
  optional, with direct fallbacks. Tickets are optional.
- QA's write limit is a plugin hook keyed on `agent_type`.
