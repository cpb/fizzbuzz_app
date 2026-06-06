---
description: Create a worktree + tmux window + Claude session primed with a PR's description
argument-hint: <pr-number>
---

Set up an isolated worktree and launch a Claude session primed with the full PR description for PR $ARGUMENTS.

## Steps

**1. Check prerequisites**

Verify you are inside a tmux session:
```bash
if [ -z "$TMUX" ]; then echo "ERROR: not inside tmux — run this from inside a tmux session"; exit 1; fi
```

Also confirm a PR number was provided:
```bash
if [ -z "$ARGUMENTS" ]; then echo "Usage: /continue-pr <pr-number>"; exit 1; fi
```

**2. Fetch PR details**

```bash
gh pr view $ARGUMENTS --json number,title,headRefName,url,body,state
```

If the PR is not found or closed, abort with a clear error.

**3. Check for an existing worktree**

```bash
git worktree list --porcelain
```

If `branch refs/heads/<headRefName>` already appears, skip to step 5.

**4. Create the worktree**

```bash
bin/worktree add <headRefName>
```

**5. Resolve the worktree path**

```bash
git worktree list --porcelain | grep -B1 "branch refs/heads/<headRefName>" | grep "^worktree" | sed 's/worktree //'
```

**6. Write the PR context file**

Write the following markdown to `<worktree-path>/pr_context.md`:

```
# PR #<number>: <title>
URL: <url>

<body>
```

**7. Create the tmux window**

Check whether any existing pane is already running inside the worktree path:
```bash
tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
  | awk -v p="<worktree-path>" 'index($2, p) == 1 {print $1; exit}'
```

If a match is found, skip window creation and use that target for send-keys in step 8.

If no match, create a new window named `pr-<number>` starting in the worktree:
```bash
tmux new-window -n "pr-<number>" -c "<worktree-path>"
```
The new window target is `pr-<number>`.

**8. Start Claude primed with the PR description**

Send a command to the window target. The single quotes prevent the current shell from expanding the subshell — the tmux window's shell will expand it:
```bash
tmux send-keys -t "<window-target>" 'claude "$(< pr_context.md)"' Enter
```

**9. Print a confirmation**

```
Created: pr-<number>  →  <worktree-path>
PR #<number>: <title>
<url>
```
