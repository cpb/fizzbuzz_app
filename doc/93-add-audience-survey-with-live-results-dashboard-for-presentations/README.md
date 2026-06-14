# Issue #93 — Audience Survey with Live Results Dashboard

This document tree answers: **What is the simplest, most idiomatic way to add an anonymous
audience survey with a live-updating results dashboard to the FizzBuzz Rails 8 app?**

---

## What this PR contains

Five parallel research tracks + one implementation plan, written as ground-truth terrain maps
that an implementer can follow directly. No application code is written here.

---

## Reading order

For a first read, start here and follow the links in order:

1. **[Research overview](research/README.md)** — Breadth-first summary of all five research topics; read this to understand the full terrain before diving into any leaf doc.
2. **[Implementation plan](plans/README.md)** — Start here if you are ready to implement; the plan synthesizes all research into concrete ordered steps.

For deep-dives by topic:

| Topic | Entry | Key question answered |
|---|---|---|
| Turbo Streams + solid_cable | [research/existing-turbo-patterns/README.md](research/existing-turbo-patterns/README.md) | Which broadcast pattern fits a live aggregate dashboard? |
| Database schema | [research/survey-schema/README.md](research/survey-schema/README.md) | What table structure stores all survey fields efficiently? |
| Live results dashboard | [research/live-results-dashboard/README.md](research/live-results-dashboard/README.md) | How do results stay fresh for every connected viewer? |
| Mobile form UX | [research/mobile-form-ux/README.md](research/mobile-form-ux/README.md) | What CSS and form helpers make it work on a phone via QR code? |
| Rails routing | [research/rails-routing/README.md](research/rails-routing/README.md) | What routes and controller structure fits the app's conventions? |

---

## Full document tree

```
docs/93-add-audience-survey-with-live-results-dashboard-for-presentations/
  README.md                                    ← you are here
  research/
    README.md                                  ← breadth-first research summary
    existing-turbo-patterns/
      README.md                                ← broadcast patterns overview + Mermaid diagram
      broadcast-mechanism.md                   ← deep-dive: Turbo::StreamsChannel methods + channel naming
      aggregate-broadcast-options.md           ← options compared; job-based fan-out recommended
    survey-schema/
      README.md                                ← schema recommendation + ERD + migration sketch
      schema-options.md                        ← flat vs normalized; multi-select and Likert trade-offs
      aggregation-queries.md                   ← GROUP BY / AVG queries for dashboard aggregates
    live-results-dashboard/
      README.md                                ← update strategy recommendation + flow diagram
      update-strategies.md                     ← broadcast-from-controller vs job vs polling compared
      results-ui-design.md                     ← partial structure, CSS bar charts, presenter layout
    mobile-form-ux/
      README.md                                ← CSS gap analysis + mobile form layout mockup
      existing-css-inventory.md                ← complete audit of application.css rules
      mobile-form-patterns.md                  ← ERB helpers, touch targets, Likert matrix, drawer suppression
    rails-routing/
      README.md                                ← routing recommendation + route→controller→view diagram
      route-options.md                         ← singular resource vs resources vs standalone routes
      controller-design.md                     ← SurveysController actions, CSRF, Turbo Stream format, tests
  plans/
    README.md                                  ← plans overview
    01-survey-implementation.md                ← full implementation plan (migration → model → routes → controller → views → CSS → tests)
```
