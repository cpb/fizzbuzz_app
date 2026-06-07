# .claude/commands/

## Skill file format

Each skill is a Markdown file with YAML frontmatter:

```yaml
---
description: One-line description shown in the skill list
argument-hint: <required-arg> [optional-arg]
---
```

Followed by a one-sentence summary and a `## Steps` section with numbered, bold-headed steps.

## Skill-contribution PR convention

When a PR adds or modifies a skill file, testing **must** use the PR-branch worktree — not static file inspection. This ensures the skill resolves to the PR's version, not main's.

`/qa-pr` detects `.claude/commands/*.md` in the PR diff and delegates to `/qa-pr-skill`, which:

1. Resolves the existing PR worktree (created by `/start-pr` or `/continue-pr`)
2. Opens a `claude` session there with a structured prompt listing the test-plan items
3. That session exercises the skills automatically and produces a numbered verification report
4. The operator reviews the report and confirms pass/fail back in the `/qa-pr` window

Do not test skill changes by reading the `.md` files statically — behaviour depends on how Claude interprets and executes the instructions, which only shows up in a live session.

## Available skills

| Skill | Purpose |
|---|---|
| `/start-pr <n>` | Create worktree + plan-mode Claude for a GitHub issue |
| `/continue-pr <n>` | Create worktree + Claude session for an open PR |
| `/finish-pr [n]` | CI gate → squash-merge → worktree teardown |
| `/qa-pr [n]` | Router: detect PR mode, delegate to sub-commands, finish on pass |
| `/qa-pr-skill <n>` | Skill-contribution walkthrough via automated Claude session |
| `/qa-pr-app <n>` | App-change walkthrough via dev server + browser automation |
| `/new-issue [topic]` | Elicit intent and create a GitHub issue |
| `/hill-first <layers>` | Write failing tests per layer, open draft PR for human hill review |
