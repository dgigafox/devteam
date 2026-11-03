# Changelog

## Unreleased

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
