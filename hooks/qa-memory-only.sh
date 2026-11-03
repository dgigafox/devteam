#!/bin/sh
# Lets devteam's QA agent write to its own memory folder and nowhere else.
#
# Why this exists: `memory:` in an agent's frontmatter turns on Write and Edit so the agent
# can save notes, and those tools work on any path. Without this hook, giving QA a memory
# would also let it edit the code it is meant to be judging. Plugin agents ignore `hooks`
# in their own frontmatter, so this runs as a plugin hook on every Write and Edit and
# checks which agent made the call.
#
# Claude Code sends the tool call as JSON on stdin. Exit 0 allows it; exit 2 blocks it and
# the message on stderr goes back to the agent.

input=$(cat)
case "$input" in
  *'"devteam:qa"'*) ;;
  *) exit 0 ;;
esac

# From here the caller may be QA, so fail closed.
if ! command -v jq >/dev/null 2>&1; then
  echo "devteam:qa is read-only, and this hook needs jq to check the path. Install jq." >&2
  exit 2
fi
agent=$(printf '%s' "$input" | jq -r '.agent_type // empty')
[ "$agent" = "devteam:qa" ] || exit 0

path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
case "$path" in
  */../*) ;;
  "$HOME/.claude/agent-memory/devteam:qa/"* | "$HOME/.claude/agent-memory/devteam-qa/"* | "$HOME/.claude/agent-memory/qa/"*) exit 0 ;;
esac

echo "devteam:qa is read-only. It may write only inside its memory folder under $HOME/.claude/agent-memory/, not $path" >&2
exit 2
