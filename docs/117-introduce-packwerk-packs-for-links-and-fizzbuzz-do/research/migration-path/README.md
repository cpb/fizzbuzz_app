# Research — Migration Path

Research for Issue #117: mechanics of moving fizzbuzz_app from a flat Rails
structure into Packwerk packs without breaking autoloading, views, or tests.

## Table of Contents

- [file-movement-strategy.md](file-movement-strategy.md) — How file movement works (source changes, autoload_paths, view_paths), directory structure before/after, QrCodeGenerator resolution
- [test-path-changes.md](test-path-changes.md) — Test discovery with packs, whether tests move, VCR cassette and fixture handling, evals directory decision

## Key Findings

- **No source-code constant changes needed** — files move verbatim because Zeitwerk is configured to add `packs/*/app/<layer>/` as autoload roots (not `packs/*/app/` itself)
- **View paths require explicit registration** — ActionView does not inherit the Zeitwerk path config; add `config.paths["app/views"] += Dir[root.join("packs/*/app/views")]` to `config/application.rb`
- **Tests should stay at root** — `bin/rails test` discovers only `test/`; moving tests to `packs/*/test/` adds complexity without Packwerk benefit (Packwerk does not analyze test files)
- **VCR cassettes stay at root** — `test/cassettes/` is referenced by `test/test_helper.rb`; moving cassettes would require updating that path and all per-test cassette names
- **evals/ directory stays at root** — `EvalLoader` seeds from `evals/` at app boot; moving it requires updating `lib/eval_loader.rb` load paths, a separate concern from pack creation
- **QrCodeGenerator moves to root** — resolves the only cross-domain Ruby class reference (`_survey_qr.html.erb` → `QrCodeGenerator`); QR generation is a generic utility shared by both domains
- **Commit order matters** — install packwerk first (before any file moves) so `bin/packwerk check` can verify each step
