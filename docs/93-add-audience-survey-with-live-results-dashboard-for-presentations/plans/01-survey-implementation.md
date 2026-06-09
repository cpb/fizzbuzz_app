# Plan: Audience Survey with Live Results Dashboard (Issue #93)

## Decision

Add a flat `survey_responses` table with a single `SurveysController` exposing
`show` (form), `create` (submit), and `results` (dashboard) under `resource :survey`.
On every submission the `create` action broadcasts `broadcast_replace_to(:survey_results, ...)`
directly — no extra job class — replacing `#results_panel` for all connected dashboard viewers
via `turbo_stream_from :survey_results`.

## Rationale

**Schema** — A flat single table with string-backed enums and a JSON-serialized `ai_tools`
column was chosen over a normalized join-table approach. The existing `ruby_llm_evals_*`
tables use the same flat pattern. SQLite performs best on single-table scans, and all
aggregation queries (`GROUP BY`, `AVG`) work directly without joins.
See: [survey-schema/schema-options.md] and [survey-schema/aggregation-queries.md].

**Broadcast strategy** — The research compared async-job broadcast vs. inline controller
broadcast. For this presenter tool (hundreds of responses, not thousands), broadcasting
directly in `create` after a successful save is simpler, avoids job-queue race conditions
(two near-simultaneous saves could broadcast stale aggregates if a job beats the second
DB commit), and matches the spirit of `PublishGistJob`'s `broadcast_replace_to :links`
pattern. See: [live-results-dashboard/update-strategies.md].

**Channel** — The symbol `:survey_results` follows the same convention as `:links` in
`PublishGistJob` and `turbo_stream_from :links` in `links/index.html.erb`. No custom
ActionCable channel class is needed; everything routes through `Turbo::StreamsChannel`.
See: [existing-turbo-patterns/broadcast-mechanism.md].

**Routing** — `resource :survey` (singular) is the correct Rails idiom for a single
global resource. It produces short, QR-friendly URLs (`/survey`, `/survey/results`) and
auto-generates all named helpers. See: [rails-routing/route-options.md].

**CSS** — The app has no media queries. Survey-specific CSS (~120 lines) is added under
a `/* Survey */` section in `application.css` using existing Johari design tokens only.
The bottom drawer is suppressed via `content_for :no_drawer` to reclaim 80px on mobile.
See: [mobile-form-ux/mobile-form-patterns.md] and [live-results-dashboard/results-ui-design.md].

---

## Steps

### 1. Migration — create `survey_responses`

Create `db/migrate/<timestamp>_create_survey_responses.rb`:

```ruby
class CreateSurveyResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :survey_responses do |t|
      t.text    :location
      t.string  :role,                  null: false
      t.boolean :writes_ruby,           null: false
      t.string  :paid_to_write_ruby,    null: false
      t.string  :years_of_experience,   null: false
      t.string  :prior_experience,      null: false
      t.string  :team_ai_adoption,      null: false
      t.text    :ai_tools,              null: false, default: "[]"
      t.integer :likert_overhyped
      t.integer :likert_frustrated
      t.integer :likert_limit_to_boilerplate
      t.integer :likert_anxious
      t.integer :likert_made_peace
      t.integer :likert_more_capable
      t.datetime :submitted_at,         null: false
      t.timestamps
    end
    add_index :survey_responses, :role
    add_index :survey_responses, :submitted_at
  end
end
```

Run `bin/rails db:migrate` (and `bin/rails db:migrate RAILS_ENV=test`).

### 2. Model — `app/models/survey_response.rb`

Key signatures:

```ruby
class SurveyResponse < ApplicationRecord
  serialize :ai_tools, coder: JSON

  enum :role, { developer: "developer", engineering_manager: "engineering_manager",
                student: "student", other: "other" }, validate: true

  enum :paid_to_write_ruby, { yes: "yes", no: "no", sometimes: "sometimes" }, validate: true

  enum :years_of_experience, { none: "none", lt_1: "lt_1", one_to_3: "1_3",
                                four_to_6: "4_6", seven_to_9: "7_9",
                                ten_to_13: "10_13", fourteen_plus: "14_plus" }, validate: true

  enum :prior_experience, { none: "none", lt_2: "lt_2",
                             two_to_5: "2_5", five_plus: "5_plus" }, validate: true

  enum :team_ai_adoption, {
    regularly_integrated: "regularly_integrated",
    actively_experimenting: "actively_experimenting",
    tried_no_routine: "tried_no_routine",
    aware_not_started: "aware_not_started",
    evaluated_decided_not_to_use: "evaluated_decided_not_to_use"
  }, validate: true

  validates :role, :paid_to_write_ruby, :years_of_experience,
            :prior_experience, :team_ai_adoption, :writes_ruby, :submitted_at, presence: true

  validates :likert_overhyped, :likert_frustrated, :likert_limit_to_boilerplate,
            :likert_anxious, :likert_made_peace, :likert_more_capable,
            numericality: { only_integer: true, in: 1..5 }, allow_nil: true

  LIKERT_COLUMNS = %i[
    likert_overhyped likert_frustrated likert_limit_to_boilerplate
    likert_anxious likert_made_peace likert_more_capable
  ].freeze

  AI_TOOL_OPTIONS = %w[
    claude_code_cli cursor copilot chatgpt gemini other none
  ].freeze

  def self.aggregate_stats
    total = count.to_f
    role_counts   = group(:role).count
    exp_counts    = group(:years_of_experience).count
    adopt_counts  = group(:team_ai_adoption).count
    likert_avgs   = LIKERT_COLUMNS.index_with { |col| average(col)&.round(2) }
    tool_counts   = Hash.new(0).tap do |h|
      pluck(:ai_tools).each { |raw| JSON.parse(raw).each { |t| h[t] += 1 } }
    end
    { total: total.to_i, role: role_counts, years_of_experience: exp_counts,
      team_ai_adoption: adopt_counts, likert: likert_avgs,
      ai_tools: tool_counts.sort_by { |_, v| -v }.to_h }
  end
end
```

Gotcha: `serialize :ai_tools, coder: JSON` stores a Ruby Array as a JSON string; the
default `"[]"` in the migration must be a string literal, not a Ruby array.

### 3. Routes — `config/routes.rb`

Add before `resources :links`:

```ruby
resource :survey, only: [:show, :create] do
  get :results, on: :member
end
```

Named helpers produced: `survey_path` (GET/POST), `results_survey_path` (GET).

### 4. Controller — `app/controllers/surveys_controller.rb`

```ruby
class SurveysController < ApplicationController
  def show
    @response = SurveyResponse.new(submitted_at: Time.current)
  end

  def create
    @response = SurveyResponse.new(survey_params.merge(submitted_at: Time.current))
    if @response.save
      stats = SurveyResponse.aggregate_stats
      Turbo::StreamsChannel.broadcast_replace_to(
        :survey_results,
        target: "results_panel",
        partial: "surveys/results_panel",
        locals: { stats: stats }
      )
      redirect_to results_survey_path, notice: "Response recorded — thank you!"
    else
      render :show, status: :unprocessable_entity
    end
  end

  def results
    @stats = SurveyResponse.aggregate_stats
  end

  private

  def survey_params
    params.require(:survey_response).permit(
      :location, :role, :writes_ruby, :paid_to_write_ruby,
      :years_of_experience, :prior_experience, :team_ai_adoption,
      :likert_overhyped, :likert_frustrated, :likert_limit_to_boilerplate,
      :likert_anxious, :likert_made_peace, :likert_more_capable,
      ai_tools: []
    )
  end
end
```

Gotcha: `ai_tools: []` is required in `permit` for the array checkboxes. Without it
Rails strips the param entirely, resulting in an empty JSON array being stored.

### 5. Views

File tree:

```
app/views/surveys/
  show.html.erb            — anonymous survey form
  results.html.erb         — dashboard shell + turbo_stream_from
  _results_panel.html.erb  — Turbo Stream replace target (#results_panel)
  _question_result.html.erb — one question's bar chart row
```

`results.html.erb` — subscribe and render initial state:

```erb
<% content_for :no_drawer, true %>
<h1>Survey Results</h1>
<%= turbo_stream_from :survey_results %>
<div id="results_panel">
  <%= render "surveys/results_panel", stats: @stats %>
</div>
```

`_results_panel.html.erb` — outer wrapper replaced on each broadcast:

```erb
<p class="results-meta"><%= pluralize(@stats[:total], "response") %> so far</p>
<%# render each dimension using _question_result partial %>
```

`show.html.erb` — form using `collection_radio_buttons` / `collection_check_boxes` block
pattern (see [mobile-form-ux/mobile-form-patterns.md] for the Likert matrix ERB).
Include `<% content_for :no_drawer, true %>` at top.

### 6. CSS — `app/assets/stylesheets/application.css`

Append a `/* Survey */` section (~120 lines) covering:

- `.survey-form { max-width: 640px }` — readable on desktop, full-width on phone
- `.survey-field`, `textarea` — full-width, `font-size: 1rem` (prevents iOS Safari auto-zoom)
- `.radio-option`, `.checkbox-option` — `min-height: 44px` touch targets
- `.likert-fieldset`, `.likert-row`, `.likert-options`, `.likert-option` — flex row desktop;
  `@media (max-width: 600px)` stacks statement above options
- `.survey-submit { width: 100% }` on mobile, `width: auto` at 480px+
- `.results-meta`, `.question-result`, `.result-bars`, `.result-bar`,
  `.result-bar__fill { transition: width 0.4s ease-out }` — dashboard cards and animated bars

Use only existing tokens: `--teal`, `--charcoal`, `--grid`, `--cream`, `--border`.
No new color values. No charting gem.

Layout gotcha: add to `app/views/layouts/application.html.erb`:

```erb
<% unless content_for?(:no_drawer) %>
  <div class="bottom-drawer"><%= yield :drawer %></div>
<% end %>
```

This suppresses the 80px drawer on survey/results pages that set `content_for :no_drawer`.

### 7. Tests

`test/controllers/surveys_controller_test.rb`:

- `GET /survey` returns `:success`
- `POST /survey` with valid params creates one `SurveyResponse` and redirects to `results_survey_path`
- `POST /survey` with missing required param renders `:show` with `:unprocessable_entity`
- `GET /survey/results` returns `:success`

`test/system/surveys_test.rb`:

- Visit `/survey`, fill all required fields, submit, assert redirect to `/survey/results`
  and that the page shows "1 response so far"
- Submit a second response (or seed one via `SurveyResponse.create!`), assert the count
  increments in the Turbo Stream replace (requires `ActionCable::TestHelper` or a brief
  `sleep` in the system test to let the in-process async adapter deliver the broadcast)

---

## Open Questions

1. **Result scope**: `aggregate_stats` currently aggregates all rows. If the app ever hosts
   multiple independent surveys (different presentations/events), responses should be scoped
   by an event identifier. For now, a single global table is assumed.

2. **Thank-you page**: The `create` action redirects to `/survey/results`. Some presenters
   may prefer to redirect back to `/survey` with a "thank you" flash so the audience member
   stays on a neutral screen rather than seeing the evolving results. Consider a dedicated
   `surveys#thank_you` action gated by a session flag.

3. **Duplicate submission prevention**: Nothing prevents a user from submitting multiple
   times. A session flag (`session[:survey_submitted] = true`) checked in `show` and `create`
   would prevent resubmission within the same browser session, but is not required for MVP.

4. **Results access control**: Results are currently public. If the presenter wants to keep
   results hidden until reveal, a simple token-in-URL approach (`/survey/results?token=...`)
   or a presenter-only session flag would suffice without adding a full auth system.

5. **Likert optionality**: All Likert columns are `allow_nil: true`. The form should mark
   them as optional in UI copy or validate presence depending on the presentation's needs.
   Implementer should confirm whether all 6 Likert items are required.
