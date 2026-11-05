---
name: setup
description: Prepare a repository for /devteam:implement — inspect it, draft and prove the .agents/devteam.md file it reads (areas, build order, gates, tickets, worktrees, CI, code review), write it, then ask the user once to keep, adjust or discard it. Never edits the root AGENTS.md and never commits. Run only when typed as /devteam:setup, from the repo root or a monorepo app's folder.
disable-model-invocation: true
---

# Setting up a repository

Run as `/devteam:setup`, or when a run finds the repo not ready.
Start it in the folder the file is for: the repo root, or in a monorepo the
app's folder (`apps/<app>`). That folder is the app root; setup writes
`.agents/devteam.md` there and nowhere else. In a worktree, "there" means the
same app folder in the main checkout (the parent folder of
`git rev-parse --path-format=absolute --git-common-dir`): the file may stay
untracked, and `/devteam:implement` falls back to the main checkout when a
worktree has no copy. Step 1 checks that file too. At a monorepo root
whose apps are listed in the root `AGENTS.md`, stop and say which app folder to
start in. It writes the repo file, `.agents/devteam.md`, from what
the repo already shows, then the user reviews everything at once. It never
invents a rule: a section holds only what was found in the repo or said by the
user.

## Why a setup step

The skill holds no repo facts. Every path, command and check comes from the repo
file. A repo without it cannot be planned, built or gated, and writing it by
hand is the main hurdle. Setup drafts it; the user decides.

Setup never edits the root `AGENTS.md`. Every session loads that file, whatever
the task, so this skill's sections stay in the repo file, which loads only when
a run reads it.

## 1. Check

Read `.agents/devteam.md`, following its pointers, and show a table
(**item** · **status**: present, incomplete or missing · **required** ·
**detail**) of:

- **Required:** `## Areas` with its table (Area · Paths · Instructions · Fast
  verify · Lockfile → regenerate), every row with an Area, Paths and Fast
  verify, every named Instructions file existing (`none` is allowed), and
  `### Build order` with content.
- **Optional:** `### Shared surfaces`, `### Review triggers`,
  `## Verification gates`, `## Delivery`, `## Tickets`, `## Worktrees`,
  `## CI`, `## Code review`, `## Acceptance tests`, `## Risk`, `## Skills`.

Headings inside code blocks do not count. Everything present → say the repo is
ready and stop. Otherwise work through every row that is missing or incomplete,
required rows first.

## 2. Inspect

Read, in parallel, before drafting anything:

- every existing `AGENTS.md` and `CLAUDE.md`, and any `README.md` at the root or
  one level down
- the manifests and lockfiles at the root and one level down (`package.json`,
  `mix.exs`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile` and their
  lockfiles)
- the scripts or aliases those manifests define for test, lint, format and build
- `.github/workflows/*` (or the repo's CI config): required checks, the
  code-review check and the bot that posts it, coverage uploads and their
  artifact names
- `.opencodereview/rules/` or any other review rubric
- the top-level folders and where the tests for each live

Existing text wins. Never rewrite a section that is already present in the repo
file; only add what is missing. When the root `AGENTS.md` or another file
already covers a section, even under another name (an `## E2E worktrees` for
`## Worktrees`), write a pointer to it instead of a copy:

```markdown
## Worktrees

See `AGENTS.md` § E2E worktrees.
```

General facts — gates, CI, worktrees — belong where every agent can see them.
The repo file points at them, so there is one source.

In a monorepo, every path in the repo file is relative to the app root. Shared
files above it, such as the app's CI workflows, are written from the git root
with a leading `/` (`/.github/workflows/web_*.yml`), and go in the unowned list.
A pointer to the monorepo's rules uses a relative path:
`See ../../AGENTS.md § Verification gates`. Prove each command from the app
root.

## 3. Draft and prove

Draft every missing or incomplete row, in this order: `## Areas` (table, unowned
paths, gate configs), `### Build order`, `### Shared surfaces`,
`### Review triggers`, then `## Verification gates`, `## Delivery`,
`## Tickets`, `## Worktrees`, `## CI`, `## Code review`, `## Acceptance tests`,
`## Risk`, `## Skills`. No questions yet.

- **Areas.** One area per part of the code with its own stack, test command or
  owner — usually a top-level app or package. Paths cover the code and its
  tests. Instructions is that area's `AGENTS.md` if it has one, otherwise
  `none`: an area with no rules of its own follows the root `AGENTS.md`. Fast
  verify is the narrowest command that compiles and tests that area.
- **Prove every command.** Run each Fast verify and each gate once, redirected
  to a log, and record its exit code. A command that fails, or does not exist,
  is not written; it goes on the gaps list.
- **Gates decide verify commands.** Where `## Verification gates` names the
  check for a path, use it. Do not pick a heavier or lighter one.
- **Worktree capabilities** come only from the list the `worktree` skill in
  `## Skills` defines. A tool or service that is not on it is a health check
  or a setup command, not a capability. With no worktree skill, write no
  capabilities: only setup commands and health checks.
- **Skills.** Write `## Skills` from the skills that can do a job, in two
  groups:
  - **In the repo:** `.agents/skills/` and `.claude/skills/` in every folder
    from the app root up to the git root (a monorepo often installs them at
    its root), and any skill `AGENTS.md` names.
  - **Outside the repo:** your own skills (`~/.claude/skills/`) and plugin
    skills, as this session lists them. Write a plugin skill as
    `plugin:skill`. Mark each such row `(user-level)` in Notes: a teammate may
    not have it, and their run then asks to use the built-in way or stop.

  One row per job `/devteam:implement` § Skills lists, only where a skill's own
  description clearly does that job. When both groups have one, take the
  repo's. Read each skill's events or arguments and map devteam's ticket events
  to them in Notes. A job no skill fits is left out, not guessed: it is done
  the built-in way.
- **Tickets.** Write `## Tickets` only when the repo shows a tracker: ticket
  keys in branch names, PR titles or commit subjects, a tracker named in
  `AGENTS.md`, or an MCP server for one in the repo's config. Name the tracker,
  the tools to reach it, and the key pattern. Statuses, the ready mark and the
  readiness brief go in only where the repo states them; otherwise they are
  gaps for the user. So do the `Ticket set`, `Order` and `Parent start` lines
  that `/devteam:implement`'s `ticket-sets.md` describes.
- **Risk.** Write `## Risk` only when the repo already grades PR risk: a
  rules file for it, risk labels in `gh label list`, or a workflow that blocks
  the merge on them. Point at the rules and the record template rather than
  copying them. Write the lines `/devteam:implement` § What `## Risk` holds
  lists, each only where the repo states it. Never invent levels or rules; with
  none in the repo, the section is a gap, not a default.
- **Note the source** of each line: the file, script or workflow it came from. A
  fact you could not find in the repository itself (only in a PR comment, a log
  or memory) is marked _(unverified)_ in the text, or left out.
- A section with nothing to go on — no CI, no review rubric — is not written. It
  goes on the gaps list.

## 4. Write

Before writing, run `git status --porcelain` on every file you will touch. If
one has uncommitted changes, stop and call `AskUserQuestion`: **write anyway** ·
**stop here**, because step 5's discard could not restore it cleanly.

Then write every drafted section into `.agents/devteam.md`,
creating it if needed, under a `# devteam` heading. Existing text
stays as it is. Never edit the root `AGENTS.md`. Where an area's Instructions is
`none` and there is something proven to put in its own file, create
`<area>/AGENTS.md`: how to run the area's tests and checks, and how to run and
check the app if one runs, plus a `## Rules` heading with one line asking the
team to add the area's coding rules. Never write rules yourself. Where the repo
links `CLAUDE.md` to `AGENTS.md`, add the same symlink.

## 5. Review — one checkpoint

Show, in one message:

- a table of what was written: **file** · **section** · **source**
- `git diff` of the changed files, and the full text of any new file
- the gaps: **item** · **why** (a command that failed, or nothing to go on)

Call `AskUserQuestion`: **keep it** · **adjust** · **discard all**.

If `## Skills` has `(user-level)` rows, ask about them in the same call, as a
second question with `multiSelect`: one option per row (**job** → **skill**),
"keep these user-level skills?". A row left unticked is removed before step 6.

- **keep it** → step 6.
- **adjust** → apply the user's words, then show this review again.
- **discard all** → `git checkout -- <files>` for the files that existed, delete
  the files and symlinks you created, and stop.

## 6. Check again

Run the check in step 1 again and show the table. Never stage, commit or push;
say which files changed so the user can.
