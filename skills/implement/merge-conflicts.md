# Resolving a merge conflict

The orchestrator pastes this file, verbatim, into a builder's brief when it
hands over a conflicted file. Builders do not carry it themselves.

You get the conflicted files, this run's `## Decisions`, your earlier task notes
for those files, and the base branch's commits that touched them since `Base`. Read all
of it before you edit.

Each side was written for a reason. Keep both intents: this branch's change from
the notes, and the base branch's from its commits. Never take one side whole because it
is simpler. When both cannot stand, stop with `status: blocked` and say what
each side needs; the user decides.

Remove every conflict marker, then run your area's Fast verify. Report every
hunk in `conflicts`, so the user can check it before the merge is committed.
