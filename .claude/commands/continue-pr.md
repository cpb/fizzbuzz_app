---
description: Create a worktree + tmux window + Claude session primed with a PR's description
argument-hint: <pr-number>
---

Set up an isolated worktree and launch a Claude session primed with the full PR description for PR $ARGUMENTS.

## Steps

**1. Check prerequisites**

```bash
if [ -z "$TMUX" ]; then echo "ERROR: not inside tmux"; exit 1; fi
if [ -z "$ARGUMENTS" ]; then echo "Usage: /continue-pr <pr-number>"; exit 1; fi
```

**2. Check for hill-ready gate**

Fetch labels from the PR:

```bash
hill_ready=$(gh pr view $ARGUMENTS --json labels --jq '[.labels[].name] | contains(["hill-ready"])')
```

If `hill_ready` is `true`, this PR is a hill under review. Enter the following loop:

**a) Wait for CI and report status:**

```bash
bin/worktree check-hill "$ARGUMENTS"
```

**b) Reflect and elicit feedback with `AskUserQuestion`:**

Present a summary of what CI shows versus what was expected (use inference to explain the report).

**c) On "Looks correct — I'll remove `hill-ready` now":**

Wait for the operator to remove the label, then confirm. Once gone, set `hill_gate_cleared=true` and proceed.

**3. Prepare the worktree**

```bash
pr_json=$(bin/worktree prepare "$ARGUMENTS" --pr)
wt_path=$(echo "$pr_json" | jq -r '.worktree_path')
```

**4. Write the PR context file**

Use inference to generate `pr_context.md` in the worktree path.

- Include the PR title and URL.
- Summarize the body.
- If `hill_gate_cleared` is true, append the "Implementation task" section instructions.

**5. Launch the harness**

```bash
bin/worktree harness "$ARGUMENTS"
```

**6. Print a confirmation**

Print a summary including the worktree path, PR title/URL, and remote control name.
