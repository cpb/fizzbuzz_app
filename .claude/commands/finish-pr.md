---
description: Wait for CI, merge a PR, and clean up its worktree and tmux window
argument-hint: [pr-number]
---

Finish a PR: block until CI completes, merge on green, tear down the worktree, and close the tmux window.

## Steps

**1. Determine the PR number**

If `$ARGUMENTS` is set, use it. Otherwise detect from the current branch:
```bash
gh pr view --json number --jq '.number'
```
Abort if no PR is found for the current branch.

**2. Fetch PR details**

```bash
gh pr view <number> --json number,title,headRefName,url,state
```

Abort if `state` is not `OPEN`.

**3. Resolve the worktree path for this PR**

```bash
git worktree list --porcelain | grep -B1 "branch refs/heads/<headRefName>" | grep "^worktree" | sed 's/worktree //'
```

Store this as `wt_path`. If no worktree exists for this branch, skip steps 6 and 7 (nothing to tear down locally).

**4. Detect which tmux window owns this worktree**

Find the window target for any pane whose current path is inside the worktree:
```bash
pr_target=$(tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
  | awk -v p="$wt_path" 'index($2, p) == 1 {print $1; exit}')
```

Check whether that target is the window we are currently running in:
```bash
current_target=$(tmux display-message -p "#{session_name}:#{window_index}" 2>/dev/null || echo "")
same_window=$( [ -n "$pr_target" ] && [ "$pr_target" = "$current_target" ] && echo "yes" || echo "no" )
```

`pr_target` may be empty if no window is open for this worktree — that is fine, skip the kill step.

**5. Block until CI completes**

`gh pr checks --watch` streams live check status and exits 0 when all pass, 1 when any fail:
```bash
gh pr checks <number> --watch
```

If it exits non-zero, print:
```
CI failed on PR #<number>. Fix the failures before finishing.
```
…and stop. Do NOT merge or clean up.

**6. Merge the PR**

```bash
gh pr merge <number> --squash
```

Do not pass `--delete-branch` — gh will try to delete the local branch, which fails while a worktree is using it. The remote branch is deleted separately after the worktree is removed:
```bash
git push origin --delete <headRefName>
```
(Skip the push if the remote branch is already gone — `git ls-remote --exit-code origin <headRefName>` exits non-zero if it doesn't exist.)

**7. Update main in the main worktree**

Fast-forward the local `main` branch to match the remote after the squash merge:
```bash
main_worktree=$(dirname "$(git rev-parse --git-common-dir)")
git -C "$main_worktree" fetch origin main
git -C "$main_worktree" merge --ff-only origin/main
```

If `merge --ff-only` fails (unexpected divergence), print a warning but continue — do not abort the cleanup.

**8. Remove the worktree**

`git worktree remove` fails if the shell is currently inside the directory being removed. Always cd to the main worktree first (reuse `$main_worktree` from step 7):
```bash
cd "$main_worktree" && bin/worktree down <headRefName>
```

**9. Close the tmux window**

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
