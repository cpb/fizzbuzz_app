# test/

Domain test coverage lives alongside the code — see each pack's `CLAUDE.md`:

| Pack | Tests |
|---|---|
| `packs/fizzbuzz/CLAUDE.md` | FizzBuzzer, LLMFizzBuzzer, controller, jobs, system test |
| `packs/links/CLAUDE.md` | LinksController, Link, Gist, GistPublisher, PublishGistJob, system test |
| `packs/surveys/CLAUDE.md` | SurveysController, system test |

## Root test files

- `test/configuration/` — `EvaluationConfigurationTest`: RubyLLM eval job lifecycle (VCR cassettes in `test/cassettes/`)
- `test/evals/` — LLM eval suites; cassettes in `test/cassettes/`
- `test/helpers/` — view helper tests
- `test/lib/` — eval loader tests

## Test setup

- **System tests**: Falcon web server via Rackup, Capybara + headless Chrome (1400×1400), queue adapter switched to `:async_job` per test.
- **Unit / controller tests**: Standard Rails test queue (`:test` adapter, synchronous).
- **VCR**: `cassette_library_dir = Rails.root` — cassette names are full relative paths. Use `use_cassette("short_name")` (not `VCR.use_cassette`) — the helper auto-derives the directory from the calling test file's location.
- **Fixtures**: `fixture_paths` includes `test/fixtures/` and all `packs/*/test/fixtures/` directories.

## Manual confirmation needed

- **Job timing**: The 1-second sleep between broadcasts is not exercised in automated tests.
- **WebSocket error paths**: No test covers Turbo Stream connectivity failures or reconnection.
- **Multi-worktree isolation**: Separate worktrees not sharing ports, storage, or PIDs is not covered by automated tests.

Run all tests with `bin/rails test`.
