# Issue #117: Introduce Packwerk Packs for Links, FizzBuzz, and Surveys

## Bottom Line

fizzbuzz_app has been modularized into three domain packs (`packs/links`,
`packs/fizzbuzz`, `packs/surveys`) and four utility packs (`packs/rails_shims`,
`packs/qr_code`, `packs/evals`, `packs/test_shims`) with zero violations and no
breaking changes. Six of seven plans are complete; Plan 07 (enforce boundaries + CI)
remains.

## Why This Matters

Packwerk enforces domain boundaries at the source-code level, preventing accidental
coupling between features. Once `bin/packwerk check` runs in CI, any new code that
reaches across domain boundaries is caught immediately. Each feature is now safer to
change independently and ownership is explicit.

**No user-facing changes.** This is purely infrastructure reorganization.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `packs/surveys` added to scope | Surveys feature existed and had clean domain separation; included alongside links and fizzbuzz |
| `QrCodeGenerator` moves to `packs/qr_code` | Initially planned to stay at root; extracted as a first-class utility pack since it's shared infrastructure, not a links concept |
| `evals/` migrates to `packs/fizzbuzz` (Plan 05) | Initially planned to stay at root due to path complexity; migrated after domain packs stabilized |
| `packs/rails_shims` extracts base classes | `ApplicationController`, `ApplicationJob`, `ApplicationRecord` moved out of root so root can be labeled `app` layer |
| `packs/test_shims` extracts test support | Mirrors rails_shims for the test layer; keeps pack tests self-contained |
| Tests move into packs | Co-location makes ownership explicit; Rakefile updated for test discovery |
| `enforce_privacy: true` from day 1 | New packs start clean; no legacy violations to record |
| Hagemann's 4 layers (`app/UI/data/utility`) | Standard vocabulary from *Gradual Modularization for Ruby and Rails*; feature packs at `UI`, utilities at `utility` |
| Root package gets `layer: app` after Plan 04 | Once base classes move to `packs/rails_shims`, root only contains app-layer concerns |
| Manual path config, not `packs-rails` | Explicit and transparent; avoids an extra dependency |

## What This PR Contains

Research and planning artifacts for introducing Packwerk domain boundary enforcement into
fizzbuzz_app — covering installation, restructuring three feature domains and four utility
packs into bounded packs, and reaching `bin/packwerk check` passing with zero violations
while keeping the full test suite green.

**Research:**
- `packwerk-setup` — gem v3.3.0, Rails 8.1 compat, packwerk.yml format, validate vs check
- `domain-inventory` — complete file map by domain, cross-domain dependencies identified
- `pack-conventions` — directory layout, package.yml format, Zeitwerk autoloading
- `migration-path` — file movement mechanics, view paths, test/fixture/evals decisions

**Plans (6 of 7 complete):**
1. ~~Install packwerk + configure paths (baseline)~~ ✓
2. ~~Create packs/links, packs/fizzbuzz, packs/surveys (file migration)~~ ✓
3. ~~Delete workbook stub controllers, views, and JS~~ ✓
4. ~~Extract packs/rails_shims, packs/qr_code, packs/evals, packs/test_shims~~ ✓
5. ~~Migrate evals/ data dir and test infrastructure into packs/fizzbuzz~~ ✓
6. Enforce boundaries across all packs + CI integration (pending)

## Reading Order

1. **[research/domain-inventory/](research/domain-inventory/README.md)**
   — Start here. Understand what files exist, which domain they belong to, and
   the cross-domain dependencies that must be resolved.

2. **[research/packwerk-setup/](research/packwerk-setup/README.md)**
   — Gem version, Rails 8.1 compatibility, and config file reference.

3. **[research/pack-conventions/](research/pack-conventions/README.md)**
   — Pack directory structure, `package.yml` format, and Zeitwerk autoloading.

4. **[research/migration-path/](research/migration-path/README.md)**
   — File movement mechanics, view paths, and test/fixture decisions.

5. **[plans/](plans/README.md)**
   — Seven sequential implementation plans: install → create packs → cleanup → utilities → evals → enforce + CI.

## Table of Contents

### Research
- [research/README.md](research/README.md) — Breadth-first summary of all research
- [research/domain-inventory/](research/domain-inventory/README.md) — File map and cross-domain dependencies
  - [file-map.md](research/domain-inventory/file-map.md)
  - [cross-domain-dependencies.md](research/domain-inventory/cross-domain-dependencies.md)
- [research/packwerk-setup/](research/packwerk-setup/README.md) — Installation and configuration
  - [gem-compatibility.md](research/packwerk-setup/gem-compatibility.md)
  - [packwerk-yml-format.md](research/packwerk-setup/packwerk-yml-format.md)
- [research/pack-conventions/](research/pack-conventions/README.md) — Directory layout and package.yml
  - [directory-layout.md](research/pack-conventions/directory-layout.md)
  - [package-yml-format.md](research/pack-conventions/package-yml-format.md)
  - [autoloading.md](research/pack-conventions/autoloading.md)
- [research/migration-path/](research/migration-path/README.md) — File movement and test strategy
  - [file-movement-strategy.md](research/migration-path/file-movement-strategy.md)
  - [test-path-changes.md](research/migration-path/test-path-changes.md)

### Plans
- [plans/README.md](plans/README.md) — Summary and execution order
- [plans/01-install-packwerk.md](plans/01-install-packwerk.md) — Gems, config, baseline verification ✓
- [plans/02-create-packs.md](plans/02-create-packs.md) — File migration, package.yml, step-by-step verification ✓
- [plans/03-cleanup-workbook.md](plans/03-cleanup-workbook.md) — Delete workbook stubs from #118 extraction ✓
- [plans/04-extract-utility-packs.md](plans/04-extract-utility-packs.md) — Extract rails_shims, qr_code, evals, test_shims ✓
- [plans/05-migrate-evals.md](plans/05-migrate-evals.md) — Move evals data dir and tests into packs/fizzbuzz ✓
- [plans/07-enforce-boundaries.md](plans/07-enforce-boundaries.md) — Final violation sweep, CI integration
