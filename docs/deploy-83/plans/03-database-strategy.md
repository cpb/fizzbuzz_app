# 03 — Database Strategy

> Status: Draft — soft launch planning
> Cross-references: [architecture-evolution.md](../research/architecture-evolution.md), [system-as-built.md](../research/system-as-built.md)

---

## Decision: Stay on SQLite3 for the soft launch

**Verdict: SQLite3 is sufficient for 130 concurrent users. No database migration is needed before launch.**

Evidence from research:

- **Write rate is within WAL mode's envelope.** The app's peak write pattern is ~130 writes/second to `production.sqlite3` (one Turbo Stream broadcast per countdown step per session) plus ~130 INSERT/s into `production_cable.sqlite3`. Published benchmarks show Rails + SQLite sustaining ~2,500 write requests/second under simplified conditions; real-world reports show no issues at 128 concurrent workers. 130 writes/s is well within this ceiling.
- **`busy_timeout: 5000` covers transient contention.** `config/database.yml` already sets `timeout: 5000` for all four databases, mapping to SQLite's `busy_timeout` pragma. Research confirms that ≥5 s timeout eliminates `SQLITE_BUSY` errors that appear at shorter values under moderate concurrency.
- **4 separate SQLite files reduce contention.** `production.sqlite3` (app data), `production_cache.sqlite3` (Solid Cache), `production_queue.sqlite3` (Solid Queue), and `production_cable.sqlite3` (Solid Cable) each have their own per-file write lock. A cache sweep or cable poll storm cannot block an application write.
- **Single Kamal container removes the multi-host complication.** The soft launch targets one host. SQLite's single-writer constraint is only operationally fragile at >1 Docker host. The `fizzbuzz_app_storage:/rails/storage` volume mount in `config/deploy.yml` is already correct for single-host persistence.

The highest-risk database at 130 sessions is `production_cable.sqlite3`: ~1,300 SELECT/s from Solid Cable polling (130 connections × 10 polls/s) plus ~130 INSERT/s from broadcasts. This is documented as sufficient for "hundreds, not thousands" of connections in Solid Cable's own README.

---

## What to verify before launch

### 1. Write-concurrency benchmark

Run a write-concurrency simulation against the running production container before going live. The simplest proxy is Apache Bench against a route that triggers a DB write:

```bash
# 1,300 requests total, 130 concurrent — simulates one countdown step across all sessions
ab -n 1300 -c 130 http://localhost:3000/

# Or with wrk for a sustained load test (10 seconds at 130 concurrent):
wrk -t 13 -c 130 -d 10s http://localhost:3000/
```

**Watch for:**
- Any `SQLITE_BUSY` errors in `log/production.log` — grep: `grep -i "busy\|locked\|SQLITE_BUSY" log/production.log`
- p99 response latency reported by `ab` — acceptable threshold is **< 500 ms**
- WAL file growth: `ls -lh storage/*.sqlite3-wal` — a WAL file that grows without checkpointing indicates a checkpoint-stall condition

**Expected outcome:** Zero `SQLITE_BUSY` errors with `timeout: 5000`. p99 latency well under 500 ms for short transactions.

### 2. Confirm WAL mode is active

Rails 8 enables WAL mode by default, but verify it is active on the production database after the first deploy:

```bash
# From a rails console on the production container:
ActiveRecord::Base.connection.execute("PRAGMA journal_mode;").first
# => {"journal_mode" => "wal"}

# Or directly with sqlite3 CLI:
sqlite3 storage/production.sqlite3 "PRAGMA journal_mode;"
# => wal
```

If the result is not `wal`, check `config/environments/production.rb` for pragma overrides. The required configuration trio is:

```
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;   # already set via database.yml timeout:
```

---

## Litestream backup (required before launch)

SQLite has no built-in streaming replication. **Without Litestream, a host failure loses all data.** This is the only mandatory infrastructure addition before the soft launch.

[Litestream](https://litestream.io) streams SQLite WAL changes to object storage as they are written — continuous, near-zero-latency backup with point-in-time restore.

### Kamal accessory option (recommended)

Add Litestream as a Kamal accessory in `config/deploy.yml`. It runs as a sidecar container on the same host, sharing the `storage/` volume mount:

```yaml
# config/deploy.yml (additions)
accessories:
  litestream:
    image: litestream/litestream:latest
    volumes:
      - fizzbuzz_app_storage:/rails/storage
    files:
      - config/litestream.yml:/etc/litestream.yml
    cmd: replicate -config /etc/litestream.yml
```

```yaml
# config/litestream.yml
dbs:
  - path: /rails/storage/production.sqlite3
    replicas:
      - type: s3
        bucket: YOUR_BUCKET
        path: fizzbuzz-app/production
        access-key-id: $LITESTREAM_ACCESS_KEY_ID
        secret-access-key: $LITESTREAM_SECRET_ACCESS_KEY
        endpoint: https://YOUR_ENDPOINT   # Hetzner: nbg1.your-objectstorage.com

  - path: /rails/storage/production_cable.sqlite3
    replicas:
      - type: s3
        bucket: YOUR_BUCKET
        path: fizzbuzz-app/cable

  - path: /rails/storage/production_queue.sqlite3
    replicas:
      - type: s3
        bucket: YOUR_BUCKET
        path: fizzbuzz-app/queue

  # production_cache.sqlite3 omitted — cache is rebuildable, backup is low value
```

Point-in-time restore:

```bash
litestream restore -config /etc/litestream.yml -o /rails/storage/production.sqlite3 \
  s3://YOUR_BUCKET/fizzbuzz-app/production
```

---

## Migration triggers for PostgreSQL

From [architecture-evolution.md](../research/architecture-evolution.md) — revisit the SQLite decision if any of the following appear in production:

| Signal | Threshold | Action |
|---|---|---|
| `SQLITE_BUSY` errors in logs | Any sustained occurrence despite 5 s timeout | Investigate first; if persistent, plan PG migration |
| p99 write latency | > 500 ms under normal load | Profile which DB is the bottleneck; PG migration likely needed |
| Multiple web containers needed | Scaling beyond 1 Kamal host | SQLite with shared NFS/EFS is fragile; switch to PG |
| Solid Queue job rate | > 5,000 jobs/minute sustained | SQLite lacks `FOR UPDATE SKIP LOCKED`; Sidekiq + PG more appropriate |
| `WorkbookSession` write load | Heavy concurrent writes from issue #79 | Re-evaluate after that feature is spec'd |

The current soft launch at 130 users on a single container does not approach any of these thresholds.

---

## Migration path if triggered

High-level only — a full migration workbook would be a separate document:

1. Add `gem "pg"` to `Gemfile`; keep `gem "sqlite3"` for development if desired.
2. Update `config/database.yml` production block: `adapter: postgresql` for each named database (`primary`, `cache`, `queue`, `cable`). Add `pool`, `host`, `username`, `password` from env vars.
3. Provision a PostgreSQL instance (managed, e.g. Hetzner Managed PostgreSQL, or a dedicated container via Kamal accessory).
4. Run `bin/rails db:migrate` for each database — Solid Cache, Queue, and Cable each ship their own `db/*_migrate` folders.
5. For Solid Cable on PostgreSQL, point `connects_to` at `primary` or a dedicated PG database — both are documented as valid configurations.
6. For Solid Queue on PostgreSQL, enable `use_skip_locked: true` in `config/queue.yml` to unlock efficient concurrent worker dispatch.
7. Schema dump switches from `db/schema.rb` to `db/structure.sql` if PostgreSQL-specific features are used — update `config/application.rb` accordingly.
8. Update Litestream replication config to remove PG-migrated databases; PG handles its own WAL archiving.
9. Remove the `fizzbuzz_app_storage` SQLite volume mount from `config/deploy.yml` once all databases are on PostgreSQL (keep for Active Storage files if used).
10. Run the same write-concurrency benchmark post-migration to confirm no regressions.

---

## Open questions for human decision

1. **Object storage target** — Hetzner Object Storage (same datacenter as the app host, zero egress cost) vs Backblaze B2 vs AWS S3. Hetzner is the lowest-friction option if the host is in Hetzner; needs a bucket name and endpoint URL.
2. **Backup retention period** — Litestream defaults to keeping all snapshots. A retention policy (e.g. 7 days of WAL, monthly snapshots) needs an explicit `retention` and `retention-check-interval` in `litestream.yml`.
3. **Cache database backup** — `production_cache.sqlite3` is rebuildable from app state. Recommend skipping Litestream replication for it (saves backup I/O and storage cost). Confirm this is acceptable.
4. **Encryption at rest** — The `fizzbuzz_app_storage` Docker volume is not encrypted by default. Decide whether this is in scope for the soft launch or a post-launch hardening item.
5. **`WorkbookSession` write profile (issue #79)** — Once that model is built, re-run the write-contention analysis. If each workbook step generates multiple writes per session, the 130 writes/s estimate increases and the cable database load estimate should be recalculated.

---

*Plan authored for issue #83 soft launch. Last updated: 2026-06-08.*
