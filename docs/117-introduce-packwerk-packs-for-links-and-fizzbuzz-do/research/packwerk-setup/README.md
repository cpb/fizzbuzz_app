# Packwerk Setup Research

Research for Issue #117: Introduce Packwerk packs for links and fizzbuzz domains.

This research covers what is required to install and configure Packwerk in fizzbuzz_app
(Rails 8.1.3, Ruby ~> 3.3, Falcon, Propshaft, Zeitwerk).

## Table of Contents

- [gem-compatibility.md](gem-compatibility.md) — Packwerk gem version, Rails 8.1 compatibility, Propshaft/Falcon notes, gem group placement, companion gems (packwerk-extensions, packs-rails)
- [packwerk-yml-format.md](packwerk-yml-format.md) — Full packwerk.yml reference, root package.yml minimum content, bin/packwerk generation, validate vs check distinction, package_todo.yml strategy

## Key Findings

- **Packwerk 3.3.0** (released May 2026) is the current version; requires Ruby >= 3.3 (matches this app's `~> 3.3`)
- **No `load_paths` in packwerk.yml** — removed in 2.0; Packwerk reads autoload paths directly from Rails/Zeitwerk
- **`enforce_privacy` removed in 3.0** — if privacy enforcement is needed, add `packwerk-extensions` (optional)
- **Gem group**: development only (not needed in production or test)
- **No known incompatibilities** with Propshaft or Falcon — both are asset/server concerns orthogonal to Packwerk's static analysis
- **packs-rails** (optional, 0.1.0) can auto-register `packs/*/app/` directories as Rails autoload paths; otherwise configure manually in `config/application.rb`
- **Zero-violation target**: start with enforcement off at root, on at each new pack; avoid `package_todo.yml` for new packs
