# app/

## Routes

| Method | Path | Controller#action | UI surface |
|---|---|---|---|
| `GET` | `/` | `FizzBuzzController#start` | Form: enter a starting number and click Start |
| `POST` | `/` | `FizzBuzzController#create` | Redirects back to GET; enqueues `FizzBuzzJob` |
| `GET` | `/up` | `Rails::HealthController#show` | Health check — returns 200 when the server is ready |

## Key behaviour

`FizzBuzzController#create` reads `params[:starting_integer]`, redirects back to the form, and enqueues `FizzBuzzJob.set(wait: 1.second).perform_later(starting - 1)` (skipped when starting is 1).

`FizzBuzzJob` broadcasts a Turbo Stream append to the `fizz_buzz_channel` for the current number's FizzBuzz result, sleeps 1 second, then enqueues itself for `number - 1` until it reaches 1. Results appear in the `#results` div in real time.

## Key UI elements

- **Number field**: `starting_integer` (default 100)
- **Submit button**: "Start"
- **Results container**: `#results` div, populated by Turbo Stream appends
- **Turbo Stream subscription**: `fizz_buzz_channel`
