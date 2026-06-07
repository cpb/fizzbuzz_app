# app/

## Routes

| Method | Path | Controller#action | UI surface |
|---|---|---|---|
| `GET` | `/` | `FizzBuzzController#start` | Form: enter a starting number, optional "Use LLM" checkbox, click Start |
| `POST` | `/` | `FizzBuzzController#create` | Redirects back to GET; enqueues `FizzBuzzJob` or `LlmFizzBuzzJob` |
| `GET` | `/up` | `Rails::HealthController#show` | Health check — returns 200 when the server is ready |

## Key behaviour

`FizzBuzzController#create` reads `params[:starting_integer]`, generates a UUID `tab_token`, redirects back to the form with `starting_integer`, `tab_token`, and `use_llm` params. When `params[:use_llm]` is present it enqueues `LlmFizzBuzzJob`; otherwise `FizzBuzzJob`. Both are enqueued with `set(wait: 1.second).perform_later(starting - 1, tab_token)` (skipped when starting is 1).

`FizzBuzzJob` broadcasts a Turbo Stream append to `"fizz_buzz_channel:#{tab_token}"` for the current number's FizzBuzz result, sleeps 1 second, then enqueues itself for `number - 1` with the same `tab_token` until it reaches 1. Results appear in the `#results` div in real time.

`LlmFizzBuzzJob` follows the same broadcast/countdown pattern, delegating to `LlmFizzBuzzer.call(number)`. Currently a painted-door stub that returns `number.to_s`; real inference is wired in issue #51.

The `tab_token` travels in the URL so each browser tab gets its own scoped channel — tabs stream independently and do not share results.

## Key UI elements

- **Number field**: `starting_integer` (default 10)
- **Use LLM checkbox**: `use_llm` (value `"1"` when checked; absent when unchecked)
- **Submit button**: "Start"
- **Results container**: `#results` div, populated by Turbo Stream appends
- **Turbo Stream subscription**: `fizz_buzz_channel:#{tab_token}` (present only after form submit)
