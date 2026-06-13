# Plan: Enforce Boundaries and Verify

**Decision:** With files already in their pack directories, add `bin/packwerk check`
to CI (`.github/workflows/`), do a final full sweep of violations, and open the PR.

**Rationale:** Enforcement was already turned on during pack creation
(`enforce_dependencies: true`, `enforce_privacy: true`, `enforce_layers: true`).
This plan covers the final verification sweep, CI integration, and PR opening.
No violations are expected because the one cross-domain dependency was resolved
in Plan 02 and the layer assignments form a valid DAG (feature → utility).

See: [packwerk-yml-format.md](../research/packwerk-setup/packwerk-yml-format.md),
[package-yml-format.md](../research/pack-conventions/package-yml-format.md),
[cross-domain-dependencies.md](../research/domain-inventory/cross-domain-dependencies.md)

---

## Steps

### 1. Final packwerk sweep

```sh
bin/packwerk validate   # config is valid
bin/packwerk check      # zero violations
```

If any violations appear, fix them — do NOT run `bin/packwerk update-todo`.

**Expected violations and fixes:**

The research found only one cross-domain Ruby class reference:
`_survey_qr.html.erb` → `QrCodeGenerator`. This is resolved by keeping
`QrCodeGenerator` at root (Plan 02, Step A). No other violations are expected.

If packwerk reports a privacy violation for `QrCodeGenerator` being referenced
from `packs/fizzbuzz` — that means Packwerk classified it as belonging to
`packs/links` even though the file stayed at root. In that case:
- Confirm `qr_code_generator.rb` is at `app/models/` (root package), not inside any pack
- Run `bin/packwerk validate` to check the package graph
- The root package has `enforce_privacy: false`, so root constants are always accessible

### 2. Confirm test suite is fully green

```sh
bin/rails test
```

All tests must pass. Pay attention to:
- System tests (depend on view paths for template resolution)
- Eval tests (depend on evals/ data files at root)
- Helper tests (`runs_helper_test.rb` — depends on helper being loadable)

### 3. Add packwerk check to CI

Locate the CI workflow file:
```sh
ls .github/workflows/
```

Add `bin/packwerk validate && bin/packwerk check` as a step, either in the
existing CI job or as a separate job. Example addition to a GitHub Actions job:

```yaml
- name: Check Packwerk boundaries
  run: bin/packwerk validate && bin/packwerk check
```

Commit:
```sh
git add .github/workflows/
git commit -m "ci: add packwerk validate and check to CI"
```

### 4. Final commit check

All commits in this issue should be self-contained. Review the log:

```sh
git log --oneline main..HEAD
```

Expected commits (in order):
1. `feat: install packwerk with extensions and configure autoload paths`
2. `refactor: create packs/links with models, controller, job, and views`
3. `refactor: create packs/fizzbuzz with models, controllers, jobs, and views`
4. `ci: add packwerk validate and check to CI`

### 5. Open the PR

```sh
git push -u origin HEAD
gh pr create \
  --title "feat: introduce packwerk packs for links and fizzbuzz domains" \
  --body "$(cat <<'EOF'
Closes #117

## Summary

- Installs packwerk 3.x + packwerk-extensions
- Creates `packs/links` (Link, Gist, GistPublisher, LinksController, PublishGistJob, views)
- Creates `packs/fizzbuzz` (FizzBuzzer, LLMFizzBuzzer, FizzBuzzController, FizzBuzzJob, LLMFizzBuzzJob, views)
- Configures Zeitwerk autoload paths and ActionView view paths for packs/
- `QrCodeGenerator` remains at app root as shared utility (used by both domains)
- `bin/packwerk check` passes with zero violations
- Full test suite remains green
- bin/packwerk validate + check added to CI

## Test plan

- [ ] `bin/packwerk validate` exits 0
- [ ] `bin/packwerk check` exits 0 with "No violations detected."
- [ ] `bin/rails zeitwerk:check` exits 0 with "All is good!"
- [ ] `bin/rails test` — all tests pass
- [ ] Visit / (fizzbuzz form) — renders correctly
- [ ] Visit /links — renders correctly
- [ ] Visit /survey — renders correctly
- [ ] Visit /evals — renders correctly (engine views unaffected)
EOF
)"
```

---

## Open Questions

None. All cross-domain dependencies identified in research have resolutions.

## Verification Checklist

- [ ] `bin/packwerk validate` → "Validation successful."
- [ ] `bin/packwerk check` → "No violations detected."
- [ ] `bin/rails zeitwerk:check` → "All is good!"
- [ ] `bin/rails test` → all tests pass (root + pack tests via updated Rakefile)
- [ ] Each pack's `package.yml` has `enforce_dependencies: true`, `enforce_privacy: true`, `enforce_layers: true`
- [ ] Each pack's `package.yml` declares `layer: feature` and `dependencies: ["."]`
- [ ] Root `package.yml` has `enforce_layers: true`, `layer: utility`
- [ ] `packwerk.yml` lists both `"./"` and `"packs/*/"` in `package_paths`
- [ ] `packwerk.yml` declares `architecture_layers: [feature, utility]`
- [ ] No `package_todo.yml` files exist anywhere
- [ ] Tests in `packs/links/test/` and `packs/fizzbuzz/test/` pass when run with `bin/rails test packs/links/test/ packs/fizzbuzz/test/`
