# Broadcast Mechanism — Deep Dive

## Overview

The app uses two distinct broadcast strategies, both routed through `Turbo::StreamsChannel` class methods. Neither broadcasts from a controller directly; all live updates originate in Active Jobs or ActiveRecord model callbacks (via `broadcast_replace_to`).

---

## Strategy 1: Job-Based Broadcasting (FizzBuzz flow)

### Files
- `app/jobs/fizz_buzz_job.rb`
- `app/jobs/llm_fizz_buzz_job.rb`

### Pattern

Both jobs follow the same structure:

```ruby
# app/jobs/fizz_buzz_job.rb  (lines 5-11)
def perform(number, tab_token)
  result = FizzBuzzer.call(number)
  Turbo::StreamsChannel.broadcast_prepend_to(
    "fizz_buzz_channel:#{tab_token}",
    target: "results",
    partial: "fizz_buzz/result",
    locals: { result: result }
  )
  sleep 1
  FizzBuzzJob.perform_later(number - 1, tab_token) if number > 1
end
```

`LLMFizzBuzzJob` (`app/jobs/llm_fizz_buzz_job.rb`) is identical in structure, substituting `LLMFizzBuzzer.call(number)` for computation.

### Key characteristics

| Property | Value |
|---|---|
| Broadcast method | `Turbo::StreamsChannel.broadcast_prepend_to` |
| Channel name | `"fizz_buzz_channel:#{tab_token}"` — tab-scoped UUID |
| Target DOM id | `"results"` |
| Partial | `"fizz_buzz/_result"` |
| Recursion | Self-chains via `perform_later(number - 1, tab_token)` with 1-second sleep |
| Scope | Strictly per-tab — only the tab that initiated the FizzBuzz session receives updates |

### Trigger chain

```
POST / (FizzBuzzController#create)
  → generates SecureRandom.uuid as tab_token
  → redirect_to root_path(starting_integer:, tab_token:, use_llm:)
  → FizzBuzzJob.set(wait: 1.second).perform_later(starting, tab_token)
      → broadcast_prepend_to "fizz_buzz_channel:#{tab_token}"
      → recurse until number == 0
```

The `tab_token` is passed as a query parameter in the redirect URL (`start.html.erb` line 21: `params[:tab_token]`), so each browser tab gets a unique subscription without any server-side session storage.

---

## Strategy 2: Job-Based Broadcasting (Links/Gist flow)

### File
- `app/jobs/publish_gist_job.rb`

### Pattern A — Model-level broadcast (per Link update)

```ruby
# app/jobs/publish_gist_job.rb  (line 13)
link.broadcast_replace_to [ link, session_id ],
  partial: "links/link",
  locals: { session_id: session_id }
```

This uses the ActiveRecord model's `broadcast_replace_to` convenience method (from `turbo-rails`). The channel name is derived from the array `[link, session_id]`, which turbo serializes to a compound stream name like `"gid://fizzbuzz-app/Link/42-session-abc"`.

### Pattern B — Class-level broadcast (new QR code for all links viewers)

```ruby
# app/jobs/publish_gist_job.rb  (lines 17-21)
Turbo::StreamsChannel.broadcast_append_to(
  :links,
  target: "qr_code_container",
  partial: "links/qr_code",
  locals: { gist: gist }
)
```

This broadcasts to the symbolic channel `:links` — all subscribers on the links index page see the QR code appear without being individually targeted. This is a **shared/global broadcast pattern**, the closest existing precedent for what the survey aggregate dashboard needs.

---

## The `broadcast_prepend_to` vs `broadcast_append_to` vs `broadcast_replace_to` methods

All three are class methods on `Turbo::StreamsChannel` (turbo-rails 2.0.23 / Rails 8.1.3):

| Method | Turbo Stream Action | Use in this app |
|---|---|---|
| `broadcast_prepend_to` | Inserts HTML before first child of target | FizzBuzz results (new numbers appear at top) |
| `broadcast_append_to` | Inserts HTML after last child of target | QR code added to bottom of `#qr_code_container` |
| `broadcast_replace_to` | Replaces the element with matching DOM id | Per-link update after gist publish |

---

## Partial rendering details

### `fizz_buzz/_result.html.erb`

```erb
<%# lines 1-7 %>
<% css_class = case result.to_s
               when /\AFizzBuzz\z/i then "result--fizzbuzz"
               when /\AFizz\z/i     then "result--fizz"
               when /\ABuzz\z/i     then "result--buzz"
               else                      "result--number"
               end %>
<p id="result_<%= Time.now.to_i %>" class="result <%= css_class %>"><%= result %></p>
```

Each result gets a unique DOM id via `Time.now.to_i` to avoid collision since prepend would otherwise stack identical ids.

---

## Channel naming conventions summary

| Channel | Type | Scope |
|---|---|---|
| `"fizz_buzz_channel:#{tab_token}"` | String with UUID suffix | Per browser tab |
| `[link, session_id]` | Array (serialized by turbo) | Per Link record + session |
| `:links` | Symbol | Global — all links-page viewers |

The symbolic `:links` channel is the **only existing fan-out/shared broadcast** in the codebase. Everything else is session- or tab-scoped.

---

## No custom ActionCable channels

There are no files in `app/channels/` beyond the Rails-generated defaults. All ActionCable usage is mediated entirely through `Turbo::StreamsChannel`, which is the built-in turbo-rails channel. This means:

- No custom subscription logic
- No `received` callbacks in JavaScript
- No `ActionCable.createConsumer` calls in JS
- All WebSocket communication is handled by Turbo's opaque client-side stream subscription mechanism

The only JavaScript files present are:
- `app/javascript/application.js` — imports `@hotwired/turbo-rails` and `controllers`
- `app/javascript/controllers/hello_controller.js` — a placeholder Stimulus controller (does nothing)
- `app/javascript/controllers/index.js` — registers controllers

No custom Stimulus controllers exist beyond `hello_controller.js`, which is unused in production views.
