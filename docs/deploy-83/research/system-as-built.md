# fizzbuzz_app — System As Built

> Reference document for the production stack as of June 2026. Describes what is running, not what should be changed.

---

## 1. Runtime

| Item | Value |
|---|---|
| Ruby | `~> 3.3` (pinned to 3.3.6 in `.ruby-version`) |
| Rails | `~> 8.1.3` |
| Load defaults | `8.1` |
| Web server | [Falcon](https://github.com/socketry/falcon) |
| Worker count | 1 (`--count 1`) |
| Entrypoint (container) | `./bin/thrust ./bin/rails server` |
| Entrypoint (dev) | `bundle exec falcon serve --bind http://0.0.0.0:$PORT --count 1` |

`bin/dev` sets `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` (required on macOS when Falcon forks) and exec-replaces itself with the Falcon process. The container entrypoint (`bin/docker-entrypoint`) runs `db:prepare` before starting when the command is `rails server`.

The container uses a two-stage Dockerfile. The build stage compiles gems and runs `assets:precompile`. The final stage runs as a non-root `rails:rails` user (uid/gid 1000). [jemalloc](https://github.com/jemalloc/jemalloc) is preloaded via `LD_PRELOAD` for reduced memory fragmentation and allocation latency.

---

## 2. Concurrency model — Falcon

[Falcon](https://socketry.github.io/falcon/guides/rails-integration/index.html) is a multi-process, multi-fiber Rack-compatible HTTP server built on the [`async`](https://github.com/socketry/async) gem. Key properties:

- **Fibers, not threads**: Each incoming request runs inside a lightweight Ruby fiber. When a fiber blocks on I/O (database query, HTTP call, file read), it yields control cooperatively and another fiber runs. No OS thread context switches; no thread-safety constraints on request handling code.
- **`--count 1`**: Runs a single worker process. This is intentional: the app uses `adapter: async` for ActionCable in development, which is in-process and cannot be shared across OS processes. Running multiple forked workers would split the in-process message bus across processes with no IPC bridge. Production ActionCable uses Solid Cable (SQLite-backed), which is safe for multiple workers, but the current config keeps a single worker.
- **Concurrency ceiling**: Within the single worker, Falcon can handle thousands of concurrent connections via fibers. The bottleneck for this app is SQLite (single-writer), not Falcon's I/O scheduler.
- **HTTP/1 and HTTP/2**: Falcon supports both natively. In the container deployment, HTTP/2 termination is handled by Thruster (see section 7).

For I/O-bound workloads Falcon can [outperform Puma by 3-4x](https://www.scoutapm.com/blog/birds-of-a-fiber) at 500+ concurrent connections doing external API calls.

---

## 3. Database — SQLite3 multi-DB

All databases are SQLite3 files stored under `storage/`. In the Docker container they are mounted from a named volume (`fizzbuzz_app_storage:/rails/storage`) so they persist across deploys.

| Role | File | Purpose |
|---|---|---|
| `primary` | `storage/production.sqlite3` | Application data (main AR models) |
| `cache` | `storage/production_cache.sqlite3` | Solid Cache entries |
| `queue` | `storage/production_queue.sqlite3` | Solid Queue job records |
| `cable` | `storage/production_cable.sqlite3` | Solid Cable message rows |

All four share the same base config (`adapter: sqlite3`, `timeout: 5000`). Max connections per database is `RAILS_MAX_THREADS` (default 5). Each database has its own `migrations_paths` so schema migrations are isolated.

The four-database split keeps Solid Cache, Solid Queue, and Solid Cable writes from contending with application writes. SQLite's per-file writer lock means a slow cache sweep cannot block a user-facing query.

---

## 4. Background jobs

**Development / test**: `config.active_job.queue_adapter = :async_job` (set in `config/application.rb`). Uses [`async-job-adapter-active_job`](https://github.com/socketry/async-job-adapter-active_job). Jobs run in-process on the same Falcon fiber scheduler. No separate process, no persistence. Jobs are lost on restart.

**Production**: `config.active_job.queue_adapter = :solid_queue` (set in `config/environments/production.rb`) connecting to the `queue` database. `config/deploy.yml` sets `SOLID_QUEUE_IN_PUMA: true`, which runs the [Solid Queue](https://github.com/rails/solid_queue) supervisor inside the web process — no separate `bin/jobs` process needed for a single-server deploy.

Solid Queue configuration (`config/queue.yml`):

| Setting | Value |
|---|---|
| Dispatcher polling interval | 1 second |
| Dispatcher batch size | 500 jobs |
| Worker queues | all (`*`) |
| Worker threads per process | 3 |
| Worker processes | `JOB_CONCURRENCY` env var (default 1) |
| Worker polling interval | 0.1 seconds |

A recurring job clears finished Solid Queue rows every hour at minute 12 (`config/recurring.yml`):

```ruby
SolidQueue::Job.clear_finished_in_batches(sleep_between_batches: 0.3)
```

**Defined jobs** (as of this branch):
- `FizzBuzzJob` — broadcasts FizzBuzz sequence over ActionCable
- `LLMFizzBuzzJob` — delegates to `LLMFizzBuzzer.call`, broadcasts via ActionCable
- `PublishGistJob` — creates or updates a GitHub Gist, broadcasts result via ActionCable

---

## 5. ActionCable + Solid Cable

`config/cable.yml`:

| Environment | Adapter | Notes |
|---|---|---|
| development | `async` | In-process; requires web console for live testing — `bin/rails console` is a separate process and cannot see in-process broadcasts |
| test | `async` | In-process |
| production | `solid_cable` | Writes to `cable` SQLite DB |

[Solid Cable](https://github.com/rails/solid_cable) is a database-backed ActionCable adapter that stores broadcast messages as rows in a table. Connected clients poll for new rows rather than receiving server-push notifications. Configuration:

| Setting | Value |
|---|---|
| `polling_interval` | 0.1 seconds |
| `message_retention` | 1 day |
| `connects_to` | `{ database: { writing: :cable } }` |

Because writes are sequential on SQLite, the `use_skip_locked` option (which optimizes polling on PostgreSQL/MySQL) has no effect and is not set.

Despite polling, [Solid Cable's throughput is comparable to Redis](https://github.com/rails/solid_cable) for most workloads. At the soft-launch scale (130 users) SQLite polling at 100ms is not a bottleneck.

---

## 6. Caching — Solid Cache

`config/cache.yml` / `config/environments/production.rb`:

```ruby
config.cache_store = :solid_cache_store
```

| Setting | Value |
|---|---|
| Backend | `solid_cache` gem, `cache` SQLite DB |
| Max size | 256 MB |
| Namespace | Rails environment name |
| Max age | not set (no explicit cap; entries expire by size eviction) |

[Solid Cache](https://github.com/rails/solid_cache) stores cache entries in the database. It replaces a Redis/Memcached dependency. It is the Rails 8 default. Eviction is LRU within the configured `max_size`.

---

## 7. HTTP proxy — Thruster

The container `CMD` is:

```
./bin/thrust ./bin/rails server
```

[Thruster](https://github.com/basecamp/thruster) is a lightweight Go process that wraps the Rails server process. It provides:

| Feature | Detail |
|---|---|
| HTTP/2 | Upgrades HTTP/1 from the Rails process to HTTP/2 for clients |
| Gzip compression | Automatically compresses responses |
| Public asset caching | Serves fingerprinted assets with long-lived cache headers without hitting the Rails process |
| X-Sendfile | Accelerates file downloads via `X-Sendfile` header |
| Zero config | All features are on by default; tunable via environment variables |

Thruster runs on port 80 (the `EXPOSE 80` port in the Dockerfile). It proxies to the Rails process on the port Falcon binds to internally. In production behind Kamal, Thruster sits between `kamal-proxy` (which handles SSL termination and load balancing) and the Rails application.

---

## 8. Deploy — Kamal

[Kamal 2](https://kamal-deploy.org) manages zero-downtime container deployments via Docker. It:

- Builds the Docker image locally (or on a remote builder), pushes it to a registry, and SSHs into target servers to `docker run` the new container with a rolling cutover
- Manages secrets via `.kamal/secrets` (not committed; references env vars or a secret manager)
- Runs `kamal-proxy` on each server to handle HTTP/2, SSL certificates (Let's Encrypt), and routing between old and new container versions during deploys
- Bridges fingerprinted assets between old and new versions (configured at `asset_path: /rails/public/assets`) to prevent 404s on in-flight requests during a rolling deploy

**Current `config/deploy.yml` state — placeholder values:**

| Key | Current value | Needs real value |
|---|---|---|
| `servers.web` | `192.168.0.1` | Yes — target host IP |
| `registry.server` | `localhost:5555` | Yes — Docker registry host |
| `registry.username` | commented out | Yes |
| `registry.password` | commented out | Yes (`KAMAL_REGISTRY_PASSWORD`) |
| `proxy.ssl` | commented out | Yes — enable with real hostname |
| `env.clear.SOLID_QUEUE_IN_PUMA` | `true` | No — correct for single-server |
| `builder.arch` | `amd64` | Verify against target server arch |
| `volumes` | `fizzbuzz_app_storage:/rails/storage` | Correct — persists SQLite files |

The `job:` server section (for a dedicated `bin/jobs` worker) is commented out; Solid Queue runs inside the web process.

---

## 9. Asset pipeline — Propshaft + ImportMap

[Propshaft](https://github.com/rails/propshaft) replaces Sprockets as the asset pipeline. It is the Rails 8 default. Key differences from Sprockets:

- No bundling or transpilation — assets are served as-is with a digest fingerprint appended to filenames
- Precomputes all asset paths at boot; no runtime path resolution overhead
- Does not handle JavaScript module dependencies — those are handled by ImportMap

[importmap-rails](https://github.com/rails/importmap-rails) maps JavaScript module specifiers to URLs via a browser-native `<script type="importmap">` tag. No Node.js, no bundler. Dependencies are loaded directly from CDN or `vendor/javascript/`. With HTTP/2 (provided by Thruster), multiple small script fetches carry no meaningful latency penalty versus a single bundle.

Frontend stack: Turbo (Hotwire SPA-like navigation + Turbo Streams for ActionCable-driven partial updates) + Stimulus (lightweight DOM controllers).

---

## 10. Eval infrastructure — ruby_llm-evals

The `ruby_llm-evals` gem (development/test only) provides a Rails engine for evaluating LLM prompt quality. It is not active in production.

Fixture paths in `test/fixtures/ruby_llm/evals/`:

| File | Contents |
|---|---|
| `prompts.yml` | Prompt definitions |
| `samples.yml` | Input variable sets + expected outputs |
| `runs.yml` | Evaluation run records |
| `prompt_executions.yml` | Per-sample execution records |

VCR cassettes for LLM calls are stored in `test/cassettes/`. The `webmock` gem intercepts HTTP at the test layer; cassettes replay recorded responses so tests run without live API calls.

The `ruby_llm` gem (also dev/test only) provides the LLM client used by `LLMFizzBuzzer` and evaluated by the evals engine.

---

## Sources

- [Falcon — Rails Integration Guide](https://socketry.github.io/falcon/guides/rails-integration/index.html)
- [Falcon GitHub — socketry/falcon](https://github.com/socketry/falcon)
- [Birds of a Fiber: Falcon async Ruby web server (Scout APM)](https://www.scoutapm.com/blog/birds-of-a-fiber)
- [Solid Cable GitHub — rails/solid_cable](https://github.com/rails/solid_cable)
- [Solid Cache GitHub — rails/solid_cache](https://github.com/rails/solid_cache)
- [Thruster GitHub — basecamp/thruster](https://github.com/basecamp/thruster)
- [Kamal Deploy — Installation](https://kamal-deploy.org/docs/installation/)
- [Propshaft GitHub — rails/propshaft](https://github.com/rails/propshaft)
- [ruby_llm-evals GitHub — sinaptia/ruby_llm-evals](https://github.com/sinaptia/ruby_llm-evals)
