# Mobile-First Survey Form Patterns

Specifications for Issue #93 — anonymous audience survey, mobile/QR-code access.

---

## 1. Rails Form Helpers to Use

### Primary form wrapper

```erb
<%= form_with url: surveys_path, method: :post, class: "survey-form" do |f| %>
```

Use `form_with` (not `form_for` / `form_tag` — both deprecated). No `model:` since survey responses are anonymous and don't need a full ActiveRecord model exposed to the view. A plain struct or `Struct.new` with `include ActiveModel::API` works.

### Free text (open-ended answer)

```erb
<div class="survey-field">
  <%= f.label :feedback, "Your thoughts" %>
  <%= f.text_area :feedback, rows: 4, placeholder: "Type here…" %>
</div>
```

### Radio buttons (single choice)

```erb
<div class="survey-field">
  <%= f.label :experience_level, "Experience level" %>
  <div class="radio-group">
    <%= f.collection_radio_buttons :experience_level, [["beginner","Beginner"],["intermediate","Intermediate"],["advanced","Advanced"]], :first, :last do |b| %>
      <label class="radio-option">
        <%= b.radio_button %>
        <%= b.label %>
      </label>
    <% end %>
  </div>
</div>
```

`collection_radio_buttons` with a block gives full control over wrapping markup. Each `<label class="radio-option">` wraps both the `<input>` and text — tapping anywhere on the label triggers the radio. This is the correct mobile pattern.

### Checkboxes (multi-select)

```erb
<div class="survey-field">
  <%= f.label :topics, "Topics of interest (choose all that apply)" %>
  <div class="checkbox-group-list">
    <%= f.collection_check_boxes :topics, TOPIC_OPTIONS, :first, :last do |b| %>
      <label class="checkbox-option">
        <%= b.check_box %>
        <%= b.label %>
      </label>
    <% end %>
  </div>
</div>
```

Same block pattern. `collection_check_boxes` handles hidden-field-for-empty-array automatically.

### Likert scale (radio matrix — 6 statements × 5 points)

```erb
<fieldset class="likert-fieldset">
  <legend>Rate each statement</legend>
  <div class="likert-scale" aria-label="1=Strongly disagree, 5=Strongly agree">
    <% LIKERT_STATEMENTS.each do |stmt_key, stmt_text| %>
      <div class="likert-row">
        <span class="likert-label"><%= stmt_text %></span>
        <div class="likert-options">
          <% (1..5).each do |n| %>
            <label class="likert-option">
              <%= f.radio_button stmt_key, n, id: "#{stmt_key}_#{n}" %>
              <span class="likert-point"><%= n %></span>
            </label>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>
</fieldset>
```

On desktop: 5 radio buttons sit in a horizontal row next to the statement label.
On mobile (≤600px): the row stacks — statement above, 5 radio buttons below in a centered flex row.

---

## 2. CSS to Add for Survey Forms

All additions go into `application.css` under a `/* Survey */` section. They use existing tokens exclusively — no new color values.

### 2a. Survey form container

```css
/* Survey */

.survey-form {
  max-width: 640px;
}

.survey-field {
  margin-bottom: 1.75rem;
}

.survey-field > label:first-child {
  display: block;
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 0.6rem;
}
```

`max-width: 640px` keeps long text lines readable on desktop while filling the phone viewport completely.

### 2b. Textarea

```css
.survey-field textarea {
  border: 1px solid var(--border);
  border-radius: 0;
  background: transparent;
  color: var(--charcoal);
  font-family: inherit;
  font-size: 1rem;
  padding: 0.6rem 0.7rem;
  width: 100%;
  resize: vertical;
  outline: none;
  min-height: 6rem;
}

.survey-field textarea:focus {
  background: rgba(44, 44, 44, 0.05);
}
```

`width: 100%` makes it full-width on all screen sizes. `font-size: 1rem` prevents iOS Safari auto-zoom (triggered when `font-size < 16px`).

### 2c. Radio / checkbox options — touch-friendly

```css
.radio-group,
.checkbox-group-list {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
}

.radio-option,
.checkbox-option {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  min-height: 44px;          /* iOS HIG touch target minimum */
  padding: 0.4rem 0.6rem;
  border: 1px solid var(--grid);
  cursor: pointer;
  font-size: 0.95rem;
  font-family: inherit;
}

.radio-option:hover,
.checkbox-option:hover {
  background: rgba(44, 44, 44, 0.04);
}

.radio-option input[type="radio"],
.checkbox-option input[type="checkbox"] {
  accent-color: var(--teal);
  width: 1.1rem;
  height: 1.1rem;
  flex-shrink: 0;
  cursor: pointer;
}
```

Each option is a block-level label that is at least 44px tall. The input + text sit in a flex row with a clear gap.

### 2d. Submit button — mobile-sized

```css
.survey-submit {
  min-height: 44px;
  padding: 0.7rem 2rem;
  width: 100%;
  font-size: 1rem;
}

@media (min-width: 480px) {
  .survey-submit {
    width: auto;
  }
}
```

Full-width submit on phone (easy thumb reach), auto-width on tablet+.

### 2e. Likert matrix

```css
.likert-fieldset {
  border: 1px solid var(--grid);
  padding: 1rem;
  margin-bottom: 1.75rem;
}

.likert-fieldset legend {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  padding: 0 0.4rem;
}

.likert-row {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--grid);
}

.likert-label {
  flex: 1;
  font-size: 0.9rem;
  min-width: 0;             /* allow flex item to shrink */
}

.likert-options {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}

.likert-option {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.2rem;
  cursor: pointer;
  min-width: 2.5rem;
  min-height: 44px;
  justify-content: center;
}

.likert-option input[type="radio"] {
  accent-color: var(--teal);
  width: 1.1rem;
  height: 1.1rem;
  cursor: pointer;
}

.likert-point {
  font-size: 0.7rem;
  color: var(--charcoal);
  opacity: 0.6;
}

/* On narrow screens, stack statement above options */
@media (max-width: 600px) {
  .likert-row {
    flex-direction: column;
    align-items: flex-start;
    gap: 0.5rem;
  }

  .likert-options {
    width: 100%;
    justify-content: space-between;
  }

  .likert-option {
    min-width: 44px;    /* full touch target */
  }
}
```

Desktop: statement text left, 5 radio buttons right, in a single row.
Mobile: statement text on top, 5 radio buttons spread across full width below.

### 2f. Progress indicator (optional)

```css
.survey-progress {
  margin-bottom: 1.5rem;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--charcoal);
  opacity: 0.6;
}

.survey-progress-bar {
  height: 3px;
  background: var(--grid);
  margin-top: 0.4rem;
  position: relative;
}

.survey-progress-fill {
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  background: var(--teal);
  transition: width 0.3s ease;
}
```

Usage: `<div class="survey-progress-fill" style="width: 60%"></div>` — driven server-side or by a minimal Stimulus controller.

### 2g. Results dashboard bars (for live results display)

```css
.results-bar-list {
  list-style: none;
  padding: 0;
  margin: 1rem 0;
}

.results-bar-item {
  margin-bottom: 0.75rem;
}

.results-bar-label {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  margin-bottom: 0.2rem;
  display: flex;
  justify-content: space-between;
}

.results-bar-track {
  height: 1.5rem;
  background: var(--grid);
  position: relative;
}

.results-bar-fill {
  position: absolute;
  top: 0;
  left: 0;
  height: 100%;
  background: var(--teal);
  transition: width 0.4s ease;
}
```

Width driven by inline style: `style="width: <%= pct %>%"`. Compatible with Turbo Stream replace for live updates.

---

## 3. Anonymous Access

### Current auth posture

- `ApplicationController < ActionController::Base` — no Devise, no `authenticate_user!`, no before-action auth in any controller
- No authentication gem in `Gemfile`
- All existing routes are publicly accessible (FizzBuzz, Links)

**Conclusion:** The app has zero authentication infrastructure. A new `SurveysController` inheriting `ApplicationController` is automatically public.

### CSRF

`<%= csrf_meta_tags %>` is present in the layout. Rails' default CSRF protection applies to all POST/PATCH/DELETE requests. `form_with` automatically includes the CSRF token — no special handling needed. Public anonymous forms are safe as-is.

### No session tracking needed

Anonymous submissions: just write to DB on POST, no session cookie needed to identify respondent. If deduplication is desired, a fingerprint can be derived from IP + user-agent and stored in a `session[]` key after submit to prevent double-submit on reload — but this is opt-in, not required for MVP.

---

## 4. Viewport and PWA

From `app/views/layouts/application.html.erb`:

```html
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="application-name" content="Fizzbuzz App">
<meta name="mobile-web-app-capable" content="yes">
<link rel="apple-touch-icon" href="/icon.png">
```

**Already present:**
- Correct viewport meta (`width=device-width, initial-scale=1`) — no user-scalable=no (good: preserves accessibility pinch-zoom)
- Apple and Android web app capable tags
- Apple touch icon

**Not present (commented out):**
- PWA manifest link (commented out in layout, route also commented out)
- Service worker route

The viewport is correctly configured for QR-code-to-phone use. The survey URL will render properly on first open in a mobile browser.

---

## 5. Bottom Drawer Conflict

The layout always renders `<div class="bottom-drawer"><%= yield :drawer %></div>`. If a survey view does not `content_for :drawer`, the drawer renders empty but still takes up 80px at the bottom. Two options:

**Option A — leave empty drawer.** Simplest. The drawer is still visible as a bottom border/stripe. Not ideal for a clean mobile survey but acceptable.

**Option B — suppress for survey pages.** Add to survey layout or use a content_for override:
```erb
<%# In survey view — override drawer to nothing %>
<% content_for :drawer do %><% end %>
```
This renders the drawer div but empty. To hide it completely, a conditional in the layout would be needed:
```erb
<% unless content_for?(:no_drawer) %>
  <div class="bottom-drawer"><%= yield :drawer %></div>
<% end %>
```
And in survey views: `<% content_for :no_drawer, true %>`.

**Recommendation:** Option B with `content_for :no_drawer` — removes 80px dead space from mobile survey, giving more room to the form.

---

## 6. Summary of CSS Additions Required

| Addition | Why needed |
|---|---|
| `.survey-form { max-width: 640px }` | Readable line length on desktop, full-width on phone |
| `.survey-field` vertical spacing | No current pattern for survey fields |
| `textarea { width: 100%; font-size: 1rem }` | Full-width text answer; 1rem prevents iOS zoom |
| `.radio-option / .checkbox-option` with `min-height: 44px` | Touch target compliance |
| `.likert-row` flex row + `@media (max-width: 600px)` stack | Horizontal on desktop, vertical on mobile |
| `.survey-submit { width: 100% }` on mobile | Full-width submit button for easy thumb reach |
| `.survey-progress` + progress bar | Optional completion indicator |
| `.results-bar-*` | Live dashboard result bars |

All rules use existing design tokens (`--teal`, `--charcoal`, `--grid`, `--cream`, etc.). No new colors.

Estimated lines of CSS to add: ~120 lines.
