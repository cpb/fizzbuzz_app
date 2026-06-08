# 02 — CI/CD Pipeline

> Status: plan — no workflow files exist yet (other than the upstream Rails scaffold `ci.yml` and `claude.yml`).

---

## Decision: GitHub Actions

GitHub Actions is the right choice:

- Free for public repos; zero infra to maintain.
- `GITHUB_TOKEN` has built-in write access to `ghcr.io` — no extra registry credentials during the build step.
- Native integration with `gh` CLI, PR checks, and the existing `claude.yml` workflow.
- Kamal 2 requires only SSH access and a Docker registry; both are straightforward to wire from an Actions runner.

---

## Current state of `ci.yml`

`.github/workflows/ci.yml` already exists (Rails scaffold). It runs on every push/PR and covers:

| Job | What it does |
|---|---|
| `scan_ruby` | Brakeman + Bundler Audit |
| `scan_js` | `bin/importmap audit` |
| `lint` | `hk check --all` (RuboCop via `hk`) with RuboCop result cache |
| `test` | `bin/rails db:test:prepare test` (unit + integration) |
| `system-test` | `bin/rails db:test:prepare test:system` (Capybara/Selenium); uploads screenshots on failure |

Two gaps relative to this plan's requirements:

1. The `on.push.branches` value is `master` — needs to be updated to `main`.
2. No `deploy.yml` exists yet.

---

## Required changes to `ci.yml`

```yaml
# .github/workflows/ci.yml — change one line
on:
  pull_request:
  push:
    branches: [ main ]   # was: master
```

No other changes needed. The existing jobs are already correct for this stack (SQLite needs no service container; `libvips` is already installed for Active Storage).

---

## New workflow: `deploy.yml`

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    name: Deploy to production
    runs-on: ubuntu-latest
    needs: []        # CI runs in parallel; gate is enforced by branch protection (see below)
    environment: production

    permissions:
      contents: read
      packages: write   # push to ghcr.io

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to ghcr.io
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Set up SSH agent
        uses: webfactory/ssh-agent@v0.9.0
        with:
          ssh-private-key: ${{ secrets.DEPLOY_SSH_PRIVATE_KEY }}

      - name: Add production server to known_hosts
        run: |
          ssh-keyscan -H ${{ secrets.DEPLOY_HOST }} >> ~/.ssh/known_hosts

      - name: Deploy with Kamal
        env:
          RAILS_MASTER_KEY: ${{ secrets.RAILS_MASTER_KEY }}
          KAMAL_REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
        run: bundle exec kamal deploy
```

### Why no explicit `needs: [ci]`?

The cleanest gate is a **branch protection rule** on `main` requiring all CI checks to pass before a push is accepted. That means by the time `deploy.yml` triggers, CI already passed. If you prefer to keep both workflows in the same push event and have deploy wait explicitly, add a `needs` reference instead — but that couples the two workflows and complicates manual deploys.

---

## GitHub Secrets required

| Secret | Where set | Value |
|---|---|---|
| `RAILS_MASTER_KEY` | Repo → Settings → Secrets | Contents of `config/master.key` (never committed) |
| `DEPLOY_SSH_PRIVATE_KEY` | Repo → Settings → Secrets | Private key whose public half is in the server's `authorized_keys` |
| `DEPLOY_HOST` | Repo → Settings → Secrets (or Variables) | IP or hostname of the production server |
| `KAMAL_REGISTRY_PASSWORD` | Not a stored secret — use `${{ secrets.GITHUB_TOKEN }}` at deploy time | Automatically provided by Actions; no manual setup |

`GITHUB_TOKEN` is injected automatically by Actions and has `packages: write` when granted in the job's `permissions` block. No manual token creation needed for the registry.

---

## Kamal + GitHub Actions: SSH setup

Kamal SSHes from the Actions runner into the production server to run `docker pull` / `docker run`. The runner's IP is not fixed, so the server must trust the deploy key (not a specific source IP).

**One-time setup steps:**

1. Generate a dedicated deploy keypair (do not reuse your personal key):
   ```sh
   ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/fizzbuzz_deploy -N ""
   ```
2. Copy the public key to the server:
   ```sh
   ssh-copy-id -i ~/.ssh/fizzbuzz_deploy.pub user@<production-host>
   ```
   Or append manually to `/home/deploy/.ssh/authorized_keys`.
3. Store the private key (`fizzbuzz_deploy`) as the `DEPLOY_SSH_PRIVATE_KEY` Actions secret.
4. Delete the local private key after storing it (it lives only in Actions Secrets and on the server it authenticates against).

Kamal reads SSH credentials from the environment. `webfactory/ssh-agent` loads the key into `ssh-agent` before Kamal runs, so no additional Kamal SSH config is needed.

---

## `config/deploy.yml` values needed before first deploy

The research document (`system-as-built.md §8`) lists these as placeholder:

| Key | Required value |
|---|---|
| `servers.web` | Real server IP / hostname |
| `registry.server` | `ghcr.io` |
| `registry.username` | GitHub org or username (e.g. `ghcr.io/<org>/fizzbuzz_app`) |
| `registry.password` | Reference `.kamal/secrets` → `KAMAL_REGISTRY_PASSWORD` |
| `proxy.ssl` | Uncomment; set `domain:` to the real hostname |
| `builder.arch` | `amd64` if the server is x86; `arm64` if it is ARM |

The `image:` key should be `ghcr.io/<org>/fizzbuzz_app` to match the registry.

---

## Branch protection recommendation

On `main`, require:

- All four CI jobs to pass: `scan_ruby`, `scan_js`, `lint`, `test`
- (Optional) `system-test` — Capybara/Selenium adds ~2 min; worthwhile for a production branch gate
- No direct pushes — PRs only

This ensures every commit that triggers `deploy.yml` has already passed CI.

---

## Open questions

| # | Question | Impact |
|---|---|---|
| 1 | What user/org owns the ghcr.io namespace? (`ghcr.io/<org>/fizzbuzz_app`) | Must be set in `config/deploy.yml` `image:` and `registry.username` before first deploy |
| 2 | Is the production server ARM or x86? | `builder.arch` in `config/deploy.yml` |
| 3 | What SSH user does Kamal connect as? (`deploy`, `ubuntu`, `root`?) | Affects `authorized_keys` path and `.kamal/secrets` `SSH_*` vars |
| 4 | Should `system-test` be a required CI gate? | Adds ~2 min to the PR feedback loop; Selenium headless works fine on `ubuntu-latest` |
| 5 | Single environment (`production`) or separate staging? | Out of scope for the 130-user soft launch, but worth noting for future |
