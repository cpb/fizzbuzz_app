# Aggregate Broadcast Options — Deep Dive

## The challenge

The audience survey dashboard must show live-updating aggregate results (vote counts and percentages per answer option) to **all currently connected results-page viewers** whenever any viewer submits a survey response. This is a fundamentally different broadcast pattern from what the app currently uses for FizzBuzz (per-tab) and link updates (per-record + session).

Key requirements:
1. A single survey response from viewer A must update the dashboard for viewers B, C, D, … in real time.
2. The broadcast target is a shared channel — not scoped per user or per tab.
3. The payload is aggregate data (totals + percentages), not raw individual records.
4. Latency must feel live (sub-second for an audience in a room).

---

## Option A: Broadcast from a job after each save (recommended)

### How it maps to existing patterns

This is a direct extension of the FizzBuzz/PublishGist job pattern. After a `SurveyResponse` record is saved (in the controller), a job is enqueued that recomputes aggregates and broadcasts to a shared survey channel.

```ruby
# Proposed: app/jobs/broadcast_survey_results_job.rb
class BroadcastSurveyResultsJob < ApplicationJob
  queue_as :default

  def perform(survey_id)
    survey = Survey.find(survey_id)
    aggregates = survey.compute_aggregates   # e.g. { "Yes" => { count: 12, pct: 60 }, ... }
    Turbo::StreamsChannel.broadcast_replace_to(
      "survey_results:#{survey_id}",
      target: "survey_results_dashboard",
      partial: "surveys/results_dashboard",
      locals: { aggregates: aggregates, survey: survey }
    )
  end
end
```

The channel name `"survey_results:#{survey_id}"` follows the existing `"fizz_buzz_channel:#{tab_token}"` convention (namespaced string), but scoped to a survey rather than a tab — any number of viewers can subscribe to the same stream.

### Trigger

```ruby
# Proposed: app/controllers/survey_responses_controller.rb
def create
  @response = SurveyResponse.new(response_params)
  if @response.save
    BroadcastSurveyResultsJob.perform_later(@response.survey_id)
    head :no_content  # or redirect
  else
    render :new, status: :unprocessable_entity
  end
end
```

### Subscription in the results view

```erb
<%# Proposed: app/views/surveys/results.html.erb %>
<%= turbo_stream_from "survey_results:#{@survey.id}" %>
<div id="survey_results_dashboard">
  <%= render partial: "surveys/results_dashboard",
             locals: { aggregates: @survey.compute_aggregates, survey: @survey } %>
</div>
```

### Pros

- Directly follows the established job-based broadcast pattern already used for FizzBuzz and links
- Off-loads aggregate computation from the request cycle — the HTTP response returns fast
- Works with existing `solid_queue` / `async` job adapters (no new infrastructure)
- Natural fit if aggregate computation becomes expensive (can add debouncing by skipping the job if one is already queued for this survey)
- solid_cable handles fan-out to all subscribers transparently — the job needs to call `broadcast_*` exactly once

### Cons

- Adds one hop (request → job queue → job → cable) vs. inline broadcast
- In development (`async` adapter), the job runs in-process, which is fine; in production with `solid_queue` the latency is still well under a second

### Verdict: **Best fit**

---

## Option B: Broadcast directly from the controller

### Pattern

```ruby
# In SurveyResponsesController#create
def create
  @response = SurveyResponse.new(response_params)
  if @response.save
    aggregates = @response.survey.compute_aggregates
    Turbo::StreamsChannel.broadcast_replace_to(
      "survey_results:#{@response.survey_id}",
      target: "survey_results_dashboard",
      partial: "surveys/results_dashboard",
      locals: { aggregates: aggregates }
    )
    head :no_content
  end
end
```

This is simpler — fewer moving parts, no job class needed.

### Pros

- Simpler code path; easier to reason about in development
- Matches what `PublishGistJob` does conceptually but without the async hop

### Cons

- **Blocks the HTTP response** while rendering the partial and pushing to solid_cable. For a room of 200 people submitting at the same time, this could slow down the submission acknowledgment.
- Couples broadcast logic to the controller — harder to test and reuse
- If aggregate computation involves a DB query with many rows, it runs synchronously in the web worker

### Verdict: Viable for low-concurrency scenarios; prefer Option A for production robustness

---

## Option C: Scheduled/polling approach

### Pattern

A recurring job (via `solid_queue`'s `config/recurring.yml`) computes aggregates and broadcasts every N seconds regardless of submissions.

```yaml
# config/recurring.yml
broadcast_survey_results:
  class: BroadcastSurveyResultsJob
  schedule: every 2 seconds
  args: [1]   # survey_id
```

### Pros

- Decoupled from submission events — the broadcast rate is fixed regardless of traffic spikes
- Would smooth out thundering-herd problems if hundreds of people submit simultaneously

### Cons

- **Does not feel live** — 2-second polling means visible lag in a presentation context
- Wastes resources broadcasting even when nobody submitted
- The survey ID must be known at schedule time, which is awkward for dynamic surveys
- `config/recurring.yml` already exists in the app but is designed for background maintenance tasks, not user-triggered liveness

### Verdict: Not recommended; use only as a fallback/heartbeat alongside Option A

---

## Gaps and new patterns needed

### 1. Shared survey channel (minor extension)

The existing `:links` symbolic channel shows the app can do shared fan-out. A survey channel `"survey_results:#{survey_id}"` extends this to survey-scoped fan-out. No new infrastructure is required.

### 2. `broadcast_replace_to` for aggregate replacement

FizzBuzz uses `broadcast_prepend_to` (new items added). The survey dashboard needs `broadcast_replace_to` (the whole dashboard element is swapped with fresh aggregates). This method is already used by `PublishGistJob` for per-link updates — it's available and understood.

### 3. No custom ActionCable channel needed

The app has no `app/channels/` files at all. The survey feature should continue this pattern — everything through `Turbo::StreamsChannel`. No custom Ruby channel class is needed.

### 4. Aggregate computation model method

No existing model does aggregate computation. The new `Survey` model will need a `compute_aggregates` method (or equivalent scope) that returns per-option counts and percentages. This is a standard ActiveRecord `group(:answer).count` query.

### 5. Development vs. production adapter difference

In development, `config/cable.yml` uses the `async` adapter (in-process). This means broadcast from a job works only because the job also runs in-process via the `async` job adapter. The comment in `cable.yml` warns explicitly:

> "the async adapter only works within the same process, so for manually triggering cable updates from a console … you must do so from the web console"

In production, `solid_cable` uses a separate SQLite database (`storage/production_cable.sqlite3`), polling every 0.1 seconds with a 1-day message retention. The job-based approach works correctly in both environments.

---

## Recommended implementation blueprint

```
SurveyResponse#create (controller)
  → SurveyResponse.save
  → BroadcastSurveyResultsJob.perform_later(survey.id)
       → Survey.compute_aggregates
       → Turbo::StreamsChannel.broadcast_replace_to(
             "survey_results:#{survey.id}",
             target: "survey_results_dashboard",
             partial: "surveys/results_dashboard",
             locals: { aggregates: ..., survey: ... }
           )

All results-page viewers (subscribed via turbo_stream_from "survey_results:#{survey.id}")
  → receive the Turbo Stream replace action
  → #survey_results_dashboard element is swapped with updated HTML
```

This pattern requires:
- 1 new job class: `BroadcastSurveyResultsJob`
- 1 new partial: `app/views/surveys/_results_dashboard.html.erb`
- `turbo_stream_from` in the results view
- `compute_aggregates` method on `Survey` model
- No changes to cable infrastructure, no custom channels
