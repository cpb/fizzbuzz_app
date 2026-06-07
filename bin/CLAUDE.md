# bin/

## bin/worktree — worktree orchestration

| Command | What it does |
|---|---|
| `bin/worktree add <branch> [path]` | Create worktree; auto-assigns port ≥ 3001, writes `.env.local`, runs `bin/setup` |
| `bin/worktree list` | Show all worktrees with port and server status |
| `bin/worktree cd <name>` | Print `cd` command for eval: `eval "$(bin/worktree cd <name>)"` |
| `bin/worktree server <name>` | Start dev server in background → `log/dev_server.log` |
| `bin/worktree logs <name>` | Tail the server log |
| `bin/worktree stop <name>` | Stop server, keep worktree |
| `bin/worktree down <name>` | Stop server and remove worktree |

## Reading the active port

Each worktree stores its assigned port in `.env.local`:
```bash
grep "^PORT=" .env.local | cut -d= -f2
```

The dev server binds to `0.0.0.0:<port>`. The health check is `GET /up` → 200 when ready.

## bin/dev

Starts the Falcon web server on `$PORT` (default 3000). Used directly in the foreground or via `bin/worktree server <name>` for a background process whose output goes to `log/dev_server.log`.
