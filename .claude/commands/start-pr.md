---
description: Open a worktree + tmux window with Claude in plan mode to tackle a GitHub issue
argument-hint: <issue-number>
---

Set up an isolated worktree and launch Claude in plan mode, primed with the full issue description, for issue $ARGUMENTS.

## Steps

**1. Prepare the worktree**

```bash
if [ -z "$ARGUMENTS" ]; then echo "Usage: /start-pr <issue-number>"; exit 1; fi

issue_json=$(bin/worktree prepare "$ARGUMENTS" --issue)
```

**2. Launch the harness**

```bash
bin/worktree harness "$ARGUMENTS"
```

**3. Print a confirmation**

Print a summary including the worktree path, issue title/URL, and the remote control name from the JSON.
Mention that Claude is in plan mode.
