# test/

## Automated coverage

| Test file | What it covers |
|---|---|
| `test/models/fizz_buzzer_test.rb` | `FizzBuzzer.call` returns correct string for multiples of 3, 5, 15, and plain numbers |
| `test/models/llm_fizz_buzzer_test.rb` | `LlmFizzBuzzer.call` correctness — all tests skipped pending real inference (see #51) |
| `test/controllers/fizz_buzz_controller_test.rb` | `GET /` returns 200; `POST` enqueues `FizzBuzzJob` or `LlmFizzBuzzJob` based on `use_llm` param; `POST` with 1 does not enqueue; redirect URL includes a UUID `tab_token` |
| `test/jobs/fizz_buzz_job_test.rb` | Job counts down, stops at 1, broadcasts to `fizz_buzz_channel:#{tab_token}` (not global channel), carries token through each iteration |
| `test/jobs/llm_fizz_buzz_job_test.rb` | Same structural guarantees as `fizz_buzz_job_test.rb` for the LLM variant |
| `test/system/fizz_buzz_test.rb` | Fill form → click Start → results appear via Turbo Stream; default starting number is 10; tab A stream is unaffected when tab B submits afterward; "Use LLM" checkbox test skipped pending VCR-backed fakes (see #51) |

## What needs manual confirmation

- **Job timing**: The 1-second sleep between broadcasts is not exercised — jobs run with `:async_job` adapter in system tests, not in real time.
- **WebSocket error paths**: No test covers Turbo Stream connectivity failures or reconnection.
- **Multi-worktree isolation**: That separate worktrees do not share ports, storage, or PIDs is not covered by automated tests.

## Test setup

- **System tests**: Falcon web server via Rackup, Capybara + headless Chrome (1400×1400), queue adapter switched to `:async_job` per test so jobs run asynchronously.
- **Unit / controller tests**: Standard Rails test queue (`:test` adapter, synchronous).

Run all tests with `bin/rails test`.
