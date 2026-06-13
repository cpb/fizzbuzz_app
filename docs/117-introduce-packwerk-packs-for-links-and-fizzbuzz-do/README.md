# Issue #117: Introduce Packwerk Packs for Links and FizzBuzz

Research and planning artifacts for introducing Packwerk domain boundary
enforcement into fizzbuzz_app.

## What This PR Answers

How to install Packwerk, restructure the links/bookmarks and fizzbuzz features
into bounded packs, and reach `bin/packwerk check` passing with zero violations
while keeping the full test suite green — without disrupting the surveys domain
or evals infrastructure.

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

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| `QrCodeGenerator` stays at root | Only cross-domain Ruby class ref; it's a generic utility, not a links concept |
| Tests move into packs | Co-location makes ownership explicit; Rakefile updated for test discovery |
| `evals/` stays at root | EvalLoader and EvalTestSetup reference root-relative paths |
| `enforce_privacy: true` from day 1 | New packs start clean; no legacy violations to record |
| Two architecture layers: `feature` + `utility` | Feature packs (fizzbuzz, links) above Rails infrastructure root; prevents root from depending on pack internals |
| Manual path config, not `packs-rails` | Two packs don't justify an extra gem dependency |
