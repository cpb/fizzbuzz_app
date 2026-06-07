# Contributing

## Multi-Claude worktree workflow

Every feature or fix lives in its own git worktree so multiple Claude sessions
can run in parallel without conflicting. `main` is treated as read-only for
code edits.

### Starting work on an issue

```sh
# From a tmux session, on any branch including main:
/start-pr <issue-number>
```

Opens a new tmux window with a fresh worktree and Claude in **plan mode** —
it will propose a plan before touching any files.

### Picking up a pull request

```sh
/continue-pr <pr-number>
```

Checks out the PR branch into an isolated worktree and opens a Claude session
pre-loaded with the full PR description.

### Merging and cleaning up

```sh
/finish-pr              # detects PR from current branch
/finish-pr <pr-number>  # explicit PR number, works from any worktree
```

Waits for all CI checks to pass, squash-merges, removes the remote branch,
tears down the worktree, and closes the tmux window. Stops without merging if
CI fails.

### Manual worktree management

```sh
bin/worktree add <branch>    # create worktree (auto-assigns port)
bin/worktree list            # list all worktrees + server status
bin/worktree cd <name>       # print cd command: eval "$(bin/worktree cd <name>)"
bin/worktree server <name>   # start dev server in background
bin/worktree logs <name>     # tail the dev server log
bin/worktree down <name>     # stop server + remove worktree
```

Each worktree gets its own port, SQLite database, and PID directory, so
`bin/dev` and `bin/rails test` can run simultaneously across worktrees.

## Prerequisites for the workflow

- [tmux](https://github.com/tmux/tmux) — required for the slash-command workflow
- [GitHub CLI (`gh`)](https://cli.github.com/) — required for PR/issue commands; run `gh auth login` once

## Development commands

```sh
bin/dev                  # start dev server in this worktree
bin/rails test           # run tests (isolated database per worktree)
bin/worktree list        # see all active worktrees and their ports
bin/worktree server <name>   # start server in background
bin/worktree logs <name>     # tail the server log
bin/worktree down <name>     # stop server + remove worktree
```
