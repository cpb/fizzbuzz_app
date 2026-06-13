# Litestream SQLite Backup

Litestream runs as a Kamal accessory on the same host as the Rails app. It
shares the `fizzbuzz_app_storage` Docker volume and continuously replicates
all four production SQLite databases to a Cloudflare R2 bucket.

---

## New assets required

These must exist before the first `kamal accessory boot litestream`:

| Asset | Notes |
|---|---|
| Cloudflare R2 bucket | Create in the Cloudflare dashboard → R2 → Create bucket. Private, no public access needed. |
| R2 API token | In R2 → Manage R2 API Tokens → Create token. Scope: Object Read & Write on the bucket only. Generates an Access Key ID + Secret Access Key pair. |
| Cloudflare Account ID | Found on the R2 overview page (right sidebar). Not secret — goes in `config/deploy.yml` as a clear env var. |
| 1Password secrets | Two new entries in `fizzbuzz_app-kamal-secrets` (see below). |
| `litestream/litestream:0.3.13` image | Pulled automatically by Kamal. |

### 1Password secrets to add

Add to the `Private/fizzbuzz_app-kamal-secrets` item:

| Secret name | Value |
|---|---|
| `LITESTREAM_REPLICA_BUCKET` | R2 bucket name, e.g. `fizzbuzz-backups` |
| `LITESTREAM_ACCESS_KEY_ID` | R2 API token Access Key ID |
| `LITESTREAM_SECRET_ACCESS_KEY` | R2 API token Secret Access Key |

### Update `config/deploy.yml`

Fill in your actual account ID in the accessory's clear env:

```yaml
accessories:
  litestream:
    env:
      clear:
        CLOUDFLARE_ACCOUNT_ID: <your-cloudflare-account-id>
```

### Databases replicated

| Database | Volume path | Replica path in bucket |
|---|---|---|
| Primary | `/rails/storage/production.sqlite3` | `fizzbuzz_app/production` |
| Queue | `/rails/storage/production_queue.sqlite3` | `fizzbuzz_app/production_queue` |
| Cache | `/rails/storage/production_cache.sqlite3` | `fizzbuzz_app/production_cache` |
| Cable | `/rails/storage/production_cable.sqlite3` | `fizzbuzz_app/production_cable` |

---

## Deploy

```bash
# First-time boot (after provisioning R2 and adding secrets):
kamal accessory boot litestream

# Restart the accessory only (e.g. after config changes):
kamal accessory restart litestream
```

---

## Initial validation

Run these after the first deploy to confirm replication is active.

### 1. Accessory is running

```bash
kamal accessory logs litestream
```

Expected output within 30 seconds of start:

```
litestream: initialized db: /rails/storage/production.sqlite3
litestream: replicating: db=/rails/storage/production.sqlite3 name=s3 type=s3
# repeated for queue, cache, cable
```

If you see `no such file or directory` for a path, the app hasn't written to
that DB yet. Hit a page that exercises the relevant database (any page load
creates `production.sqlite3`; running a job creates `production_queue.sqlite3`).

### 2. Objects appear in the R2 bucket

In the Cloudflare dashboard, open the bucket and confirm `fizzbuzz_app/`
prefixes appear within a minute or two. Or via the AWS CLI with the R2 endpoint:

```bash
aws s3 ls s3://$LITESTREAM_REPLICA_BUCKET/fizzbuzz_app/ \
  --endpoint-url https://<account-id>.r2.cloudflarestorage.com \
  --recursive | head -20
```

You should see `generations/` subdirectories under each database path.

### 3. Smoke-test restore to a temporary path

Verify the replica is actually restorable without touching the live databases:

```bash
ssh root@5.78.207.157

docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  restore \
  -o /tmp/production_verify.sqlite3 \
  -endpoint https://<account-id>.r2.cloudflarestorage.com \
  "s3://<bucket>/fizzbuzz_app/production"

# Confirm valid SQLite file:
sqlite3 /tmp/production_verify.sqlite3 "PRAGMA integrity_check;"
# Expected: ok

rm /tmp/production_verify.sqlite3
```

---

## Restore procedure

**When to use:** data loss, corrupted database file, or migrating to a new server.

### 1. Stop the app

```bash
kamal app stop
```

Prevents the app from writing to SQLite files during restore. The Litestream
accessory can stay running — it will reconnect to the restored files automatically.

### 2. SSH to the server

```bash
ssh root@5.78.207.157
```

### 3. Restore each database

```bash
export LITESTREAM_ACCESS_KEY_ID=<key>
export LITESTREAM_SECRET_ACCESS_KEY=<secret>
export ACCOUNT_ID=<cloudflare-account-id>
export BUCKET=<bucket-name>
export ENDPOINT=https://${ACCOUNT_ID}.r2.cloudflarestorage.com

for db in production production_queue production_cache production_cable; do
  echo "Restoring $db..."
  docker run --rm \
    -v fizzbuzz_app_storage:/rails/storage \
    -e LITESTREAM_ACCESS_KEY_ID=$LITESTREAM_ACCESS_KEY_ID \
    -e LITESTREAM_SECRET_ACCESS_KEY=$LITESTREAM_SECRET_ACCESS_KEY \
    litestream/litestream:0.3.13 \
    restore \
    -if-replica-exists \
    -endpoint $ENDPOINT \
    -o /rails/storage/${db}.sqlite3 \
    "s3://$BUCKET/fizzbuzz_app/${db}"
done
```

`-if-replica-exists` skips databases with no replica (e.g. `production_cable`
if no WebSocket connections have been made yet).

### 4. Verify the restored files

```bash
for db in production production_queue production_cache production_cable; do
  path=/var/lib/docker/volumes/fizzbuzz_app_storage/_data/${db}.sqlite3
  if [ -f "$path" ]; then
    echo -n "$db: "
    sqlite3 "$path" "PRAGMA integrity_check;"
  else
    echo "$db: skipped (not restored)"
  fi
done
```

All present databases should print `ok`.

### 5. Restart the app

```bash
# Back on your local machine:
kamal app start
```

### 6. Confirm replication resumed

```bash
kamal accessory logs litestream
```

Litestream reconnects to the restored files within seconds.

---

## Point-in-time restore

Litestream stores WAL frames so you can restore to any moment within the
retention window (default: indefinite until you configure `retention`).

```bash
docker run --rm \
  -v fizzbuzz_app_storage:/rails/storage \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  restore \
  -timestamp "2026-06-12T18:00:00Z" \
  -endpoint https://<account-id>.r2.cloudflarestorage.com \
  -o /rails/storage/production.sqlite3 \
  "s3://<bucket>/fizzbuzz_app/production"
```

Omit `-timestamp` to restore to the latest available state.

---

## Useful commands

```bash
# Tail live accessory logs
kamal accessory logs litestream -f

# List available generations (snapshots) in R2
docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  generations \
  -endpoint https://<account-id>.r2.cloudflarestorage.com \
  "s3://<bucket>/fizzbuzz_app/production"

# List available WAL snapshots
docker run --rm \
  -e LITESTREAM_ACCESS_KEY_ID=<key> \
  -e LITESTREAM_SECRET_ACCESS_KEY=<secret> \
  litestream/litestream:0.3.13 \
  snapshots \
  -endpoint https://<account-id>.r2.cloudflarestorage.com \
  "s3://<bucket>/fizzbuzz_app/production"
```
