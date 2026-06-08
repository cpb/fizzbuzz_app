# Cloud Deploy Plan — fizzbuzz_app

**Decision: Hetzner CX32 + GitHub Container Registry (ghcr.io)**

Hetzner is the cheapest native Kamal target with local NVMe disk — optimal for SQLite WAL performance. At €6.80/mo for 4 vCPU / 8 GB RAM / 80 GB NVMe, it costs 3.5× less than an equivalent DigitalOcean Droplet ($24/mo) and avoids the Kamal workarounds required by Fly.io, Render, and Railway. The existing `config/deploy.yml` structure requires only value substitution, not restructuring. See [`research/hosting-providers.md`](../research/hosting-providers.md) for the full provider comparison.

---

## 1. Prerequisites

### Hetzner Cloud

- [ ] Create a [Hetzner Cloud](https://console.hetzner.cloud) account
- [ ] Create a **CX32** server: 4 vCPU, 8 GB RAM, 80 GB NVMe, Ubuntu 24.04
- [ ] Add your SSH public key during server creation (or via the Hetzner console)
- [ ] Note the server's public IPv4 address

### DNS

- [ ] Create an **A record** pointing your domain (e.g., `fizzbuzz.example.com`) to the Hetzner server IP
- [ ] Confirm DNS propagation before running `kamal setup`: `dig +short fizzbuzz.example.com`

### GitHub Container Registry

- [ ] Ensure the GitHub organization/account has Packages enabled (free; no self-hosted registry needed)
- [ ] Create a **Personal Access Token (classic)** with scopes: `read:packages`, `write:packages`, `delete:packages`
  - Settings → Developer settings → Personal access tokens → Tokens (classic)
- [ ] Store the token value — it becomes `KAMAL_REGISTRY_PASSWORD` in `.kamal/secrets`

### Rails master key

- [ ] Confirm `config/master.key` is present locally (not committed to git)
- [ ] Store the key value in your secret manager (1Password) or export it as `RAILS_MASTER_KEY` in your shell before running Kamal commands

### Local tooling

- [ ] Ruby gem: `gem install kamal` (or it is in the Gemfile under `:deployment`)
- [ ] Docker Desktop (or Docker Engine) running locally for the image build step
- [ ] `ssh root@<hetzner-ip>` reachable before running `kamal setup`

---

## 2. Changes Required in `config/deploy.yml`

The file already has the correct structure. Replace placeholder values only:

| Key | Placeholder | Real value |
|---|---|---|
| `servers.web` | `192.168.0.1` | `<hetzner-server-ipv4>` |
| `registry.server` | `localhost:5555` | `ghcr.io` |
| `registry.username` | _(commented out)_ | `<github-username-or-org>` |
| `registry.password` | _(commented out)_ | `KAMAL_REGISTRY_PASSWORD` (secret ref — see section 3) |
| `image` | _(check current value)_ | `ghcr.io/<github-org>/fizzbuzz_app` |
| `proxy.ssl` | _(commented out)_ | `true` |
| `proxy.host` | _(commented out)_ | `fizzbuzz.example.com` |
| `builder.arch` | `amd64` | `amd64` — correct for Hetzner CX32 |

Fields confirmed correct — **do not change**:

| Key | Value | Reason |
|---|---|---|
| `env.clear.SOLID_QUEUE_IN_PUMA` | `true` | Solid Queue runs in-process; no separate job server needed |
| `volumes` | `fizzbuzz_app_storage:/rails/storage` | Persists all 4 SQLite files across deploys (see section 5) |
| `asset_path` | `/rails/public/assets` | Bridges fingerprinted assets during rolling deploy |

---

## 3. Secrets — `.kamal/secrets`

`.kamal/secrets` is **not committed** (already in `.gitignore`). Create or update it:

```sh
# .kamal/secrets
RAILS_MASTER_KEY=$RAILS_MASTER_KEY
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
```

Before running any Kamal command, export these in your shell:

```sh
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD=<your-github-pat>
```

Kamal reads `.kamal/secrets`, substitutes the env vars, and injects `RAILS_MASTER_KEY` into the container at runtime via the `env.secret` key in `deploy.yml`. Confirm `env.secret` includes `RAILS_MASTER_KEY` in the deploy config.

---

## 4. Deploy Steps

### First deploy (server provisioning)

```sh
# 1. Verify DNS resolves to the server
dig +short fizzbuzz.example.com

# 2. Export secrets
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD=<your-github-pat>

# 3. Provision the server: installs Docker, kamal-proxy, creates volume
kamal setup

# 4. Build image, push to ghcr.io, deploy container
kamal deploy
```

### Subsequent deploys

```sh
export RAILS_MASTER_KEY=$(cat config/master.key)
export KAMAL_REGISTRY_PASSWORD=<your-github-pat>
kamal deploy
```

### Post-deploy verification

```sh
# Health check (Kamal proxy liveness endpoint)
curl -I https://fizzbuzz.example.com/up
# Expect: HTTP/2 200

# App smoke test
curl -s https://fizzbuzz.example.com | grep -i fizzbuzz

# Check running containers on the server
kamal details

# Tail application logs
kamal logs
```

**WebSocket / ActionCable test**: Open the app in a browser, trigger a FizzBuzz job, and confirm the results stream to the page via Turbo Streams. This exercises Solid Cable (SQLite-backed polling at 100ms) end to end.

---

## 5. Volume Persistence

The `fizzbuzz_app_storage:/rails/storage` volume in `config/deploy.yml` is **already correct**. No changes needed.

What it does:
- Docker creates a named volume `fizzbuzz_app_storage` on the Hetzner server at first `kamal setup`
- All four SQLite files (`production.sqlite3`, `production_cache.sqlite3`, `production_queue.sqlite3`, `production_cable.sqlite3`) live under `/rails/storage` inside the container, which maps to this volume on the host
- The volume survives container restarts, image updates, and `kamal deploy` cycles — data is never lost during a normal deploy

SQLite WAL mode is enabled by default in Rails 8. With local NVMe on CX32, WAL performance is optimal — reads never block writes, and the four-database split eliminates cross-concern write contention.

**Optional: automated backup** — run [Litestream](https://litestream.io) as a sidecar replicating to Hetzner Object Storage or a Storage Box (~€3.45/mo for 1 TB). Not required for soft launch but recommended before opening to all 130 users.

---

## 6. Open Questions

| Question | Options | Who decides |
|---|---|---|
| **Domain name** | What hostname to put in `proxy.host`? | Human — required before `kamal setup` |
| **GitHub org vs personal account** | Registry image path: `ghcr.io/<org>/fizzbuzz_app` vs `ghcr.io/<username>/fizzbuzz_app` | Human — affects `registry.username` and `image` values |
| **Server region** | Hetzner has EU (Nuremberg, Falkenstein, Helsinki) and US (Ashburn). Pick closest to user base. | Human |
| **Litestream backup** | Add before or after soft launch? Adds ~€3.45/mo. | Human |
| **Fly.io as alternative** | Fly.io is viable (see research doc) but requires `flyctl` instead of `kamal deploy` — the existing `config/deploy.yml` would not be used. Only worth considering if EU latency is a concern and US West region is needed. | Human |
| **Image visibility** | ghcr.io defaults to private for org packages. A private image requires `registry.password` on the server at pull time — Kamal handles this. If the repo is public and the image should be public too, set package visibility to public in GitHub settings (eliminates the need for a pull credential). | Human |

---

*Provider comparison that drove this decision: [`research/hosting-providers.md`](../research/hosting-providers.md)*
