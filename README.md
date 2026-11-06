# devteam

A Claude Code plugin that takes one task to a reviewed pull request with a team
of agents, and stops for your approval at every step that matters.

```text
/devteam:setup                                  prepare a repository once
/devteam:implement PROJ-123                     a ticket
/devteam:implement Work on the review comments on PR #482
/devteam:implement Change the checkout button colour to the brand blue
```

## Why it exists

A single agent that builds a whole task copies whatever patterns the code
already has, good or bad, and runs to the end before you see anything. devteam
splits the work and keeps you in it:

- **A planner** states the design first: the records and their states, the
  rules every operation shares and where they live, the lifetimes, and each new
  mechanism with the alternative it rejected. It lists every decision it made
  that the task didn't cover. You approve the design and the plan before any
  code is written, and the build stops once more after the first phase that
  builds the design, before later phases copy its shape.
- **One builder per area** of the code, for the whole run, each with that
  area's rules from the repo's own instruction files. The builder that made a
  mechanism is the one that extends it. It never edits outside its area.
- **Checkpoints** after each phase, which is also that phase's commit, and
  before the push.
- **A reviewer** checks the diff against the repo's review rubric before the PR
  opens, and **QA** checks each acceptance criterion in the running app.
- **Two watchers** follow CI and the code-review bot after the push. Every
  finding is shown to you as a table before anything is fixed.

The cost is time and tokens: it is slower than a single agent, on purpose.

## How a repository tells it what to do

The plugin holds no repository facts. `/devteam:setup` inspects the repository
and writes `.agents/devteam.md`: the areas (paths, instruction file, fast
verify), build order, and the gates, tickets, worktrees, CI and code review
sections. A section can point at an existing heading instead of copying it:

```markdown
## Verification gates

See `AGENTS.md` § Verification gates.
```

The file lives outside `AGENTS.md` because every session loads `AGENTS.md`,
whatever the task. In a monorepo, each app keeps its own file in
`apps/<app>/.agents/`, and you start the session in that app's folder.

## Optional skills

A repository can hand some jobs to skills it already uses. The repo file's
`## Skills` table names the skill for each job; devteam never looks one up by
name. A job with no row is done the built-in way:

| Job             | Built in                                          |
| --------------- | ------------------------------------------------- |
| `worktree`      | `git worktree add`, with no resource claims       |
| `tickets`       | The tracker's own tools, as `## Tickets` says     |
| `commit`        | Writes the Conventional Commits message itself    |
| `pr`            | `gh pr create`, filling the repo's PR template    |
| `readiness-fix` | Lists a ticket's gaps, with no skill to suggest   |
| `after-merge`   | Leaves closing the ticket to a person             |
| `glossary`      | Leaves a missing term to the docs audit           |
| `acceptance-tests` | Leaves the planner's acceptance-test line to the reviewer |

With no `## Tickets` section, the repository uses no tickets and every ticket
step is skipped.

## Install

```text
/plugin marketplace add dgigafox/devteam
/plugin install devteam@devteam
```

For a local checkout, add the folder instead: `/plugin marketplace add
~/Projects/devteam`. While developing, `claude --plugin-dir ~/Projects/devteam`
loads the working copy without installing it.

Needs `gh` and `jq`. QA uses the Chrome DevTools MCP server when the app has a
browser UI.

## Agents

| Agent                   | Job                                                       | Writes             |
| ----------------------- | --------------------------------------------------------- | ------------------ |
| `devteam:worktree`      | Creates the worktree and runs the repo's setup            | nothing tracked    |
| `devteam:planner`       | Splits the task into phases, one area each                | nothing            |
| `devteam:builder`       | Builds one area's phase, code and tests                   | its area           |
| `devteam:docs`          | Repo documentation: ADRs, glossary, guides                | the `docs` area    |
| `devteam:reviewer`      | Reviews the diff against the repo's rules                 | its review file    |
| `devteam:qa`            | Checks acceptance criteria in the running app             | its memory only    |
| `devteam:gates`         | Runs the repo's gates before each commit and push         | nothing            |
| `devteam:ci-watcher`    | Watches CI and merge conflicts after a push               | nothing            |
| `devteam:review-triage` | Sorts the code-review bot's findings, posts agreed replies | PR replies only    |

A plugin hook enforces QA's limit: plugin agents ignore `hooks` in their own
frontmatter, so `hooks/hooks.json` checks every Write and Edit and blocks
`devteam:qa` outside its memory folder.
