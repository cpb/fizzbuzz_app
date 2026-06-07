---
name: run-fizzbuzz-app
description: Build, run, and drive the fizzbuzz-app Rails server. Use when asked to start the app, run its dev server, take a screenshot of its UI, interact with the running app, or verify a change works in the browser.
---

A Rails 8 app (Falcon server) that streams a FizzBuzz countdown via Turbo Streams. Drive it by starting the dev server, then using the Claude-in-Chrome MCP browser tools to navigate and interact — `chromium-cli` is not available in this environment.

All paths below are relative to the repo root (`fizzbuzz_app/`).

## Prerequisites

- Ruby (version in `.ruby-version`) — already present on this machine
- Bundler — already present

No additional `apt-get` installs needed.

## Setup

Gems are installed via `bin/setup`. Run this once after cloning, or if `bundle check` fails:

```bash
bin/setup --skip-server
```

## Run (agent path)

### 1. Determine port

Each worktree stores its port in `.env.local`. Read it:

```bash
PORT=$(grep "^PORT=" .env.local 2>/dev/null | cut -d= -f2)
PORT=${PORT:-3000}
echo "Using port $PORT"
```

### 2. Start the server

If already running (check with `curl -sf http://localhost:$PORT/up`), skip this step.

```bash
# Background — logs go to log/dev_server.log
bin/worktree server $(git branch --show-current)

# Or foreground (for one-off runs):
PORT=$PORT bin/dev &
echo $! > /tmp/fizzbuzz-dev.pid
```

Wait until the server is ready:

```bash
timeout 30 bash -c "until curl -sf http://localhost:$PORT/up >/dev/null; do sleep 1; done" && echo "ready"
```

### 3. Navigate and screenshot via MCP browser tools

Use the Claude-in-Chrome MCP tools (loaded via ToolSearch). Typical flow:

```
# Load tools first:
ToolSearch: select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__browser_batch,mcp__claude-in-chrome__computer

# Get or create a tab:
mcp__claude-in-chrome__tabs_context_mcp (createIfEmpty: true)

# Navigate to the start page:
mcp__claude-in-chrome__navigate { url: "http://localhost:PORT/fizz_buzz/start", tabId: <id> }

# Take a screenshot:
mcp__claude-in-chrome__computer { action: "screenshot", tabId: <id>, save_to_disk: true }
```

### 4. Submit the form and observe streaming results

```
# Clear the number field, type a starting number, click Start:
mcp__claude-in-chrome__browser_batch:
  - computer triple_click on the "Starting integer" input (coords ~[184, 90] at 1x zoom)
  - computer type "5"
  - computer left_click "Start" button
  - computer wait 6   ← N+1 seconds (one result per second)
  - computer screenshot save_to_disk:true
```

Results appear in the `#results` div, one per second, as Turbo Stream appends. At starting integer N, wait at least `N + 1` seconds for all results to arrive.

Expected output for starting integer 5: **Buzz, 4, Fizz, 3, 2, 1** (top to bottom).

### 5. Stop the server

```bash
# If started via bin/worktree server:
bin/worktree stop $(git branch --show-current)

# If started manually:
kill $(cat /tmp/fizzbuzz-dev.pid)
```

## Run (human path)

```bash
bin/dev   # → opens http://localhost:3000/fizz_buzz/start in a browser. Ctrl-C to stop.
```

## Test

```bash
bin/rails test
```

Expected: 10 runs, 23 assertions, 0 failures.

## Gotchas

- **`chromium-cli` is not installed.** Use the `mcp__claude-in-chrome__*` MCP tools instead. Load them with ToolSearch before calling.
- **`curl POST` returns 422.** Rails CSRF protection blocks raw `curl` POST requests. Use the browser tools to submit the form, not `curl`. GET requests (health check, page load) work fine with `curl`.
- **Results arrive 1 per second via SolidQueue + Turbo Streams.** Don't declare the page empty just because the `#results` div is blank immediately after clicking Start. Wait `N + 1` seconds, then screenshot.
- **Port varies by worktree.** The main worktree uses 3000; each `bin/worktree add` worktree gets a unique port ≥ 3001 stored in `.env.local`. Always read the port from `.env.local` rather than hardcoding 3000.
- **`bin/setup` starts the server by default.** Pass `--skip-server` to skip the server launch during setup.

## Troubleshooting

- **`bundle check` fails**: run `bundle install`
- **Port already in use**: another worktree is running. Either use that server or stop it with `bin/worktree stop <name>`
- **`/up` returns 500**: DB migration needed — run `bin/rails db:prepare`
- **Results never appear after clicking Start**: SolidQueue workers run in-process via Falcon's async adapter; no separate worker process needed. If results are missing, check `log/development.log` for job errors.
