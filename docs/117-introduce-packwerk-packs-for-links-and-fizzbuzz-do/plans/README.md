# Plans — Issue #117: Introduce Packwerk Packs

Three sequential plans that together deliver `bin/packwerk check` passing with
zero violations and the full test suite green.

## Table of Contents

- [01-install-packwerk.md](01-install-packwerk.md) — Add gems, generate binstub + config files, configure autoload and view paths, verify clean baseline
- [02-create-packs.md](02-create-packs.md) — Move domain files into packs/links and packs/fizzbuzz, create package.yml with enforcement on, verify at each step
- [03-enforce-boundaries.md](03-enforce-boundaries.md) — Final violation sweep, add packwerk to CI, open PR

## Execution Order

Plans must run sequentially — each plan's output is the next plan's prerequisite:

```
01-install-packwerk
  → packwerk installed, paths configured, clean baseline
    → 02-create-packs
        → files in packs, package.yml files with enforcement on, zero violations
          → 03-enforce-boundaries
              → CI updated, PR opened
```

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| Use manual `config.paths.add` instead of `packs-rails` gem | Only two packs; manual is transparent and avoids an extra dependency |
| `QrCodeGenerator` stays at root | Generic utility used by both fizzbuzz and links; moving it to links creates an architecturally odd dependency |
| Tests stay at root `test/` | Packwerk doesn't analyze test files; moving tests adds complexity with no boundary enforcement benefit |
| No `package_todo.yml` | New packs start clean — fix violations rather than recording them |
| `enforce_privacy: true` from the start | Both packs are new; no legacy code to grandfather in |
