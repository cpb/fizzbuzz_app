# packs/fizzbuzz

## Source

| File | Role |
|---|---|
| `app/controllers/fizz_buzz_controller.rb` | Form entry, tab-token generation, job dispatch |
| `app/models/fizz_buzzer.rb` | Core FizzBuzz logic |
| `app/models/llm_fizz_buzzer.rb` | LLM variant — currently a stub returning `number.to_s` (see #51) |
| `app/jobs/fizz_buzz_job.rb` | Countdown broadcaster |
| `app/jobs/llm_fizz_buzz_job.rb` | LLM countdown broadcaster |
| `app/views/fizz_buzz/` | Form and Turbo Stream result partial |

## Routes

| Method | Path | Action | UI surface |
|---|---|---|---|
| `GET` | `/` | `FizzBuzzController#start` | Form: starting number field, "Use LLM" checkbox, Start button |
| `POST` | `/` | `FizzBuzzController#create` | Redirects back to GET; enqueues job |

## Key behaviour

`FizzBuzzController#create` reads `params[:starting_integer]`, generates a UUID `tab_token`, redirects back to the form with `starting_integer`, `tab_token`, and `use_llm` params. When `params[:use_llm]` is present it enqueues `LLMFizzBuzzJob`; otherwise `FizzBuzzJob`. Both are enqueued with `set(wait: 1.second).perform_later(starting - 1, tab_token)` (skipped when starting is 1).

`FizzBuzzJob` broadcasts a Turbo Stream append to `"fizz_buzz_channel:#{tab_token}"` for the current number's FizzBuzz result, sleeps 1 second, then enqueues itself for `number - 1` with the same `tab_token` until it reaches 1.

The `tab_token` travels in the URL so each browser tab gets its own scoped channel — tabs stream independently and do not share results.

## Key UI elements

- **Number field**: `starting_integer` (default 10)
- **Use LLM checkbox**: `use_llm` (value `"1"` when checked; absent when unchecked)
- **Submit button**: "Start"
- **Results container**: `#results` div, populated by Turbo Stream appends
- **Turbo Stream subscription**: `fizz_buzz_channel:#{tab_token}` (present only after form submit)

## Tests

| Test file | What it covers |
|---|---|
| `test/models/fizz_buzzer_test.rb` | `FizzBuzzer.call` returns correct string for multiples of 3, 5, 15, and plain numbers |
| `test/models/llm_fizz_buzzer_test.rb` | `LLMFizzBuzzer.call` correctness — all tests skipped pending real inference (see #51) |
| `test/controllers/fizz_buzz_controller_test.rb` | `GET /` returns 200; `POST` enqueues `FizzBuzzJob` or `LLMFizzBuzzJob` based on `use_llm`; `POST` with 1 does not enqueue; redirect URL includes a UUID `tab_token` |
| `test/jobs/fizz_buzz_job_test.rb` | Job counts down, stops at 1, broadcasts to `fizz_buzz_channel:#{tab_token}` (not global channel), carries token through each iteration |
| `test/jobs/llm_fizz_buzz_job_test.rb` | Same structural guarantees as `fizz_buzz_job_test.rb` for the LLM variant |
| `test/system/fizz_buzz_test.rb` | Fill form → click Start → results appear via Turbo Stream; default starting number is 10; tab A stream is unaffected when tab B submits afterward |

## Manual confirmation needed

- **Job timing**: The 1-second sleep between broadcasts is not exercised — jobs run with `:async_job` adapter in system tests, not in real time.
- **WebSocket error paths**: No test covers Turbo Stream connectivity failures or reconnection.
