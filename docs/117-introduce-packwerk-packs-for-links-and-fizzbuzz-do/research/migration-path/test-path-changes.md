# Test Path Changes

## Decision: Tests Move Into Packs

Tests for each domain move into their pack at `packs/<name>/test/`, collocated
with their source files. This makes pack ownership explicit and keeps related
code together.

## Test Runner Configuration

`bin/rails test` discovers only the root `test/` directory by default.
Two changes are needed:

### 1. Rakefile — include pack test directories in the default test task

```ruby
# Rakefile
require_relative "config/application"
Rails.application.load_tasks

# Override the default test task to include tests from packs
Rake::Task[:test].clear
Rails::TestTask.new(:test) do |t|
  t.pattern = FileList[
    "test/**/*_test.rb",
    "packs/*/test/**/*_test.rb"
  ]
  t.verbose = false
end
```

After this change, `bin/rails test` and `rake test` run tests from both
`test/` and all `packs/*/test/` directories.

### 2. Explicit path invocation (useful for focused runs)

Run tests for a single pack without the Rakefile change:

```sh
bin/rails test packs/links/test/
bin/rails test packs/fizzbuzz/test/
bin/rails test packs/links/test/ packs/fizzbuzz/test/ test/
```

## VCR Cassettes — Stay at Root

`test/test_helper.rb` configures:
```ruby
VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  ...
end
```

VCR resolves `cassette_library_dir` relative to `Dir.pwd` (Rails root), not
the test file path. Tests in `packs/links/test/` that require `test_helper.rb`
will still find cassettes at `test/cassettes/` — no changes needed to cassette
names or the VCR configuration.

**Decision: `test/cassettes/` stays at root.**

## Fixtures — Stay at Root

`test/test_helper.rb` loads fixtures with `fixtures :all`, which Rails resolves
relative to `test/fixtures/`. Pack tests require `test_helper.rb`, inheriting
this fixture setup. All fixture YAML files remain at `test/fixtures/`.

**Decision: `test/fixtures/` stays at root.**

## Requiring test_helper from Pack Tests

Tests in pack directories need to require `test_helper.rb`. The relative path
changes depending on depth — use `expand_path` for robustness:

```ruby
# packs/links/test/models/link_test.rb
require_relative "../../../../test/test_helper"
```

Or, if `test/` is added to the Ruby load path (Rails does this via
`require "rails/test_help"` in test_helper), tests can use:

```ruby
require "test_helper"
```

**Recommendation:** Use `require "test_helper"` — Rails adds `test/` to the load
path during test runs, so this works regardless of the test file's location.

## evals Tests — Stay at Root

The eval tests in `test/evals/` and supporting files in `test/support/` use:
- `EvalTestSetup` which sets `fixture_paths` with root-relative paths
- VCR cassettes from `test/cassettes/` with cassette names hardcoded in each test
- `require_relative` references to `test/support/` files

Moving these 20+ files requires updating all `require_relative` paths and
verifying `EvalTestSetup`'s `fixture_paths` still resolve. This is a
separate concern from creating the packs.

**Decision: `test/evals/`, `test/support/`, and related infrastructure stay at root for Issue #117.**

## Summary — What Moves vs. Stays

| Location | Move? | Destination |
|----------|-------|-------------|
| `test/models/fizz_buzzer_test.rb` | Yes | `packs/fizzbuzz/test/models/` |
| `test/models/llm_fizz_buzzer_test.rb` | Yes | `packs/fizzbuzz/test/models/` |
| `test/controllers/fizz_buzz_controller_test.rb` | Yes | `packs/fizzbuzz/test/controllers/` |
| `test/jobs/fizz_buzz_job_test.rb` | Yes | `packs/fizzbuzz/test/jobs/` |
| `test/jobs/llm_fizz_buzz_job_test.rb` | Yes | `packs/fizzbuzz/test/jobs/` |
| `test/system/fizz_buzz_test.rb` | Yes | `packs/fizzbuzz/test/system/` |
| `test/models/link_test.rb` | Yes | `packs/links/test/models/` |
| `test/models/gist_test.rb` | Yes | `packs/links/test/models/` |
| `test/models/gist_publisher_test.rb` | Yes | `packs/links/test/models/` |
| `test/models/qr_code_generator_test.rb` | Yes | `packs/links/test/models/` |
| `test/controllers/links_controller_test.rb` | Yes | `packs/links/test/controllers/` |
| `test/jobs/publish_gist_job_test.rb` | Yes | `packs/links/test/jobs/` |
| `test/system/links_test.rb` | Yes | `packs/links/test/system/` |
| `test/evals/*.rb` (20 files) | No | Complex setup paths; separate concern |
| `test/support/eval_*.rb` | No | Required by evals tests |
| `test/helpers/runs_helper_test.rb` | No | Evals infrastructure |
| `test/configuration/` | No | Evals infrastructure |
| `test/lib/` | No | Evals infrastructure |
| `test/controllers/surveys_controller_test.rb` | No | Surveys not packed this issue |
| `test/system/surveys_test.rb` | No | Surveys not packed this issue |
| `test/cassettes/` | No | Root-relative path in VCR config |
| `test/fixtures/` | No | Root-relative path in fixtures :all |
| `test/test_helper.rb` | No | Shared infrastructure |
| `test/application_system_test_case.rb` | No | Shared infrastructure |
