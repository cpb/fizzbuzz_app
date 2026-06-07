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

Try each source in order, stopping at the first that succeeds:

1. `$ARGUMENTS` — use it directly if set.
2. `.worktree-session.json` — read with:
   ```bash
   jq -r '.number' .worktree-session.json
   ```
3. Current branch — detect from git:
   ```bash
   gh pr view --json number --jq '.number'
   ```

If all three fail, abort:
```
ERROR: could not determine PR number. Run /qa-pr <pr-number>.
```

Print which source was used, e.g. `Using PR #<n> from .worktree-session.json`.

**3. Fetch PR details**

```bash
gh pr view <number> --json number,title,body,headRefName,url,state
```

Abort if `state` is not `OPEN`.

**4. Detect PR mode**

Use `git diff` against the merge base rather than the GitHub files list — this reflects only what the PR actually introduces, not files carried in via rebase:

```bash
wt_path=$(git worktree list --porcelain \
  | grep -B2 "branch refs/heads/<headRefName>" \
  | grep "^worktree" | sed 's/worktree //')
changed=$(git -C "$wt_path" diff --name-only \
  "$(git -C "$wt_path" merge-base HEAD origin/main)")
```

Classify from `$changed`:

- **skill** — any path matches `.claude/commands/*.md`
- **app** — any path matches `app/*`, `config/routes.rb`, or `db/*`

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
