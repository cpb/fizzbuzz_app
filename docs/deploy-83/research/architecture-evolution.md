# Architecture Evolution — Option Space for 130-User Soft Launch

**App:** fizzbuzz_app — Rails 8.1.3 / Ruby 3.3.6  
**Goal:** Sustain 130 simultaneous concurrent wizard sessions without errors, timeouts, or job queue overflow.  
**Current stack snapshot:** Falcon (web server), SQLite3 × 4 files, async_job (in-process), Solid Cable (SQLite polling, 100 ms), Kamal/Docker (placeholder config).

---

## 1. SQLite3 at 130 Concurrent Sessions

### WAL mode write-lock ceiling

SQLite in WAL mode supports an **unlimited number of concurrent readers and exactly one writer at a time** — writes are fully serialized. This is not a tunable ceiling; it is the fundamental architecture. What WAL does change compared to the default journal mode is that readers no longer block the writer and the writer no longer blocks readers ([SQLite WAL docs](https://sqlite.org/wal.html)).

In the stock Rails 8 configuration this app already sets `timeout: 5000` in `database.yml`, which maps to the `busy_timeout` pragma. Without a busy timeout, concurrent write attempts fail immediately with `SQLITE_BUSY`; with 5000 ms the connection queue retries for up to 5 seconds before raising. Benchmarks from [Ten Thousand Meters](https://tenthousandmeters.com/blog/sqlite-concurrent-writes-and-database-is-locked-errors/) show that at moderate concurrency, ≥5 s timeout eliminates lock errors that appeared reliably at shorter values. The required pairing is: WAL mode + `synchronous=NORMAL` + `busy_timeout ≥ 5000`. ([Fractaled Mind — improving concurrency](https://fractaledmind.com/2023/12/11/sqlite-on-rails-improving-concurrency/))

### Practical concurrency limit

Stephen Margheim (fractaledmind) published a [synthetic benchmark](https://fractaledmind.com/2023/12/05/sqlite-myths-linear-writes-do-not-scale/) showing Rails + SQLite sustaining ~2,500 write requests/second under simplified conditions (single-index table, one SQL write per request). A [real-world benchmark](https://shivekkhurana.com/blog/sqlite-in-production/) on a 16-core M3 Max reported no issues up to 128 concurrent Puma workers.

[Litestack benchmarks](https://www.slideshare.net/slideshow/litestack-talk-at-brighton-2024-unleashing-the-power-of-sqlite-for-ruby-apps/270168513) with 8 concurrent processes recorded 798 K point reads/s and 167 K point updates/s on a mid-range laptop. [SQLite's own guidance](https://sqlite.org/whentouse.html) recommends staying on SQLite when the site receives fewer than ~100 K hits/day or runs on a single server with low write concurrency.

### Write contention threshold for fizzbuzz_app

The app's write pattern is: one DB write per Turbo Stream broadcast per countdown step. With 130 sessions, each counting down from (say) 10, at 1-second intervals, the peak write rate is ~130 writes/second to the primary database, with equal or higher rates to the cable database (one row per broadcast). A [2024 deep-dive by Mohammed Al-Bayati](https://oldmoe.blog/2024/07/08/the-write-stuff-concurrent-write-transactions-in-sqlite/) confirms that short, well-batched transactions are the key variable — long-running transactions starve the write queue.

Write contention becomes observable when: (a) individual transactions are long relative to write frequency, or (b) the WAL file grows unchecked and checkpointing stalls reads. With 130 sessions at ~1 write/s each, this is within SQLite's documented envelope *provided* transactions remain short and `busy_timeout` is set. The risk is the cable database, which will absorb 130 × (write + polling reads) simultaneously.

### Triggers that indicate PostgreSQL migration

- Sustained `SQLITE_BUSY` errors in production logs despite a 5 s timeout.
- p99 write latency exceeds 500 ms under normal load.
- Multiple Kamal web containers needed (SQLite requires a shared filesystem mount for multi-host — not impossible but operationally fragile).
- App needs `FOR UPDATE SKIP LOCKED` for efficient job dispatch (Solid Queue with SQLite falls back to plain locking per [Solid Queue docs](https://github.com/rails/solid_queue)).
- Team installs a separate read replica or needs streaming replication (Litestream covers backup but not read scaling).

### What a Rails multi-DB migration to PostgreSQL looks like

The Rails 8 multi-database config (`primary`, `cache`, `queue`, `cable` in `database.yml`) maps cleanly to PostgreSQL databases or schemas. Migration path:

1. Add the `pg` gem; remove or keep `sqlite3` for dev.
2. Update `database.yml` production block to use `adapter: postgresql` for each named database.
3. Each Solid component (Cache, Queue, Cable) ships its own `db/*_migrate` folder. Running `db:migrate` across all databases re-creates the schemas.
4. Solid Cable on PostgreSQL can be pointed at the primary database or a dedicated one — [Rails Designer guide](https://railsdesigner.com/action-cable-with-postgres/) covers both configurations.
5. Schema dump will switch from `db/schema.rb` (SQLite) to `db/schema.rb` in SQL format (`structure.sql`) if using PostgreSQL-specific features.
6. For Solid Queue the migration unlocks `FOR UPDATE SKIP LOCKED`, removing the SQLite fallback lock-wait path and supporting multiple concurrent workers without contention. ([Solid Queue README](https://github.com/rails/solid_queue))

---

## 2. Falcon: Single-Worker vs Multi-Worker

### Concurrency model

Falcon uses Ruby's Fiber Scheduler and the `async` gem. Within a single worker process, incoming connections are each assigned a fiber. Fibers cooperatively yield control at I/O boundaries (database queries, HTTP calls, `sleep`), letting other fibers run. This is fundamentally different from Puma's preemptive thread model: threads can be suspended by the Ruby VM at any instruction; fibers only yield when the code explicitly calls an async I/O primitive.

Consequence: a CPU-bound fiber (heavy serialization, ERB rendering, synchronous `sleep 1`) **blocks the entire event loop** for its duration. Standard Rails `sleep 1` in `LLMFizzBuzzJob` and `FizzBuzzJob` is a blocking call unless the fiber scheduler intercepts it. ([Scout APM — Birds of a Fiber](https://www.scoutapm.com/blog/birds-of-a-fiber))

For I/O-heavy workloads (many concurrent connections all waiting on external HTTP), Falcon has been benchmarked at 200%+ throughput over Puma because fibers have negligible context-switch cost. For CPU-heavy or synchronous-sleep-heavy workloads the advantage disappears. ([JetThoughts — Falcon in Production](https://jetthoughts.com/blog/falcon-web-server-async-ruby-in-production/))

### `--count 1` vs `--count N`

`--count` sets the number of **worker processes** (not fibers). Each process runs its own independent event loop with its own fiber pool.

- `--count 1`: single process, single event loop. All 130 concurrent sessions share one event loop. A blocking fiber starves all others.
- `--count N`: N independent processes, each handling a subset of connections. Increases CPU utilization across cores but does not share in-memory state.

The Gemfile shows `gem "falcon"` and `gem "puma"` coexist — Puma is still present. The `SOLID_QUEUE_IN_PUMA: true` env var in `deploy.yml` suggests the production intent is Puma-based. Clarifying which server `bin/dev` actually starts matters before scaling decisions.

### Multi-worker Falcon and ActionCable

The [Falcon README](https://www.rubydoc.info/gems/falcon/0.36.4) explicitly states:

> "If you use the async adapter, you should run Falcon in threaded mode, or in forked mode with `--count 1`. Otherwise, your messaging system will be distributed over several processes with no IPC mechanism."

In production this app uses Solid Cable (not the async adapter), so cross-process isolation is handled by the database rather than in-memory pub/sub. However, WebSocket connections in a multi-process setup are sticky to one process — a broadcast enqueued in process A may not reach a client connected to process B unless all processes poll the same database. With Solid Cable on a shared SQLite file this works because all processes read the same `production_cable.sqlite3`. With a shared-filesystem mount constraint under Docker/Kamal this is the same single-file requirement noted in the SQLite section.

### Production recommendation

The [Ruby Events talk on Falcon](https://www.rubyevents.org/talks/keynote-building-and-deploying-interactive-rails-applications-with-falcon) suggests using multiple workers (`--count` matching CPU core count) with a Redis-backed or DB-backed ActionCable adapter. For apps using synchronous ActiveRecord (standard Rails), running with `--count 1` plus async-io awareness or falling back to Puma with multiple threads is the more conservative choice. ([DeployHQ 2025 guide](https://www.deployhq.com/blog/ruby-application-servers-in-2025-a-complete-performance-and-architecture-guide))

---

## 3. ActionCable Adapter Landscape

### async (current dev/test adapter)

In-memory, same-process pub/sub. Messages are delivered synchronously to subscribers within the same process with zero latency. Has no persistence and no cross-process visibility — if a job runs in a separate process (or the worker restarts) messages are lost. Cable.yml already marks this dev/test only; it cannot be used in any multi-process production topology.

### Solid Cable (current production adapter)

Solid Cable stores broadcasts as rows in the `messages` table in `production_cable.sqlite3`. Each connected client's ActionCable server polls that table every 100 ms (`polling_interval: 0.1.seconds` in `cable.yml`). Messages are retained for 1 day.

**Latency profile:** worst-case delivery = polling_interval = 100 ms. Average ≈ 50 ms. This is acceptable for the fizzbuzz countdown (1-second step intervals) but is not suitable for sub-10 ms real-time (collaborative cursors, financial tickers). ([Saeloun — Solid Cable guide](https://blog.saeloun.com/2026/05/26/rails-8-solid-cable-database-backed-websockets/))

**Fan-out math at 130 sessions:** Each poll is a `SELECT` with a `WHERE created_at > last_seen_at` filter. At 130 connections polling every 100 ms, the cable database receives ~1,300 SELECT queries/second. Each broadcast (one per countdown step) inserts one row; with 130 sessions at ~1 step/s that is ~130 INSERT/s. WAL mode allows these reads and writes to be concurrent, but 1,300 read queries/second on a single SQLite file on a single Docker container is measurable I/O. [Solid Cable's README](https://github.com/rails/solid_cable) notes it is tested against SQLite, MySQL, and PostgreSQL — for hundreds (not thousands) of concurrent connections it is documented as sufficient.

**Single-process constraint:** On a single Kamal container with one SQLite mount, Solid Cable works as designed. Scaling to multiple web containers would require either switching to PostgreSQL for the cable database or adding Redis.

### Redis adapter

The canonical ActionCable production adapter before Rails 8. Uses Redis pub/sub: a broadcast publishes to a Redis channel, each ActionCable server process subscribes and delivers to local WebSocket connections. Latency is typically sub-1 ms (in-memory pub/sub). Requires a Redis (or Valkey) sidecar — the commented-out `redis` accessory block in `deploy.yml` shows it is anticipated but not yet provisioned. Horizontal scaling is straightforward — all web containers subscribe to the same Redis instance.

### AnyCable

AnyCable replaces the Ruby WebSocket server component with a Go binary that manages WebSocket connections. The Rails app handles channel logic via gRPC calls from the Go server. This separation lets the Go server hold 10,000+ persistent WebSocket connections with minimal memory, while the Rails app handles only RPC calls (not long-lived sockets). Memory usage is reported at ~60% less than standard ActionCable. ([AppSignal — AnyCable for Rails](https://blog.appsignal.com/2024/05/01/anycable-for-ruby-on-rails-how-does-it-improve-over-action-cable.html))

**When it becomes the right call:** The [AnyCable project](https://github.com/anycable/anycable) suggests considering it at >500–1,000 sustained connections or 5,000–10,000 peak. At 130 sessions AnyCable is over-engineering; the threshold is around 1,000 sustained concurrent WebSocket connections. It still requires Redis for pub/sub.

---

## 4. Solid Queue vs Sidekiq

### Solid Queue with SQLite

Solid Queue is the Rails 8 default, running in-process via `SOLID_QUEUE_IN_PUMA: true` (current `deploy.yml`). It uses the queue database (`production_queue.sqlite3`) with a supervisor/dispatcher/worker model.

**SQLite limitation:** Solid Queue relies on `FOR UPDATE SKIP LOCKED` for efficient concurrent worker dispatch. SQLite does not support this clause — the adapter falls back to plain locking, meaning worker processes must queue up for the lock. The [Solid Queue README](https://github.com/rails/solid_queue) notes SQLite is supported but "realistic production use means Postgres or MySQL" for multi-worker configurations.

**Throughput benchmark:** Solid Queue tops out around ~5,000 jobs/minute; Sidekiq reaches 10,000+ jobs/minute. Job pickup latency: Solid Queue 100 ms–1.2 s vs Sidekiq ~8 ms. ([JetThoughts comparison](https://jetthoughts.com/blog/solid-queue-vs-sidekiq-complete-comparison/), [Nikita Sinenko benchmark](https://nsinenko.com/rails/background-jobs/architecture/2026/02/17/solid-queue-vs-sidekiq-vs-goodjob-rails/))

### fizzbuzz_app job pattern

`FizzBuzzJob` and `LLMFizzBuzzJob` each enqueue themselves recursively, once per second, counting down from the starting integer. With 130 sessions at starting_integer = 10, peak enqueue rate = ~130 jobs/second = 7,800 jobs/minute. This approaches Solid Queue's documented ceiling and **exceeds** it if all sessions start simultaneously.

Additional concern: `sleep 1` inside the job body is a blocking sleep. On Solid Queue with a single in-Puma worker thread pool, a queue of 130 sleeping jobs stalls other work. The `sleep` should be replaced with `set(wait: 1.second).perform_later(...)` (already partially present in the controller but not consistently in the job bodies themselves).

### Sidekiq

Redis-backed, separate process. Typical throughput 10,000+ jobs/minute with ~8 ms latency. Sidekiq Pro adds batching and rate-limiting. Operationally requires a Redis sidecar (same as Redis ActionCable adapter — the two can share one Redis instance). The complexity is justified when: job pickup latency matters, job volume exceeds ~5,000/minute, or jobs need retries with fine-grained backoff controls. ([Medium — 5 reasons Sidekiq beats Solid Queue](https://medium.com/@traveling-coder-abhishek/5-reasons-why-sidekiq-still-beats-solid-queue-for-high-concurrency-jobs-d645b533fa0c))

---

## 5. Rails 8 "No-PaaS" Stack — Solid Everything

### Philosophy

Rails 8 ships Solid Queue, Solid Cache, and Solid Cable as defaults to eliminate the Redis dependency for applications that fit a single-server model. The design thesis (DHH, 2024): most web apps are CPU- and I/O-constrained before they are database-constrained, and SQLite on NVMe is fast enough for the long tail of production apps. This removes an entire class of infrastructure (Redis, job server sidecar, external cache cluster) at the cost of all writes being serialized through a local file. ([Reinteractive — Solid Trifecta](https://reinteractive.com/articles/tutorial-series-for-experienced-rails-developers/rails-8-solid-trifecta-comparison-cache-cable-queue), [SharpSkill deep dive](https://sharpskill.dev/en/blog/ruby-on-rails/solid-queue-solid-cache-rails-8-guide))

The 4-SQLite-file architecture (primary, cache, queue, cable) provides **I/O isolation** — cache storms do not block job dispatch, and cable polling does not interfere with application writes. ([Oliver Eidel analysis](https://eidel.io/posts/4-sqlite-databases-is-rails-8-taking-sqlite-too-far))

### Where it works well

- Single-server deployments (one Kamal host, one Docker container, shared `/rails/storage` volume).
- Read-heavy workloads with write bursts, where the serialized write queue rarely exceeds a few hundred ms.
- Teams that want zero external dependencies — the entire stack runs from one `docker run`.
- Applications with modest real-time requirements (notifications, dashboard refreshes) where 100 ms cable latency is acceptable.

### Where it hits limits

| Signal | Implication |
|---|---|
| Need >1 web container | SQLite requires a shared filesystem; not possible with multiple Docker hosts without NFS/EFS mount |
| Solid Queue job rate >5,000/min | Throughput ceiling; SQLite lacks `SKIP LOCKED` |
| >1,000 concurrent WebSocket connections | Solid Cable polling load becomes significant database I/O |
| Write-heavy workloads with transactions >5 ms | SQLITE_BUSY errors accumulate despite timeout |
| Need real-time pub/sub <10 ms | Redis or AnyCable required |

The [Rails 8 in Production analysis](https://rubylearning.com/blog/2026/03/16/rails-8-solid-stack-vs-redis-sidekiq-production/) summarizes it as: Solid on SQLite is "good enough for 95% of applications" at low-to-medium scale on a single server, with PostgreSQL + Redis as the natural next step when horizontal scaling or higher throughput is needed.

---

## Source Index

- [SQLite WAL docs — sqlite.org](https://sqlite.org/wal.html)
- [SQLite Appropriate Uses — sqlite.org](https://sqlite.org/whentouse.html)
- [The Write Stuff: Concurrent Write Transactions in SQLite — Oldmoe's blog](https://oldmoe.blog/2024/07/08/the-write-stuff-concurrent-write-transactions-in-sqlite/)
- [SQLite concurrent writes and "database is locked" errors — Ten Thousand Meters](https://tenthousandmeters.com/blog/sqlite-concurrent-writes-and-database-is-locked-errors/)
- [Linear writes don't scale (myth) — Fractaled Mind](https://fractaledmind.com/2023/12/05/sqlite-myths-linear-writes-do-not-scale/)
- [Improving concurrency — Fractaled Mind](https://fractaledmind.com/2023/12/11/sqlite-on-rails-improving-concurrency/)
- [The how and why of optimal performance — Fractaled Mind](https://fractaledmind.com/2024/04/15/sqlite-on-rails-the-how-and-why-of-optimal-performance/)
- [SQLite in Production — Real-World Benchmark](https://shivekkhurana.com/blog/sqlite-in-production/)
- [Litestack talk Brighton 2024 — SlideShare](https://www.slideshare.net/slideshow/litestack-talk-at-brighton-2024-unleashing-the-power-of-sqlite-for-ruby-apps/270168513)
- [4 SQLite Databases: Is Rails 8 Taking SQLite Too Far? — Oliver Eidel](https://eidel.io/posts/4-sqlite-databases-is-rails-8-taking-sqlite-too-far)
- [Falcon web server — Birds of a Fiber — Scout APM](https://www.scoutapm.com/blog/birds-of-a-fiber)
- [Falcon in Production — JetThoughts](https://jetthoughts.com/blog/falcon-web-server-async-ruby-in-production/)
- [What Puma, Falcon, and Pitchfork teach about Ruby concurrency — Codeminer42](https://blog.codeminer42.com/what-puma-falcon-and-pitchfork-teach-you-about-ruby-concurrency/)
- [Ruby Application Servers 2025 — DeployHQ](https://www.deployhq.com/blog/ruby-application-servers-in-2025-a-complete-performance-and-architecture-guide)
- [Falcon README — async adapter + --count caveat](https://www.rubydoc.info/gems/falcon/0.36.4)
- [Keynote: Building and Deploying Interactive Rails Applications with Falcon](https://www.rubyevents.org/talks/keynote-building-and-deploying-interactive-rails-applications-with-falcon)
- [Solid Cable GitHub README](https://github.com/rails/solid_cable)
- [Rails 8 Solid Cable: Database-Backed WebSockets — Saeloun](https://blog.saeloun.com/2026/05/26/rails-8-solid-cable-database-backed-websockets/)
- [Ditching Redis: Solid Cable in Rails 8 — DEV Community](https://dev.to/zilton7/ditching-redis-how-to-handle-websockets-in-rails-8-with-solid-cable-1jdb)
- [Solid Cable in Production with Kamal — Miles Woodroffe](https://mileswoodroffe.com/articles/solid-cable-in-production)
- [AnyCable for Ruby on Rails — AppSignal](https://blog.appsignal.com/2024/05/01/anycable-for-ruby-on-rails-how-does-it-improve-over-action-cable.html)
- [AnyCable vs Action Cable: A Benchmark War — DEV Community](https://dev.to/alex_aslam/anycable-vs-action-cable-a-benchmark-war-4c3f)
- [Solid Queue GitHub README](https://github.com/rails/solid_queue)
- [Solid Queue vs Sidekiq — JetThoughts](https://jetthoughts.com/blog/solid-queue-vs-sidekiq-complete-comparison/)
- [Solid Queue vs Sidekiq vs GoodJob — Nikita Sinenko](https://nsinenko.com/rails/background-jobs/architecture/2026/02/17/solid-queue-vs-sidekiq-vs-goodjob-rails/)
- [5 Reasons Sidekiq Beats Solid Queue — Medium](https://medium.com/@traveling-coder-abhishek/5-reasons-why-sidekiq-still-beats-solid-queue-for-high-concurrency-jobs-d645b533fa0c)
- [Rails 8 in Production: Is the Solid Stack Enough? — RubyLearning](https://rubylearning.com/blog/2026/03/16/rails-8-solid-stack-vs-redis-sidekiq-production/)
- [Rails 8 Solid Trifecta — Reinteractive](https://reinteractive.com/articles/tutorial-series-for-experienced-rails-developers/rails-8-solid-trifecta-comparison-cache-cable-queue)
- [Solid Queue & Solid Cache Deep Dive 2026 — SharpSkill](https://sharpskill.dev/en/blog/ruby-on-rails/solid-queue-solid-cache-rails-8-guide)
- [Use Action Cable with PostgreSQL — Rails Designer](https://railsdesigner.com/action-cable-with-postgres/)
