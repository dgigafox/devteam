---
name: implement
description: Take one task — a ticket, plain instructions, or work on an open pull request — to a reviewed pull request with the devteam agents, in any repository with a `.agents/devteam.md` file. Readiness check and ticket moves when the repo uses tickets, worktree, plan, one builder per area, review, QA in the running app, commits, PR, then CI and code review watched until clean, and the PR's risk classified when the repo grades risk. Run only when typed as /devteam:implement followed by a ticket key or instructions, or /devteam:implement --continue [slug]. Run /devteam:setup first to prepare a repository.
disable-model-invocation: true
---

# devteam implement

Take one task to a pull request with CI green and every code-review finding
handled. Area-owned agents plan, build, review and test. You, the orchestrator,
ask every question, keep the ledger, dispatch agents, commit, push, open the PR
and move the ticket.

**Arguments:** what to do, in the user's words, or `--continue [slug]` to resume
a run. `/devteam:setup` prepares a repository for this skill.

```text
/devteam:implement PROJ-123
/devteam:implement PROJ-123 leave the email template alone
/devteam:implement Change the checkout button colour to the brand blue
/devteam:implement Work on the review comments on PR #482
```

## Why this exists

A single agent that builds everything knows nothing about the repo's areas, and
runs to the end without showing its work. Here each builder gets one area of the
code and that area's rules, read from the repo's own instruction files; the user
approves the plan, each phase, the commits and the push; and QA checks each
acceptance criterion in the running app. The skill holds no repo facts: every
path, command and check comes from the target repo's
[repo file](#the-repo-file) at run time.

It only runs when typed, because it moves tickets, pushes and opens PRs.

## Before you start

The agents ship with this plugin as `devteam:<role>`. If `devteam:planner` is
not an agent you can dispatch, stop and say so: the plugin is not loaded, so
restart the session after installing or enabling it.

**Optional skills.** Four steps use a skill when it is installed, and do the
work directly when it is not. Check once, at the start, which are available, and
record them in the ledger:

| Skill                 | Without it                                                                                                                                            |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `create-worktree`     | The worktree agent runs `git worktree add` itself (its own file says how)                                                                              |
| `ticket-lifecycle`    | Move the ticket with the tracker's own tools, as `## Tickets` says; with no way to move it, skip the move and say so once                             |
| `conventional-commit` | Write each message yourself: `type(scope): subject`, a body that says why, and the repo's trailer rules                                              |
| `pr`                  | `gh pr create` with a title in the same form, and a body from the run, filling the repo's pull request template (`.github/PULL_REQUEST_TEMPLATE.md`) if it has one |

Otherwise read the [repo file](#the-repo-file) and check four things:

- the repo file exists, in the session's folder or the main checkout (see
  [the repo file](#the-repo-file))
- an `## Areas` section with a table: Area · Paths · Instructions · Fast verify
  · Lockfile → regenerate
- every row has an Area, Paths and a Fast verify. Instructions may be `none`:
  that area has no rules of its own beyond the root `AGENTS.md`. A named
  Instructions file must exist.
- an `### Build order` under it, with content

Show a table (**item** · **status**: present, incomplete or missing ·
**detail**). If no repo file is found but one exists in a folder below the git
root (a monorepo app, such as `apps/<app>`), stop and say: start the session in
that folder. Never offer setup at a monorepo root. If any other check fails,
call `AskUserQuestion`: **set up the repo now** (read
`${CLAUDE_PLUGIN_ROOT}/skills/setup/SKILL.md` and follow it, then start the
task) · **stop here**. The shape:

```markdown
## Areas

| Area | Paths | Instructions | Fast verify | Lockfile → regenerate |
| --- | --- | --- | --- | --- |
| api | `src/api/**`, `test/api/**` | `src/api/AGENTS.md` | `<test command for test/api>` | none |
| ui | `src/ui/**` | none | `<ui test command>` | `package-lock.json` → `npm install` |

- Unowned (ask before editing): `.github/**`, `Dockerfile`
- Gate configs (never edited to pass a gate): `.eslintrc.json`

### Build order
### Shared surfaces
### Review triggers
```

The other sections this skill reads by heading are `## Verification gates`,
`## Delivery`, `## Tickets`, `## Worktrees`, `## CI`, `## Code review`,
`## Acceptance tests` and `## Risk`. `## Tickets` says which tracker the repo uses, the
tools to reach it, its statuses for ready, in progress, review and QA, its ready
mark, and its readiness brief. Without it, the repo uses no tickets. `## Risk`
says how the repo grades a PR's risk ([Step 12](#step-12--classify-the-risk));
without it, PRs carry no risk. When an agent reports one missing (`needs_from: user` or
a `missing_repo_info` line), ask the user. Never guess a default.

### The repo file

Everything this skill reads about a repo lives in one file,
`.agents/devteam.md`, by heading. Not in the root `AGENTS.md`:
every session loads that, whatever the task, and this skill's sections would
make it longer for work that never uses them. Neither client auto-loads the repo
file, so it costs nothing until a run reads it.

A section may point elsewhere instead of repeating it:

```markdown
## Verification gates

See `AGENTS.md` § Verification gates.
```

Read a pointer as the named section of the named file. A repo keeps general
facts — gates, CI, worktrees — where every agent can see them, and the repo file
points at them, so there is one source and no drift.

**The app root** is the folder that holds the repo file: the nearest folder,
from where the session started up to the git root, with
`.agents/devteam.md`. In a single repo it is the git root. In a
monorepo it is the app's folder, such as `apps/web`, and the session must start
there or below it.

**Find the repo file once, at the start.** The file may be left untracked, so a
worktree may not have it. Walking up from a worktree never reaches the main
checkout: the main checkout is not a parent folder of the worktree.

1. Walk up from the session's folder to the git root, as above. Found → that is
   the repo file.
2. Not found, and the session is in a worktree (`git rev-parse --git-dir` and
   `git rev-parse --git-common-dir` differ): the main checkout is the parent
   folder of `git rev-parse --path-format=absolute --git-common-dir`. Take the
   session's folder relative to the git root, and walk up the same relative
   path in the main checkout. Found → that is the repo file, and its folder's
   relative path is the app root.
3. Still not found → the readiness check reports it missing.

Record the file's absolute path as `**Repo file:**` in the ledger, and pass it
as `repo file` in every dispatch. An agent never builds the path itself. When
the file is in the main checkout, an edit there applies to every worktree at
once; nothing is copied.

- `<app>` means the app root inside the worktree: `<worktree>` itself in a
  single repo, `<worktree>/apps/web` in a monorepo.
- Every path in the repo file is relative to the app root. A path that starts
  with `/` is relative to the git root: a monorepo's shared files, such as
  `/.github/workflows/web_*.yml`.
- Every command runs from the app root, unless the repo file names another
  directory.
- A pointer's file is relative to the app root: `AGENTS.md` is the app's,
  `../../AGENTS.md` the monorepo's.
- To compare a changed path with the repo file, take it from
  `git diff --name-only` at the worktree root and drop the app root's prefix. A
  changed path outside the app root matches only `/` paths; anything else
  outside it is outside every area.

Every agent reads the repo file at the `repo file` path it is given and
follows its pointers the same way. A pointer's file is still relative to the
app root inside the worktree: `AGENTS.md` is `<app>/AGENTS.md`.

If the arguments start with `--continue`, read [ledger.md](ledger.md) and resume
from `**State:**`. Fetch the ticket and the PR again first (Step 0's fetch, not
its checks).

## Laws

1. **Agents never commit, stage or push.** You do, and only at the steps below.
   You never rebase or force-push. You never merge the PR. Never ask the user to
   stage, commit or push either: their part is answering the checkpoints.
2. **Never edit a file an agent owns** — not a refactor, a rename, or a typo.
   Dispatch its owner, with the user's words passed through verbatim. Your
   writes are the ledger, merge commits, and the unowned files in `## Areas`,
   after the user approves each one. A change the user asks for directly is
   still dispatched: size is not the test, ownership is. Only the user's
   explicit "do it yourself" overrules this.
3. **Never let an agent work outside its area.** It reports `needs_from`; you
   dispatch the owner for that one change.
4. **Never trust `files_changed` over `git diff --name-only`.** If they
   disagree, stop.
5. **Never pipe a gate into `tail`, `head` or `grep`.** The pipeline returns the
   last command's status, so a failing gate reads as green. Redirect to a log
   and `echo "EXIT=$?"`.
6. **A gate result belongs to the tree it ran on.** Any edit after a gate makes
   it stale — including a one-line fix, a test-only change, or a change the user
   asked for. Every commit and every push needs a passing `devteam:gates`
   result for the tree it commits or pushes. A pass on the same tree is reused,
   not re-run ([Reusing a verified command](#reusing-a-verified-command)). Gates never need
   a yes: run them, and ask only when one fails.
7. **One builder at a time.** They share a worktree and its build output.
   Reviewers and watchers are read-only and run in parallel.
8. **Every finding reaches the user before any fix.** Never blame this diff for
   a failure it cannot reach; pre-existing is a valid verdict.
9. **Ask, never assume.** Every question is a call to the `AskUserQuestion` tool.
   Never type the options as a list in your reply and wait for a
   typed answer; that is not asking. Each option list in this skill (**approve**
   · **adjust** · …) is the tool's options, with your recommendation first and
   labelled `(Recommended)`. If the tool times out with no answer, call it
   again. Never fall back to a recommendation. This holds for questions this
   skill does not list, and for questions a skill you use asks
   (`conventional-commit`, `pr`, `ticket-lifecycle`, `create-worktree`). **Every
   stop that waits for the user ends in an `AskUserQuestion` call**, so a
   checkpoint never looks like a status update. Only a stop that ends the run
   (not ready, no `## Areas`, `blocked` worktree) is plain text.

**The user never sees an agent's result block.** It comes back to you. A finding
you have not printed is one they do not know exists, and an id like `F2` means
nothing on its own. Print the table as text before `AskUserQuestion`, in the
same message. Every option that names findings says what they are: **fix all** →
"F1 stuck dialog, F2 missing error-state test". Never write an id in a question
without its one-line description.

**Every report with more than one item is a markdown table**, with the columns
this skill names for it. Never a bullet list, never an agent's raw keys. Keep
each cell to one line; put long text (a log, a drafted reply) below the table,
labelled with the row's id. Every column has a header, and a symbol never stands
alone: write `🟠 correctness`, not `🟠`.

Each agent's own file defines its result block. Pass anything unfamiliar through
to the user rather than guessing at it. If a required field is missing, name it
and stop.

**Every agent works in the worktree.** Subagents start in the session's
directory, which is the main checkout. Give every dispatch the worktree's
absolute path, `<app>` and the `repo file` path, and tell the agent to run
every command from `<app>` and to read and edit only under the worktree. The
one exception is reading the repo file, which may sit in the main checkout.

## Agents

| Agent                                                                | Step                         | Writes                              |
| -------------------------------------------------------------------- | ---------------------------- | ----------------------------------- |
| `devteam:worktree`                                      | 1                            | the worktree                        |
| `devteam:planner`                                       | 3                            | nothing                             |
| `devteam:builder`, `devteam:docs`          | 4, and every fix             | their phase's area                  |
| `devteam:reviewer`, `devteam:docs` (audit) | 5, every fix, and 12 (risk)  | nothing                             |
| `devteam:qa`                                            | 6                            | its own memory only                 |
| `devteam:gates`                                         | before every commit and push | lockfiles only, when asked          |
| `devteam:ci-watcher`                                    | 9, 10                        | nothing                             |
| `devteam:review-triage`                                 | 11                           | PR replies, after the user confirms |

The planner tags each phase with an `area` from the `## Areas` table. This is
the only place the mapping lives:

area `docs` (if the table has one) → `devteam:docs` · every other
area → `devteam:builder`

## Step 0 — What kind of task?

Read the user's words. Whatever is not a ticket key or a PR is the
**instruction**; keep it verbatim.

1. **A ticket** (a key matching the pattern in `## Delivery`, such as
   `PROJ-123`) → follow [readiness.md](readiness.md). Not ready → stop with the
   gaps. Write nothing to the tracker. When `## Tickets` has a `Ticket set`
   line and the ticket has children, it is a parent: follow
   [ticket-sets.md](ticket-sets.md), which checks the children and asks for the
   PR shape.
2. **A PR** (`#482`, `PR 482`, or its URL) →
   `gh pr view <n> --json number,title,body,headRefName,url,state`. It must be
   open. The PR already has its acceptance criteria, so skip the readiness
   check. Take the ticket from the PR's title and fetch it as readiness.md says;
   the ticket steps then apply. The worktree checks out the PR's branch.
3. **Neither** → no ticket to check or move. Skip every ticket step below.

With no `## Tickets` section, the repo uses no tickets: every task is case 2 or
3, and a PR's title is not searched for a key.

"The ticket" in the steps below means there is one. For a parent delivered as
one PR, it means every child, with the exceptions
[ticket-sets.md](ticket-sets.md#one-pr-for-the-parent) lists.

## Step 1 — Worktree

```bash
git rev-parse --git-dir; git rev-parse --git-common-dir   # equal ⇒ main checkout
```

- **Main checkout:** dispatch `devteam:worktree` with the slug
  ([ledger.md](ledger.md)), the PR number if there is one, the main checkout's
  path, the app root relative to the git root (`.` in a single repo), and the
  areas the run will touch: for a PR, the areas its changed paths fall in;
  otherwise `all`. Show the user a table (**item** · **value**) of its `path`,
  `branch`, `resources`, and any `failed_step` with the fix. A `blocked` result
  stops the run. A `partial` result → call `AskUserQuestion`: **fix it and
  continue** · **stop**.
- **Already in a worktree:** use it. Check it is on a named branch — the PR's
  `headRefName`, if there is a PR — then run the setup checks `## Worktrees`
  names, each redirected to a log. Name any fix.

From here, every command and every dispatch uses the worktree's absolute path
and `<app>`. Record both in the ledger. The base branch is the one
`## Delivery` names, else the remote's default
(`git symbolic-ref --short refs/remotes/origin/HEAD`); `origin/<base>` below
means that branch. Record `Base` as `git merge-base origin/<base> HEAD`.

## Step 2 — Ticket to in progress

Skip without a ticket. Use `ticket-lifecycle` from the worktree when it is
installed; otherwise move the ticket with the tracker's tools, to the statuses
`## Tickets` names. Below, its events and their usual Jira statuses:

- **No PR:** `ready` if the ticket is not already ready or in progress (`Ready`,
  `In Progress`), then `start`.
- **A PR:** `resume` if the ticket is in review (`To Review`). Otherwise leave
  it.

When the ticket has a parent and `## Tickets` names a `Parent start`, apply it
right after the first `start`, unless the parent is already in progress or
later.

## Step 3 — Plan

Dispatch `devteam:planner` with:

- the user's instruction, **verbatim**. It is the task without a ticket, and it
  narrows the ticket when there is one.
- the ticket, its comments, and each linked ticket's full description, all
  **verbatim**. Say which linked tickets have already shipped, with which
  commit. Never pass a summary. If you must cut, name exactly what you cut.
- with a PR: its title and body, verbatim, and `git diff --stat $BASE`. Say the
  branch already holds this work and the plan adds to it.
- with a ticket set: the parent and every child, verbatim, and the order table.
  Ask for a `ticket` on every phase and every criterion.
- the worktree path.

Without a ticket, the planner writes the acceptance criteria from the
instruction. You show them at Gate 1 like any other.

Write the ledger ([ledger.md](ledger.md)) from its `phases`,
`acceptance_criteria` and `assumptions`.

### Gate 1, part 1 — Decisions

Skip if `decisions_needed` is `none`. Otherwise ask them before showing the
plan, because the plan may change. Call `AskUserQuestion` once, one question per
decision, up to four per call: the full question, each option with its one-line
reason, the planner's recommendation first and labelled `(Recommended)`. Write
each answer as a `D` line marked `(user)`.

If any answer differs from the recommendation, dispatch the planner again with
the same input plus the answers, verbatim, marked settled. Rewrite the ledger's
phases and acceptance. Ask any new `decisions_needed` too.

### Gate 1, part 2 — The plan

Show these tables. Do not paste the plan.

- **Phases** — phase · agent · what · tasks · expected files
- **Acceptance criteria** — id · criterion. These matter most: QA holds the
  finished work to them.
- **Decisions and assumptions** — id · decision · by (`user` or `planner`). The
  decisions are a reminder, not asked again. The assumptions go in full.
- **New mechanisms** — what · where · the alternative the planner rejected. Only
  if any.

Then one line for the review triggers.

Call `AskUserQuestion` with these options:

- **approve, stop after each phase** — the default when phases depend on each
  other or one is risky
- **approve, run them all** — build straight through and stop once at the end
- **adjust** — amend from the user's words; a changed decision or overruled
  assumption becomes a `D` line and the planner runs again
- **abort** — delete the ledger, and say the worktree, ticket and PR stay as
  they are

Record the pace in the ledger. Never change it mid-run without asking.

## Step 4 — Build

Phases run one at a time, in the plan's order. The planner orders them by
`### Build order`. `### Shared surfaces` says when a phase that touches a
surface must widen, or be followed by a phase for another area. Check each
phase's `touches` against that table before you dispatch it. A surface the plan
missed → stop and call `AskUserQuestion`: **add the phase** · **replan the
rest** · **stop here**.

Each builder works task by task: write the test for the task's behaviour and see
it fail for the right reason, write the code until it passes, refactor and run
it again. A task with no behavioural test surface (config, docs, a pure rename)
says why in its note. Then the builder runs the phase's verify command. No other
agent writes the tests.

For each phase:

1. Note `git diff --name-only`, so you can tell what this phase touched. With a
   ticket set, `start` the phase's child if it has not started (Step 2).
2. Dispatch the phase's agent with: the worktree path, the area name and its
   Paths, the area's Instructions file pasted **verbatim** (or
   `Instructions: none` when the area has no file), its Fast verify and the
   phase's verify command, the numbered tasks, the ledger's `## Decisions`
   verbatim, and the `contract` and `handoff` lines earlier phases returned,
   verbatim. **Nothing else.** Builders do not run the full gates.
3. Check the claim: every path inside the area's Paths, every expected path
   present, and the real diff matching `files_changed`.
4. Tick the boxes with an inline note, and bump `**State:**`. Record each
   `pass` in the builder's `verified` under `## Verified`. Do the same after
   every fix a builder makes.

`devteam:builder` returns: `status`, `area`, `verify`,
`verify_result`, `verified`, `files_changed`, `tests_added`, `contract`, `needs_from`,
`declined`, `conflicts`, `shared_surface`, `handoff`, `user_notes`. A
`shared_surface` other than `none` → check it against `### Shared surfaces` as
above. `devteam:docs` returns its own shape.

**Per-phase pace:** stop after each phase and say in one line what it did, then
a table of `files_changed` (**file** · **change** · **lines** from
`git diff --stat`), then the verify result (and why, if `degraded`),
`tests_added`, `contract`/`handoff` and `user_notes`. Call `AskUserQuestion`:
**next phase** · **fix this phase** · **replan the rest** · **stop here**.

**Fix this phase** → send the user's words, verbatim, to the same builder with
`SendMessage`, so it keeps its context. After a restart that builder is gone:
dispatch a fresh one with the same brief plus the phase's ticked boxes and notes
from the ledger.

**Run-all pace:** keep going, adding a row per phase to one table: **phase** ·
**agent** · **status** · **files** · **verify**.

These stop the build in either pace:

- `status: blocked` → name who it needs. Call `AskUserQuestion`: **dispatch
  <owner>** · **stop here**. On yes, dispatch that owner for the one change,
  then the blocked agent again.
- `status: failed` → show the failure. Call `AskUserQuestion`: **fix this
  phase** · **replan the rest** · **stop here**. Dispatch nobody until the user
  answers.
- a path outside the agent's area, or missing from the real diff → show what is
  on disk. Call `AskUserQuestion`: **keep it** · **send it to its owner** ·
  **stop here**.

Never roll back. `git diff` is the user's undo.

**After the last phase**, show `git diff --stat $BASE` and every `contract`
line. Call `AskUserQuestion`: **review + QA** · **QA only** · **fix first** ·
**stop here**.

## Step 5 — Review

Dispatch `devteam:reviewer` and `devteam:docs` (audit
mode) in one message. Give the reviewer what a human reviewer would get:

- the instruction, the ticket and comments, verbatim, and the acceptance
  criteria
- the ledger's `## Decisions`, verbatim. Code that builds something other than a
  `(user)` decision is a finding, and so is a business rule found in neither the
  ticket nor the decisions.
- `git diff $BASE`
- every phase's `user_notes`, `tests_added` and `contract`
- which of the repo's `### Review triggers` the diff hits, and the planner's
  `review_triggers` line
- whether the plan has an acceptance-test phase under `## Acceptance tests`, and
  if not, the planner's reason. A test never written leaves nothing in the diff.

More than ten findings → point the reviewer at
`<main checkout>/.claude/plans/<slug>-review.md`. Append every finding to
`## Findings`.

Print the findings table first, whatever the outcome, one row per finding of
every severity:

| id  | severity | where                  | finding                                      | owner |
| --- | -------- | ---------------------- | -------------------------------------------- | ----- |
| F1  | major    | `src/ui/upload.ts:142` | A failed upload leaves the dialog stuck open | ui    |

**Nothing actionable** — no `blocker`, and no `major` in this run's diff → say
so under the table and go to Step 6.

**Otherwise stop.** Call `AskUserQuestion`: **fix all** · **blockers only** ·
**let me pick** · **skip to QA**, each option listing its findings. **Let me
pick** → ask again with `multiSelect`, one option per finding, four per
question.

Owners fix the picked findings. Paste [review-findings.md](review-findings.md)
verbatim into each brief that hands over a finding. A builder may **decline**
one with a reason: that is a disagreement, not a failed fix. Show both sides,
then call `AskUserQuestion` per decline: **accept the decline** · **fix it
anyway**. Never settle it yourself.

Then dispatch the reviewer **once** more, scoped to its findings plus the fix
diff. Show the table again with a status column: `resolved`, `unresolved`,
`declined`, `changed`. All `resolved` or `declined` → Step 6. Anything else →
show the user and call `AskUserQuestion`: **go to QA** · **I'll fix it myself**
· **stop here**. One review round only.

## Step 6 — QA

Dispatch `devteam:qa` with the worktree path, the acceptance
criteria, the diff, the areas touched, and `already_passed`
([Reusing a verified command](#reusing-a-verified-command)). It checks each
criterion in the running app and runs the full gates, skipping any already
passed on these files. It never edits. Record each `pass` in its `verified`.

Report its two answers as two tables:

- **Acceptance** — id · criterion · verdict (`met`, `unmet`, `unverifiable`) ·
  evidence or why · owner when unmet.
- **Regression** — gate · exit code · step that stopped it · log.

All met and the gates clean → Step 7. Otherwise stop and show the unmet criteria
with owners, the `unverifiable` ones with why, and `env_blocked`. Call
`AskUserQuestion`: **fix it** · **I'll fix it myself** · **accept as is** ·
**abort**.

On **fix it**: owner fixes → reviewer reviews that fix → QA re-checks only the
unmet criteria plus the gates (`pass: re-check`). Then show the result and call
`AskUserQuestion`, whatever the outcome: **commit** (only if all met and clean)
· **I'll fix it myself** · **accept as is** · **abort**.

An `unverifiable` criterion is never met. It stays a visible gap, and only the
user accepts it.

## Reusing a verified command

A verification command that already passed on the same files is skipped, not
run again. This matters because the same command often runs three times on the
same files: the builder's Fast verify after the last phase or a fix, QA's
regression gates, and the commit gates. A commit doesn't change any file
either, so the push would re-run them too.

**Why not the commit sha?** Builders don't commit; every change stays
uncommitted until Step 7. HEAD doesn't move while the files do, and a commit
moves HEAD without changing a file. The tree id tracks the files themselves.

**The tree id** is the id of the worktree's files as they are now, committed or
not:

```bash
cd <worktree> && tmp=$(mktemp) && cp "$(git rev-parse --git-path index)" "$tmp" && GIT_INDEX_FILE="$tmp" git add -A && GIT_INDEX_FILE="$tmp" git write-tree; rm -f "$tmp"
```

It uses a throwaway index, so the real one is untouched. Ignored files (build
output, `deps/`) don't count. The same files give the same id, before and after
a commit.

**Record every pass, one line per command.** The builder, QA and gates return a
`verified` list: each command they ran, its directory, its tree id and its
result. Add each `pass` to the ledger's `## Verified`:

```markdown
- `phoenix` · `mix precommit` · tree 3467875 · builder P2 · 2026-11-04 10:12
```

Never record `fail`, `degraded` or `skipped`, or a line with tree `changed` (the
command edited files while it ran). When a gates result has
`verify_result: pass`, also add one mode line: `gates <mode> · tree <id> ·
<time>`.

**Reuse it.** Before you dispatch QA or gates, take the tree id.

- **Gates, `commit` mode:** a `gates commit`, `gates push` or `gates lockfiles`
  line on this tree id → don't dispatch. Say
  `gates: reused — tree <id> passed at <time>`.
- **Gates, `push` mode:** a `gates push` line on this tree id → don't dispatch.
- **Otherwise, QA and gates:** pass `already_passed`, every `## Verified` line
  on this tree id. The agent skips each command on that list and runs the rest.
  On a clean run, the push runs only the push-only gates.
- **Builders** get no list. They change files, so nothing they could skip would
  still match.

A skip matches only the same command, from the same directory, on the same tree
id. A narrowed `mix test test/foo_test.exs` never stands in for
`mix precommit`.

Caveats:

- Any edit changes the tree id, so every command runs again, however small the
  edit.
- A merge of the base branch changes the tree. Nothing from before it counts.
- If the repo file was edited since a pass, don't reuse it. It may name
  different gates now.
- A skip assumes the same files give the same result. A flaky test or a service
  that was up then and down now is not re-checked.

## Step 7 — Commit

1. `devteam:gates` in `commit` mode, reusing passes where it can. Any `fail` → show a
   table (**command** · **exit** · **stopped at** · **log**) and call
   `AskUserQuestion`: **fix it** (owner, then reviewer, then gates again) ·
   **stop**.
2. Use `conventional-commit`. Work out the split from the ledger's phases and
   `git diff --stat HEAD`: one commit per coherent change, scoped to the ticket
   key, or the repo's no-ticket scope from `## Delivery` without a ticket. Show
   the proposed commits as a table (**#** · **subject** · **files**) and call
   `AskUserQuestion`. Commit only after a yes.
3. Record each sha and subject under `## Commits`.
4. Show the commits made (**sha** · **subject**). Call `AskUserQuestion`: **push
   and open the PR** (**push to the PR** when there is one) · **stop here**.
   Pushing is outward-facing; never push without this yes.

## Step 8 — Pull request and review

1. `devteam:gates` in `push` mode, reusing a pass where it can. It adds the
   push-only gates `## Verification gates` names for the changed paths. Any `fail` stops
   the push: show the same gate table and call `AskUserQuestion`: **fix it**
   (owner, reviewer, gates again) · **stop here**.
2. **No PR yet:** use `pr`. The title follows `## Delivery`:
   `<type>(PROJ-123): <lowercase subject>`, or the no-ticket scope without a
   ticket. The body comes from the run: what changed and why by area, the
   acceptance criteria with QA's verdicts, the gates that ran, and the findings
   left alone with their reasons. Never a task id. `pr` pushes, opens the PR,
   and moves the ticket to review. Without `pr`, push, open the PR with
   `gh pr create`, and `submit` the ticket. **A PR already:** `git push` to its
   branch. Never open a second PR, and never rewrite its title or body. With a
   ticket, `submit` it (`ticket-lifecycle submit`, or the tracker's tools).
3. With `## Risk`: a new PR opens with the pending PR label (tell `pr` to add
   it, or pass `--label` to `gh pr create`), and the ticket gets the pending
   ticket label. An existing PR gets the [risk reset](#resetting-the-risk)
   after this push.
4. Record `**PR:**`, `**Head:**` and the push time (UTC) in the ledger. State →
   `pr-open`.

## Step 9 — Conflict check

After the PR opens and after every push, dispatch
`devteam:ci-watcher` in `conflicts` mode. Do it again whenever a
watch reports, before you show that report.

On `conflicting`, show a table: **file** · **owner**. Call `AskUserQuestion`:
**fix now** · **not now**. On **fix now**:

1. `git fetch origin <base> && git merge origin/<base>` in the worktree. Never
   rebase.
2. Each owned file → its owner, with: the conflicted files, the ledger's
   `## Decisions` verbatim, the ticked boxes and notes that touched those files,
   and `git log --format='%h %s' $BASE..origin/<base> -- <files>`, and
   [merge-conflicts.md](merge-conflicts.md) pasted verbatim. The owner returns
   `conflicts`, one item per hunk.
3. Unowned files (the unowned list under `## Areas`) → show your resolution of
   each and call `AskUserQuestion`: **apply it** · **adjust**. Edit only after a
   yes.
4. Lockfiles → `devteam:gates` in `lockfiles` mode. It regenerates
   each with the command in the `## Areas` table.
5. Show one table of every hunk: **file** · **owner** · **kept** · **why**, with
   the unowned files' approved resolutions as rows too. A `blocked` owner's row
   says what each side needs. Call `AskUserQuestion`: **commit and push** ·
   **adjust** · **stop here**. **adjust** sends the user's words to that file's
   owner, then shows the table again.
6. On **commit and push**: you commit the merge. Then gates in `push` mode, then
   push, the [risk reset](#resetting-the-risk), then steps 9–11 again.

## Steps 10 and 11 — Watch CI and OCR

After every push, once the conflict check is clean, dispatch two background
agents in one message. Each reports once, on its own:

- **Watch A** — `devteam:ci-watcher` in `ci` mode, with the PR
  number and head sha.
- **Watch B** — `devteam:review-triage` in `triage` mode, with the
  PR number, head sha, and push time.

**A report for an older commit is dropped.** Compare its `head` with the PR's
current head. A `stale` status, or a mismatch, is never shown as current.

When both report clean for the current head, go to Step 12.

When one reports while the other still runs, its `AskUserQuestion` also offers:
**fix now** (push, and both watches restart) or **wait for the other** and fix
everything in one push. On fix now, stop the running watch before you push.

### Watch A — CI

`timeout` → show a table of what is still pending (**job** · **workflow** ·
**started**) and call `AskUserQuestion`: **keep waiting** · **stop watching**.

Otherwise show two separate tables:

- **Related to this change** — id · job · failing test · cause · owner. A
  coverage failure gets its own table: **file:line** · **source line** ·
  **owner**, not per-file counts.
- **Unrelated** — id · job · failing test · cause · remedy: update from the base branch
  (with the commit that fixed it), fix by an agent, or re-run (at most 2 re-runs
  per job).

Call `AskUserQuestion` for which to act on. Nothing happens without a yes.

- Related fix → [Fixing an open PR](#fixing-an-open-pr).
- Coverage fix → the same path. Tell the owner: cover each line through real
  behaviour. If only a mock of one of our own modules could reach a line, remove
  the clause when it is not needed, or report why it stays. Never write a
  contrived test to reach a line.
- Update from the base branch → Step 9's merge path.
- Re-run → `gh run rerun <run-id> --failed`. Only on a yes, and only under the
  cap.

Never run coverage locally to find missed lines while CI has the coverage report
for the current head; the watcher reads it (the artifact `## CI` names). Run
coverage locally only when the watcher says the report is missing or is for an
older sha, and tell the user why.

### Watch B — OCR

Show one table of the findings, sorted by severity: **id** · **severity** ·
**where** (`file:line`) · **finding** · **owner** · **verdict** (FIX, DECLINE,
VERIFY-FIRST, DEFER) · **why**. The severity cell is the dot and its word:
`🔴 security`, `🟠 correctness`, `🟡 nitpick`, `🔵 coverage`. Call
`AskUserQuestion` for which to act on.

Picked findings → [Fixing an open PR](#fixing-an-open-pr), with one extra
checkpoint after the reviewer: show a table of the drafted replies (**id** ·
**finding** · **verdict** · **reply**; a long reply goes below the table under
its id) and call `AskUserQuestion`: **post these replies** · **adjust**. After
the push, `devteam:review-triage` in `reply` mode with the
confirmed replies, the fix sha filled in. It replies, then resolves. DEFER
replies start with `🔖 **DEFERRED**`.

### Fixing an open PR

Every change after this run's Step 8 push — a CI fix, an OCR fix, or anything
the user asks for — takes this path:

1. `resume` the ticket, if there is one (Step 2). State → `fixing`.
2. The owner fixes it. A finding from the reviewer, OCR or a person comes with
   [review-findings.md](review-findings.md) pasted verbatim into the brief.
3. The reviewer checks the fix diff. Its findings follow Step 5's rules.
4. `devteam:gates` in `commit` mode. No question; a `fail` is a
   checkpoint (Step 7.1).
5. **Checkpoint:** the commit split (Step 7.2). You commit after a yes.
6. **Checkpoint:** the push (Step 7.4). On a yes, gates in `push` mode, then you
   push.
7. The [risk reset](#resetting-the-risk), with `## Risk`.
8. `submit` the ticket, if there is one (Step 8). State → `pr-open`.
9. Steps 9–11 again, then Step 12.

## Step 12 — Classify the risk

Skip without `## Risk`. It runs once both watches report clean for the PR's
current head. State → `classifying`; after the route, `done`.

**Why the diff and not a person decides.** The risk says whether the PR needs
manual QA before it merges. A merge-gate check in the repo reads the label and
the record comment, so a PR left at pending can never merge. Grading the final
diff against written rules gives the same answer every time, and the record
shows why.

### What `## Risk` holds

```markdown
## Risk

- Rules: `docs/risk-levels.md` (has a `Rules version:` line)
- Levels, lowest first: normal, high. Unclassified: pending
- PR labels: `risk:pending` · `risk:normal` · `risk:high`. Also removed on reset: `qa:passed`
- Ticket labels: `risk-pending` · `risk-normal` · `risk-high`
- Proposal: the parent ticket's `## Risk` section, `Proposed: <level>`
- Record: a PR comment whose first line is `<!-- acme:risk-record v1 -->`. Template: see `docs/pr-risk.md` § Risk record
- Merge-gate check: `risk-gate`
- Handoff: level `high` → the QA status, with skill `ticket-lifecycle handoff-qa`
```

Every line but Rules, Levels, PR labels and Record is optional. No ticket
labels → only the PR is labelled. No proposal → record `none`. No merge-gate
check → nothing to exclude. No handoff → every level stays in review.

### Classify

1. **Same head everywhere.** The local `HEAD`, the PR's `headRefOid` and the
   head both watches reported on must be one commit. Otherwise run steps 9–11
   for the PR's head first.
2. **Labels exist.** `gh label list --limit 500 --json name` must hold every PR
   label `## Risk` names. A missing one → stop and say so; a maintainer creates
   it. Never create a label.
3. **Dispatch `devteam:reviewer` in `risk` mode**, fresh, with: the full
   `git diff $BASE...HEAD`, the file list from `gh pr diff <pr> --name-only`,
   the rules file, verbatim, and the levels. It returns each matched rule with
   its file, the level the rules give, the rules version, and any input it
   could not read.
4. **Decide.** The level is the higher of the reviewer's level and the
   proposal. A proposal is never lowered. A child reads it from its parent.
5. **Fail closed.** A missing input, a file list that differs between the two
   diffs, a reviewer `status` other than `success`, or a template field you
   cannot fill all keep the risk at pending. Show each reason and call
   `AskUserQuestion`: **retry** · **stop here**. Never fall back to the lowest
   level.
6. **Write the record** as a new PR comment
   (`gh pr comment <pr> --body-file <file>`, the file in the scratchpad), from
   the repo's template. Fill each field the template names from the run: the
   level, the matched rules with files, the proposal, the rules version, the
   full head sha, the ticket. A field the template explains (such as a Spec
   version, or `none` without one) is filled as it says. Never edit an older
   record: the newest one counts.
7. **Then set the labels**, so the merge gate reads the new record: remove the
   pending PR label and add the level's. With a ticket and ticket labels, set
   the level's label and remove the other risk labels. Change ticket labels by
   read, change, read again; keep every other label.
8. **Verify.** Read the PR again. The head is unchanged and it has exactly one
   risk label. The head moved → [reset](#resetting-the-risk) and start again
   at step 1.

No question is asked before steps 6 and 7: the labels come from the diff and
the rules, not from a choice. Record the level, the matched rules, the head and
the record's URL under the ledger's `## Risk`.

### Route

- A level `## Risk` hands off, with a ticket → the handoff. Use the named skill
  when it is installed, with the ticket, the PR, the head and the record's URL.
  Otherwise take the tracker's transition to the QA status `## Tickets` names.
  Move only a ticket in the review status; anything else, or no such
  transition → say so and leave it. The record authorizes the handoff, so no
  question is asked.
- A level that hands off, without a ticket → say the PR needs manual QA before
  it merges.
- Any other level → the PR stays in review for a person to merge.

### Resetting the risk

Every push after a classification makes it stale: a review fix, a CI fix, a QA
fix, a merge of the base. Right after each push to a PR, with `## Risk`:

1. Remove every risk label the PR has, and the labels `## Risk` lists as also
   removed on reset. Add the pending label. One `gh pr edit` call, removing
   only labels the PR has.
2. With a ticket and ticket labels, set the pending ticket label and remove the
   others.
3. Clear the ledger's `**Risk:**` to `pending`.

Step 12 then runs again once the watches are clean on the new head.

## Done

The run is done when both watches report clean for the PR's current head: every
non-OCR job passed (the merge-gate check aside) and every OCR finding is fixed,
declined or deferred with a reply. With `## Risk`, Step 12 has also classified
and routed that head. Set `**State:** done` and print:

1. **PR** — URL, head sha, ticket status (or `no ticket`), and the risk level
   with its record's URL.
2. **Changed** — file · agent · why.
3. **Gates** — command · exit code · log. Pre-existing failures labelled.
4. **Acceptance** — id · criterion · verdict. `unverifiable` ones are gaps.
5. **Left alone** — id · finding · outcome (`minor`, `note`, declined, deferred)
   · reason.

Items 2–5 are tables.

**Suggest QA when the PR is mergeable.** Only without `## Risk` (with it, Step
12 routes the ticket), only with a ticket, and only when
`## Tickets` names a QA status (in Jira, often `To QA`). The PR is mergeable when no review thread is unresolved and every
check that blocks the merge passed:

```bash
gh pr checks <pr> --required --json name,bucket
gh api graphql -f query='query { repository(owner:"<owner>", name:"<repo>") { pullRequest(number:<pr>) { reviewThreads(first:100) { nodes { isResolved } } } } }'
```

Not every ticket needs QA, so this is a suggestion, never a default. Call
`AskUserQuestion`: **move to QA** · **leave it in review**. On a yes, take the
tracker's transition to that status (in Jira, `listJiraIssueTransitions` then
the transition). No such transition → say so and leave the ticket. Moving it
needs no new push and no gates.

After the PR merges, the ticket is outside this skill. Where a
`complete-delivery` skill is installed, it closes the ticket.

## Notes

- Area names come from the `## Areas` table. Its Paths column is the authority
  on what each area owns. Don't invent areas.
- The unowned paths under `## Areas` belong to no agent. Show the change and
  call `AskUserQuestion` first, then edit them yourself. Everything else has an
  owner.
- The gate configs under `## Areas` are gates. Nobody edits a gate to make a
  finding go away.
- Watch A's required checks, the OCR check and its bot author, and the coverage
  checks come from `## CI`. The review rubric comes from `## Code review`. The
  merge-gate check comes from `## Risk`: Watch A skips it, because it waits for
  the risk and for QA, not for this change.
