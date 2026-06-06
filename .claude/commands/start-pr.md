---
description: Open a worktree + tmux window with Claude in plan mode to tackle a GitHub issue
argument-hint: <issue-number>
---

Set up an isolated worktree and launch Claude in plan mode, primed with the full issue description, for issue $ARGUMENTS.

## Steps

**1. Check prerequisites**

```bash
if [ -z "$TMUX" ]; then echo "ERROR: not inside tmux"; exit 1; fi
if [ -z "$ARGUMENTS" ]; then echo "Usage: /start-pr <issue-number>"; exit 1; fi
```

**2. Fetch issue details**

```bash
gh issue view $ARGUMENTS --json number,title,body,url,labels,state
```

Abort if the issue is not found or `state` is `CLOSED`.

**3. Derive the branch name**

Slugify the title: lowercase, replace runs of non-alphanumeric characters with `-`, strip leading/trailing hyphens, truncate to 50 characters. Prefix with `issue-<number>/`:

```bash
slug=$(gh issue view $ARGUMENTS --json title \
  --jq '.title | ascii_downcase | gsub("[^a-z0-9]+"; "-") | ltrimstr("-") | rtrimstr("-")' \
  | cut -c1-50)
branch="issue-<number>/$slug"
```

**4. Check for an existing worktree**

```bash
git worktree list --porcelain
```

If `branch refs/heads/<branch>` already appears, skip to step 6.

**5. Create the worktree**

```bash
bin/worktree add <branch>
```

**6. Resolve the worktree path**

```bash
git worktree list --porcelain \
  | grep -B1 "branch refs/heads/<branch>" \
  | grep "^worktree" \
  | sed 's/worktree //'
```

**7. Write the issue context file**

Write the following markdown to `<worktree-path>/pr_context.md`:

```
# Issue #<number>: <title>
URL: <url>
Labels: <labels>

<body>
```

**8. Find or create the tmux window**

Check for an existing pane already in this worktree:
```bash
pr_target=$(tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
  | awk -v p="<worktree-path>" 'index($2, p) == 1 {print $1; exit}')
```

If no match, create a new window named `issue-<number>`:
```bash
tmux new-window -n "issue-<number>" -c "<worktree-path>"
```

Use the new window as the target.

**9. Start Claude in plan mode**

Send the command to the window. `--permission-mode plan` starts Claude in plan mode so it must get approval before making any edits. The issue description becomes the opening prompt:

```bash
tmux send-keys -t "<window-target>" 'claude --permission-mode plan "$(< pr_context.md)"' Enter
```

**10. Print a confirmation**

```
Started: issue-<number>  →  <worktree-path>
Issue #<number>: <title>
<url>
Claude is in plan mode — it will propose a plan before making any changes.
```
