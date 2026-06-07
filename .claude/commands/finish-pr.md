---
description: Wait for CI, merge a PR, and clean up its worktree and tmux window
argument-hint: [pr-number]
---

Finish a PR: block until CI completes, merge on green, tear down the worktree, and close the tmux window.

## Steps

**1. Determine PR details**

Check for a session file in the current directory first:

```bash
session_loaded=""
if [ -f ".worktree-session.json" ] && [ "$(jq -r '.type' .worktree-session.json)" = "pr" ]; then
  number=$(jq '.number' .worktree-session.json)
  title=$(jq -r '.title' .worktree-session.json)
  headRefName=$(jq -r '.headRefName' .worktree-session.json)
  url=$(jq -r '.url' .worktree-session.json)
  wt_path=$(jq -r '.worktree_path' .worktree-session.json)
  remote_control=$(jq -r '.remote_control' .worktree-session.json)
  recorded_window=$(jq -r '.tmux_window' .worktree-session.json)
  session_loaded=true
fi
```

If not loaded, fall back to `gh`:

```bash
if [ -z "$session_loaded" ]; then
  number=${ARGUMENTS:-$(gh pr view --json number --jq '.number')}
  pr_json=$(gh pr view "$number" --json title,headRefName,url)
  title=$(echo "$pr_json" | jq -r '.title')
  headRefName=$(echo "$pr_json" | jq -r '.headRefName')
  url=$(echo "$pr_json" | jq -r '.url')
fi
```

Abort if no PR number could be determined.

**2. Resolve the worktree path**

Skip if `wt_path` is already set from the session file.

```bash
if [ -z "$wt_path" ]; then
  wt_path=$(git worktree list --porcelain | grep -B2 "branch refs/heads/$headRefName" | grep "^worktree" | sed 's/worktree //')
fi
```

If no worktree exists for this branch, skip steps 5 and 6 (nothing to tear down locally).

If `remote_control` and `recorded_window` are not yet set, read from the worktree session file:

```bash
if [ -z "$remote_control" ] && [ -f "$wt_path/.worktree-session.json" ]; then
  remote_control=$(jq -r '.remote_control' "$wt_path/.worktree-session.json")
  recorded_window=$(jq -r '.tmux_window'   "$wt_path/.worktree-session.json")
fi
```

**3. Detect which tmux window owns this worktree**

```bash
pr_target=$(bin/tmux-window "$wt_path")
current_target=$(tmux display-message -p "#{session_name}:#{window_index}" 2>/dev/null || echo "")
same_window=$( [ -n "$pr_target" ] && [ "$pr_target" = "$current_target" ] && echo "yes" || echo "no" )
```

`bin/tmux-window` reads `.worktree-session.json` from the worktree path, tries
`recorded_window` first (the authoritative name written at creation time), falls back
to a pane-path scan, and verifies the result before returning it. Empty output means
no window was found — skip the kill step.

**4. Block until CI completes**

`gh pr checks --watch` streams live check status and exits 0 when all pass, 1 when any fail:
```bash
gh pr checks <number> --watch
```

If it exits non-zero, print:
```
CI failed on PR #<number>. Fix the failures before finishing.
```
…and stop. Do NOT merge or clean up.

**5. Merge the PR**

```bash
gh pr merge <number> --squash
```

Do not pass `--delete-branch` — gh will try to delete the local branch, which fails while a worktree is using it. The remote branch is deleted separately after the worktree is removed:
```bash
git push origin --delete <headRefName>
```
(Skip the push if the remote branch is already gone — `git ls-remote --exit-code origin <headRefName>` exits non-zero if it doesn't exist.)

**6. Update main in the main worktree**

Fast-forward the local `main` branch to match the remote after the squash merge:
```bash
main_worktree=$(dirname "$(git rev-parse --git-common-dir)")
git -C "$main_worktree" fetch origin main
git -C "$main_worktree" merge --ff-only origin/main
```

If `merge --ff-only` fails (unexpected divergence), print a warning but continue — do not abort the cleanup.

**7. Remove the worktree**

`git worktree remove` fails if the shell is currently inside the directory being removed. Always cd to the main worktree first (reuse `$main_worktree` from step 6):
```bash
cd "$main_worktree" && bin/worktree down <headRefName>
```

**8. Close the tmux window**

Skip this step if `pr_target` is empty (no window was open for this worktree).

**Case A — running from a DIFFERENT window** (`same_window` is `no`):

Kill the window by its session:index target:
```bash
tmux kill-window -t "$pr_target"
```

Print:
```
Merged PR #<number> and cleaned up. Closed tmux window $pr_target.
```

**Case B — running FROM the PR's own window** (`same_window` is `yes`):

Schedule a self-destruct 3 seconds out so Claude has time to finish printing:
```bash
(sleep 3 && tmux kill-window -t "$current_target") &
```

Print:
```
PR #<number> merged and worktree removed. Closing this window in 3 seconds.
```

Then stop — do not make any further tool calls.
