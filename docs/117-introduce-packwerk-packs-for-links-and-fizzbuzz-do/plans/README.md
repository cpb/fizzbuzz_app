# Plans — Issue #117: Introduce Packwerk Packs

Seven plans that together deliver `bin/packwerk check` passing with zero violations,
no architectural debt at the Rails root, and the full test suite green.

## Table of Contents

- [01-install-packwerk.md](01-install-packwerk.md) — Add gems, generate binstub + config files, configure autoload and view paths, verify clean baseline
- [02-create-packs.md](02-create-packs.md) — Move domain files into packs/links, packs/fizzbuzz, and packs/surveys; create package.yml with enforcement on
- [03-cleanup-workbook.md](03-cleanup-workbook.md) — Delete workbook stub controllers, views, and JS from the #118 extraction
- [04-extract-utility-packs.md](04-extract-utility-packs.md) — Extract packs/rails_shims (base classes) and packs/qr_code; label root as app layer
- [05-migrate-evals.md](05-migrate-evals.md) — Move evals/ data dir and test/evals/ into packs/fizzbuzz; update EvalLoader paths
- [07-enforce-boundaries.md](07-enforce-boundaries.md) — Final violation sweep across all packs, add packwerk to CI, open PR

## Execution Order

Plans must run sequentially — each plan's output is the next plan's prerequisite:

```
01-install-packwerk
  → packwerk installed, paths configured, clean baseline
    → 02-create-packs
        → packs/links, packs/fizzbuzz, packs/surveys created; zero violations
          → 03-cleanup-workbook          (no dependencies; can run any time after 01)
          → 04-extract-utility-packs     (depends on 02; unlocks labeled root layer)
          → 05-migrate-evals             (depends on 02; moves evals into packs/fizzbuzz)
              → 07-enforce-boundaries    (depends on 02–05; final sweep + CI)
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Use manual `config.paths.add` instead of `packs-rails` gem | Only two packs; manual is transparent and avoids an extra dependency |
| `QrCodeGenerator` moves to packs/qr_code (Plan 04) | Generic utility used by both fizzbuzz and links; extracted as a first-class utility pack rather than staying at root or in links |
| Tests move into packs | Co-location makes pack ownership explicit; Rakefile updated to include `packs/*/test/` in the default test run |
| Evals tests migrate to packs/fizzbuzz (Plan 05) | EvalTestSetup has complex root-relative path setup; migration deferred to Plan 05 to keep Plan 02 focused on domain file moves |
| No `package_todo.yml` | New packs start clean — fix violations rather than recording them |
| `enforce_privacy: true` from the start | Both packs are new; no legacy code to grandfather in |
| Hagemann's 4 layers (`app/UI/data/utility`) in packwerk.yml | Provides vocabulary for future modularization depth; all four layers named even if `data`/`utility` are empty today |
| Feature packs at `UI` layer | fizzbuzz and links are user-facing features (controllers + views + domain logic); `data` available if they're ever split |
| Root package gets `layer: app` after Plan 04 | After base classes move to `packs/rails_shims` (utility), root only contains app-layer concerns (routes, layouts, shared assets); can then be labeled and enforced |
| Global nav stays at root | `application.html.erb` belongs semantically at `app` layer; root is now a proper `app`-layer package after Plan 04 |
