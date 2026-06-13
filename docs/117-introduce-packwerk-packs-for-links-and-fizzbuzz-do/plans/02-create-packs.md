# Plan: Create packs/links and packs/fizzbuzz

**Decision:** Move domain files (source + tests) into packs using `git mv`.
Resolve the one cross-domain dependency by keeping `QrCodeGenerator` at root.
Tests move with their domain. Fixtures, cassettes, and evals infrastructure
stay at root.

**Rationale:** No source-code constant changes are needed because Zeitwerk adds
each `packs/*/app/<layer>/` directory as an autoload root. Tests move to
co-locate ownership but do not affect Packwerk boundary enforcement (Packwerk
ignores test files). `QrCodeGenerator` stays at root because it's a generic
utility used by both domains.

See: [directory-layout.md](../research/pack-conventions/directory-layout.md),
[file-movement-strategy.md](../research/migration-path/file-movement-strategy.md),
[test-path-changes.md](../research/migration-path/test-path-changes.md),
[cross-domain-dependencies.md](../research/domain-inventory/cross-domain-dependencies.md)

---

## Pack Dependency Diagram

The intended dependency graph after this plan completes:

```mermaid
graph TD
    subgraph utility["Layer: utility (root package)"]
        Root["Rails Root\nApplicationController · ApplicationRecord\nApplicationJob · QrCodeGenerator\nSurveysController · SurveyResponse"]
    end

    subgraph feature["Layer: feature (packs)"]
        Links["packs/links\nLinksController\nLink · Gist · GistPublisher\nPublishGistJob\nviews/links/"]
        FizzBuzz["packs/fizzbuzz\nFizzBuzzController\nFizzBuzzer · LLMFizzBuzzer\nFizzBuzzJob · LLMFizzBuzzJob\nviews/fizz_buzz/"]
    end

    Links -->|"depends on (.)"| Root
    FizzBuzz -->|"depends on (.)"| Root

    style Root fill:#e8f4f8,stroke:#0077b6
    style Links fill:#e8f8e8,stroke:#2d6a2d
    style FizzBuzz fill:#fff3e0,stroke:#e65100
```

**Key properties:**
- No inter-pack dependencies (fizzbuzz ↔ links)
- Both feature packs depend only on the root utility layer
- Root utility layer has no pack dependencies (surveys + infrastructure only)
- Layer enforcement: feature packs CAN depend on utility; utility CANNOT depend on feature

---

## Steps

### Step A: Resolve the cross-domain dependency

`QrCodeGenerator` is already at `app/models/qr_code_generator.rb` — it
**stays there**. When `packs/links` is created without `qr_code_generator.rb`,
that file remains in the root package and is accessible to all packs (root has
`enforce_privacy: false`).

Verify both views reference it cleanly:
```sh
grep -r "QrCodeGenerator" app/views/fizz_buzz/  # found in _survey_qr.html.erb
grep -r "QrCodeGenerator" app/views/links/       # found in _qr_code.html.erb
```

No code changes needed.

### Step B: Create packs/links

#### B1 — Move source files

```sh
mkdir -p packs/links/app/{controllers,jobs,models,views}

git mv app/controllers/links_controller.rb  packs/links/app/controllers/
git mv app/jobs/publish_gist_job.rb         packs/links/app/jobs/
git mv app/models/link.rb                   packs/links/app/models/
git mv app/models/gist.rb                   packs/links/app/models/
git mv app/models/gist_publisher.rb         packs/links/app/models/
git mv app/views/links                      packs/links/app/views/
```

#### B2 — Move tests

```sh
mkdir -p packs/links/test/{controllers,jobs,models,system}

git mv test/controllers/links_controller_test.rb  packs/links/test/controllers/
git mv test/jobs/publish_gist_job_test.rb         packs/links/test/jobs/
git mv test/models/link_test.rb                   packs/links/test/models/
git mv test/models/gist_test.rb                   packs/links/test/models/
git mv test/models/gist_publisher_test.rb         packs/links/test/models/
git mv test/models/qr_code_generator_test.rb      packs/links/test/models/
git mv test/system/links_test.rb                  packs/links/test/system/
```

Update `require` lines in moved test files. Change any `require_relative`
paths that reference `test_helper` to:
```ruby
require "test_helper"
```

Rails adds `test/` to the load path during test runs, so `require "test_helper"`
resolves regardless of the test file's location.

#### B3 — Add package.yml

```yaml
# packs/links/package.yml
enforce_dependencies: true
enforce_privacy: true
enforce_layers: true
layer: feature
dependencies:
  - "."
```

#### B4 — Verify

```sh
bin/rails zeitwerk:check
bin/rails test
bin/packwerk validate
bin/packwerk check
```

Expected: all green, zero violations.

#### B5 — Commit

```sh
git add packs/links/ app/ test/
git commit -m "refactor: create packs/links — move models, controller, job, views, and tests"
```

---

### Step C: Create packs/fizzbuzz

#### C1 — Move source files

```sh
mkdir -p packs/fizzbuzz/app/{controllers,helpers/ruby_llm/evals,jobs,models,views}

git mv app/controllers/fizz_buzz_controller.rb   packs/fizzbuzz/app/controllers/
git mv app/jobs/fizz_buzz_job.rb                 packs/fizzbuzz/app/jobs/
git mv app/jobs/llm_fizz_buzz_job.rb             packs/fizzbuzz/app/jobs/
git mv app/models/fizz_buzzer.rb                 packs/fizzbuzz/app/models/
git mv app/models/llm_fizz_buzzer.rb             packs/fizzbuzz/app/models/
git mv app/views/fizz_buzz                       packs/fizzbuzz/app/views/
git mv app/helpers/ruby_llm/evals/runs_helper.rb packs/fizzbuzz/app/helpers/ruby_llm/evals/
```

#### C2 — Move tests

```sh
mkdir -p packs/fizzbuzz/test/{controllers,jobs,models,system}

git mv test/controllers/fizz_buzz_controller_test.rb  packs/fizzbuzz/test/controllers/
git mv test/jobs/fizz_buzz_job_test.rb                packs/fizzbuzz/test/jobs/
git mv test/jobs/llm_fizz_buzz_job_test.rb            packs/fizzbuzz/test/jobs/
git mv test/models/fizz_buzzer_test.rb                packs/fizzbuzz/test/models/
git mv test/models/llm_fizz_buzzer_test.rb            packs/fizzbuzz/test/models/
git mv test/system/fizz_buzz_test.rb                  packs/fizzbuzz/test/system/
```

Update `require "test_helper"` as in Step B2.

Note: `test/evals/` tests, `test/helpers/`, `test/configuration/`, and
`test/support/` stay at root — see [test-path-changes.md](../research/migration-path/test-path-changes.md).

#### C3 — Add package.yml

```yaml
# packs/fizzbuzz/package.yml
enforce_dependencies: true
enforce_privacy: true
enforce_layers: true
layer: feature
dependencies:
  - "."
```

#### C4 — Verify

```sh
bin/rails zeitwerk:check
bin/rails test
bin/packwerk validate
bin/packwerk check
```

Expected: all green, zero violations.

#### C5 — Commit

```sh
git add packs/fizzbuzz/ app/ test/
git commit -m "refactor: create packs/fizzbuzz — move models, controllers, jobs, views, and tests"
```

---

## Files That Move

### packs/links (source)

| From | To |
|------|----|
| `app/controllers/links_controller.rb` | `packs/links/app/controllers/` |
| `app/jobs/publish_gist_job.rb` | `packs/links/app/jobs/` |
| `app/models/link.rb` | `packs/links/app/models/` |
| `app/models/gist.rb` | `packs/links/app/models/` |
| `app/models/gist_publisher.rb` | `packs/links/app/models/` |
| `app/views/links/` | `packs/links/app/views/links/` |

### packs/links (tests)

| From | To |
|------|----|
| `test/controllers/links_controller_test.rb` | `packs/links/test/controllers/` |
| `test/jobs/publish_gist_job_test.rb` | `packs/links/test/jobs/` |
| `test/models/link_test.rb` | `packs/links/test/models/` |
| `test/models/gist_test.rb` | `packs/links/test/models/` |
| `test/models/gist_publisher_test.rb` | `packs/links/test/models/` |
| `test/models/qr_code_generator_test.rb` | `packs/links/test/models/` |
| `test/system/links_test.rb` | `packs/links/test/system/` |

### packs/fizzbuzz (source)

| From | To |
|------|----|
| `app/controllers/fizz_buzz_controller.rb` | `packs/fizzbuzz/app/controllers/` |
| `app/jobs/fizz_buzz_job.rb` | `packs/fizzbuzz/app/jobs/` |
| `app/jobs/llm_fizz_buzz_job.rb` | `packs/fizzbuzz/app/jobs/` |
| `app/models/fizz_buzzer.rb` | `packs/fizzbuzz/app/models/` |
| `app/models/llm_fizz_buzzer.rb` | `packs/fizzbuzz/app/models/` |
| `app/views/fizz_buzz/` | `packs/fizzbuzz/app/views/fizz_buzz/` |
| `app/helpers/ruby_llm/evals/runs_helper.rb` | `packs/fizzbuzz/app/helpers/ruby_llm/evals/` |

### packs/fizzbuzz (tests)

| From | To |
|------|----|
| `test/controllers/fizz_buzz_controller_test.rb` | `packs/fizzbuzz/test/controllers/` |
| `test/jobs/fizz_buzz_job_test.rb` | `packs/fizzbuzz/test/jobs/` |
| `test/jobs/llm_fizz_buzz_job_test.rb` | `packs/fizzbuzz/test/jobs/` |
| `test/models/fizz_buzzer_test.rb` | `packs/fizzbuzz/test/models/` |
| `test/models/llm_fizz_buzzer_test.rb` | `packs/fizzbuzz/test/models/` |
| `test/system/fizz_buzz_test.rb` | `packs/fizzbuzz/test/system/` |

### Stays at Root

| File | Reason |
|------|--------|
| `app/models/qr_code_generator.rb` | Shared utility (both domains use it) |
| `app/models/survey_response.rb` | Surveys domain (not packed this issue) |
| `app/controllers/surveys_controller.rb` | Surveys domain |
| `app/views/surveys/` | Surveys domain |
| `test/evals/`, `test/support/`, `test/helpers/` | Complex path dependencies |
| `test/cassettes/` | cassette_library_dir in test_helper.rb |
| `test/fixtures/` | fixtures :all in test_helper.rb |

---

## Open Questions

1. **Engine views**: `app/views/ruby_llm/evals/runs/` — verify that moving
   these to `packs/fizzbuzz/app/views/ruby_llm/evals/runs/` doesn't break the
   engine's view resolution. Test by visiting `/evals` after the move. If
   broken, keep those views at root.

2. **runs_helper.rb**: After moving to the fizzbuzz pack, confirm the constant
   `RubyLLM::Evals::RunsHelper` is still found by running the helper tests.

## Verification

- `bin/rails zeitwerk:check` exits 0 after each step
- `bin/rails test` passes after each step (all test types: unit, controller, system)
- `bin/packwerk validate` exits 0 after each step
- `bin/packwerk check` exits 0 with "No violations detected." after each step
