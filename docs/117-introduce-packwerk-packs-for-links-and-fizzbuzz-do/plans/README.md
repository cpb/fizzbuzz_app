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
| Tests move into packs | Co-location makes pack ownership explicit; Rakefile updated to include `packs/*/test/` in the default test run |
| Evals tests stay at root | EvalTestSetup has complex root-relative path setup; migration is a separate concern |
| No `package_todo.yml` | New packs start clean — fix violations rather than recording them |
| `enforce_privacy: true` from the start | Both packs are new; no legacy code to grandfather in |
| Hagemann's 4 layers (`app/UI/data/utility`) in packwerk.yml | Provides vocabulary for future modularization depth; all four layers named even if `data`/`utility` are empty today |
| Feature packs at `UI` layer | fizzbuzz and links are user-facing features (controllers + views + domain logic); `data` available if they're ever split |
| Root package has no `layer:` field | Root contains mixed-layer concerns (global nav at `app` level + base classes at `utility` level); packwerk-extensions exempts unlabeled packages from layer enforcement, preventing an unsolvable pack → root violation |
| Global nav stays at root for now | `application.html.erb` belongs semantically in an `app`-layer pack; extracting it is a future step once base classes move to `utility` |
