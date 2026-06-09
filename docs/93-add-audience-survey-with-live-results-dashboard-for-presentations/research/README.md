# Research — Issue #93 Audience Survey

Breadth-first summary of five parallel research tracks covering the terrain for
implementing an anonymous audience survey with live-updating results dashboard.

---

## Table of Contents

- [existing-turbo-patterns/](existing-turbo-patterns/README.md) — How the app currently broadcasts Turbo Stream updates; which pattern fits a live aggregate dashboard
- [survey-schema/](survey-schema/README.md) — Database schema design for storing all survey fields; migration sketch
- [live-results-dashboard/](live-results-dashboard/README.md) — Real-time update strategies; results UI layout and CSS bar charts
- [mobile-form-ux/](mobile-form-ux/README.md) — CSS gap analysis and mobile-first form patterns for anonymous QR-code access
- [rails-routing/](rails-routing/README.md) — Route and controller structure; singular resource recommendation

---

## Breadth-first summary

### existing-turbo-patterns

The app uses `Turbo::StreamsChannel` class methods exclusively — no custom ActionCable channel classes exist. Two patterns are in production:

- **Tab-scoped** (`FizzBuzzJob`): broadcasts to `"fizz_buzz_channel:#{tab_token}"` so each browser tab gets its own stream
- **Global fan-out** (`PublishGistJob`): broadcasts to the symbolic `:links` channel so all viewers of `/links` receive the update simultaneously

The `:links` fan-out is the direct precedent for the survey dashboard. Broadcasting from a job after each `SurveyResponse.create` (using `Turbo::StreamsChannel.broadcast_replace_to(:survey_results, ...)`) is the recommended approach. `solid_cable 4.0.0` backs WebSockets in production via a dedicated SQLite database; the development adapter is in-process `async`.

Key files: `app/jobs/publish_gist_job.rb`, `app/views/links/index.html.erb`, `config/cable.yml`

→ [broadcast-mechanism.md](existing-turbo-patterns/broadcast-mechanism.md) · [aggregate-broadcast-options.md](existing-turbo-patterns/aggregate-broadcast-options.md)

---

### survey-schema

A **single flat `survey_responses` table** (18 columns) is recommended over a normalized approach. This matches the existing `ruby_llm_evals_*` flat-table convention and keeps all aggregation queries to single-table scans.

Key decisions:
- **Enum fields** (role, paid_to_write_ruby, years_of_experience, prior_experience, team_ai_adoption): string columns with Rails `enum` macro + `validate: true`
- **Multi-select AI tools**: single `text` column with `serialize :ai_tools, coder: JSON`; SQLite's `json_each()` or simple Ruby-side aggregation at survey scale
- **Likert items**: 6 separate `integer` columns (1–5), one per statement; enables `AVG(likert_overhyped)` in a single SQL expression without unpivoting
- **Location**: plain `text` (free-form)
- **`submitted_at`**: required datetime for ordering without exposing identity

→ [schema-options.md](survey-schema/schema-options.md) · [aggregation-queries.md](survey-schema/aggregation-queries.md)

---

### live-results-dashboard

`Turbo::StreamsChannel.broadcast_replace_to(:survey_results, target: "results_panel", partial: "surveys/results_panel", locals: { stats: })` called **directly in `SurveysController#create`** after a successful save is the recommended approach. This avoids job-queue race conditions (two near-simultaneous saves could broadcast stale aggregates if a queued job beats the second DB commit) and needs no extra job class.

Results are displayed as CSS bar charts — inline `width: X%` on `<span>` elements with `transition: width 0.4s ease-out` for smooth Turbo Stream swap animations. No charting gem. Three partials: `results.html.erb` (page + subscribe), `_results_panel.html.erb` (replace target `#results_panel`), `_question_result.html.erb` (one question card).

→ [update-strategies.md](live-results-dashboard/update-strategies.md) · [results-ui-design.md](live-results-dashboard/results-ui-design.md)

---

### mobile-form-ux

The app uses the hand-written "Johari design language" CSS system — **zero media queries** exist today. The viewport meta tag is already set correctly for mobile. Key gaps to fill with ~120 lines of new CSS:

- `.btn` is ~28px tall (below 44px iOS minimum) — survey buttons need `min-height: 44px`
- `.form-field input { width: 24rem }` overflows phone viewports — survey fields need `width: 100%`
- No `textarea` styles — needs `width: 100%; font-size: 1rem` (prevents iOS Safari auto-zoom)
- Likert matrix (6 rows × 5 columns) needs `@media (max-width: 600px)` to stack vertically
- 80px fixed bottom drawer competes with survey content — suppress via `content_for :no_drawer`

`form_with`, `collection_radio_buttons`, and `collection_check_boxes` with block patterns are the correct Rails helpers. No auth gem exists; a `SurveysController < ApplicationController` is public by default. CSRF handled automatically by `form_with`.

→ [existing-css-inventory.md](mobile-form-ux/existing-css-inventory.md) · [mobile-form-patterns.md](mobile-form-ux/mobile-form-patterns.md)

---

### rails-routing

`resource :survey, only: [:show, :create] do; get :results, on: :member; end` — singular resource, no ID, QR-friendly URLs (`/survey`, `/survey/results`). A single `SurveysController` with `show` (form), `create` (submit + broadcast), `results` (dashboard) matches the app's flat controller-per-feature structure. No authentication changes needed. Turbo Stream format handling follows the existing pattern: no `respond_to` block in the controller; the view subscribes with `turbo_stream_from :survey_results` and receives asynchronous broadcasts.

Named helpers: `survey_path` (GET/POST), `results_survey_path` (GET).

→ [route-options.md](rails-routing/route-options.md) · [controller-design.md](rails-routing/controller-design.md)
