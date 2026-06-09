# Update Strategies for Live Survey Results

## Existing App Patterns

Two broadcast patterns are already in use:

1. **Per-tab async job** (`FizzBuzzJob`) — broadcasts `prepend` to a
   UUID-scoped channel `"fizz_buzz_channel:#{tab_token}"` so each browser tab
   gets its own stream.
2. **Named-symbol channel from job** (`PublishGistJob`) — broadcasts `append`
   or `replace` to the symbol `:links` (a shared channel, all viewers of
   `/links` receive the update).

The survey results page is a **shared channel** scenario: many viewers watch
the same aggregated data, so the `:links` job pattern is the closest
analogue. No per-tab scoping is needed.

---

## Option A — Broadcast-replace from controller after save (RECOMMENDED)

```ruby
# app/controllers/survey_responses_controller.rb
def create
  @response = SurveyResponse.new(response_params)
  if @response.save
    stats = SurveyResponse.aggregate_stats(@response.survey)
    Turbo::StreamsChannel.broadcast_replace_to(
      :survey_results,
      target: "results_panel",
      partial: "surveys/results_panel",
      locals: { survey: @response.survey, stats: stats }
    )
    redirect_to survey_thankyou_path(@response.survey)
  else
    render :new, status: :unprocessable_entity
  end
end
```

Results page subscribes with:

```erb
<%= turbo_stream_from :survey_results %>
<div id="results_panel">
  <%= render "surveys/results_panel", survey: @survey, stats: @stats %>
</div>
```

**Assessment:**

| Criterion | Rating |
|---|---|
| Simplicity | Excellent — 3 lines, no job, no callback |
| Correctness under concurrency | Good — each response triggers its own broadcast; rare near-simultaneous saves produce two broadcasts a few ms apart; the later one wins in the DOM and shows the correct final count |
| Fit with existing patterns | Excellent — mirrors `PublishGistJob`'s `broadcast_replace_to :links` pattern |
| Latency | Sub-second for all viewers |
| Dependency | None; solid_cable already wired for production |

**Trade-off:** The aggregate query runs in the request cycle, adding a small
DB read after each save. For a typical audience survey (dozens to low hundreds
of responses), this is negligible. At very high concurrency (hundreds of
simultaneous submitters) you would see the request thread blocked briefly, but
this is not a realistic concern for a presenter tool.

---

## Option B — Broadcast from an after_create callback or job (async)

```ruby
# app/models/survey_response.rb
after_create_commit -> { BroadcastSurveyResultsJob.perform_later(survey_id) }

# app/jobs/broadcast_survey_results_job.rb
class BroadcastSurveyResultsJob < ApplicationJob
  queue_as :default

  def perform(survey_id)
    survey = Survey.find(survey_id)
    stats  = SurveyResponse.aggregate_stats(survey)
    Turbo::StreamsChannel.broadcast_replace_to(
      :survey_results,
      target: "results_panel",
      partial: "surveys/results_panel",
      locals: { survey: survey, stats: stats }
    )
  end
end
```

**Assessment:**

| Criterion | Rating |
|---|---|
| Simplicity | Moderate — adds a job class and a callback |
| Correctness under concurrency | Slightly worse — job queue can reorder; two near-simultaneous responses may enqueue two jobs that run in the wrong order (race between job pickup and aggregate query). The second job may broadcast stale data if job A runs after job B finishes. |
| Fit with existing patterns | Good — matches `FizzBuzzJob` / `PublishGistJob` style |
| Latency | 100 ms–few seconds depending on solid_queue worker load |
| Dependency | Requires solid_queue worker running |

**Verdict:** Adds complexity without meaningful benefit for this use case. The
async broadcast can also race: if two responses arrive 10 ms apart, both jobs
enqueue and the first job's `aggregate_stats` call may still see only one row
if it beats the DB commit of the second response. Option A avoids this
entirely because the broadcast happens after the successful save.

---

## Option C — Meta-refresh or `setInterval` polling

```html
<!-- meta-refresh -->
<meta http-equiv="refresh" content="5">

<!-- or JavaScript -->
<script>setInterval(() => location.reload(), 5000)</script>
```

**Assessment:**

| Criterion | Rating |
|---|---|
| Simplicity | High — no Turbo code at all |
| Correctness | Good — eventual consistency within the polling interval |
| Fit with existing patterns | Poor — the app uses Turbo Streams everywhere; full-page reload is jarring on a projector |
| Latency | Up to 5 seconds behind |
| UX | Full-page flash disrupts readability on a projected screen |

**Verdict:** Acceptable fallback if WebSocket/cable is unavailable, but should
not be the primary strategy given the app's Hotwire foundation.

---

## Option D — Turbo Frame polling

```erb
<turbo-frame id="results_panel"
             src="<%= survey_results_path(@survey) %>"
             refresh="interval"
             data-interval="5000">
  <%= render "surveys/results_panel", survey: @survey, stats: @stats %>
</turbo-frame>
```

**Assessment:**

| Criterion | Rating |
|---|---|
| Simplicity | Moderate — needs a dedicated JSON/HTML endpoint that returns only the frame content |
| Correctness | Good — eventual consistency at 5 s |
| Fit with existing patterns | Weak — no Turbo Frames exist in the app today |
| Latency | Up to 5 seconds |
| UX | Smooth DOM swap, no full-page flash |

**Verdict:** A reasonable choice if WebSocket support is unavailable (e.g.,
certain CDN/proxy configurations). Still inferior to push-based Turbo Streams
for a live-results projector display.

---

## Recommendation Summary

**Use Option A (broadcast-replace from controller).** It is the simplest
implementation, directly mirrors the `:links` broadcast pattern already in
`PublishGistJob`, delivers the lowest latency, and avoids the concurrency race
conditions introduced by async jobs.

### Channel naming

Use the symbol `:survey_results`. This matches the `:links` symbol already
used in `PublishGistJob` and `turbo_stream_from :links` in
`links/index.html.erb`. Symbols produce the string `"survey_results"` as the
channel name — simple, readable, and scoped clearly to this feature.

If the app ever hosts multiple simultaneous surveys you would scope to a
survey-specific channel: `"survey_results:#{survey.id}"`. For issue #93
(single presenter survey), the global symbol is sufficient.

---

## Aggregation Query Design

The `aggregate_stats` method should return a structure that the partial can
render without additional queries.

### Proposed data structure

```ruby
# Returns:
# {
#   question_id => {
#     question: <Question>,
#     total:    Integer,          # total responses for this question
#     breakdown: [
#       { label: "Strongly agree", value: "strongly_agree", count: 12, pct: 60.0 },
#       { label: "Agree",          value: "agree",          count: 5,  pct: 25.0 },
#       ...
#     ],
#     mean: Float | nil           # only for Likert/numeric questions
#   },
#   ...
# }

def self.aggregate_stats(survey)
  rows = where(survey: survey)
           .group(:question_id, :answer_value)
           .count  # => { [q_id, answer] => count, ... }

  totals = rows.each_with_object(Hash.new(0)) do |((q_id, _), count), h|
    h[q_id] += count
  end

  survey.questions.index_with do |question|
    q_id    = question.id
    total   = totals[q_id].to_f
    choices = question.answer_options  # ordered list of {value:, label:} hashes

    breakdown = choices.map do |opt|
      count = rows[[q_id, opt[:value]]] || 0
      { label: opt[:label], value: opt[:value], count: count,
        pct: total > 0 ? (count / total * 100).round(1) : 0.0 }
    end

    numeric_rows = breakdown.select { |b| b[:value].match?(/\A\d+\z/) }
    mean = if numeric_rows.any? && total > 0
             numeric_rows.sum { |b| b[:value].to_i * b[:count] } / total
           end

    { question: question, total: total.to_i, breakdown: breakdown, mean: mean }
  end
end
```

### Why a single GROUP BY query

A single `GROUP BY question_id, answer_value` query returns all counts in one
round-trip. This is preferable to N+1 queries (one per question) when
broadcasting after each save, keeping the request cycle fast.

SQLite3 handles this efficiently for the expected data volumes (hundreds to
low thousands of rows for a presentation survey).
