---
description: Walk through a PR's test plan with the operator, then finish-pr on unanimous pass or propose a recovery plan on failure
argument-hint: [pr-number]
---

Sequentially exercise and verify every test plan item in the active PR, elicit operator agreement at each step, then merge on success or enter plan mode to recover on failure.

## Steps

**1. Determine the PR number**

If `$ARGUMENTS` is set, use it. Otherwise detect from the current branch:
```bash
gh pr view --json number --jq '.number'
```
Abort if no PR is found for the current branch.

**2. Fetch PR details**

```bash
gh pr view <number> --json number,title,url,body,state
```

Abort if `state` is not `OPEN`.

**3. Extract the test plan**

Parse all markdown checkbox lines (`- [ ] …`) from the PR body. These are the test plan items. Print the full list before starting:

```
Test plan for PR #<number>: <title>
<url>

  1. <item 1>
  2. <item 2>
  ...
```

If no checkbox items are found, use `AskUserQuestion` to ask the operator to describe the steps to verify before continuing.

**4. Work through each item sequentially**

For each test plan item (in order):

**a. Announce** — print which step you are on:

```
── Step N of M ──────────────────────────────
<item text>
```

**b. Exercise** — use the `run` skill to start the application or trigger the behavior described in the step. If the step requires manual user action (e.g. running a slash command in another tmux window), describe exactly what the operator should do and wait.

**c. Verify** — use the `verify` skill to observe the actual outcome and confirm whether it matches the expected behavior described in the step.

**d. Elicit agreement** — use `AskUserQuestion`:

- Question: `"Step N: <item text> — did this pass?"`
- Options: `"Pass"` / `"Fail"` / `"Skip (not applicable)"`

If the operator answers **Fail**, record the step number and the observed behavior, then jump immediately to step 7 (recovery plan). Do not continue to the next step.

If the operator answers **Skip**, note it and continue to the next item.

**5. Elicit final confirmation**

After all items have been passed or skipped, use `AskUserQuestion` for a final gate:

- Question: `"All N test plan steps are done. Ready to merge PR #<number>: <title>?"`
- Options: `"Yes — merge it"` / `"No — something needs fixing"`

If `"Yes"`, proceed to step 6. If `"No"`, jump to step 7.

**6. Finish the PR**

Invoke the `finish-pr` skill. It will wait for CI, squash-merge, tear down the worktree, and close the tmux window.

**7. Propose a recovery plan** *(only reached on failure)*

Summarise the failure before proposing a fix:

```
── Failure on step N ────────────────────────
Item:     <item text>
Observed: <what actually happened>
```

Then enter plan mode to propose a concrete recovery plan. The plan should include:

- The likely root cause based on what was observed
- The specific files and changes needed to fix it
- How to re-run this skill to re-verify once the fix is applied
