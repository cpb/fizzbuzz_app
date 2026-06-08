# Hosting Providers for Kamal + Rails + Falcon + SQLite (130 Concurrent Users)

**App profile:** Rails 8.1.3 / Ruby 3.3.6, Falcon web server, SQLite3 (4 files in `storage/`), Kamal 2.x deployment, Thruster proxy, async_job in-process. No Redis. Target: ~130 simultaneous users, soft launch.

---

## Summary Comparison Table

| Provider | Kamal Native | SQLite Volumes | Min RAM for 130 users | Est. Monthly Cost | Ops Complexity |
|---|---|---|---|---|---|
| **Fly.io** | Workaround needed | Yes (Fly Volumes) | 2–4 GB | $22–$43/mo | Medium |
| **Render** | No (incompatible) | Yes (Persistent Disk) | 2–4 GB | $25–$80/mo | Low |
| **Railway** | No (incompatible) | Yes (Volumes) | 2–4 GB | $25–$40/mo | Low |
| **Hatchbox** | No (own deployer) | Yes (symlinked shared dir) | 2–4 GB | $10/mo + VPS cost | Low–Med |
| **DigitalOcean Droplet** | Yes (native) | Yes (Block Storage) | 4 GB | $24/mo | Medium |
| **Hetzner** | Yes (native) | Yes (Cloud Volumes) | 4 GB | ~$7–$10/mo | Medium |

---

## 1. Fly.io

**Website:** [fly.io](https://fly.io) | **Pricing:** [fly.io/pricing](https://fly.io/pricing) | **Docs:** [fly.io/docs](https://fly.io/docs)

### SQLite Support
Fly.io supports SQLite on persistent Volumes. You create a volume with `fly volumes create` and mount it in `fly.toml` under `[mounts]` (e.g., `destination = "/data"`). The SQLite files must live on the mount path rather than in the container image. Fly snapshots volumes once daily, retaining up to 5 days. Volumes cost **$0.15/GB/month**; snapshot storage is **$0.08/GB/month** (first 10 GB free).

**Critical constraint:** Fly Volumes are pinned to a single host. Applications using SQLite on a Fly Volume cannot be deployed to multiple regions or scaled to multiple instances. Single-machine deployment is required (`fly launch --ha=false`).

### Kamal Compatibility
Kamal is designed to SSH into servers as root and run Docker commands directly. Fly.io does not expose root SSH access to the underlying VM in the standard Machines API workflow. Fly.io has documented how to [run an OpenSSH server inside a Machine](https://fly.io/docs/blueprints/opensshd/) as a workaround, but this is non-trivial and adds operational surface area. The more common pattern is to use Fly's own `fly deploy` toolchain (which also reads your Dockerfile). Fly.io and Kamal can share the same `Dockerfile` and coexist in the same repo, but Kamal is not the deploy mechanism when targeting Fly — `flyctl` is.

### Pricing (as of 2025)
- `shared-cpu-2x` + 4 GB RAM: ~$22/mo
- `performance-1x` (dedicated) + 4 GB RAM: ~$43/mo
- Persistent volume (10 GB): ~$1.50/mo
- Outbound bandwidth: $0.02/GB (North America/Europe)
- IPv4 address: $2/mo

A 40% discount is available when reserving compute blocks annually.

### Falcon Support
No known platform-level issues with Falcon. Fly routes external HTTPS traffic to your container's port; Falcon listens on that port. Thruster (Kamal's proxy) may conflict with Fly's built-in Anycast proxy — one proxy layer is typically sufficient.

### Persistent Storage Durability
Volumes are stored on NVMe SSDs local to a Fly host. Daily snapshots are automated. There is no cross-region replication for volumes. Durability depends on Fly's host hardware; it is not equivalent to a managed database service.

### Deployment Simplicity
1. Install `flyctl`, authenticate
2. `fly launch --ha=false` (picks up Dockerfile)
3. `fly volumes create` and update `fly.toml`
4. `fly deploy`

Approximately 4–6 steps from zero. Fly's Rails-specific [guide for SQLite](https://fly.io/docs/rails/advanced-guides/sqlite3/) is well-maintained.

### SQLite WAL + I/O Characteristics
Fly Volumes use local NVMe, which is fast for WAL-mode SQLite. Because only one instance can mount a volume, there are no concurrent-write cross-host issues. I/O latency is low and consistent for single-machine workloads.

---

## 2. Render

**Website:** [render.com](https://render.com) | **Pricing:** [render.com/pricing](https://render.com/pricing) | **Persistent Disks:** [render.com/docs/disks](https://render.com/docs/disks)

### SQLite Support
Render supports persistent disks that can be attached to a paid web service. The disk is mounted at a path you specify (e.g., `/data`), and SQLite files stored there survive deploys and restarts. Persistent disk storage costs **$0.25/GB/month**.

**Constraint:** A service can only be scaled to one instance when using a persistent disk (same single-instance limitation as Fly Volumes for SQLite).

### Kamal Compatibility
**Incompatible.** Render is a managed PaaS. It does not provide SSH root access to the underlying server infrastructure. Kamal requires direct SSH access to run `docker` commands on the target machine. Render handles container orchestration internally; you push code or a Docker image via Render's own build and deploy pipeline, not via Kamal.

### Pricing (as of 2025)
- Starter: $7/mo — 512 MB RAM, 0.5 CPU (too small for 130 users)
- Standard: $25/mo — 2 GB RAM, 1 CPU
- Pro: $80/mo — 4 GB RAM, 2 CPUs
- Persistent disk (10 GB): $2.50/mo
- Outbound bandwidth metered above plan allowance

### Falcon Support
No known Render-level issues with Falcon. Render routes traffic to your container's `PORT` environment variable. Falcon binds to that port. Thruster is unnecessary on Render since Render provides its own HTTPS termination.

### Persistent Storage Durability
Render disks are network-attached SSD volumes. Render does not document explicit replication; backup is manual (download or rsync). Disk persistence survives deploys and restarts but not disk hardware failure without user-initiated backup.

### Deployment Simplicity
1. Connect GitHub repo on Render dashboard
2. Set environment variables
3. Configure persistent disk path
4. Push to deploy (Render builds from Dockerfile automatically)

Approximately 3–5 steps. No CLI required for initial deploy.

### SQLite WAL + I/O Characteristics
Render disks are network-attached rather than local NVMe. Network-attached storage introduces higher and more variable I/O latency compared to local disk. For a write-light Rails app, this is unlikely to be a bottleneck, but WAL checkpoint and vacuum operations may be slower than on local-disk providers.

---

## 3. Railway

**Website:** [railway.com](https://railway.com) | **Pricing:** [railway.com/pricing](https://railway.com/pricing) | **Volumes:** [docs.railway.com/volumes/reference](https://docs.railway.com/volumes/reference)

### SQLite Support
Railway supports persistent volumes that mount into your container at a specified path. Volumes are billed at **$0.25/GB/month** based on used storage. Volume resizing is available on Hobby and Pro plans with zero-downtime live resize.

**Note:** Docker images that run as a non-root UID may have permission issues on mounted volumes. The `RAILWAY_RUN_UID=0` environment variable resolves this.

### Kamal Compatibility
**Incompatible.** Railway is a fully managed PaaS with no SSH access to the underlying infrastructure. You cannot SSH into Railway machines or install Docker tooling. Kamal's deployment model (SSH + Docker on a provisioned server) does not apply. Railway uses Railpack or your `Dockerfile` for builds; deployment is triggered via git push or Railway's CLI, not Kamal.

### Pricing (as of 2025)
Railway uses usage-based billing on top of a plan subscription:
- Hobby plan: $5/mo base + usage
- RAM: $0.000231/GB/minute (~$10/GB/month continuously)
- CPU: $0.000463/vCPU/minute
- Storage: $0.25/GB/month
- Egress: $0.10/GB

For a service using ~2 GB RAM continuously: ~$20–25/mo total. For 4 GB RAM: ~$45–50/mo.

### Falcon Support
No known Railway-level issues with Falcon. Railway routes traffic to the port defined by `PORT`. Thruster is redundant with Railway's HTTPS termination layer.

### Persistent Storage Durability
Railway volumes are network-attached. Railway does not publish specific SLA or replication details for volume storage. Manual backup via the Railway CLI or scheduled jobs is the primary option.

### Deployment Simplicity
1. Connect GitHub on Railway dashboard or use `railway init`
2. Configure environment variables
3. Attach a volume, set mount path
4. `git push` or `railway up`

Approximately 3–5 steps. Railway's developer experience is polished.

### SQLite WAL + I/O Characteristics
Network-attached storage (same caveat as Render). For a read-heavy or mixed workload at 130 users, the I/O overhead is unlikely to be limiting, but local-disk providers (Hetzner, DigitalOcean) will outperform Railway on raw SQLite write throughput.

---

## 4. Hatchbox

**Website:** [hatchbox.io](https://hatchbox.io) | **SQLite docs:** [hatchbox.relationkit.io](https://hatchbox.relationkit.io/articles/75-can-i-use-sqlite-databases)

### SQLite Support
Hatchbox explicitly supports SQLite. The database files are stored in the application's `shared/` directory on the VPS, which Hatchbox symlinks into each release (Capistrano-style). Files persist across deploys because `shared/` is on the host filesystem, not in a container.

### Kamal Compatibility
**Not applicable — Hatchbox is an alternative to Kamal, not a Kamal target.** Hatchbox is its own Rails deployment manager. It connects to your VPS (DigitalOcean, Hetzner, Linode, etc.) and configures Nginx, Passenger or Puma, and SSL via its own tooling. It does not use Docker or Kamal internally. Choosing Hatchbox means not using the existing `config/deploy.yml`. Hatchbox costs **$10/mo per managed server**.

### Pricing (as of 2025)
- Hatchbox fee: $10/mo per server (unlimited apps per server)
- VPS cost: separate (e.g., Hetzner CX32 ~$7/mo, DigitalOcean 4 GB ~$24/mo)
- Total for Hetzner + Hatchbox: ~$17/mo

### Falcon Support
**Potentially incompatible.** Hatchbox configures Puma or Passenger by default for Rails apps. There is no documented Hatchbox support for Falcon. Using Falcon would require custom configuration outside of Hatchbox's managed setup.

### Persistent Storage Durability
Durability depends on the underlying VPS provider. Hatchbox's symlinked `shared/` directory lives on the host disk. Automated backup must be configured independently (cron + rsync, Litestream, or provider snapshots).

### Deployment Simplicity
1. Sign up for Hatchbox, connect VPS via SSH key
2. Hatchbox provisions the server (Nginx, rbenv, etc.)
3. Connect GitHub repo, configure environment
4. Deploy from Hatchbox dashboard or `git push`

Approximately 4–6 steps, with less server configuration knowledge required than raw Kamal.

### SQLite WAL + I/O Characteristics
Files live directly on the VPS local disk (no container abstraction). This is the highest-performance SQLite configuration of the six providers for local-disk VPS options — local NVMe or SSD with no network-storage overhead.

---

## 5. DigitalOcean Droplet

**Website:** [digitalocean.com](https://www.digitalocean.com) | **Pricing:** [digitalocean.com/pricing/droplets](https://www.digitalocean.com/pricing/droplets) | **Block Storage:** [digitalocean.com/products/block-storage](https://www.digitalocean.com/products/block-storage)

### SQLite Support
Full support. SQLite files are stored directly on the Droplet's local disk, or on a separately attached Block Storage volume. For a single-machine deployment, the local disk in `storage/` (mounted as a Kamal Docker volume) requires no additional configuration. DigitalOcean Block Storage volumes are available at **$0.10/GB/month**.

### Kamal Compatibility
**Native and well-documented.** DigitalOcean Droplets are the most commonly documented Kamal deployment target. Kamal connects via SSH to the Droplet (root or a sudo user), installs Docker if missing, and manages container lifecycle. Multiple tutorials and community resources exist for this exact combination. The `config/deploy.yml` server IP simply points at the Droplet's public IP.

### Pricing (as of 2025)
- Basic 2 vCPU, 4 GB RAM: **$24/mo**
- General Purpose 2 vCPU, 8 GB RAM: **$63/mo**
- Block Storage (10 GB): **$1/mo**
- Outbound bandwidth: 4 TB included, then $0.01/GB
- Automated Droplet backups: 20% of Droplet cost (weekly snapshots, 4 retained)

### Falcon Support
No platform-level issues. The Droplet is a plain Ubuntu (or other Linux) server. Falcon runs as the Rack server inside your Docker container; Thruster handles HTTPS termination at the container edge.

### Persistent Storage Durability
Local disk is tied to the Droplet. If the Droplet is destroyed, data is lost unless backed up. Block Storage volumes are independent of the Droplet lifecycle and can be re-attached to a new Droplet. DigitalOcean Spaces (S3-compatible) can be used for Litestream SQLite backups.

### Deployment Simplicity
1. Create Droplet (Ubuntu 22.04/24.04), copy SSH key
2. Set server IP in `config/deploy.yml`
3. Configure Docker registry credentials
4. `kamal setup && kamal deploy`

Approximately 4–5 steps. The most direct path for a project with Kamal already configured.

### SQLite WAL + I/O Characteristics
Local NVMe SSD on all current Droplet tiers. SQLite WAL mode performs well; concurrent reads are non-blocking. At 130 users, I/O is unlikely to be the bottleneck. Block Storage volumes are network-attached (higher latency than local disk) — local Droplet disk is preferable for SQLite on a single Droplet.

---

## 6. Hetzner

**Website:** [hetzner.com/cloud](https://www.hetzner.com/cloud) | **Pricing:** [hetzner.com/cloud/regular-performance](https://www.hetzner.com/cloud/regular-performance) | **Volumes:** [docs.hetzner.com/cloud/volumes](https://docs.hetzner.com/cloud/volumes)

### SQLite Support
Full support. SQLite files are stored on the Hetzner Cloud Server's local disk or on a separately attached Hetzner Volume (block storage). Hetzner Volumes behave as standard block devices, mountable at any path. For a Kamal deployment, mounting `./storage` as a Docker volume to the host filesystem (`/data/storage:/rails/storage`) is the standard pattern.

### Kamal Compatibility
**Native — the most popular community-documented Kamal target.** Hetzner is consistently cited as the default recommendation for Kamal deployments in the Rails community. Multiple comprehensive tutorials exist: the [Hetzner Community tutorial](https://community.hetzner.com/tutorials/deploy-rails-8-app-on-hetzner-with-kamal/) and numerous blog posts cover zero-downtime deploys, Let's Encrypt SSL, and production hardening.

### Pricing (as of 2025, EUR; ~USD parity)
- CX22: 2 vCPU, 4 GB RAM, 40 GB disk, 20 TB traffic — **€3.79/mo**
- CX32: 4 vCPU, 8 GB RAM, 80 GB disk, 20 TB traffic — **€6.80/mo**
- Cloud Volume (10 GB): €0.044/GB/mo (~€0.44/mo)
- Snapshots: €0.011/GB/mo
- Automated backups (up to 7): 20% of server cost
- Storage Box (1 TB, for Litestream offsite backup): ~€3.45/mo

Note: Verify current rates at [hetzner.com/cloud](https://www.hetzner.com/cloud) as prices can change.

### Falcon Support
No platform-level issues. Hetzner servers run standard Linux; Docker containers run without restriction. Falcon inside a Docker container functions identically to any other Linux VPS.

### Persistent Storage Durability
Local disk is tied to the server instance. Hetzner Cloud Volumes are network-attached SSD storage independent of the server lifecycle. Hetzner provides automated server backups (up to 7 retained) and snapshot capabilities. For SQLite, [Litestream](https://litestream.io) replicating to Hetzner Object Storage or a Storage Box is a common and well-documented pattern in the Hetzner + Rails community.

### Deployment Simplicity
1. Create CX22/CX32 server, add SSH key in Hetzner Cloud Console
2. Set server IP in `config/deploy.yml`
3. Configure Docker registry credentials
4. `kamal setup && kamal deploy`

Same 4–5 step flow as DigitalOcean, at significantly lower cost. Hetzner's data centers are in Europe (Nuremberg, Falkenstein, Helsinki) and the US (Ashburn, Virginia) — consider latency relative to your user base.

### SQLite WAL + I/O Characteristics
Local NVMe storage on all CX-series instances. This is the highest raw I/O performance tier of the compared providers at the given price point. Hetzner Volumes are network-attached (higher latency); for SQLite WAL performance, using local disk with host-path Docker volume mounts is recommended over Hetzner Volumes. A CX32 (4 vCPU, 8 GB) provides headroom for 130 concurrent users with Falcon's fiber-based concurrency model.

---

## Notes on Sizing for 130 Concurrent Users

Falcon handles concurrency via lightweight fibers within a single process. Each active fiber holds a Rack env, ActiveRecord connection, and per-request state. For a Rails app with SQLite:

- At 130 concurrent users, memory pressure depends on response complexity and query result sizes, not raw thread count.
- A rough baseline: 256–512 MB per worker process × WEB_CONCURRENCY workers. A single-process Falcon deployment with 2–4 GB RAM is the typical starting point.
- The ActiveRecord connection pool size should match Falcon's concurrency; with SQLite WAL mode, reads are concurrent and only writes serialize.
- SQLite WAL mode (`pragma journal_mode=WAL`) is required for any meaningful concurrency. Rails 8 enables this by default.
- The 4 SQLite files (primary, cache, queue, cable) all write independently, reducing write contention compared to a single database file.

---

*Pricing verified from provider documentation as of 2025–2026. Check provider pricing pages directly before committing, as rates change.*

---

## Sources

- [Fly.io Resource Pricing](https://fly.io/docs/about/pricing/)
- [Fly.io SQLite on Rails](https://fly.io/docs/rails/advanced-guides/sqlite3/)
- [Fly.io Volumes Overview](https://fly.io/docs/volumes/overview/)
- [Render Pricing](https://render.com/pricing)
- [Render Persistent Disks](https://render.com/docs/disks)
- [Railway Pricing](https://railway.com/pricing)
- [Railway Volumes Reference](https://docs.railway.com/volumes/reference)
- [Hatchbox SQLite docs](https://hatchbox.relationkit.io/articles/75-can-i-use-sqlite-databases)
- [DigitalOcean Droplet Pricing](https://www.digitalocean.com/pricing/droplets)
- [Hetzner Cloud Regular Performance](https://www.hetzner.com/cloud/regular-performance)
- [Hetzner Cloud Volumes](https://docs.hetzner.com/cloud/volumes/)
- [Hetzner Community: Deploy Rails 8 with Kamal](https://community.hetzner.com/tutorials/deploy-rails-8-app-on-hetzner-with-kamal/)
- [Falcon Rails Integration](https://socketry.github.io/falcon/guides/rails-integration/index.html)
- [Kamal deploy.org](https://kamal-deploy.org/)
- [Kamal vs PaaS — JudoScale](https://judoscale.com/blog/kamal-vs-paas)
