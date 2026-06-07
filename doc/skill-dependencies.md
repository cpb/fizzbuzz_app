# Skill Dependencies

Maps each skill to its required tools, auth env vars, and cloud vs. desktop readiness.

Run `bin/check-tools` with no arguments to print this table live with current-version tool names.

## Dependency map

| Skill | Required tools | Auth env var | Cloud-ready? |
|---|---|---|---|
| `start-pr` | `claude`, `gh`, `tmux`, `jq` | `GITHUB_TOKEN` | No — desktop only |
| `continue-pr` | `claude`, `gh`, `tmux`, `jq` | `GITHUB_TOKEN` | No — desktop only |
| `qa-pr-skill` | `claude`, `gh`, `tmux`, `jq` | `GITHUB_TOKEN` | No — desktop only |
| `finish-pr` | `gh`, `tmux`, `jq` | `GITHUB_TOKEN` | Yes |
| `qa-pr` | `gh`, `jq` | `GITHUB_TOKEN` | Yes |
| `qa-pr-app` | `gh`, `jq`, `node` | `GITHUB_TOKEN` | Yes |
| `run-fizzbuzz-app` | `node` | none | Yes |
| `new-issue` | `gh`, `jq` | — | Yes |

## Tool notes

**`claude`** — The Claude Code CLI binary. Skills that spawn `claude` in a tmux window (`start-pr`, `continue-pr`, `qa-pr-skill`) are desktop-only until multi-Claude cloud support is available. These skills check for the binary at entry and abort with a clear error if it is absent.

**`node`** — Node.js, used to run `npx playwright` for headless browser automation in `run-fizzbuzz-app` and `qa-pr-app`. On Claude Code Web, Playwright browsers are pre-installed at `$PLAYWRIGHT_BROWSERS_PATH` (`/opt/pw-browsers`). Locally, install Node via your own means (homebrew, nvm, etc.) and run `npx playwright install chromium` once.

**`gh`** — GitHub CLI. Requires a `GITHUB_TOKEN` environment variable (or `gh auth login` for interactive sessions). See `.env.example` for where to set it in a worktree.

**`chromedriver`** — Used by the Rails test suite (`capybara` + `selenium-webdriver`) for system tests. Declared in the `Brewfile`; installed automatically on macOS via `bin/setup`. Not required by skill browser automation (skills use Playwright).

**`tmux`**, **`jq`** — Required by workflow skills that orchestrate sessions and parse JSON. Declared in the `Brewfile`.

## Auth

Set `GITHUB_TOKEN` in `.env.local` (gitignored) for any skill that calls `gh`:

```
GITHUB_TOKEN=ghp_...
```

The `.env.example` file documents this variable alongside other worktree overrides.

## Desktop-only skills

`start-pr`, `continue-pr`, and `qa-pr-skill` spawn a `claude` CLI subprocess inside a new tmux window. This pattern requires:

1. The `claude` binary in `PATH`
2. An authenticated Claude account (the CLI reads credentials from `~/.claude/`)
3. A running tmux session (`$TMUX` must be set)

None of these are available in headless cloud environments. Each of these skills checks for the `claude` binary at entry and exits immediately with:

```
ERROR: desktop-only — requires 'claude' CLI in PATH.
This skill spawns a Claude session in a tmux window and is not supported in cloud environments.
```

Making these skills cloud-compatible (e.g. via the Anthropic API instead of CLI subprocess) is out of scope for this iteration.
