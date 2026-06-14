# packs/surveys

## Source

| File | Role |
|---|---|
| `app/controllers/surveys_controller.rb` | `show` (form), `create` (submit), `results` (live results) |
| `app/models/survey_response.rb` | Survey submission record |
| `app/views/surveys/` | Form, results panel partial, results view |

## Routes

| Method | Path | Action | UI surface |
|---|---|---|---|
| `GET` | `/survey` | `SurveysController#show` | Audience survey form |
| `POST` | `/survey` | `SurveysController#create` | Submit response; redirects to results |
| `GET` | `/survey/results` | `SurveysController#results` | Live results dashboard |

## Tests

| Test file | What it covers |
|---|---|
| `test/controllers/surveys_controller_test.rb` | `GET /survey` returns 200; valid `POST` creates response and redirects to results; missing required param renders form with 422; `GET /survey/results` returns 200 |
| `test/system/surveys_test.rb` | Fill out full form → submit → "Response recorded" confirmation → results page shows count |
