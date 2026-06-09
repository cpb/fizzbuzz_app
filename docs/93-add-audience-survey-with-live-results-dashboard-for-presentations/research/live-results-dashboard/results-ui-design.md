# Results Dashboard UI Design

## Design Constraints

- No CSS framework (app uses bespoke Johari tokens in `application.css`)
- Must be readable when projected or screen-shared (1080p or lower, viewed at a distance)
- High contrast: app palette is cream `#F5EDD6` background, charcoal `#2C2C2C` text
- Font: monospace (`Courier New`) for body; condensed sans-serif (`Arial`) for headings
- No authentication required — the results URL is public

---

## Layout

Use a **single-column card layout**. Each question gets one card; cards stack
vertically so a presenter can scroll to a specific question or display all at
once.

```
+--------------------------------------------------+
|  SURVEY TITLE (h1, 3rem, uppercase)              |
|  N responses so far  (live counter)              |
+--------------------------------------------------+
|                                                  |
|  Q1  How engaged are you?              [12 resp] |
|  ================================================|
|  Strongly agree  ████████████████  60%  (7)      |
|  Agree           ████████         33%  (4)       |
|  Neutral         ██               7%  (1)        |
|  Disagree                         0%  (0)        |
|  Strongly disagree                0%  (0)        |
|                                                  |
|  Q2  Pick your background                        |
|  ================================================|
|  Engineering     ████████████████  50%  (6)      |
|  Design          ████████         25%  (3)       |
|  ...                                             |
+--------------------------------------------------+
```

Bar charts are pure CSS — a `<span>` with `width` set inline to the
percentage value. No JavaScript or canvas required.

---

## Partial Structure

```
app/views/surveys/
  results.html.erb           ← page layout; turbo_stream_from :survey_results
  _results_panel.html.erb    ← REPLACED by Turbo Stream on every new response
    _question_result.html.erb ← rendered once per question inside results_panel
```

### `results.html.erb`

```erb
<h1><%= @survey.title %></h1>

<%= turbo_stream_from :survey_results %>

<div id="results_panel">
  <%= render "surveys/results_panel", survey: @survey, stats: @stats %>
</div>
```

Notes:
- `turbo_stream_from :survey_results` sets up the WebSocket subscription.
- `#results_panel` is the single Turbo Stream replace target — the entire
  aggregated block is swapped atomically on each update, avoiding partial
  renders that could show inconsistent intermediate states.

### `_results_panel.html.erb`

```erb
<p class="results-meta">
  <%= pluralize(@stats.values.sum { |s| s[:total] }, "response") %> so far
</p>

<% @stats.each_value do |stat| %>
  <%= render "surveys/question_result", stat: stat %>
<% end %>
```

### `_question_result.html.erb`

```erb
<div class="question-result">
  <h2 class="question-result__text"><%= stat[:question].text %></h2>
  <p class="question-result__count"><%= stat[:total] %> responses</p>

  <ul class="result-bars" role="list">
    <% stat[:breakdown].each do |row| %>
      <li class="result-bar">
        <span class="result-bar__label"><%= row[:label] %></span>
        <span class="result-bar__track">
          <span class="result-bar__fill" style="width: <%= row[:pct] %>%"></span>
        </span>
        <span class="result-bar__pct"><%= row[:pct] %>%</span>
        <span class="result-bar__count">(<%= row[:count] %>)</span>
      </li>
    <% end %>
  </ul>

  <% if stat[:mean] %>
    <p class="question-result__mean">Mean: <%= stat[:mean].round(2) %></p>
  <% end %>
</div>
```

---

## CSS Additions

The following CSS should be appended to `app/assets/stylesheets/application.css`.
It reuses existing Johari design tokens and follows the same naming conventions.

```css
/* ============================================================
   Survey Results Dashboard
   ============================================================ */

/* Page-level heading already uses h1 styles from base */

.results-meta {
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--charcoal);
  opacity: 0.5;
  margin: 0 0 2rem 0;
}

/* Question card */

.question-result {
  border: 1px solid var(--border);
  padding: 1.5rem 2rem;
  margin-bottom: 1.5rem;
}

.question-result__text {
  font-family: Arial, 'Arial Narrow', Helvetica, sans-serif;
  font-weight: 900;
  font-stretch: condensed;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  font-size: 1.75rem;   /* large for projector */
  margin: 0 0 0.4rem 0;
}

.question-result__count {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  opacity: 0.4;
  margin: 0 0 1rem 0;
}

.question-result__mean {
  font-size: 1rem;
  margin: 0.8rem 0 0 0;
  opacity: 0.7;
}

/* Bar chart list */

.result-bars {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}

.result-bar {
  display: grid;
  grid-template-columns: 14rem 1fr 4rem 3rem;
  align-items: center;
  gap: 0.75rem;
  font-size: 1.25rem;   /* larger than default for projector legibility */
}

.result-bar__label {
  font-family: 'Courier New', Courier, monospace;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.result-bar__track {
  height: 1.5rem;
  background: var(--grid);
  border: 1px solid var(--border);
  position: relative;
  overflow: hidden;
}

.result-bar__fill {
  display: block;
  height: 100%;
  background: var(--teal);
  transition: width 0.4s ease-out;  /* animates smoothly when Turbo Stream swaps */
}

.result-bar__pct {
  text-align: right;
  font-weight: bold;
}

.result-bar__count {
  opacity: 0.5;
}
```

### Projector-specific font sizing rationale

- `h1` is already `2.5rem` (from base).
- `question-result__text` is `1.75rem` — one step down; bold condensed uppercase
  is readable at 10 m distance.
- `.result-bar` text at `1.25rem` is 20 px at standard DPI, 40 px at 2x —
  legible at projection distances without wasting vertical space.
- The bar track height of `1.5rem` makes filled segments clearly visible even
  at low projector brightness.

### Color usage

| Element | Color | Token |
|---|---|---|
| Bar fill | Teal | `var(--teal)` `#4A9B8E` |
| Track background | Grid overlay | `var(--grid)` |
| Question heading | Charcoal | `var(--charcoal)` |
| Meta / count | Charcoal + opacity | `var(--charcoal)` 40-50% |
| Page background | Cream | `var(--cream)` |

This palette provides sufficient contrast on typical projector white
backgrounds. For dark-mode/dark-projector use, the presenter can add a simple
toggle that swaps `--cream` and `--charcoal` values.

---

## No charting gem needed

The app has no charting dependency and should not add one. The pure-CSS bar
approach:
- Works offline / without CDN
- Has no JavaScript payload
- Transitions smoothly when Turbo Stream replaces the DOM node (CSS
  `transition: width 0.4s ease-out`)
- Requires zero build pipeline changes

If richer visualizations (donut charts, sparklines) become a requirement
later, `chartkick` + `Chart.js` (importmap-pinnable) would be the lowest-
friction addition. Do not add this now.

---

## Public URL / Authentication

The results controller action should skip authentication entirely (if any auth
is added to the app in future). The results path should be a clean, shareable
URL:

```
GET /surveys/:id/results   →  SurveysController#results
```

No token or session required. The survey `id` is the only identifier. The
presenter shares this URL and it is bookmarkable.
