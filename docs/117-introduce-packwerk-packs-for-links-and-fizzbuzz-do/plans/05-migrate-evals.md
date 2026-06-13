# Plan: Migrate Evals Infrastructure into packs/fizzbuzz

**Decision:** Move the evals data directory (`evals/`), eval test files (`test/evals/`),
and eval support infrastructure (`test/support/eval_*.rb`, `test/helpers/`,
`test/configuration/`, `test/lib/eval_loader_test.rb`) into `packs/fizzbuzz/`. Update
`EvalLoader` to reference the new data path.

**Rationale:** The evals infrastructure is fizzbuzz-domain code — it tests and seeds
fizzbuzz prompts, samples, and LLM evaluation runs. Leaving it at root contradicts the
domain boundary enforced by `packs/fizzbuzz`. The complexity of the path updates was the
original reason for deferral (see `test-path-changes.md`); this plan resolves them
systematically.

See: [test-path-changes.md](../research/migration-path/test-path-changes.md)

---

## Steps

### 1. Move evals/ data directory

```sh
git mv evals/ packs/fizzbuzz/evals/
```

Update `lib/eval_loader.rb` — change the root-relative path to the new pack-relative path.
Find the line that references `Rails.root.join("evals", ...)` and change `"evals"` to
`"packs/fizzbuzz/evals"`. Example:

```ruby
# Before
def self.seed_dir
  Rails.root.join("evals")
end

# After
def self.seed_dir
  Rails.root.join("packs/fizzbuzz/evals")
end
```

Update `config/deploy.yml` Kamal seed-evals aliases if they reference `evals/` paths
directly — update to `packs/fizzbuzz/evals/`.

### 2. Move test/evals/

```sh
mkdir -p packs/fizzbuzz/test/evals
git mv test/evals/*.rb packs/fizzbuzz/test/evals/
```

### 3. Move eval support files

```sh
mkdir -p packs/fizzbuzz/test/support
git mv test/support/eval_fixture_writer.rb   packs/fizzbuzz/test/support/
git mv test/support/eval_test_setup.rb       packs/fizzbuzz/test/support/
```

### 4. Move related test infrastructure

```sh
mkdir -p packs/fizzbuzz/test/helpers/ruby_llm/evals
mkdir -p packs/fizzbuzz/test/configuration
mkdir -p packs/fizzbuzz/test/lib

git mv test/helpers/ruby_llm/evals/runs_helper_test.rb \
       packs/fizzbuzz/test/helpers/ruby_llm/evals/
git mv test/configuration/evaluation_configuration_test.rb \
       packs/fizzbuzz/test/configuration/
git mv test/lib/eval_loader_test.rb \
       packs/fizzbuzz/test/lib/
```

### 5. Update require paths in moved test files

All moved test files that use `require_relative` to reference support files need updating.
Change `require_relative "../../support/eval_test_setup"` patterns to `require "test_helper"`
(Rails adds `test/` to the load path, and `eval_test_setup.rb` is no longer at that
root-relative path).

Update `EvalTestSetup` in `packs/fizzbuzz/test/support/eval_test_setup.rb` — any
`fixture_paths` additions that reference root-relative paths need to be updated to
reference `packs/fizzbuzz/test/fixtures/` or remain at `test/fixtures/` (since
`fixtures :all` loads from `test/fixtures/` via Rails convention; if eval fixtures
moved to pack, update accordingly).

VCR cassettes stay at root (`test/cassettes/`) — `cassette_library_dir` in `test_helper.rb`
is root-relative and resolves correctly from pack test files.

### 6. Verify

```sh
bin/rails test packs/fizzbuzz/test/evals/
bin/rails test packs/fizzbuzz/test/
bin/rails test
```

All tests must pass. Pay particular attention to eval tests — they exercise VCR cassette
replay and fixture loading.

### 7. Commit

```sh
git add packs/fizzbuzz/evals/ packs/fizzbuzz/test/ lib/eval_loader.rb config/deploy.yml
git rm -r evals/ test/evals/ test/support/eval_*.rb
git commit -m "refactor: migrate evals infrastructure into packs/fizzbuzz — data dir, test/evals/, and support files"
```

---

## Open Questions

1. **EvalTestSetup fixture_paths**: Verify whether `EvalTestSetup` references
   `test/fixtures/ruby_llm/evals/` or the `evals/` data directory. If it uses the former,
   no change needed (fixtures stay at `test/fixtures/`). If it uses `evals/` data,
   update to `packs/fizzbuzz/evals/`.

2. **db/seeds.rb**: If seeds reference `EvalLoader` with a specific path, update the
   reference after the `evals/` move.

## Verification

- [ ] `bin/rails test packs/fizzbuzz/test/evals/` → all eval tests pass
- [ ] `bin/rails test` → full suite passes (root + all packs)
- [ ] `evals/` no longer exists at Rails root (`ls evals/ 2>&1 | grep "No such file"`)
- [ ] `packs/fizzbuzz/evals/fizzbuzz/` exists with prompts.yml, samples.yml, etc.
- [ ] `lib/eval_loader.rb` references `packs/fizzbuzz/evals` not `evals`
