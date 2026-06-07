---
name: run-fizzbuzz-app
description: Build, run, and drive the fizzbuzz-app Rails server. Use when asked to start the app, run its dev server, take a screenshot of its UI, interact with the running app, or verify a change works in the browser.
---

A Rails 8 app (Falcon server) that streams a FizzBuzz countdown via Turbo Streams. Drive it by starting the dev server, then using the `mcp__playwright__*` MCP tools for headless browser automation. The Playwright MCP server is pre-configured in `.mcp.json` — no extra setup needed.

All paths below are relative to the repo root (`fizzbuzz_app/`).

## Prerequisites

- Ruby (version in `.ruby-version`) — already present
- Bundler — already present
- Node.js — required to run `@playwright/mcp`; pre-installed on Claude Code Web, install locally via your own means

No additional `apt-get` installs needed.

## Setup

Gems are installed via `bin/setup`. Run once after cloning, or if `bundle check` fails:

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

### 3. Navigate and screenshot via Playwright MCP

Load the tools, then navigate and screenshot:

```
ToolSearch: select:mcp__playwright__browser_navigate,mcp__playwright__browser_take_screenshot,mcp__playwright__browser_snapshot

mcp__playwright__browser_navigate { url: "http://localhost:PORT/" }
mcp__playwright__browser_take_screenshot {}
```

### 4. Submit the form and observe streaming results

```
ToolSearch: select:mcp__playwright__browser_fill_form,mcp__playwright__browser_click,mcp__playwright__browser_wait_for

# Fill the starting integer field and submit:
mcp__playwright__browser_fill_form { fields: [{ selector: "input[name='starting_integer']", value: "5" }] }
mcp__playwright__browser_click { selector: "input[type='submit']" }

# Wait N+1 seconds for all Turbo Stream results (1 result per second):
mcp__playwright__browser_wait_for { time: 6000 }

# Read results and screenshot:
mcp__playwright__browser_snapshot {}
mcp__playwright__browser_take_screenshot {}
```

Expected output for starting integer 5: **Buzz, 4, Fizz, 3, 2, 1** (top to bottom) in the `#results` div.

### 5. Stop the server

```bash
# If started via bin/worktree server:
bin/worktree stop $(git branch --show-current)

# If started manually:
kill $(cat /tmp/fizzbuzz-dev.pid)
```

## Run (human path)

```bash
bin/dev   # → opens http://localhost:3000/ in a browser. Ctrl-C to stop.
```

## Test

```bash
bin/rails test
```

Expected: 10 runs, 23 assertions, 0 failures.

## Gotchas

- **`mcp__claude-in-chrome__*` tools are desktop-only** — do not use them. Use `mcp__playwright__*` instead; the server is configured in `.mcp.json` and works both locally and on Claude Code Web.
- **`curl POST` returns 422.** Rails CSRF protection blocks raw `curl` POST requests. Use the Playwright MCP tools to submit the form. GET requests (health check, page load) work fine with `curl`.
- **Results arrive 1 per second via SolidQueue + Turbo Streams.** Use `browser_wait_for { time: (N+1)*1000 }` — don't declare the `#results` div empty just because it's blank immediately after clicking Start.
- **Port varies by worktree.** The main worktree uses 3000; each `bin/worktree add` worktree gets a unique port ≥ 3001 stored in `.env.local`. Always read the port from `.env.local` rather than hardcoding 3000.
- **`bin/setup` starts the server by default.** Pass `--skip-server` to skip the server launch during setup.

## Troubleshooting

- **`bundle check` fails**: run `bundle install`
- **Port already in use**: another worktree is running. Either use that server or stop it with `bin/worktree stop <name>`
- **`/up` returns 500**: DB migration needed — run `bin/rails db:prepare`
- **Results never appear after clicking Start**: SolidQueue workers run in-process via Falcon's async adapter; no separate worker process needed. If results are missing, check `log/development.log` for job errors.
- **Playwright MCP not found**: confirm `npx @playwright/mcp@latest` is runnable (`node` in PATH) and `.mcp.json` is present at the repo root.
