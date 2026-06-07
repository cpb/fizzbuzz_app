---
description: Open a worktree + tmux window with Claude in plan mode to tackle a GitHub issue
argument-hint: <issue-number>
---

Set up an isolated worktree and launch Claude in plan mode, primed with the full issue description, for issue $ARGUMENTS.

## Steps

**1. Prepare the worktree**

```bash
if [ -z "$TMUX" ]; then echo "ERROR: not inside tmux"; exit 1; fi
if [ -z "$ARGUMENTS" ]; then echo "Usage: /start-pr <issue-number>"; exit 1; fi

# Fetch metadata and prepare worktree
issue_json=$(bin/worktree prepare "$ARGUMENTS" --issue)
wt_path=$(echo "$issue_json" | jq -r '.worktree_path')
```

**2. Write the issue context file**

Use inference to generate a high-quality `pr_context.md` in the worktree path.

- Include the issue title, URL, and labels.
- Summarize the body.
- If the issue carries the `test-first` label, append the "Test-first hill required" section instructions (Outside-in test layers, `/hill-first`, etc.).

**3. Launch the harness**

```bash
bin/worktree harness "$ARGUMENTS"
```

**4. Print a confirmation**

Print a summary including the worktree path, issue title/URL, and the remote control name from the JSON.
Mention that Claude is in plan mode.
