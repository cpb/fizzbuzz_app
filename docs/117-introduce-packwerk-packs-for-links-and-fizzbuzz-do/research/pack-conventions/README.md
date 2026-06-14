# Research — Packwerk Pack Conventions

Summary of pack directory layout, package.yml format, public API declaration,
and Zeitwerk autoloading for Issue #117 (introduce `packs/links` and
`packs/fizzbuzz`).

---

## Table of Contents

- [directory-layout.md](directory-layout.md) — Canonical pack directory structure; concrete example for `packs/links`; where tests live
- [package-yml-format.md](package-yml-format.md) — Full reference for package.yml fields; annotated examples for both packs and the root package
- [autoloading.md](autoloading.md) — How Zeitwerk handles pack directories; what config/application.rb changes are needed; known gotchas with Rails 8.1

---

## Breadth-first summary

### directory-layout

Packs live under `packs/` at the project root. Each pack mirrors the Rails
`app/` subdirectory structure inside `packs/<name>/app/`. Public API goes in
`packs/<name>/app/public/`. Constants inside a pack **must be namespaced** to
match their file path under Zeitwerk — `packs/links/app/models/links/link.rb`
defines `Links::Link`, not a top-level `Link`.

Tests can live either inside the pack (`packs/links/test/`) or remain in the
root `test/` directory. packs-rails supports both; root `test/` is simpler and
requires no test runner configuration changes.

→ [directory-layout.md](directory-layout.md)

---

### package-yml-format

`package.yml` has five relevant fields for this app:

| Field | Type | Purpose |
|---|---|---|
| `enforce_dependencies` | bool / `"strict"` | Require explicit dependency declarations |
| `enforce_privacy` | bool / `"strict"` | Only `app/public/` constants visible to other packs |
| `public_path` | string | Override default `app/public/` |
| `dependencies` | list | Packs this pack may reference |
| `metadata` | map | Free-form ownership/contact info |

Privacy enforcement (`enforce_privacy`) was extracted from core packwerk into
the `packwerk-extensions` gem after packwerk 3.0. Both features remain widely
used but are now opt-in. **Recommended starter config for brownfield packs** (migrating existing code into packs):
`enforce_dependencies: false`, `enforce_privacy: false` to avoid a violation flood while
packs are being established. For **new packs created from scratch** (like `packs/links`
and `packs/fizzbuzz` in this issue), start with enforcement on from day 1 — there is no
legacy code to grandfather in.

→ [package-yml-format.md](package-yml-format.md)

---

### autoloading

Packwerk's constant resolver uses the same Zeitwerk assumptions as Rails: file
paths translate to constant names. For `packs/*/app/` subdirectories to be
autoloaded, those paths must appear in Rails' `autoload_paths` /
`eager_load_paths`.

Two approaches:
1. **packs-rails gem** — adds pack autoload paths automatically; no
   config/application.rb changes needed.
2. **Manual** — add a glob to `config/application.rb`:
   ```ruby
   Dir["#{root}/packs/*/app"].each { |p| config.autoload_paths << p }
   ```

Rails 8.1 uses Zeitwerk exclusively. The `config.autoload_lib` call in
fizzbuzz_app's `config/application.rb` is unrelated and does not need to
change; pack paths are additive.

→ [autoloading.md](autoloading.md)
