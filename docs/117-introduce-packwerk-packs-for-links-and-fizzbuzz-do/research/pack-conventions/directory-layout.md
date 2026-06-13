# Pack Directory Layout

## Canonical Structure

Each pack lives under `packs/` at the Rails root. Inside, it mirrors the Rails
`app/` subdirectory structure. Tests may live inside the pack (`packs/<name>/test/`)
or remain at the root `test/` directory.

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
    └── test/                   ← optional; tests can stay at root test/ instead
        ├── controllers/
        │   └── links_controller_test.rb
        ├── jobs/
        │   └── publish_gist_job_test.rb
        ├── models/
        │   ├── link_test.rb
        │   └── gist_publisher_test.rb
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

### Option A: Tests inside the pack (full isolation)

```
packs/links/test/
  controllers/links_controller_test.rb
  models/link_test.rb
  system/links_test.rb
```

**Requires:** Adding pack test paths to test_helper.rb or adjusting how
`bin/rails test` is invoked. Standard `bin/rails test` does not discover
`packs/*/test/` by default.

### Option B: Tests at root (recommended for this issue)

Keep existing `test/` structure untouched. Tests remain in:
```
test/
  controllers/links_controller_test.rb
  models/link_test.rb
  system/links_test.rb
```

**Advantage:** `bin/rails test` continues to work unchanged. Packwerk does
not analyze test files for boundary violations (only `app/` files). Tests can
reference any constant without creating pack violations.

**Recommendation:** Keep tests at root for Issue #117. This delivers the
Packwerk boundary enforcement without introducing test runner complexity.
Moving tests to packs is a future enhancement.

## Concrete Example for fizzbuzz_app

```
packs/
├── fizzbuzz/
│   ├── package.yml
│   └── app/
│       ├── controllers/
│       │   └── fizz_buzz_controller.rb     (was app/controllers/)
│       ├── jobs/
│       │   ├── fizz_buzz_job.rb            (was app/jobs/)
│       │   └── llm_fizz_buzz_job.rb        (was app/jobs/)
│       ├── models/
│       │   ├── fizz_buzzer.rb              (was app/models/)
│       │   └── llm_fizz_buzzer.rb          (was app/models/)
│       └── views/
│           └── fizz_buzz/                  (was app/views/fizz_buzz/)
│               ├── start.html.erb
│               ├── _result.html.erb
│               └── _survey_qr.html.erb
└── links/
    ├── package.yml
    └── app/
        ├── controllers/
        │   └── links_controller.rb         (was app/controllers/)
        ├── jobs/
        │   └── publish_gist_job.rb         (was app/jobs/)
        ├── models/
        │   ├── link.rb                     (was app/models/)
        │   ├── gist.rb                     (was app/models/)
        │   └── gist_publisher.rb           (was app/models/)
        └── views/
            └── links/                      (was app/views/links/)
                ├── index.html.erb
                ├── new.html.erb
                ├── _link.html.erb
                └── _qr_code.html.erb
```

Note: `QrCodeGenerator` moves to `app/models/` at root (see
[cross-domain-dependencies.md](../domain-inventory/cross-domain-dependencies.md)).
