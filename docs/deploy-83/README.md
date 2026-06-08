# Deploy Docs — Issue #83: 130-User Soft Launch

This folder contains the research and planning documents for deploying fizzbuzz_app to a publicly accessible URL and running a 130-user concurrent soft launch of the CBT workbook wizard.

**These are planning documents only.** No code has been changed. Each plan document describes what a follow-on PR should do, and why.

---

## Problem this work addresses

Issue #83 needs to:
1. Get the app off the laptop and onto a public URL
2. Handle 130 simultaneous wizard sessions without errors or queue overflow
3. Export captured `WorkbookSession` rows as labeled eval fixtures

Before any of that is possible, someone needs to answer eight infrastructure questions and document the decisions. That is what this folder does.

---

## The eight questions answered here

| # | Question | Where answered |
|---|---|---|
| 1 | What is the lowest-effort path to a public URL? | [plans/01-cloud-deploy.md](plans/01-cloud-deploy.md) |
| 2 | How do we wire continuous deployment? | [plans/02-ci-cd.md](plans/02-ci-cd.md) |
| 3 | Is SQLite3 viable at 130 concurrent sessions? | [plans/03-database-strategy.md](plans/03-database-strategy.md) |
| 4 | How does multi-worker Falcon interact with ActionCable? | [plans/04-concurrency-and-cable.md](plans/04-concurrency-and-cable.md) |
| 5 | Should we adopt Solid Cable now? | [plans/04-concurrency-and-cable.md](plans/04-concurrency-and-cable.md) |
| 6 | When does Redis / AnyCable become necessary? | [plans/04-concurrency-and-cable.md](plans/04-concurrency-and-cable.md) |
| 7 | What specific SQLite tuning gives us the most headroom? | [plans/05-sqlite-falcon-optimization.md](plans/05-sqlite-falcon-optimization.md) |
| 8 | Which hosting provider fits Kamal + SQLite best? | [research/hosting-providers.md](research/hosting-providers.md) |

---

## Document map

```
docs/deploy-83/
  README.md                         ← you are here
  research/
    system-as-built.md              ← what is running today (Falcon, SQLite ×4, Solid Cable, Kamal)
    architecture-evolution.md       ← option space: SQLite vs PG, Falcon workers, cable adapters
    hosting-providers.md            ← Fly.io, Render, Railway, Hatchbox, DigitalOcean, Hetzner
  plans/
    01-cloud-deploy.md              ← decision + step-by-step Kamal deploy to Hetzner
    02-ci-cd.md                     ← GitHub Actions CI + deploy workflow YAML
    03-database-strategy.md         ← stay on SQLite3, verify WAL, add Litestream backup
    04-concurrency-and-cable.md     ← keep --count 1, keep Solid Cable, fix sleep anti-pattern
    05-sqlite-falcon-optimization.md← PRAGMA tuning, connection pool sizing, Litestream sidecar
```

---

## Recommended reading order

**If you are deploying the app for the first time:**

1. [research/system-as-built.md](research/system-as-built.md) — understand what you are deploying
2. [plans/01-cloud-deploy.md](plans/01-cloud-deploy.md) — follow the step-by-step deploy checklist
3. [plans/02-ci-cd.md](plans/02-ci-cd.md) — wire GitHub Actions after the first manual deploy

**If you are evaluating whether SQLite3 will hold up:**

1. [research/architecture-evolution.md](research/architecture-evolution.md) — the full option space with sourced benchmarks
2. [plans/03-database-strategy.md](plans/03-database-strategy.md) — the decision and migration triggers

**If you are concerned about Falcon concurrency or WebSocket performance:**

1. [plans/04-concurrency-and-cable.md](plans/04-concurrency-and-cable.md) — the `sleep 1` fix is blocking; read this first
2. [plans/05-sqlite-falcon-optimization.md](plans/05-sqlite-falcon-optimization.md) — PRAGMA tuning and connection pool sizing

**If you are comparing hosting providers:**

1. [research/hosting-providers.md](research/hosting-providers.md) — cost/tradeoff matrix
2. [plans/01-cloud-deploy.md](plans/01-cloud-deploy.md) — the decision (Hetzner CX32) and open questions

---

## Key decisions (summary)

| Decision | Recommendation | Rationale |
|---|---|---|
| Hosting | **Hetzner CX32** (~€6.80/mo) | Cheapest native Kamal target with local NVMe — optimal for SQLite WAL |
| Registry | **ghcr.io** (GitHub Container Registry) | Free, no self-hosted registry; `GITHUB_TOKEN` built-in for Actions |
| Database | **Stay on SQLite3** | 130 writes/s is well within WAL ceiling; 4 separate DB files reduce contention |
| Web server | **Falcon `--count 1`** | Correct for single-process Solid Cable; fiber concurrency handles 130 sessions |
| ActionCable | **Keep Solid Cable** | Fan-out math (1,300 polls/s) is within SQLite's envelope; Redis is unnecessary at this scale |
| Backup | **Litestream** (required before launch) | SQLite has no built-in replication; Litestream to Hetzner Object Storage |
| Job sleep fix | **Replace `sleep 1` with `set(wait: 1.second).perform_later`** | Blocking — ships before soft launch |

---

## Open questions (decisions not made here)

These require a human decision before the first deploy:

1. **Domain name** — what hostname goes in `config/deploy.yml` `proxy.host`?
2. **GitHub org/user** — which account owns the `ghcr.io` image namespace?
3. **Hetzner region** — EU (Nuremberg, Helsinki) or US (Ashburn)? Pick closest to users.
4. **Litestream storage target** — Hetzner Object Storage, Backblaze B2, or AWS S3?
5. **Redis timing** — add Redis before or after the soft launch? (Not required for 130 users, but eliminates the cable polling load)
6. **Solid Queue thread count** — 10 threads (plan's recommendation) vs 20 (maximum headroom)?

---

## What comes next (follow-on PRs)

These planning docs drive the following implementation PRs (all blocked on this one):

| PR | What it implements |
|---|---|
| Cloud deploy | Fill in `config/deploy.yml`, run `kamal setup`, verify health check |
| CI/CD | Add `.github/workflows/deploy.yml`, fix `ci.yml` branch ref |
| Litestream | Add `config/litestream.yml` and Kamal accessory |
| SQLite optimizations | Add `config/initializers/sqlite_optimizations.rb`, set `RAILS_MAX_THREADS=25` in deploy config |
| Fix `sleep 1` anti-pattern | Replace in-job sleep with `set(wait:).perform_later` in `FizzBuzzJob` and `LLMFizzBuzzJob` |
| Workbook wizard (issue #79) | `WorkbookSession` model, wizard controller/views — prerequisite for the actual soft launch |

---

*Research authored: 2026-06-08. Plans are point-in-time; verify provider pricing and gem versions before implementing.*
