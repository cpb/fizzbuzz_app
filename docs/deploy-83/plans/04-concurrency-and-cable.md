# 04 — Concurrency and ActionCable Plan

**Scope:** Falcon worker count, Solid Cable sizing, job-body sleep anti-pattern, Solid Queue worker config, WebSocket load testing, and the upgrade path beyond 130 users.

Cross-reference: [architecture-evolution.md](../research/architecture-evolution.md)

---

## 1. Decision: Keep `--count 1`

**Verdict: no change required.**

`bin/dev` and the container entrypoint both pass `--count 1`. This is correct and should remain so for the soft launch.

**Rationale:**

- Solid Cable stores broadcasts as rows in `production_cable.sqlite3`. Multiple Falcon worker processes can all read that file because SQLite WAL mode allows concurrent readers. However, under Docker/Kamal there is one named volume (`fizzbuzz_app_storage:/rails/storage`) on one host — all workers would share the same file, so the topology works. The risk is not correctness but operational complexity: any future second host without that shared volume would silently partition WebSocket connections.
- Within a single Falcon worker process, fiber concurrency handles hundreds of simultaneous connections with negligible overhead. At 130 users the bottleneck is SQLite write throughput, not Falcon's I/O scheduler.
- Increasing `--count` to match CPU cores would require validating the shared-volume assumption under Kamal and re-testing ActionCable broadcast delivery. That risk is not justified for 130 users.
- If a second web container is ever needed, the correct path is to add Redis and switch `cable.yml` to `adapter: redis` at the same time as changing `--count`. See section 6.

---

## 2. Decision: Keep Solid Cable

**Verdict: no change required.**

**Fan-out math at 130 sessions:**

| Metric | Value |
|---|---|
| WebSocket connections | 130 |
| Polling interval | 100 ms |
| Poll queries/second | 130 × 10 = **1,300 SELECT/s** on `production_cable.sqlite3` |
| Broadcast INSERT rate | ~130 sessions × ~1 step/s = **~130 INSERT/s** |
| Worst-case delivery latency | 100 ms (one polling interval) |

SQLite in WAL mode handles reads and writes concurrently: the 1,300 polls do not block the 130 inserts. Solid Cable's README documents SQLite as supported for hundreds of concurrent connections. At 130 sessions the cable database is not the bottleneck.

The 100 ms polling interval gives worst-case delivery of 100 ms and average ~50 ms. FizzBuzz steps fire at 1-second intervals; 100 ms latency is imperceptible.

**Why not Redis or AnyCable now:**

- Redis requires a provisioned sidecar, secrets management, and a `cable.yml` change — meaningful deploy scope for zero observable benefit at 130 users.
- AnyCable is appropriate at >1,000 sustained concurrent WebSocket connections. That threshold is 8× the soft-launch target. ([architecture-evolution.md §3](../research/architecture-evolution.md))

---

## 3. Required code change: remove `sleep 1` from job bodies

**Status: blocking — must ship before soft launch.**

`FizzBuzzJob` and `LLMFizzBuzzJob` contain `sleep 1` in their job bodies. This is the single highest-risk item for the soft launch.

**Why it matters with Falcon:**

Falcon's concurrency model is cooperative fiber scheduling. A fiber yields control only at async I/O boundaries. Ruby's `Kernel#sleep` is a blocking system call — it does not yield to the fiber scheduler. With 130 concurrent sessions each enqueuing a job that calls `sleep 1`, the Solid Queue worker threads (running inside the Falcon process via `SOLID_QUEUE_IN_PUMA: true`) each block for one full second. While a worker thread sleeps, no other job can run on that thread, and no other fiber in the event loop that happens to share that OS thread will be scheduled.

**The fix:**

Replace in-job `sleep` with a scheduled re-enqueue:

```ruby
# Before (blocks the event loop)
sleep 1
FizzBuzzJob.perform_later(n - 1, session_id)

# After (returns immediately; job is re-enqueued after 1 second)
FizzBuzzJob.set(wait: 1.second).perform_later(n - 1, session_id)
```

Apply the same change to `LLMFizzBuzzJob`. The job body returns immediately; Solid Queue's dispatcher picks up the re-enqueued job after the wait interval, leaving worker threads free for other work in between.

---

## 4. Solid Queue worker config

**Current state** (`config/queue.yml`): 3 worker threads, `JOB_CONCURRENCY` defaults to 1 process.

**Problem at 130 sessions:**

At peak, 130 sessions can each have one active job simultaneously. With 3 worker threads, 127 jobs queue behind the first 3. After the `sleep` fix (section 3), jobs complete in milliseconds rather than blocking for 1 second — so queue depth drains quickly. However, if all 130 sessions start at once, burst throughput still matters.

Solid Queue's documented throughput ceiling with SQLite is ~5,000 jobs/minute. 130 sessions × 10 steps = 1,300 jobs total per round, comfortably within that ceiling when sleep is removed.

**Recommended config for soft launch:**

Increase worker threads from 3 to 10 in `config/queue.yml`:

```yaml
workers:
  - queues: "*"
    threads: 10               # was 3
    processes: <%= ENV.fetch("JOB_CONCURRENCY", 1) %>
    polling_interval: 0.1
```

And set `JOB_CONCURRENCY` in `config/deploy.yml` (keep at 1 process):

```yaml
env:
  clear:
    RAILS_MAX_THREADS: "25"
    SOLID_QUEUE_IN_PUMA: "true"
    JOB_CONCURRENCY: "1"
```

Alternatively, set `JOB_CONCURRENCY=3` with `threads: 5` for 15 total worker slots — equivalent throughput, easier to tune per-process in future.

---

## 5. WebSocket load test plan

Run before approving the soft launch. Goal: confirm 130 concurrent WebSocket connections all receive broadcasts within 200 ms of job completion.

**Tool:** `k6` with the built-in `ws` module. Alternative: `websocket-bench`.

**Test scenario:**

```javascript
// k6 script outline
import ws from 'k6/ws';
import { check } from 'k6';

export let options = { vus: 130, duration: '60s' };

export default function () {
  const url = 'wss://your-host/cable';
  const res = ws.connect(url, {}, function (socket) {
    socket.on('open', () => {
      socket.send(JSON.stringify({
        command: 'subscribe',
        identifier: JSON.stringify({ channel: 'FizzBuzzChannel' })
      }));
    });
    socket.on('message', (data) => {
      // record timestamp of first broadcast received
    });
    socket.setTimeout(() => socket.close(), 30000);
  });
  check(res, { 'status was 101': (r) => r && r.status === 101 });
}
```

**Metrics to capture:**

| Metric | Pass criterion |
|---|---|
| Connection establishment | All 130 connections reach status 101 within 5 s |
| Broadcast delivery latency | p99 < 200 ms from job completion timestamp |
| Dropped frames | Zero missed broadcasts across all connections |
| `SQLITE_BUSY` errors | Zero in production Rails log during test |
| Solid Queue queue depth | Returns to 0 within 5 s of test end |

**How to correlate job completion to broadcast delivery:** Add a `completed_at` timestamp to the broadcast payload in `FizzBuzzJob`. The k6 script records `received_at = Date.now()`. Latency = `received_at - completed_at`.

---

## 6. Future cable upgrade path

If the soft launch reveals cable latency issues, or if the user base grows toward 1,000+ concurrent sessions:

**Step 1 — Add Redis, switch cable adapter:**

```yaml
# config/cable.yml
production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") %>
  channel_prefix: fizzbuzz_app_production
```

```yaml
# config/deploy.yml accessories:
redis:
  image: redis:7
  host: your-host
  port: 6379
  directories:
    data: /data
```

This removes the SQLite polling load entirely. Redis pub/sub delivers broadcasts in <1 ms. Falcon `--count` can be increased to match CPU cores. The Redis instance can also be shared with Solid Queue if migrating the queue adapter to Sidekiq at the same time.

**Step 2 — AnyCable (if >1,000 sustained concurrent connections):**

AnyCable replaces the Ruby WebSocket server with a Go binary. The Rails app handles channel logic via gRPC; the Go server manages the persistent connections. Memory usage drops ~60%. This step requires Redis (already added in Step 1). Threshold: ~1,000 sustained concurrent WebSocket connections. ([architecture-evolution.md §3](../research/architecture-evolution.md))

---

## 7. Open questions — human decisions required

| # | Question | Options | Impact |
|---|---|---|---|
| 1 | `threads` value in `queue.yml` for launch | 10 (recommended above) vs 20 (maximum headroom) | Higher thread count uses more memory inside the web process |
| 2 | Add Redis before launch or after? | After (if monitoring shows cable latency) vs before (eliminates SQLite polling load from day one) | Adding Redis before launch increases deploy complexity; deferring is lower risk at 130 users |
| 3 | `JOB_CONCURRENCY` process count | Keep at 1 (recommended) vs 2–3 for redundancy | Multiple processes increase SQLite queue contention without `SKIP LOCKED` |

---

## Summary checklist

- [ ] Remove `sleep 1` from `FizzBuzzJob` and `LLMFizzBuzzJob`; replace with `set(wait: 1.second).perform_later` — **required before launch**
- [ ] Update `queue.yml` worker `threads` from 3 to 10
- [ ] Run k6 WebSocket load test at 130 VUs; confirm all pass criteria in section 5
- [ ] Confirm `--count 1` in `bin/dev` and container entrypoint — no change needed
- [ ] Decide on Redis timing (question 2 above)
