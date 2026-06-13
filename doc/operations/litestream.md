# Litestream SQLite Backup

Litestream runs as a Kamal accessory on the same host as the Rails app. It
shares the `fizzbuzz_app_storage` Docker volume and continuously replicates
all four production SQLite databases to S3-compatible object storage.

---

## New assets required

These must exist before the first `kamal accessory boot litestream`:

| Asset | Notes |
|---|---|
| S3-compatible bucket | Any provider: AWS S3, Tigris, Backblaze B2, Cloudflare R2. Must be private. |
| IAM credentials | Access key + secret with `s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, `s3:DeleteObject` on the bucket. |
| 1Password secrets | Three new entries in `fizzbuzz_app-kamal-secrets` (see below). |
| `litestream/litestream:0.3.13` image | Pulled automatically by Kamal — no manual action needed. |

### 1Password secrets to add

Add these to the `Private/fizzbuzz_app-kamal-secrets` item:

| Secret name | Value |
|---|---|
| `LITESTREAM_REPLICA_BUCKET` | Bucket name only, e.g. `fizzbuzz-backups` (no `s3://` prefix) |
| `LITESTREAM_ACCESS_KEY_ID` | IAM access key ID |
| `LITESTREAM_SECRET_ACCESS_KEY` | IAM secret access key |

### Databases replicated

All four databases share the same bucket, under separate paths:

| Database | Volume path | Replica path |
|---|---|---|
| Primary | `/rails/storage/production.sqlite3` | `fizzbuzz_app/production` |
| Queue | `/rails/storage/production_queue.sqlite3` | `fizzbuzz_app/production_queue` |
| Cache | `/rails/storage/production_cache.sqlite3` | `fizzbuzz_app/production_cache` |
| Cable | `/rails/storage/production_cable.sqlite3` | `fizzbuzz_app/production_cable` |

---

## Deploy

```bash
# First-time boot (after adding secrets to 1Password):
kamal accessory boot litestream

# Subsequent deploys pick it up automatically alongside the app.
# To restart the accessory only:
kamal accessory restart litestream
```

---

## Initial validation

Run these checks after the first deploy to confirm replication is active.

### 1. Accessory is running

```bash
kamal accessory logs litestream
```

Expected output within 30 seconds:

```
litestream: initialized db: /rails/storage/production.sqlite3
litestream: replicating: db=/rails/storage/production.sqlite3 name=s3 type=s3
# (repeated for queue, cache, cable)
```

If you see `no such file or directory` for a DB path, the app hasn't written
to that database yet — start the app and hit at least one page to initialise
all four DBs.

### 2. Replica objects exist in S3

```bash
aws s3 ls s3://$LITESTREAM_REPLICA_BUCKET/fizzbuzz_app/ --recursive | head -20
```

You should see `generations/` directories for each database within a minute
or two of the accessory starting.

### 3. Smoke-test restore to a temporary path

Run this on the server to verify the replica is restorable without touching
the live databases:

```bash
ssh root@5.78.207.157

docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  restore -o /tmp/production_verify.sqlite3 \
  "s3://<bucket>/fizzbuzz_app/production"

# Confirm the file was written and is a valid SQLite database:
docker run --rm -v /tmp:/tmp keinos/sqlite3 \
  sqlite3 /tmp/production_verify.sqlite3 "SELECT count(*) FROM sqlite_master;"

rm /tmp/production_verify.sqlite3
```

---

## Restore procedure

**When to use:** data loss, corrupted database file, or migrating to a new
server.

### 1. Stop the app

```bash
kamal app stop
```

This prevents the app from writing to the SQLite files during restore.
Leave the Litestream accessory running — stopping it is not required, but
it will detect the file is being replaced and reconnect automatically.

### 2. SSH to the server

```bash
ssh root@5.78.207.157
```

### 3. Restore each database

Restore into the live volume paths. Use `-if-replica-exists` to skip
databases that have no replica yet (e.g. `production_cable` if no cable
connections have been made).

```bash
export LITESTREAM_ACCESS_KEY_ID=<key>
export LITESTREAM_SECRET_ACCESS_KEY=<secret>
export BUCKET=<bucket-name>

for db in production production_queue production_cache production_cable; do
  docker run --rm \
    -v fizzbuzz_app_storage:/rails/storage \
    -e LITESTREAM_ACCESS_KEY_ID=$LITESTREAM_ACCESS_KEY_ID \
    -e LITESTREAM_SECRET_ACCESS_KEY=$LITESTREAM_SECRET_ACCESS_KEY \
    litestream/litestream:0.3.13 \
    restore -if-replica-exists \
    -o /rails/storage/${db}.sqlite3 \
    "s3://$BUCKET/fizzbuzz_app/${db}"
done
```

### 4. Verify the restored files

```bash
for db in production production_queue production_cache production_cable; do
  echo -n "$db: "
  docker run --rm \
    -v fizzbuzz_app_storage:/rails/storage \
    keinos/sqlite3 \
    sqlite3 /rails/storage/${db}.sqlite3 "PRAGMA integrity_check;"
done
```

All four should print `ok`.

### 5. Restart the app

```bash
# Exit the SSH session first, then:
kamal app start
```

### 6. Confirm replication resumed

```bash
kamal accessory logs litestream
```

Litestream reconnects to the restored files automatically within seconds.

---

## Point-in-time restore

Litestream stores WAL frames alongside the snapshot, so you can restore to
any point within the retention window (default: indefinite, controlled by
the replica's `retention` setting).

```bash
docker run --rm \
  -v fizzbuzz_app_storage:/rails/storage \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  restore -timestamp "2026-06-12T18:00:00Z" \
  -o /rails/storage/production.sqlite3 \
  "s3://<bucket>/fizzbuzz_app/production"
```

Omit `-timestamp` to restore to the latest available state.

---

## Useful commands

```bash
# Tail live accessory logs
kamal accessory logs litestream -f

# List available generations (snapshots) in S3
docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  generations "s3://<bucket>/fizzbuzz_app/production"

# Check WAL lag (how far behind replication is)
docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  snapshots "s3://<bucket>/fizzbuzz_app/production"
```
