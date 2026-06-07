---
description: Interactive test-plan walkthrough with operator sign-off
argument-hint: [pr-number]
---

Walk through a PR's test plan with automated checks and operator confirmation, then finish the PR on full pass or enter plan mode on failure.

## Steps

**1. Check prerequisites**

```bash
if [ -z "$TMUX" ]; then echo "ERROR: not inside tmux — run this from inside a tmux session"; exit 1; fi
```

**2. Determine the PR number**

If `$ARGUMENTS` is set, use it. Otherwise read from `.worktree-session.json`:
```bash
jq -r '.number' .worktree-session.json
```

If `.worktree-session.json` does not exist and no argument was given, abort with:
```
ERROR: no PR number provided and .worktree-session.json not found.
Run /qa-pr <pr-number>, or start this worktree with /start-pr or /continue-pr.
```

**3. Fetch PR details**

```bash
gh pr view <number> --json number,title,body,headRefName,url,state,files
```

Abort if `state` is not `OPEN`.

**4. Detect PR mode**

Inspect `files[].path`:

- **skill** — any path matches `.claude/commands/*.md`
- **app** — any path matches `app/**`, `config/routes.rb`, or `db/**`

A PR may be both. Note which modes apply.

**5. Delegate to sub-commands**

Run the applicable sub-command(s) in order. Pass the PR number as the argument.

If the PR is skill mode: invoke the `qa-pr-skill` skill with `<number>`.
If the PR is app mode: invoke the `qa-pr-app` skill with `<number>`.

If neither mode is detected, print:
```
No skill or app changes detected in PR #<number>. Skipping automated checks.
```
Then use `AskUserQuestion` — "No automated checks apply. Ready to proceed to merge?" with options: Yes / No. On No, stop.

**6. On any failure signal from a sub-command**

Enter plan mode (`EnterPlanMode`) and propose a targeted recovery plan addressing the specific failed item. Do not proceed to merge.

**7. All checks passed — finish the PR**

Print:
```
All test-plan items passed for PR #<number>: <title>.
Calling /finish-pr to merge and clean up.
```

Invoke the `finish-pr` skill.
