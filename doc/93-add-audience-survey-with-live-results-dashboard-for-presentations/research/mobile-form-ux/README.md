# Research: Mobile-First Survey Form UX

Issue #93 — Add an anonymous audience survey with live-updating results dashboard.

## Summary of Findings

The FizzBuzz app uses a minimal hand-written CSS system called "Johari design language." It has a strong visual identity (cream/teal/peach/charcoal, monospace, square borders, condensed sans headers) but **zero responsive/mobile CSS** — no media queries exist anywhere. The viewport meta tag is already correct for mobile use.

The good news: the design language is so minimal that extending it for a mobile survey form is straightforward. No framework, no Tailwind, no Bootstrap. Just ~120 lines of new CSS using the existing tokens.

### Key facts

- **No authentication** — the app has no auth gem and no `authenticate_user!` anywhere. A `SurveysController` inheriting `ApplicationController` is public by default.
- **CSRF is handled** — `form_with` includes the token automatically; no special work needed for anonymous public forms.
- **Viewport is correct** — `<meta name="viewport" content="width=device-width,initial-scale=1">` already present.
- **Mobile-web-app-capable tags** already present; PWA manifest route is commented out (not needed for this feature).
- **The existing `.btn`** is ~28px tall — below the 44px mobile touch target minimum. Survey-specific buttons need an override.
- **`.form-field input { width: 24rem }`** is the only existing text input style and it overflows phone viewports. Survey fields need `width: 100%`.
- **No textarea styles exist.** Free-text survey answers need `width: 100%; font-size: 1rem` (1rem prevents iOS Safari auto-zoom on focus).
- **Likert matrix** needs a flex-row desktop layout + `@media (max-width: 600px)` stack to remain usable on a 375px screen.
- **Bottom drawer** (80px fixed, always rendered) competes with survey content on mobile. A `content_for :no_drawer` convention can suppress it for survey pages.

---

## Table of Contents

- [existing-css-inventory.md](./existing-css-inventory.md) — Complete rule-by-rule audit of `application.css`; lists what is and is not already mobile-friendly
- [mobile-form-patterns.md](./mobile-form-patterns.md) — Rails form helper ERB patterns; CSS additions needed; anonymous access analysis; viewport/PWA findings

---

## Mobile Survey Form Layout (ASCII Mockup)

Phone view — 375px wide:

```
+-------------------------------------------+
|  AUDIENCE SURVEY              Step 2 of 4  |
|  [============================--------]    |
|                                            |
|  YOUR EXPERIENCE LEVEL                     |
|  +--------------------------------------+  |
|  | ( ) Beginner                         |  |
|  +--------------------------------------+  |
|  +--------------------------------------+  |
|  | ( ) Intermediate                     |  |
|  +--------------------------------------+  |
|  +--------------------------------------+  |
|  | (o) Advanced                         |  |
|  +--------------------------------------+  |
|                                            |
|  RATE EACH STATEMENT  [1=disagree 5=agree] |
|                                            |
|  I learned something new today             |
|  [ 1 ] [ 2 ] [*3*] [ 4 ] [ 5 ]            |
|  ----------------------------------------  |
|  The pace was right for me                 |
|  [ 1 ] [*2*] [ 3 ] [ 4 ] [ 5 ]            |
|  ----------------------------------------  |
|                                            |
|  ANY OTHER THOUGHTS?                       |
|  +--------------------------------------+  |
|  |                                      |  |
|  |  (textarea, rows=4)                  |  |
|  |                                      |  |
|  +--------------------------------------+  |
|                                            |
|  +--------------------------------------+  |
|  |           SUBMIT RESPONSE            |  |  <- full-width, 44px+
|  +--------------------------------------+  |
+-------------------------------------------+
```

Desktop view — 1200px wide (form max-width: 640px, centered or left-aligned in page-content):

```
+----------------------------------------------------------------+
|  AUDIENCE SURVEY                                               |
|  Step 2 of 4  [===================---------]                  |
|                                                                |
|  YOUR EXPERIENCE LEVEL                                         |
|  +--------------------+  +--------------------+               |
|  | ( ) Beginner       |  | ( ) Intermediate   |               |
|  +--------------------+  +--------------------+               |
|  +--------------------+                                        |
|  | (o) Advanced       |                                        |
|  +--------------------+                                        |
|                                                                |
|  RATE EACH STATEMENT           1     2     3     4     5       |
|  I learned something new   .   ( )   ( )   (o)   ( )   ( )   |
|  The pace was right for me .   ( )   (o)   ( )   ( )   ( )   |
|                                                                |
|  ANY OTHER THOUGHTS?                                           |
|  +------------------------------------------+                 |
|  |                                          |                 |
|  |  (textarea)                              |                 |
|  +------------------------------------------+                 |
|                                                                |
|  [SUBMIT RESPONSE]                                             |
+----------------------------------------------------------------+
```

---

## Implementation Recommendation

1. Add `app/controllers/surveys_controller.rb` — no before-action, inherits `ApplicationController`
2. Add survey form view using `form_with url: surveys_path` + `collection_radio_buttons` / `collection_check_boxes` block patterns
3. Add ~120 lines of CSS to `application.css` under a `/* Survey */` section
4. Use `content_for :no_drawer` + layout conditional to suppress 80px bottom drawer on survey pages
5. For Likert matrix on mobile: single `@media (max-width: 600px)` breakpoint flips `.likert-row` from `flex-direction: row` to `flex-direction: column`
6. Live results dashboard uses Turbo Streams replacing `<div id="survey-results">` content — same pattern as the existing FizzBuzz results stream
