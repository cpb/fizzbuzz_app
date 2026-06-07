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

**3. Elicit dependencies from the operator**

Read each test-plan item and identify the concrete inputs the automated session will need in order to actually exercise the skills (not simulate them). Common dependencies:

- Items that invoke `/start-pr` need a real open GitHub issue number
- Items that invoke `/continue-pr` or `/finish-pr` need a real open PR number
- Items that check a file or branch name need the actual expected value
- Items that verify a tmux window need the expected window name

For each dependency found, collect it from the operator using `AskUserQuestion` before starting the session. For example:

- "Item 1 requires running `/start-pr`. What open issue number should it use?"
- "Item 3 requires inspecting `/finish-pr` behaviour. What PR number should it reference for the session file check?"

Store the collected values. If the operator cannot supply a dependency (e.g., no suitable open issue exists), note it as a skip condition and tell the operator the item will be marked Needs-review rather than exercised.

**4. Compose the test-runner prompt**

Build a structured message that instructs the new Claude session to exercise and report on each item automatically. Substitute all dependency values (issue numbers, PR numbers, expected names) into the item descriptions — do not leave angle-bracket placeholders.

Write the prompt to a temp file to avoid shell quoting issues:

```bash
cat > /tmp/qa-skill-<number>-prompt.txt << 'PROMPT'
You are verifying a pull request's skill changes. The PR branch is already
checked out in this worktree — skill files in .claude/commands/ are the
PR's versions.

PR #<number>: <title>
<url>

## Test-plan items to verify

1. <item 1 with concrete dependency values substituted>
2. <item 2 with concrete dependency values substituted>
...

## Instructions

For each item above, in order:
1. **Ensure a clean slate first.** If the item exercises a skill that creates a
   worktree or tmux session (e.g. `/start-pr`, `/continue-pr`), check whether a
   worktree already exists for the target branch and tear it down before running:
   ```bash
   git worktree list --porcelain | grep "branch refs/heads/<branch>"
   bin/worktree down <branch>   # if it exists
   ```
   Also kill any tmux window whose name matches the expected window name
   (`issue-<n>` or `pr-<n>`) before proceeding. This ensures you exercise the
   full creation path, not the reuse-existing branch.
2. Exercise the skill described using the concrete values provided — invoke it
   with the supplied arguments, observe what happens, and capture the outcome.
3. Check any side effects mentioned (files written, tmux windows opened,
   commands run, JSON fields present) with brief bash checks.
4. For items marked "(inspect only)" or where live invocation would have
   irreversible side effects (e.g. merging a PR), verify by reading the skill
   file and running any safe supporting bash checks instead.
5. Do not ask for operator input — run everything automatically and report.

Produce a numbered verification report at the end:

  1. [Pass/Fail/Needs-review] — item text
     Observed: one sentence describing what actually happened

Be concise. The operator will read this report and confirm in the qa-pr session.
PROMPT
```

**5. Open a Claude session in the PR worktree**

Check for an existing pane already running in the worktree:
```bash
tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
  | awk -v p="$wt_path" 'index($2, p) == 1 {print $1; exit}'
```

Create a new window named `qa-skill-<number>` (always use a fresh window so the session starts clean):
```bash
tmux new-window -n "qa-skill-<number>" -c "$wt_path"
```

Send the test-runner prompt using single quotes so the current shell does not interpret the subshell — the tmux window's shell expands it:
```bash
tmux send-keys -t "qa-skill-<number>" 'claude "$(< /tmp/qa-skill-<number>-prompt.txt)"' Enter
```

**6. Tell the operator**

Print:
```
A Claude session is running the skill test plan in window qa-skill-<number>.
Switch to that window to watch. Return here once it has finished and produced
a verification report.
```

**7. Await operator review**

Use `AskUserQuestion`:

- Question: "Review the verification report in qa-skill-<number>. How did it go?"
- Options: "All items passed" / "One or more items failed"

**8. On "All items passed"**

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

**9. On "One or more items failed"**

Use `AskUserQuestion` to collect details:
- Question: "Which item(s) failed, and what was observed? (Describe briefly)"
- (free text)

Print a failure summary, then signal failure back to the router so it can enter plan mode.
