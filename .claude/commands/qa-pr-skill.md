---
description: Verify skill-contribution PR items via automated Claude session in the PR worktree
argument-hint: <pr-number>
---

Exercise skill changes in the PR-branch worktree using an automated Claude session, collect the verification report, and walk the operator through confirming each item.

## Steps

**1. Fetch PR and extract test-plan items**

```bash
gh pr view $ARGUMENTS --json number,title,body,headRefName,url
```

Parse lines matching `^- \[ \]` in the section whose heading contains "test" (case-insensitive). Store as an ordered list. If no items are found, print a notice and return to the caller.

**2. Resolve the worktree path**

```bash
git worktree list --porcelain \
  | grep -B1 "branch refs/heads/<headRefName>" \
  | grep "^worktree" \
  | sed 's/worktree //'
```

Store as `wt_path`. If no worktree exists for this branch, abort:
```
ERROR: No worktree found for <headRefName>. Run /continue-pr <number> first.
```

**3. Compose the test-runner prompt**

Build a structured message that instructs the new Claude session to exercise and report on each item automatically. The prompt should contain:

```
You are verifying a pull request's skill changes. The PR branch is already
checked out in this worktree — skill files in .claude/commands/ are the
PR's versions.

PR #<number>: <title>
<url>

## Test-plan items to verify

<n>. <item 1>
<n>. <item 2>
...

## Instructions

For each item above, in order:
1. Exercise the skill described — invoke it with representative arguments,
   observe what happens, and capture the outcome.
2. Check any side effects mentioned (files written, tmux windows opened,
   commands run, etc.) with brief bash checks.
3. Do not ask for operator input — run everything automatically and report.

Produce a numbered verification report at the end:

  1. [Pass/Fail/Needs-review] — <item text>
     Observed: <one sentence describing what actually happened>

Be concise. The operator will read this report and confirm in the qa-pr session.
```

Store the full prompt string as `test_runner_prompt`.

**4. Open a Claude session in the PR worktree**

Check for an existing pane already running in the worktree:
```bash
tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
  | awk -v p="$wt_path" 'index($2, p) == 1 {print $1; exit}'
```

If none found, create a new window named `qa-skill-<number>`:
```bash
tmux new-window -n "qa-skill-<number>" -c "$wt_path"
```

Send the test-runner prompt as the opening message:
```bash
tmux send-keys -t "qa-skill-<number>" "claude \"$test_runner_prompt\"" Enter
```

**5. Tell the operator**

Print:
```
A Claude session is running the skill test plan in window qa-skill-<number>.
Switch to that window to watch. Return here once it has finished and produced
a verification report.
```

**6. Await operator review**

Use `AskUserQuestion`:

- Question: "Review the verification report in qa-skill-<number>. How did it go?"
- Options: "All items passed" / "One or more items failed"

**7. On "All items passed"**

For each test-plan item, fetch the current PR body and replace `- [ ] <item text>` with `- [x] <item text>`:
```bash
current_body=$(gh pr view <number> --json body --jq '.body')
# apply replacement for each item
gh pr edit <number> --body "<updated_body>"
```

Print:
```
✓ Marked <n> skill test-plan items as passed in PR #<number>.
```

Return to the caller (router).

**8. On "One or more items failed"**

Use `AskUserQuestion` to collect details:
- Question: "Which item(s) failed, and what was observed? (Describe briefly)"
- (free text)

Print a failure summary, then signal failure back to the router so it can enter plan mode.
