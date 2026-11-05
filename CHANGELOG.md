# Changelog

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
