---
description: Verify app-change PR items via dev server and browser automation
argument-hint: <pr-number>
---

Start the dev server for the PR's worktree, exercise each test-plan item with browser automation and the verify skill, elicit operator confirmation, and mark passed items in the PR body.

## Steps

**1. Fetch PR and extract test-plan items**

```bash
gh pr view $ARGUMENTS --json number,title,body,headRefName,url
```

Parse lines matching `^- \[ \]` in the section whose heading contains "test" (case-insensitive). Store as an ordered list. If no items are found, print a notice and return to the caller.

**2. Read the port and start the dev server if needed**

```bash
port=$(grep "^PORT=" .env.local | cut -d= -f2)
status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/up 2>/dev/null)
```

If `status` is not `200`:
```bash
bin/worktree server <headRefName>
```

Poll `/up` every 2 seconds, up to 10 attempts. If still not up after 10 s, abort:
```
ERROR: dev server did not start within 10 s. Check log/dev_server.log for details.
```

**3. Open the app**

Invoke the `run` skill to open the app in the browser. This gives the operator a live view for the walkthrough.

**4. Walk through each test-plan item**

Process items sequentially. For each item N of M:

**4a. Announce the item**

```
── Step N/M ─────────────────────────────────────────
<item text>
```

**4b. Run automated pre-checks**

Based on the item text, run relevant checks and present findings:
- If the item mentions a specific route or URL: curl it and show the status
- If the item mentions a file: check it exists and show relevant content
- If the item mentions a git check: run `git status` or `git log --oneline -3`
- If the item mentions a form or UI interaction: navigate to the relevant page

**4c. Use the verify skill**

Invoke the `verify` skill to observe the actual application behaviour for this item and confirm whether the outcome matches the description. Present the findings to the operator.

**4d. Ask for operator confirmation**

Use `AskUserQuestion`:

- Question: `"Step N/M: <item text> — pass or fail?"`
- Options: `"Pass"` / `"Fail"`

**4e. On Pass**

Fetch the current PR body and replace `- [ ] <item text>` with `- [x] <item text>`:
```bash
current_body=$(gh pr view <number> --json body --jq '.body')
# apply replacement for this item
gh pr edit <number> --body "<updated_body>"
```

Print: `✓ Step N marked as passed in PR #<number>.`

**4f. On Fail**

Print:
```
✗ Step N failed: <item text>
```

Signal failure back to the router. Do not continue to the next item.

**5. All items passed**

Print:
```
✓ All M app test-plan items passed for PR #<number>.
```

Return to the caller (router).
