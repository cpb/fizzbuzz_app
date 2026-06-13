# Issue #117: Introduce Packwerk Packs for Links and FizzBuzz

## Bottom Line

fizzbuzz_app can be modularized into two Packwerk packs (`packs/links`, `packs/fizzbuzz`)
with zero violations and no breaking changes. The codebase has clean domain separation;
one cross-domain Ruby dependency (`QrCodeGenerator`) is resolved by keeping it at the app
root as shared infrastructure. Three sequential implementation plans are ready to execute.

## Why This Matters

Packwerk enforces domain boundaries at the source-code level, preventing accidental coupling
between the links and fizzbuzz features. Once these packs exist, `bin/packwerk check` in CI
immediately catches any new code that reaches across domain boundaries. This makes each
feature safer to change independently and makes ownership explicit.

**No user-facing changes.** This is purely infrastructure reorganization.

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `QrCodeGenerator` stays at root | Only cross-domain Ruby class ref; it's a generic utility, not a links concept |
| Tests move into packs | Co-location makes ownership explicit; Rakefile updated for test discovery |
| `evals/` stays at root | EvalLoader and EvalTestSetup reference root-relative paths |
| `enforce_privacy: true` from day 1 | New packs start clean; no legacy violations to record |
| Hagemann's 4 layers (`app/UI/data/utility`) | Standard vocabulary from *Gradual Modularization for Ruby and Rails*; `UI` layer for feature packs, `data`/`utility` reserved for future splits |
| Root package has no `layer:` field | Mixed-layer concerns (global nav + base classes); exempt from enforcement until they're separated into proper packs |
| Manual path config, not `packs-rails` | Two packs don't justify an extra gem dependency |

## What This PR Contains

Research and planning artifacts for introducing Packwerk domain boundary enforcement into
fizzbuzz_app — covering how to install Packwerk, restructure the links/bookmarks and
fizzbuzz features into bounded packs, and reach `bin/packwerk check` passing with zero
violations while keeping the full test suite green.

**Research:**
- `packwerk-setup` — gem v3.3.0, Rails 8.1 compat, packwerk.yml format, validate vs check
- `domain-inventory` — complete file map by domain, one cross-domain dependency identified
- `pack-conventions` — directory layout, package.yml format, Zeitwerk autoloading
- `migration-path` — file movement mechanics, view paths, test/fixture/evals decisions

**Plans:**
1. Install packwerk + configure paths (baseline)
2. Create packs/links and packs/fizzbuzz (file migration)
3. Final sweep, CI integration, open implementation PR

## Reading Order

1. **[research/domain-inventory/](research/domain-inventory/README.md)**
   — Start here. Understand what files exist, which domain they belong to, and
   the one cross-domain dependency that must be resolved.

2. **[research/packwerk-setup/](research/packwerk-setup/README.md)**
   — Gem version, Rails 8.1 compatibility, and config file reference.

3. **[research/pack-conventions/](research/pack-conventions/README.md)**
   — Pack directory structure, `package.yml` format, and Zeitwerk autoloading.

4. **[research/migration-path/](research/migration-path/README.md)**
   — File movement mechanics, view paths, and test/fixture decisions.

5. **[plans/](plans/README.md)**
   — Three sequential implementation plans: install → create packs → verify + CI.

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
- [plans/01-install-packwerk.md](plans/01-install-packwerk.md) — Gems, config, baseline verification
- [plans/02-create-packs.md](plans/02-create-packs.md) — File migration, package.yml, step-by-step verification
- [plans/03-enforce-boundaries.md](plans/03-enforce-boundaries.md) — Final sweep, CI, PR
