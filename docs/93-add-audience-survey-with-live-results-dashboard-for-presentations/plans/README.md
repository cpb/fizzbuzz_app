# Plans — Issue #93 Audience Survey

Implementation plans synthesized from the five research tracks.

---

## Table of Contents

- [01-survey-implementation.md](01-survey-implementation.md) — Full end-to-end implementation plan: migration, model, routes, controller, views, CSS, and tests

---

## Summary

One plan covers the full feature. It is grounded in all five research tracks and specifies
concrete ordered steps with exact method signatures, partial names, and gotchas.

### 01-survey-implementation

**Decision**: Flat `survey_responses` table, `SurveysController` with `resource :survey` routes,
`broadcast_replace_to(:survey_results, ...)` called inline in `create` after a successful save,
~120 lines of CSS appended to `application.css`.

**7 implementation steps** in order:
1. Migration — `create_table :survey_responses` (18 columns, 2 indexes)
2. Model — `SurveyResponse` with enum declarations, JSON serializer, validations, `aggregate_stats` class method
3. Routes — `resource :survey` block with `results` member route
4. Controller — `SurveysController` with `show`, `create` (saves + broadcasts), `results`
5. Views — `show.html.erb` (form), `results.html.erb` (dashboard + subscribe), `_results_panel.html.erb` (replace target), `_question_result.html.erb`
6. CSS — `/* Survey */` section in `application.css`; `content_for :no_drawer` layout conditional
7. Tests — 4 controller assertions + 2 system test cases

**5 open questions** for the implementer: result scoping for multi-event use, thank-you page UX,
duplicate submission prevention, results access control, and Likert item optionality.

Cross-links: [survey-schema](../research/survey-schema/README.md) · [existing-turbo-patterns](../research/existing-turbo-patterns/README.md) · [live-results-dashboard](../research/live-results-dashboard/README.md) · [mobile-form-ux](../research/mobile-form-ux/README.md) · [rails-routing](../research/rails-routing/README.md)
