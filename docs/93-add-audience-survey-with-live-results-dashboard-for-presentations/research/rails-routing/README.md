# Rails Routing & Controller Design — Issue #93 Survey Feature

## Recommendation Summary

Use `resource :survey` (singular) with a single `SurveysController` exposing three actions: `show` (GET form), `create` (POST submission), and `results` (GET live dashboard). Add the `results` action as a `get :results, on: :member` override on the singular resource, or simply as a standalone collection route. No authentication changes needed — `protect_from_forgery` works transparently with public forms. The results page uses `turbo_stream_from` in the view, consistent with how FizzBuzz and Links pages already do live updates.

## Table of Contents

- [Route Options](route-options.md) — Compares three route designs; argues for singular `resource :survey`
- [Controller Design](controller-design.md) — One vs two controllers; Turbo Stream pattern; CSRF safety; test structure

## Route → Controller → View Diagram

```mermaid
graph LR
    subgraph Routes["config/routes.rb"]
        R1["GET  /survey"]
        R2["POST /survey"]
        R3["GET  /survey/results"]
    end

    subgraph Controller["SurveysController"]
        C1["#show"]
        C2["#create"]
        C3["#results"]
    end

    subgraph Views["app/views/surveys/"]
        V1["show.html.erb\n(anonymous form)"]
        V2["results.html.erb\n(live dashboard)"]
        V3["_answer.html.erb\n(turbo_stream partial)"]
    end

    R1 --> C1
    R2 --> C2
    R3 --> C3

    C1 --> V1
    C2 -->|"redirect_to survey_results_path\nor render show"| V1
    C3 --> V2
    V2 -->|"turbo_stream_from :survey_results"| V3
```

**Named helpers produced by the recommended route declaration:**

| Helper | HTTP method | Path |
|---|---|---|
| `survey_path` | GET | `/survey` |
| `survey_path` | POST | `/survey` |
| `results_survey_path` | GET | `/survey/results` |

All three URLs are short enough to fit comfortably in a QR code.
