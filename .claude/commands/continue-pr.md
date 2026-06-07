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

Fetch metadata fields (without body) and extract each value — body is fetched separately to avoid jq failing on control characters that can appear in PR descriptions:

```bash
pr_json=$(gh pr view $ARGUMENTS --json number,title,headRefName,url,state)
number=$(echo "$pr_json" | jq '.number')
title=$(echo "$pr_json" | jq -r '.title')
headRefName=$(echo "$pr_json" | jq -r '.headRefName')
url=$(echo "$pr_json" | jq -r '.url')
state=$(echo "$pr_json" | jq -r '.state')
pr_body=$(gh pr view $ARGUMENTS --json body --jq '.body')
```

Check `state` and abort immediately if the PR is not open:

- `MERGED` → `"PR #<number> is already merged. Use /finish-pr to clean up any leftover worktree, or nothing if it's already gone."`
- `CLOSED` → `"PR #<number> is closed. Nothing to continue."`

Only proceed if `state` is `OPEN`.

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
git worktree list --porcelain | grep -B2 "branch refs/heads/<headRefName>" | grep "^worktree" | sed 's/worktree //'
```

**6. Derive the remote-control name**

Use `$title` (already extracted) to build the slug. `-Rr` treats the shell variable as a raw string:

```bash
rc_slug=$(echo "$title" | jq -Rr 'ascii_downcase | gsub("[^a-z0-9]+"; "-") | ltrimstr("-") | rtrimstr("-")' \
  | cut -c1-30 | sed 's/-$//')
remote_control="x-$number-$rc_slug"
```

**7. Write the PR context file**

Write the following markdown to `<worktree-path>/pr_context.md` (use `$pr_body` for `<body>`):

```
# PR #<number>: <title>
URL: <url>

<body>
```

Then write `<worktree-path>/.worktree-session.json`:

```bash
jq -n \
  --arg remote_control "$remote_control" \
  --arg tmux_window "pr-$number" \
  --arg worktree_path "$wt_path" \
  --arg type "pr" \
  --argjson number "$number" \
  --arg title "$title" \
  --arg url "$url" \
  --rawfile initial_prompt "$wt_path/pr_context.md" \
  '{remote_control:$remote_control,tmux_window:$tmux_window,worktree_path:$worktree_path,type:$type,number:$number,title:$title,url:$url,initial_prompt:$initial_prompt}' \
  > "$wt_path/.worktree-session.json"
```

**8. Create the tmux window**

Check whether any existing pane is already running inside the worktree path:
```bash
tmux list-panes -a -F "#{session_name}:#{window_index} #{pane_current_path}" \
  | awk -v p="<worktree-path>" 'index($2, p) == 1 {print $1; exit}'
```

If a match is found, skip window creation and use that target for send-keys in step 9.

If no match, create a new window named `pr-<number>` starting in the worktree:
```bash
tmux new-window -n "pr-<number>" -c "<worktree-path>"
```
The new window target is `pr-<number>`.

**9. Start Claude primed with the PR description**

Build the command string first so `$remote_control` expands in the current shell while `$(< pr_context.md)` is deferred to the tmux window's shell:
```bash
claude_cmd="claude --remote-control $remote_control \"\$(< pr_context.md)\""
tmux send-keys -t "<window-target>" "$claude_cmd" Enter
```

**10. Print a confirmation**

```
Created: pr-<number>  →  <worktree-path>
PR #<number>: <title>
<url>
Remote control: <remote_control>
```
