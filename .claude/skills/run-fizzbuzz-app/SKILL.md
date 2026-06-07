---
name: run-fizzbuzz-app
description: Build, run, and drive the fizzbuzz-app Rails server. Use when asked to start the app, run its dev server, take a screenshot of its UI, interact with the running app, or verify a change works in the browser.
---

A Rails 8 app (Falcon server) that streams a FizzBuzz countdown via Turbo Streams. Drive it by starting the dev server, then using Playwright (via `playwright-ruby-client` gem + `npx playwright`) for headless browser automation.

All paths below are relative to the repo root (`fizzbuzz_app/`).

## Prerequisites

- Ruby (version in `.ruby-version`) — already present on this machine
- Bundler — already present
- Node.js — required for `npx playwright`; pre-installed on Claude Code Web, install locally via your own means

No additional `apt-get` installs needed.

## Setup

Gems are installed via `bin/setup`. Run this once after cloning, or if `bundle check` fails:

```bash
bin/setup --skip-server
```

On first use of browser automation, install the Playwright Chromium browser (skip if `PLAYWRIGHT_BROWSERS_PATH` is already set, as on Claude Code Web):

```bash
npx playwright install chromium
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

### 3. Navigate and screenshot via Playwright

Write a Ruby script to `/tmp/fizzbuzz_browse.rb` and run it with `bundle exec ruby`.

**Navigate and take a screenshot:**

```ruby
# /tmp/fizzbuzz_browse.rb
require 'playwright'

port = ENV.fetch('PORT', 3000)

Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
  browser = playwright.chromium.launch(headless: true)
  page = browser.new_page
  page.goto("http://localhost:#{port}/")
  page.screenshot(path: '/tmp/fizzbuzz-start.png')
  browser.close
end
```

```bash
PORT=$PORT bundle exec ruby /tmp/fizzbuzz_browse.rb
```

Then read the screenshot:

```
Read /tmp/fizzbuzz-start.png
```

### 4. Submit the form and observe streaming results

```ruby
# /tmp/fizzbuzz_results.rb
require 'playwright'

port = ENV.fetch('PORT', 3000)
n    = ENV.fetch('STARTING_INT', '5').to_i

Playwright.create(playwright_cli_executable_path: 'npx playwright') do |playwright|
  browser = playwright.chromium.launch(headless: true)
  page = browser.new_page
  page.goto("http://localhost:#{port}/")
  page.fill('input[name="starting_integer"]', n.to_s)
  page.click('input[type="submit"]')
  page.wait_for_timeout((n + 1) * 1000)  # N+1 seconds for all Turbo Stream results
  puts page.text_content('#results')
  page.screenshot(path: '/tmp/fizzbuzz-results.png')
  browser.close
end
```

```bash
PORT=$PORT STARTING_INT=5 bundle exec ruby /tmp/fizzbuzz_results.rb
```

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
bin/dev   # → opens http://localhost:3000/ in a browser. Ctrl-C to stop.
```

## Test

```bash
bin/rails test
```

Expected: 10 runs, 23 assertions, 0 failures.

## Gotchas

- **`mcp__claude-in-chrome__*` tools are desktop-only.** Use the Playwright Ruby path above instead. It works both locally and on Claude Code Web.
- **`curl POST` returns 422.** Rails CSRF protection blocks raw `curl` POST requests. Use the Playwright script to submit the form, not `curl`. GET requests (health check, page load) work fine with `curl`.
- **Results arrive 1 per second via SolidQueue + Turbo Streams.** Use `page.wait_for_timeout((n + 1) * 1000)` — don't declare the `#results` div empty just because it's blank immediately after clicking Start.
- **Port varies by worktree.** The main worktree uses 3000; each `bin/worktree add` worktree gets a unique port ≥ 3001 stored in `.env.local`. Always read the port from `.env.local` rather than hardcoding 3000.
- **`bin/setup` starts the server by default.** Pass `--skip-server` to skip the server launch during setup.
- **Playwright browsers not found locally.** If you see `Executable doesn't exist`, run `npx playwright install chromium`. On Claude Code Web the browsers are pre-installed at `$PLAYWRIGHT_BROWSERS_PATH`.

## Troubleshooting

- **`bundle check` fails**: run `bundle install`
- **Port already in use**: another worktree is running. Either use that server or stop it with `bin/worktree stop <name>`
- **`/up` returns 500**: DB migration needed — run `bin/rails db:prepare`
- **Results never appear after clicking Start**: SolidQueue workers run in-process via Falcon's async adapter; no separate worker process needed. If results are missing, check `log/development.log` for job errors.
