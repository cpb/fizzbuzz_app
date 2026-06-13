# Plan: Create packs/links and packs/fizzbuzz

**Decision:** Move domain files into packs using `git mv`, keeping all tests,
fixtures, cassettes, and evals at the Rails root. Resolve the one cross-domain
dependency by moving `QrCodeGenerator` to root before creating the packs.

**Rationale:** No source-code constant changes are needed because Zeitwerk is
configured to add each `packs/*/app/<layer>/` directory as an autoload root
(not the pack's `app/` directory as a whole). Tests stay at root because
Packwerk doesn't analyze test files and moving them adds complexity without
benefit. `QrCodeGenerator` moves to root because it's a generic utility used
by both domains — making fizzbuzz depend on links just for QR generation would
create an architecturally odd dependency.

See: [directory-layout.md](../research/pack-conventions/directory-layout.md),
[file-movement-strategy.md](../research/migration-path/file-movement-strategy.md),
[cross-domain-dependencies.md](../research/domain-inventory/cross-domain-dependencies.md)

---

## Steps

### Step A: Resolve the cross-domain dependency

Move `QrCodeGenerator` from the links domain to app root (shared utility):

```sh
# No git mv needed — file stays at app/models/qr_code_generator.rb
# It was classified as links-domain but is actually a generic utility.
# No file movement or code changes required.
```

`QrCodeGenerator` is already at `app/models/qr_code_generator.rb` — it stays
there. When `packs/links` is created without `qr_code_generator.rb`, that file
remains at the root package level and is freely accessible to all packs.

Verify:
```sh
grep -r "QrCodeGenerator" app/views/fizz_buzz/   # should find _survey_qr.html.erb
grep -r "QrCodeGenerator" app/views/links/       # should find _qr_code.html.erb
```

Both views reference `QrCodeGenerator` from root — no changes needed in either view.

### Step B: Create packs/links

```sh
mkdir -p packs/links/app/{controllers,jobs,models,views}

git mv app/controllers/links_controller.rb  packs/links/app/controllers/
git mv app/jobs/publish_gist_job.rb         packs/links/app/jobs/
git mv app/models/link.rb                   packs/links/app/models/
git mv app/models/gist.rb                   packs/links/app/models/
git mv app/models/gist_publisher.rb         packs/links/app/models/
git mv app/views/links                      packs/links/app/views/
```

Verify the app boots and tests pass:
```sh
bin/rails zeitwerk:check
bin/rails test
```

Create `packs/links/package.yml`:
```yaml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - "."
```

Run packwerk check:
```sh
bin/packwerk validate
bin/packwerk check
```

Expected: zero violations.

Commit:
```sh
git add packs/links/ app/
git commit -m "refactor: create packs/links with models, controller, job, and views"
```

### Step C: Create packs/fizzbuzz

```sh
mkdir -p packs/fizzbuzz/app/{controllers,jobs,models,views,helpers/ruby_llm/evals}

git mv app/controllers/fizz_buzz_controller.rb  packs/fizzbuzz/app/controllers/
git mv app/jobs/fizz_buzz_job.rb                packs/fizzbuzz/app/jobs/
git mv app/jobs/llm_fizz_buzz_job.rb            packs/fizzbuzz/app/jobs/
git mv app/models/fizz_buzzer.rb                packs/fizzbuzz/app/models/
git mv app/models/llm_fizz_buzzer.rb            packs/fizzbuzz/app/models/
git mv app/views/fizz_buzz                      packs/fizzbuzz/app/views/
git mv app/helpers/ruby_llm/evals/runs_helper.rb packs/fizzbuzz/app/helpers/ruby_llm/evals/
```

Verify the app boots and tests pass:
```sh
bin/rails zeitwerk:check
bin/rails test
```

Create `packs/fizzbuzz/package.yml`:
```yaml
enforce_dependencies: true
enforce_privacy: true
dependencies:
  - "."
```

Run packwerk check:
```sh
bin/packwerk validate
bin/packwerk check
```

Expected: zero violations.

Commit:
```sh
git add packs/fizzbuzz/ app/
git commit -m "refactor: create packs/fizzbuzz with models, controllers, jobs, and views"
```

---

## Files That Move

### packs/links

| From | To |
|------|----|
| `app/controllers/links_controller.rb` | `packs/links/app/controllers/` |
| `app/jobs/publish_gist_job.rb` | `packs/links/app/jobs/` |
| `app/models/link.rb` | `packs/links/app/models/` |
| `app/models/gist.rb` | `packs/links/app/models/` |
| `app/models/gist_publisher.rb` | `packs/links/app/models/` |
| `app/views/links/` | `packs/links/app/views/links/` |

### packs/fizzbuzz

| From | To |
|------|----|
| `app/controllers/fizz_buzz_controller.rb` | `packs/fizzbuzz/app/controllers/` |
| `app/jobs/fizz_buzz_job.rb` | `packs/fizzbuzz/app/jobs/` |
| `app/jobs/llm_fizz_buzz_job.rb` | `packs/fizzbuzz/app/jobs/` |
| `app/models/fizz_buzzer.rb` | `packs/fizzbuzz/app/models/` |
| `app/models/llm_fizz_buzzer.rb` | `packs/fizzbuzz/app/models/` |
| `app/views/fizz_buzz/` | `packs/fizzbuzz/app/views/fizz_buzz/` |
| `app/helpers/ruby_llm/evals/runs_helper.rb` | `packs/fizzbuzz/app/helpers/ruby_llm/evals/` |

### Stays at Root

| File | Reason |
|------|--------|
| `app/models/qr_code_generator.rb` | Shared utility (used by both domains) |
| `app/models/survey_response.rb` | Surveys domain (not packed this issue) |
| `app/controllers/surveys_controller.rb` | Surveys domain |
| `app/views/surveys/` | Surveys domain |
| `app/views/ruby_llm/evals/runs/` | Engine views — check if engine expects root path |

---

## Open Questions

1. **Engine views**: `app/views/ruby_llm/evals/runs/` — the `ruby_llm-evals`
   Engine may look for its views at engine-relative paths, not the host app.
   If so, moving these views to `packs/fizzbuzz/app/views/ruby_llm/evals/runs/`
   may break the engine's view resolution. Verify with `bin/rails routes` and
   a manual visit to `/evals`. If broken, keep those views at root.

2. **Helper loading**: After moving `runs_helper.rb` to the fizzbuzz pack,
   confirm the helper is still found by running the evals-related helper tests.

## Verification

- `bin/rails zeitwerk:check` exits 0 after each step
- `bin/rails test` passes after each step (models, controllers, jobs, system)
- `bin/packwerk validate` exits 0 after each step
- `bin/packwerk check` exits 0 with "No violations detected." after each step
