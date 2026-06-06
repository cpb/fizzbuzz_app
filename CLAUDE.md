# FizzBuzz App — Claude Code Guide

## Worktree-first development

Every feature, fix, or investigation lives in its own git worktree. The `main`
worktree is treated as read-only — Claude Code is blocked from using any tools
there (enforced by `.claude/settings.json`).

### Starting a new session

```sh
# 1. Create an isolated worktree (auto-assigns port, runs bin/setup)
bin/worktree add <branch-name>

# 2. cd into it
eval "$(bin/worktree cd <branch-name>)"

# 3. Start Claude
claude
```

### Session start protocol

At the start of every session, run `git branch --show-current`.

- **If the result is `main`**: you are blocked by the settings hook. Tell the
  user they need to create a worktree before you can do anything:
  ```
  bin/worktree add <branch-name>
  eval "$(bin/worktree cd <branch-name>)"
  claude
  ```
- **If the result is any other branch**: proceed normally.

### bin/worktree CLI

| Command | What it does |
|---|---|
| `bin/worktree add <branch> [path]` | New worktree, auto-port ≥ 3001, `.env.local`, `bin/setup` |
| `bin/worktree list` | All worktrees with port + server status |
| `bin/worktree cd <name>` | Print `cd` for eval — `eval "$(bin/worktree cd <name>)"` |
| `bin/worktree server <name>` | Start dev server in background → `log/dev_server.log` |
| `bin/worktree logs <name>` | `tail -f` the server log |
| `bin/worktree down <name>` | Stop server + `git worktree remove` |

### Worktree isolation

Each worktree has:
- Its own port (set in `.env.local`, loaded by `dotenv-rails`)
- Its own `storage/` directory (SQLite databases, Active Storage files)
- Its own `tmp/pids/` (no PID conflicts)

This means `bin/dev` and `bin/rails test` can run in multiple worktrees
simultaneously without any conflicts.

---

## Multi-Claude patterns

### Pattern A — Terminal per worktree (independent tasks)

Open a terminal per worktree and run `claude` in each. Sessions are fully
isolated and can run in parallel.

```sh
# Terminal 1
eval "$(bin/worktree cd feature-a)" && claude

# Terminal 2
eval "$(bin/worktree cd bugfix-b)" && claude
```

### Pattern B — Orchestrator + subagents (coordinated tasks)

When a task spans multiple concerns (e.g. implement a feature AND write docs
AND fix a related bug), use the Agent tool to spawn subagents into separate
worktrees.

Create a dedicated orchestrator worktree first:

```sh
bin/worktree add orchestrate-<task>
eval "$(bin/worktree cd orchestrate-<task>)"
claude
```

Then inside the orchestrator session, spawn subagents using `isolation:
"worktree"` so each gets its own isolated copy of the repo:

```
Agent(
  subagent_type: "general-purpose",
  isolation: "worktree",          # Claude Code creates a temp git worktree
  prompt: "Implement X in ...",
  run_in_background: true
)
```

Use `run_in_background: true` to fan out agents in parallel, then collect
results when they complete.

**When to use each pattern:**

| Situation | Pattern |
|---|---|
| Independent features, no shared state | A — terminals |
| Single large task with parallelizable subtasks | B — orchestrator |
| Feature + tests + docs in one go | B — orchestrator |
| Pair programming / review | A — separate terminals |

---

## Development workflow

```sh
# Run dev server in this worktree
bin/dev

# Run tests (uses TEST_DATABASE from .env.local, isolated from other worktrees)
bin/rails test

# See all active worktrees and their ports
bin/worktree list

# Start server in background, tail logs
bin/worktree server <name>
bin/worktree logs <name>

# Tear down when done
bin/worktree down <name>
```
