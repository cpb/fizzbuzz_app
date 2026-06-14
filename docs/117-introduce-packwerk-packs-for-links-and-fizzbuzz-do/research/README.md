# Research — Issue #117: Introduce Packwerk Packs

Breadth-first summary of all research topics for introducing Packwerk boundary
enforcement into fizzbuzz_app.

## Table of Contents

- [packwerk-setup/](packwerk-setup/README.md) — Gem installation, Rails 8.1 compatibility, packwerk.yml format, validate vs check, package_todo strategy
- [domain-inventory/](domain-inventory/README.md) — File map by domain, cross-domain dependency analysis, files that must stay at root
- [pack-conventions/](pack-conventions/README.md) — Pack directory layout, package.yml format, public API declaration, Zeitwerk autoloading
- [migration-path/](migration-path/README.md) — File movement mechanics, autoload/view path config, test discovery, VCR cassettes, evals directory decision

## Key Finding Per Topic

### packwerk-setup
Packwerk 3.3.0 (Ruby >= 3.3, May 2026) is compatible with Rails 8.1, Propshaft,
and Falcon. `enforce_privacy` was extracted to the `packwerk-extensions` gem in
3.0 — add both gems to `group :development, :test`. Generate `bin/packwerk` via
`bundle binstub packwerk`, then run `bin/packwerk init` for config scaffolding.

→ [gem-compatibility.md](packwerk-setup/gem-compatibility.md),
[packwerk-yml-format.md](packwerk-setup/packwerk-yml-format.md)

### domain-inventory
The codebase has clean domain separation with **one cross-domain Ruby class
reference**: `app/views/fizz_buzz/_survey_qr.html.erb` calls `QrCodeGenerator`
(a links-domain service). Navigation route helpers (`links_path`, `root_path`)
are not Packwerk violations. Resolution: keep `QrCodeGenerator` at the Rails
root as shared infrastructure.

→ [file-map.md](domain-inventory/file-map.md),
[cross-domain-dependencies.md](domain-inventory/cross-domain-dependencies.md)

### pack-conventions
Files move verbatim (no constant renaming) because Zeitwerk is configured to
add each `packs/*/app/<layer>/` directory as an autoload root. Public API lives
in `app/public/`. Tests co-locate with their domain inside the pack at
`packs/<name>/test/` — the Rakefile is updated to include `packs/*/test/` in the default
test run. Views require separate ActionView path registration in `config/application.rb`.
See [test-path-changes.md](migration-path/test-path-changes.md).

→ [directory-layout.md](pack-conventions/directory-layout.md),
[package-yml-format.md](pack-conventions/package-yml-format.md),
[autoloading.md](pack-conventions/autoloading.md)

### migration-path
Two `config/application.rb` additions are needed (Zeitwerk autoload paths +
ActionView view paths for packs). Tests, fixtures, VCR cassettes, and the
`evals/` data directory all stay at root. Atomic commit order: install packwerk
→ configure paths → create packs/links → create packs/fizzbuzz → CI step.

→ [file-movement-strategy.md](migration-path/file-movement-strategy.md),
[test-path-changes.md](migration-path/test-path-changes.md)
