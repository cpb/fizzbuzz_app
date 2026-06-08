# Plan 05 — SQLite + Falcon Optimization for 130-User Soft Launch

**Stack:** Rails 8.1.3 · Falcon `--count 1` · SQLite3 × 4 DBs · Hetzner CX32 NVMe  
**Target:** 130 concurrent wizard sessions without `SQLITE_BUSY` errors or fiber stalls  
**Cross-references:** [`research/architecture-evolution.md`](../research/architecture-evolution.md) · Plan 04 (fiber anti-patterns)

---

## 1. SQLite PRAGMA Optimizations

### 1a. Confirm WAL mode (Rails 8 default)

Rails 8 enables WAL mode automatically. Verify it is active post-deploy:

```sql
PRAGMA journal_mode;   -- expected: wal
```

No code change required unless the check fails.

### 1b. Apply remaining PRAGMAs via initializer

`database.yml` supports a limited pragma key in some Rails versions, but the most reliable approach for Rails 8 multi-DB configs is a connection initializer. Create:

**`config/initializers/sqlite_optimizations.rb`**

```ruby
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.connection_handler.connection_pool_list(:writing).each do |pool|
    pool.with_connection do |conn|
      next unless conn.adapter_name == "SQLite"

      conn.execute("PRAGMA synchronous = NORMAL")       # safe with WAL; reduces fsync cost
      conn.execute("PRAGMA wal_autocheckpoint = 1000")  # checkpoint after 1000 WAL pages (~4 MB)
      conn.execute("PRAGMA cache_size = -20000")        # 20 MB per-connection page cache
      conn.execute("PRAGMA mmap_size = 134217728")      # 128 MB memory-mapped I/O
      conn.execute("PRAGMA temp_store = MEMORY")        # temp tables in RAM, not on disk
    end
  end
end
```

**Why each PRAGMA matters at 130 users:**

| PRAGMA | Value | Reason |
|---|---|---|
| `synchronous` | `NORMAL` | WAL makes `FULL` fsync unnecessary on writes; `NORMAL` fsync only at checkpoints. Saves ~1 fsync per transaction. |
| `wal_autocheckpoint` | `1000` | Prevents unbounded WAL growth (default is 1000 but confirm). A 10 GB WAL would slow all readers. |
| `cache_size` | `-20000` | 20 MB in-process page cache per connection. Negative = kilobytes. Reduces repeated disk reads for hot pages. |
| `mmap_size` | `134217728` | 128 MB memory-mapped reads bypass `read()` syscall overhead — important at ~1,300 SELECTs/s on the cable DB. |
| `temp_store` | `MEMORY` | Sorting and grouping use RAM temp tables instead of temp files. Avoids I/O for query intermediates. |

### 1c. Confirm `busy_timeout` is active

**`config/database.yml`** already has `timeout: 5000` in the `default:` anchor. This maps to `busy_timeout = 5000` ms. All four production databases inherit it. No change required — verify post-deploy:

```sql
PRAGMA busy_timeout;   -- expected: 5000
```

Per [architecture-evolution.md §1](../research/architecture-evolution.md), the combination of WAL + `synchronous=NORMAL` + `busy_timeout ≥ 5000` is the documented minimum for eliminating lock errors at moderate concurrency.

---

## 2. Connection Pool Sizing for Falcon Fibers

### The problem

`database.yml` sets `max_connections: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>`. With the default of 5, each of the four databases has a pool of 5 connections. Falcon runs 130+ concurrent fibers. ActiveRecord checks out a connection for each fiber that touches the DB — fibers beyond the pool limit block waiting for a free connection.

### Recommendation

Set `RAILS_MAX_THREADS=25` for the soft launch in **`config/deploy.yml`**:

```yaml
env:
  clear:
    RAILS_MAX_THREADS: "25"
    SOLID_QUEUE_IN_PUMA: "true"
```

**Effect:** Each SQLite database gets a pool of 25 connections — 100 total open file descriptors for DB connections across the four databases. At 130 concurrent fibers, peak wait time drops significantly.

**Why not higher?** SQLite has a single writer per file — a pool of 100 connections does not increase write throughput, only reduces checkout wait time. At 25, peak DB operations are well within what `busy_timeout` can absorb. Higher values increase open file descriptors and WAL reader overhead with diminishing returns.

**Caveat:** Solid Queue's in-process worker (`SOLID_QUEUE_IN_PUMA: true`) shares this pool. With 10 worker threads (`config/queue.yml` after the plan 04 change) and 25 pool slots, there is no contention between job dispatch and web requests.

---

## 3. Litestream Sidecar — Real-Time Backup

SQLite has no built-in replication. The `fizzbuzz_app_storage` Docker volume is persistent across deploys but is not backed up. A single disk failure loses all production data.

**[Litestream](https://litestream.io)** replicates SQLite WAL frames to S3-compatible object storage in near-real-time (typically < 1 second lag). It runs as a sidecar alongside the Rails container.

### Option A: Kamal accessory (recommended — keeps containers separate)

Add to **`config/deploy.yml`**:

```yaml
accessories:
  litestream:
    image: litestream/litestream:latest
    host: <your-server-ip>
    volumes:
      - fizzbuzz_app_storage:/rails/storage
    cmd: replicate -config /etc/litestream.yml
    files:
      - config/litestream.yml:/etc/litestream.yml
    env:
      secret:
        - LITESTREAM_ACCESS_KEY_ID
        - LITESTREAM_SECRET_ACCESS_KEY
```

### Option B: Embedded in Dockerfile (simpler for single-machine deploys)

```dockerfile
# In the final stage of Dockerfile
COPY --from=litestream/litestream /usr/local/bin/litestream /usr/local/bin/litestream
COPY config/litestream.yml /etc/litestream.yml
CMD ["litestream", "replicate", "-exec", "./bin/thrust ./bin/rails server"]
```

The `-exec` flag starts Rails as a child process — Litestream wraps and supervises it.

### `config/litestream.yml` skeleton

```yaml
dbs:
  - path: /rails/storage/production.sqlite3
    replicas:
      - type: s3
        bucket: YOUR_BUCKET
        path: fizzbuzz-app/primary
        endpoint: https://nbg1.your-objectstorage.com   # Hetzner Object Storage example
        access-key-id: ${LITESTREAM_ACCESS_KEY_ID}
        secret-access-key: ${LITESTREAM_SECRET_ACCESS_KEY}

  - path: /rails/storage/production_cable.sqlite3
    replicas:
      - type: s3
        bucket: YOUR_BUCKET
        path: fizzbuzz-app/cable
        # ... same credentials

  - path: /rails/storage/production_queue.sqlite3
    replicas:
      - type: s3
        bucket: YOUR_BUCKET
        path: fizzbuzz-app/queue

  # production_cache.sqlite3 omitted — Solid Cache is rebuildable
```

Point-in-time restore:

```bash
litestream restore -o /rails/storage/production.sqlite3 \
  s3://YOUR_BUCKET/fizzbuzz-app/primary
```

---

## 4. Falcon-Specific: Avoid Blocking Fibers

See **Plan 04 §3** for the full analysis. Summary:

- `sleep N` in job bodies blocks the Falcon event loop — replace with `set(wait: N.seconds).perform_later`
- `FizzBuzzJob` and `LLMFizzBuzzJob` both require this fix before launch
- `PublishGistJob` makes an external HTTP call — verify the HTTP client yields at I/O (async-aware clients do; standard `Net::HTTP` may not under Falcon)

---

## 5. Hetzner NVMe: No Special I/O Config Needed

Hetzner CX32 uses local NVMe storage. NVMe devices use the `none` or `mq-deadline` I/O scheduler by default on Linux — both optimal for random-access SQLite WAL workloads. No `ionice`, `hdparm`, or scheduler tuning is needed. The bottleneck at 130 users is SQLite's single-writer serialization, not raw I/O throughput. NVMe latency (~100 µs) is well below WAL transaction overhead.

---

## 6. Verification Checklist

Run these checks immediately after the first production deploy.

### SQLite PRAGMA verification

```bash
kamal app exec --reuse 'bin/rails runner "
  puts ActiveRecord::Base.connection.execute(\"PRAGMA journal_mode;\").first.inspect
  puts ActiveRecord::Base.connection.execute(\"PRAGMA synchronous;\").first.inspect
  puts ActiveRecord::Base.connection.execute(\"PRAGMA busy_timeout;\").first.inspect
  puts ActiveRecord::Base.connection.execute(\"PRAGMA wal_autocheckpoint;\").first.inspect
"'
```

Expected values:

| PRAGMA | Expected |
|---|---|
| `journal_mode` | `wal` |
| `synchronous` | `1` (NORMAL) |
| `busy_timeout` | `5000` |
| `wal_autocheckpoint` | `1000` |
| `cache_size` | `-20000` |
| `mmap_size` | `134217728` |

Check all four databases.

### Connection pool verification

```ruby
kamal app exec --reuse 'bin/rails runner "puts ActiveRecord::Base.connection_pool.size"'
# must return 25
```

### Load test (pre-soft-launch gate)

```bash
ab -n 1300 -c 130 https://your-host/up
```

Watch for in `log/production.log`:
- `SQLITE_BUSY` → busy_timeout insufficient or transactions too long
- `ActiveRecord::ConnectionTimeoutError` → increase `RAILS_MAX_THREADS`
- `Fiber::Error` → blocking operation in fiber context

### Litestream replication lag

```bash
litestream snapshots s3://your-bucket/fizzbuzz-app/primary
# Most recent snapshot timestamp should be < 1 second ago under active write load
```

### WAL file size (ongoing)

```bash
ls -lh /rails/storage/*.sqlite3-wal
# WAL files > 10 MB under sustained load indicate stalled checkpointing
```

---

## Summary of Changes

| File | Change | Status |
|---|---|---|
| `config/initializers/sqlite_optimizations.rb` | New — sets 5 PRAGMAs on all SQLite connections at boot | New file |
| `config/deploy.yml` | `RAILS_MAX_THREADS: "25"` in `env.clear` | Edit |
| `config/deploy.yml` | Litestream accessory block | Edit |
| `config/litestream.yml` | New — Litestream replication config | New file |
| `database.yml` | No change — `timeout: 5000` already correct | — |
| WAL mode | No change — Rails 8 sets it automatically | — |
