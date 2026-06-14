# Plan: Extract Utility Packs (packs/rails_shims and packs/qr_code)

**Decision:** Extract the Rails base classes and `QrCodeGenerator` from the root package
into proper `utility`-layer packs. Once complete, root no longer contains mixed-layer
concerns and can be labeled `layer: app`. This is the architectural prerequisite for the
full layer DAG described in `research/pack-conventions/layer-architecture.md`.

**Rationale:** The root package currently holds `ApplicationController`, `ApplicationRecord`,
`ApplicationJob`, `ApplicationMailer`, and `QrCodeGenerator` — all `utility`-layer concerns
living at the `app`-layer root. The `packs/rails_shims` pattern is established in Shopify's
Sportsball example (chapter 9 of *Gradual Modularization for Ruby and Rails*). Extracting
these enables:
1. Root to declare `layer: app` with enforcement on
2. All feature packs to declare explicit `utility` dependencies
3. `QrCodeGenerator` to be a first-class utility shared by both fizzbuzz and links views

See: [layer-architecture.md](../research/pack-conventions/layer-architecture.md)

---

## Part A: packs/rails_shims

### A1 — Move base class files

```sh
mkdir -p packs/rails_shims/app/{controllers,models,jobs,mailers,helpers}

git mv app/controllers/application_controller.rb  packs/rails_shims/app/controllers/
git mv app/models/application_record.rb           packs/rails_shims/app/models/
git mv app/jobs/application_job.rb                packs/rails_shims/app/jobs/
git mv app/mailers/application_mailer.rb          packs/rails_shims/app/mailers/
git mv app/helpers/application_helper.rb          packs/rails_shims/app/helpers/
```

No changes to file contents — constants keep their names, Zeitwerk finds them via the
pack autoload paths configured in Plan 01.

### A2 — Add packs/rails_shims/package.yml

```yaml
# packs/rails_shims/package.yml
enforce_dependencies: true
enforce_privacy: false   # base classes are inherently public; enforce_privacy would
                         # require every subclass to be in app/public/, which is impractical
enforce_layers: true
layer: utility
dependencies: []         # depends only on the Rails framework, not on any pack
```

### A3 — Update all existing pack dependencies

Each feature pack currently declares `dependencies: ["."]` (root) to access base classes.
Now they depend on `packs/rails_shims` explicitly. Update each `package.yml`:

```yaml
# packs/links/package.yml
enforce_dependencies: true
enforce_privacy: true
enforce_layers: true
layer: UI
dependencies:
  - "packs/rails_shims"
  - "packs/qr_code"     # LinksController views use QrCodeGenerator — added in Part B
```

```yaml
# packs/fizzbuzz/package.yml
enforce_dependencies: true
enforce_privacy: true
enforce_layers: true
layer: UI
dependencies:
  - "packs/rails_shims"
  - "packs/qr_code"     # _survey_qr.html.erb uses QrCodeGenerator — added in Part B
```

```yaml
# packs/surveys/package.yml
enforce_dependencies: true
enforce_privacy: true
enforce_layers: true
layer: UI
dependencies:
  - "packs/rails_shims"
```

### A4 — Label root as app layer

Root can now be a proper `app`-layer package — it no longer contains utility-layer concerns:

```yaml
# package.yml (root)
enforce_dependencies: true
enforce_privacy: false
enforce_layers: true
layer: app
dependencies:
  - "packs/rails_shims"   # config/application.rb, layouts, and any remaining root code
                           # inherit from ApplicationController/ApplicationRecord
```

### A5 — Verify

```sh
bin/rails zeitwerk:check
bin/rails test
bin/packwerk validate
bin/packwerk check
```

Expected: zero violations. All feature packs depend on `packs/rails_shims` (utility layer)
which is lower than UI — valid in the layer DAG. Root depends on `packs/rails_shims` —
also valid (app → utility).

### A6 — Commit

```sh
git add packs/rails_shims/ app/ package.yml \
        packs/links/package.yml packs/fizzbuzz/package.yml packs/surveys/package.yml
git commit -m "refactor: extract packs/rails_shims — ApplicationController, ApplicationRecord, ApplicationJob, ApplicationMailer, ApplicationHelper"
```

---

## Part B: packs/qr_code

### B1 — Move QrCodeGenerator

```sh
mkdir -p packs/qr_code/app/models
mkdir -p packs/qr_code/test/models

git mv app/models/qr_code_generator.rb           packs/qr_code/app/models/
git mv packs/links/test/models/qr_code_generator_test.rb  packs/qr_code/test/models/
```

Note: `qr_code_generator_test.rb` was moved to `packs/links/test/` in Plan 02 because
the test is a links-domain concern. Now that `QrCodeGenerator` has its own utility pack,
the test moves there — the tested class and its test are co-located.

### B2 — Add packs/qr_code/package.yml

```yaml
# packs/qr_code/package.yml
enforce_dependencies: true
enforce_privacy: false   # QrCodeGenerator is the entire public API of this pack
enforce_layers: true
layer: utility
dependencies: []         # wraps rqrcode gem only; no pack dependencies
```

### B3 — Verify

```sh
bin/rails zeitwerk:check
bin/rails test
bin/packwerk validate
bin/packwerk check
```

Expected: zero violations. Both `packs/links` and `packs/fizzbuzz` already declare
`packs/qr_code` as a dependency (added in A3).

### B4 — Commit

```sh
git add packs/qr_code/ packs/links/package.yml packs/fizzbuzz/package.yml
git commit -m "refactor: extract packs/qr_code — QrCodeGenerator as shared utility pack"
```

---

## Part C: packs/eval_loader

`EvalLoader` (currently `lib/eval_loader.rb`) is a utility class that seeds eval YAML data
into the database. It has no domain knowledge about fizzbuzz prompts specifically — it is a
generic YAML-to-ActiveRecord loader. Extract it to a `utility`-layer pack so it can be
explicitly depended on by `packs/fizzbuzz` and called from `db/seeds.rb` at root.

### C1 — Move EvalLoader

```sh
mkdir -p packs/eval_loader/app/services
git mv lib/eval_loader.rb packs/eval_loader/app/services/eval_loader.rb
```

The constant `EvalLoader` is resolved from `packs/eval_loader/app/services/` via the pack
autoload paths configured in Plan 01. No changes to the constant name or calling code.

### C2 — Add packs/eval_loader/package.yml

```yaml
# packs/eval_loader/package.yml
enforce_dependencies: true
enforce_privacy: false   # EvalLoader is the entire public API of this pack
enforce_layers: true
layer: utility
dependencies:
  - "packs/rails_shims"  # EvalLoader uses ActiveRecord (via RubyLLM::Evals models)
```

### C3 — Update callers to declare dependency

`packs/fizzbuzz` (which calls `EvalLoader` in eval tests and via `db/seeds.rb`) and root
need to declare the dependency:

```yaml
# packs/fizzbuzz/package.yml — add to dependencies:
  - "packs/eval_loader"
```

Root `package.yml` — add to dependencies:
```yaml
  - "packs/eval_loader"   # db/seeds.rb calls EvalLoader.seed_dir
```

### C4 — Verify

```sh
bin/rails zeitwerk:check
bin/rails db:seed      # verify EvalLoader still resolves and seeds correctly
bin/rails test
bin/packwerk validate
bin/packwerk check
```

### C5 — Commit

```sh
git add packs/eval_loader/ packs/fizzbuzz/package.yml package.yml
git rm lib/eval_loader.rb
git commit -m "refactor: extract packs/eval_loader — EvalLoader as utility pack, remove from lib/"
```

---

## Verification Checklist

- [ ] `bin/packwerk validate` → "Validation successful."
- [ ] `bin/packwerk check` → "No violations detected."
- [ ] `bin/rails zeitwerk:check` → "All is good!"
- [ ] `bin/rails test` → all tests pass
- [ ] `packs/rails_shims/package.yml` has `layer: utility`, `enforce_dependencies: true`
- [ ] `packs/qr_code/package.yml` has `layer: utility`, `enforce_dependencies: true`
- [ ] Root `package.yml` has `layer: app`, `enforce_dependencies: true`
- [ ] `packs/links/package.yml` dependencies list `packs/rails_shims` and `packs/qr_code`
- [ ] `packs/fizzbuzz/package.yml` dependencies list `packs/rails_shims` and `packs/qr_code`
- [ ] `packs/surveys/package.yml` dependencies list `packs/rails_shims`
- [ ] `packs/qr_code/test/models/qr_code_generator_test.rb` passes
- [ ] `packs/eval_loader/package.yml` has `layer: utility`, `enforce_dependencies: true`
- [ ] `lib/eval_loader.rb` no longer exists (`git ls-files lib/eval_loader.rb` → empty)
- [ ] `bin/rails db:seed` succeeds (EvalLoader autoloads from pack)
- [ ] `packs/fizzbuzz/package.yml` lists `packs/eval_loader` in dependencies
