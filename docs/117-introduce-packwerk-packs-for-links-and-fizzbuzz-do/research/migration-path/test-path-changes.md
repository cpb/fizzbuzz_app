# Test Path Changes

## Does bin/rails test Discover packs/*/test/?

**No.** By default, `bin/rails test` discovers test files only under `test/`.
Moving tests to `packs/*/test/` requires either:

1. Passing pack test directories explicitly:
   ```sh
   bin/rails test test/ packs/links/test/ packs/fizzbuzz/test/
   ```
2. Adding a custom Rake task that globs `packs/**/test/**/*_test.rb`
3. Modifying `Rakefile` to include pack test paths in the default test task

## Recommendation: Keep Tests at Root

**Keep all tests in the existing `test/` directory for Issue #117.**

Rationale:
- Packwerk does not analyze test files for boundary violations — test code can
  reference any constant from any pack without creating violations
- `bin/rails test` continues to work unchanged with no configuration
- test_helper.rb, fixtures, cassettes, and system test infrastructure all
  assume `test/` as root
- Moving tests to packs is a future enhancement that can be done independently

The acceptance criteria for Issue #117 is "full test suite passes after
restructure" — keeping tests at root guarantees this without risk.

## VCR Cassettes

`test/test_helper.rb` configures:
```ruby
VCR.configure do |config|
  config.cassette_library_dir = "test/cassettes"
  ...
end
```

VCR cassettes (in `test/cassettes/`) reference the cassette name as a string
in each test file. Moving cassettes would require:
1. Updating `cassette_library_dir` in test_helper.rb
2. Updating cassette name strings in every test that uses VCR

**Decision: cassettes stay at `test/cassettes/`.**

## Fixtures

`test/test_helper.rb` loads fixtures with `fixtures :all`, which finds all
YAML files under `test/fixtures/`. Moving fixtures to `packs/*/test/fixtures/`
would require changing this line.

**Decision: fixtures stay at `test/fixtures/`.**

## evals/ Root Directory

The `evals/` directory at the Rails root contains YAML data files loaded by:
- `lib/eval_loader.rb` — seeds the database at boot (development/test)
- `EvalTestSetup` in `test/support/eval_test_setup.rb` — sets fixture_paths
  for eval tests

Moving `evals/` to `packs/fizzbuzz/evals/` would require updating the load
paths in `lib/eval_loader.rb` and the fixture_paths in `eval_test_setup.rb`.

**Decision for Issue #117: `evals/` stays at the Rails root.**

The evals infrastructure (`EvalLoader`, `EvalTestSetup`) is not changed by
this issue. Moving `evals/` into the fizzbuzz pack is a follow-up concern.
The `test/evals/*.rb` test files also stay at root.

## test/support/ Files

`test/support/eval_fixture_writer.rb` and `test/support/eval_test_setup.rb`
are shared test infrastructure required by the evals tests. They stay at root.

## Summary Table

| Location | Move? | Reason |
|----------|-------|--------|
| `test/models/*_test.rb` | No | bin/rails test discovers test/ |
| `test/controllers/*_test.rb` | No | Same |
| `test/jobs/*_test.rb` | No | Same |
| `test/system/*_test.rb` | No | Same |
| `test/evals/*.rb` | No | EvalTestSetup paths; low value for packwerk |
| `test/helpers/` | No | Low value for packwerk |
| `test/configuration/` | No | Low value for packwerk |
| `test/lib/` | No | Low value for packwerk |
| `test/support/` | No | Shared infrastructure |
| `test/cassettes/` | No | cassette_library_dir in test_helper.rb |
| `test/fixtures/` | No | fixtures :all in test_helper.rb |
| `evals/` | No | EvalLoader paths; separate concern |
