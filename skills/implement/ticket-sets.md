# Ticket sets

A ticket set is a parent ticket and the child tickets that hold its work, such
as a Jira Story and its Sub-tasks. Started with the parent's key,
`/devteam:implement` delivers the children, in the order their blocking links
set, and keeps the parent and every child in step.

## Why this exists

Started with one child, a run moves only that child. The parent and the other
children fall out of sync, and the run never sees the order the children must
ship in. Started with the parent as a plain ticket, the run builds from the
parent's text alone and moves a ticket nobody builds.

It does not read a design or a spec, and it does not check the code against
one. Not every parent has a design, so the children's own text is the brief.

## What `## Tickets` holds

Three optional lines. Without the first, a parent key is an ordinary ticket.

```markdown
- Ticket set: the children are `parent = <KEY>` (JQL)
- Order: `Blocks` links between children
- Parent start: In Progress
```

- **Ticket set** says how to find a parent's children with the tracker's tools.
- **Order** names the link type where one child blocks another. None named →
  the children's key order.
- **Parent start** is the parent's status once work starts. With a `tickets`
  skill in `## Skills`, the move is that skill's `parent-start` event instead.
  None named → the parent is never moved.

## Detect and check

After the fetch in [readiness.md](readiness.md), look up the ticket's children
as **Ticket set** says. No children → an ordinary ticket. Children → a ticket
set, with the fetched ticket as its parent:

1. **Fetch every child** as readiness.md fetches a ticket, verbatim. The
   parent's text is context for every child: it often holds the requirements
   the children split up.
2. **Check every child's readiness.** A child already done is out of the set;
   say so. Any child not ready → stop, with one table: **ticket** · **check** ·
   **gap**. Write nothing to the tracker.
3. **Order the children.** Each child is a node. Each **Order** link between two
   children is an edge. A blocker outside the set must be done; name any that
   is not and stop. A cycle → stop and name it. Never guess an order.
4. **Show the order** as a table: **#** · **ticket** · **summary** · **blocked
   by** · **status**.

Record the parent and the children under `**Ticket:**` and in the ledger's
`## Tickets` table.

## Choose the PR shape

Call `AskUserQuestion`:

- **one PR for the parent** — one worktree, one plan, one PR for every child.
  The usual choice, and the default recommendation.
- **one PR per ticket** — one run per child, each with its own PR, in order.

Recommend **one PR per ticket** instead, and say why, when any of these hold:
more than five children; a chain of three or more children that each wait for
the one before; or the repo's `### Review triggers` hit most children. Each
then gets a review a person can finish.

Record the choice as a `D` line marked `(user)`.

## One PR for the parent

The rest of the skill runs once, for the whole set. "The ticket" in a step means
every child, except where this list says otherwise.

- **Slug and worktree** take the parent's key.
- **Step 2.** Move each child only when its first phase starts (Step 4), not
  all at once: a child nobody is building yet stays where it is. The first
  child's start also applies **Parent start**, once.
- **Step 3.** The planner gets the parent and every child verbatim, and the
  order table. Each phase names the one child it delivers (`ticket`), and no
  phase of a child runs before the phases of the children that block it. The
  acceptance criteria come from every child, each tagged with its child.
- **Step 7.** Each commit is scoped to the child it delivers. A commit that
  serves several children takes the parent's key.
- **Step 8.** The PR title is scoped to the parent's key. The body lists every
  child with its acceptance verdicts. Every child is submitted.
- **Risk (Step 12).** The proposal is read from the parent. Every child gets the
  ticket label, and every child is handed off.

## One PR per ticket

This run builds nothing. Show the order table with a **start now** column:
`yes` for a child whose blockers are all merged, else the blockers it waits for.
Then stop, and say: run `/devteam:implement <child>` for each `yes` child; run
the next children once their blockers' PRs merge.

Each child's run is an ordinary ticket run. Two things still come from the
parent: Step 2 applies **Parent start** on that child's start, and Step 12
reads the proposal from the parent.

## Caveats

- The set is fixed at Step 0. A child added to the parent later is not in it;
  start a new run for it.
- On `--continue`, fetch the parent and every child again. A child someone else
  moved stays where they put it; say so, and never move it back.
- **Parent start** is safe to apply twice only if the skill or status move
  passes over a parent already in progress. Check the parent's status first.
