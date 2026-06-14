# Pack Directory Layout

## Canonical Structure

Each pack lives under `packs/` at the Rails root. Inside, it mirrors the Rails
`app/` subdirectory structure. Tests live inside the pack at `packs/<name>/test/`,
collocated with their domain.

```
packs/
└── links/
    ├── package.yml             ← pack metadata and enforcement settings
    ├── app/
    │   ├── controllers/
    │   │   └── links_controller.rb
    │   ├── jobs/
    │   │   └── publish_gist_job.rb
    │   ├── models/
    │   │   ├── link.rb
    │   │   ├── gist.rb
    │   │   └── gist_publisher.rb
    │   ├── public/             ← public API (if enforce_privacy: true)
    │   │   └── (public constants go here)
    │   └── views/
    │       └── links/
    │           ├── index.html.erb
    │           ├── new.html.erb
    │           ├── _link.html.erb
    │           └── _qr_code.html.erb
    └── test/
        ├── controllers/
        │   └── links_controller_test.rb
        ├── jobs/
        │   └── publish_gist_job_test.rb
        ├── models/
        │   ├── link_test.rb
        │   ├── gist_test.rb
        │   ├── gist_publisher_test.rb
        │   └── qr_code_generator_test.rb
        └── system/
            └── links_test.rb
```

## Constant Naming — No Namespace Required

**Constants are NOT namespaced by pack name.** Zeitwerk autoloads each
`app/<layer>/` directory as a separate root, not `app/` as a whole. The
mapping is:

| File Path | Autoload Root | Constant Name |
|-----------|--------------|---------------|
| `packs/links/app/models/link.rb` | `packs/links/app/models/` | `Link` |
| `packs/links/app/controllers/links_controller.rb` | `packs/links/app/controllers/` | `LinksController` |
| `packs/fizzbuzz/app/models/fizz_buzzer.rb` | `packs/fizzbuzz/app/models/` | `FizzBuzzer` |
| `packs/fizzbuzz/app/jobs/fizz_buzz_job.rb` | `packs/fizzbuzz/app/jobs/` | `FizzBuzzJob` |

This means files can be moved from `app/` to `packs/<name>/app/` **without
changing any constant references** in the source code. The classes keep their
existing names.

## Public API Directory

When `enforce_privacy: true` is set (via `packwerk-extensions`), Packwerk
treats only constants under `packs/<name>/app/public/` as accessible from
outside the pack. All other constants in `packs/<name>/app/` are private.

Example — if `QrCodeGenerator` needs to be accessible from outside `packs/links`:

```
packs/links/
└── app/
    ├── models/
    │   └── link.rb              ← private (only links pack can reference)
    └── public/
        └── qr_code_generator.rb ← public (any pack can reference)
```

The class defined in `app/public/qr_code_generator.rb` is still named
`QrCodeGenerator` — the `public/` directory does not add a namespace.

## Where Tests Live

Tests live inside the pack collocated with their domain. This makes pack
ownership explicit and keeps related code together.

```
packs/links/test/
  controllers/links_controller_test.rb
  models/link_test.rb
  models/gist_publisher_test.rb
  system/links_test.rb
```

**Test runner impact:** `bin/rails test` discovers only `test/` by default.
The Rakefile must be updated, or tests invoked with explicit paths. See
[test-path-changes.md](../migration-path/test-path-changes.md) for configuration.

**Important:** Packwerk does not analyze test files for boundary violations.
Tests can freely reference constants from any pack — moving tests to packs is
about co-location and ownership, not boundary enforcement.

## Concrete Example for fizzbuzz_app

```
packs/
├── fizzbuzz/
│   ├── package.yml
│   ├── app/
│   │   ├── controllers/
│   │   │   └── fizz_buzz_controller.rb     (was app/controllers/)
│   │   ├── helpers/ruby_llm/evals/
│   │   │   └── runs_helper.rb              (was app/helpers/ruby_llm/evals/)
│   │   ├── jobs/
│   │   │   ├── fizz_buzz_job.rb            (was app/jobs/)
│   │   │   └── llm_fizz_buzz_job.rb        (was app/jobs/)
│   │   ├── models/
│   │   │   ├── fizz_buzzer.rb              (was app/models/)
│   │   │   └── llm_fizz_buzzer.rb          (was app/models/)
│   │   └── views/
│   │       └── fizz_buzz/                  (was app/views/fizz_buzz/)
│   └── test/
│       ├── controllers/fizz_buzz_controller_test.rb
│       ├── jobs/fizz_buzz_job_test.rb
│       ├── jobs/llm_fizz_buzz_job_test.rb
│       ├── models/fizz_buzzer_test.rb
│       ├── models/llm_fizz_buzzer_test.rb
│       └── system/fizz_buzz_test.rb
└── links/
    ├── package.yml
    ├── app/
    │   ├── controllers/
    │   │   └── links_controller.rb         (was app/controllers/)
    │   ├── jobs/
    │   │   └── publish_gist_job.rb         (was app/jobs/)
    │   ├── models/
    │   │   ├── link.rb                     (was app/models/)
    │   │   ├── gist.rb                     (was app/models/)
    │   │   └── gist_publisher.rb           (was app/models/)
    │   └── views/
    │       └── links/                      (was app/views/links/)
    └── test/
        ├── controllers/links_controller_test.rb
        ├── jobs/publish_gist_job_test.rb
        ├── models/link_test.rb
        ├── models/gist_test.rb
        ├── models/gist_publisher_test.rb
        ├── models/qr_code_generator_test.rb
        └── system/links_test.rb
```

Notes:
- `QrCodeGenerator` stays at `app/models/` (root) — shared utility used by both domains. See [cross-domain-dependencies.md](../domain-inventory/cross-domain-dependencies.md).
- Evals tests (`test/evals/`, cassettes) stay at root — EvalLoader and EvalTestSetup reference root-relative paths; migrating them is a separate concern.
