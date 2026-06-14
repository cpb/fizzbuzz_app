# Domain Inventory — Issue #117 Research

Research for introducing Packwerk packs `packs/links` and `packs/fizzbuzz`
into fizzbuzz_app.

## Summary

The codebase has clean domain separation between links, fizzbuzz, and surveys.
There is **one notable cross-domain dependency**: `app/views/fizz_buzz/_survey_qr.html.erb`
references `QrCodeGenerator` (a links-domain service) and survey routes
(`survey_path`, `survey_url`, `results_survey_path`). All other files are
cleanly contained within their domain.

`PublishGistJob` references only `Link`, `Gist`, and `GistPublisher` — no
cross-domain leakage.

The `test/evals/` directory belongs with the fizzbuzz pack: all eval tests
exercise fizzbuzz prompts/samples via `LLMFizzBuzzer`. The `evals/` data
directory at the repo root also belongs with fizzbuzz.

## Table of Contents

- [file-map.md](file-map.md) — Every file in app/ and test/ classified by domain
- [cross-domain-dependencies.md](cross-domain-dependencies.md) — Cross-domain references with Mermaid diagram
