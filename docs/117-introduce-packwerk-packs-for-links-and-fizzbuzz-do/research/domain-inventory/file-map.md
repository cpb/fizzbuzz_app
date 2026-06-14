# File Map — Domain Classification

Every file in `app/` and `test/` classified by domain and Packwerk pack target.

Pack targets:
- `packs/links` — links/bookmarks domain
- `packs/fizzbuzz` — fizzbuzz domain
- `root` — stays at app root (infrastructure / shared / framework-owned)
- `out-of-scope` — workbook extraction, engine code, or fixture data not being moved

---

## app/ Files

| File Path | Domain | Pack Target |
|-----------|--------|-------------|
| `app/models/application_record.rb` | infrastructure | packs/rails_shims |
| `app/models/link.rb` | links | packs/links |
| `app/models/gist.rb` | links | packs/links |
| `app/models/gist_publisher.rb` | links | packs/links |
| `app/models/qr_code_generator.rb` | utility | packs/qr_code |
| `app/models/fizz_buzzer.rb` | fizzbuzz | packs/fizzbuzz |
| `app/models/llm_fizz_buzzer.rb` | fizzbuzz | packs/fizzbuzz |
| `app/models/survey_response.rb` | surveys | packs/surveys |
| `app/controllers/application_controller.rb` | infrastructure | packs/rails_shims |
| `app/controllers/fizz_buzz_controller.rb` | fizzbuzz | packs/fizzbuzz |
| `app/controllers/links_controller.rb` | links | packs/links |
| `app/controllers/surveys_controller.rb` | surveys | packs/surveys |
| `app/controllers/replays_controller.rb` | workbook | delete (Plan 03) |
| `app/controllers/workbook_session_replays_controller.rb` | workbook | delete (Plan 03) |
| `app/controllers/workbook_sessions/replays_controller.rb` | workbook | delete (Plan 03) |
| `app/controllers/concerns/.keep` | infrastructure | root |
| `app/jobs/application_job.rb` | infrastructure | packs/rails_shims |
| `app/jobs/fizz_buzz_job.rb` | fizzbuzz | packs/fizzbuzz |
| `app/jobs/llm_fizz_buzz_job.rb` | fizzbuzz | packs/fizzbuzz |
| `app/jobs/publish_gist_job.rb` | links | packs/links |
| `app/mailers/application_mailer.rb` | infrastructure | packs/rails_shims |
| `app/helpers/application_helper.rb` | infrastructure | packs/rails_shims |
| `app/helpers/ruby_llm/evals/runs_helper.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `app/views/layouts/application.html.erb` | infrastructure | root |
| `app/views/layouts/mailer.html.erb` | infrastructure | root |
| `app/views/layouts/mailer.text.erb` | infrastructure | root |
| `app/views/fizz_buzz/_result.html.erb` | fizzbuzz | packs/fizzbuzz |
| `app/views/fizz_buzz/_survey_qr.html.erb` | fizzbuzz (cross-domain) | packs/fizzbuzz* |
| `app/views/fizz_buzz/start.html.erb` | fizzbuzz | packs/fizzbuzz |
| `app/views/links/_link.html.erb` | links | packs/links |
| `app/views/links/_qr_code.html.erb` | links | packs/links |
| `app/views/links/index.html.erb` | links | packs/links |
| `app/views/links/new.html.erb` | links | packs/links |
| `app/views/surveys/_results_panel.html.erb` | surveys | packs/surveys |
| `app/views/surveys/results.html.erb` | surveys | packs/surveys |
| `app/views/surveys/show.html.erb` | surveys | packs/surveys |
| `app/views/pwa/manifest.json.erb` | infrastructure | root |
| `app/views/pwa/service-worker.js` | infrastructure | root |
| `app/views/replays/show.html.erb` | workbook | delete (Plan 03) |
| `app/views/workbook_sessions/replays/_step.html.erb` | workbook | delete (Plan 03) |
| `app/views/workbook_sessions/replays/advance.turbo_stream.erb` | workbook | delete (Plan 03) |
| `app/views/workbook_sessions/replays/show.html.erb` | workbook | delete (Plan 03) |
| `app/views/ruby_llm/evals/runs/_fizzbuzz_grid.html.erb` | fizzbuzz/evals | packs/fizzbuzz |
| `app/views/ruby_llm/evals/runs/show.html.erb` | fizzbuzz/evals | packs/fizzbuzz |
| `app/assets/stylesheets/application.css` | infrastructure | root |
| `app/assets/images/.keep` | infrastructure | root |
| `app/javascript/application.js` | infrastructure | root |
| `app/javascript/controllers/application.js` | infrastructure | root |
| `app/javascript/controllers/dismissible_controller.js` | infrastructure | root |
| `app/javascript/controllers/hello_controller.js` | infrastructure | root |
| `app/javascript/controllers/index.js` | infrastructure | root |
| `app/javascript/controllers/replay_controller.js` | workbook | delete (Plan 03) |
| `app/javascript/controllers/word_by_word_controller.js` | workbook | delete (Plan 03) |

*`_survey_qr.html.erb` lives in the fizzbuzz pack directory but references survey and links domain items — see cross-domain-dependencies.md.

---

## test/ Files (non-cassette)

| File Path | Domain | Pack Target |
|-----------|--------|-------------|
| `test/test_helper.rb` | infrastructure | root |
| `test/application_system_test_case.rb` | infrastructure | root |
| `test/CLAUDE.md` | docs | root |
| `test/models/fizz_buzzer_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/models/llm_fizz_buzzer_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/models/link_test.rb` | links | packs/links |
| `test/models/gist_test.rb` | links | packs/links |
| `test/models/gist_publisher_test.rb` | links | packs/links |
| `test/models/qr_code_generator_test.rb` | links | packs/links |
| `test/controllers/fizz_buzz_controller_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/controllers/links_controller_test.rb` | links | packs/links |
| `test/controllers/surveys_controller_test.rb` | surveys | packs/surveys |
| `test/jobs/fizz_buzz_job_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/jobs/llm_fizz_buzz_job_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/jobs/publish_gist_job_test.rb` | links | packs/links |
| `test/system/fizz_buzz_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/system/links_test.rb` | links | packs/links |
| `test/system/surveys_test.rb` | surveys | packs/surveys |
| `test/evals/fizzbuzz_basic_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v2_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v3_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v4_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v5_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v6_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v7_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v7_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v8_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v9_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v10_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v11_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_basic_v12_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_clean_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/fizzbuzz_eval_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/yoda_fizzbuzz_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/evals/ |
| `test/evals/eval_fixture_writer_test.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz/test/evals/ |
| `test/evals/eval_test_setup_test.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz/test/evals/ |
| `test/support/eval_fixture_writer.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz/test/support/ |
| `test/support/eval_test_setup.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz/test/support/ |
| `test/lib/eval_loader_test.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz/test/lib/ |
| `test/helpers/ruby_llm/evals/runs_helper_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/helpers/ |
| `test/configuration/evaluation_configuration_test.rb` | fizzbuzz/evals | packs/fizzbuzz/test/configuration/ |
| `test/fixtures/links.yml` | links | packs/links/test/fixtures/ |
| `test/fixtures/ruby_llm/evals/prompts.yml` | fizzbuzz/evals | packs/fizzbuzz/test/fixtures/ruby_llm/evals/ |
| `test/fixtures/ruby_llm/evals/samples.yml` | fizzbuzz/evals | packs/fizzbuzz/test/fixtures/ruby_llm/evals/ |
| `test/fixtures/ruby_llm/evals/runs.yml` | fizzbuzz/evals | packs/fizzbuzz/test/fixtures/ruby_llm/evals/ |
| `test/fixtures/ruby_llm/evals/prompt_executions.yml` | fizzbuzz/evals | packs/fizzbuzz/test/fixtures/ruby_llm/evals/ |
| `test/cassettes/fizzbuzz_basic_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz/test/cassettes/ |
| `test/cassettes/fizzbuzz_basic_v*_*.yml` (×80+) | fizzbuzz/evals | packs/fizzbuzz/test/cassettes/ |
| `test/cassettes/fizzbuzz_clean_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz/test/cassettes/ |
| `test/cassettes/fizzbuzz_eval_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz/test/cassettes/ |
| `test/cassettes/yoda_fizzbuzz_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz/test/cassettes/ |
| `test/cassettes/gist_publisher_*.yml` (×2) | links | packs/links/test/cassettes/ |
| `test/cassettes/execute_sample_job_*.yml` (×3) | fizzbuzz/evals | packs/fizzbuzz/test/cassettes/ |
| `test/cassettes/*_negative.yml` / `*_positive.yml` (×20) | surveys | packs/surveys/test/cassettes/ |
| `test/fixtures/survey_responses.yml` (if exists) | surveys | packs/surveys/test/fixtures/ |
| `test/fixtures/files/.keep` | infrastructure | root |

---

## Files That Cannot Move Into Packs

These files must remain at the Rails app root regardless of domain:

| File | Reason |
|------|--------|
| `config/routes.rb` | Rails convention — single routes file wires all domains |
| `config/application.rb` | Rails app bootstrap |
| `config/environment*.rb` | Rails environments |
| `config/database.yml` | Single database config |
| `app/views/layouts/application.html.erb` | Shared layout (app-layer; stays at root) |
| `app/assets/stylesheets/application.css` | Shared stylesheet |
| `app/javascript/` (index, application, controllers/index) | Shared JS bundle |
| `test/test_helper.rb` | Shared test infrastructure |
| `test/application_system_test_case.rb` | Shared system test infrastructure |
| `lib/eval_loader.rb` | ~~Shared library used by seeds; path updated in Plan 05 but file stays in lib/~~ → Moved to `packs/eval_loader` (Plan 04, Part C) |

Note: `app/controllers/application_controller.rb`, `app/models/application_record.rb`,
`app/jobs/application_job.rb`, `app/mailers/application_mailer.rb`, and
`app/helpers/application_helper.rb` were previously listed here as immovable.
Plan 04 extracts these into `packs/rails_shims` — they CAN move once the autoload
paths are configured in Plan 01.

Note: `test/cassettes/` and `test/fixtures/` are empty after migration — all per-domain
cassettes and fixtures move to `packs/<name>/test/cassettes/` and `packs/<name>/test/fixtures/`
respectively (Plan 02). Only `test/fixtures/files/.keep` remains at root.

---

## evals/ Root Directory

All `evals/` files move to `packs/fizzbuzz/evals/` in Plan 05. `EvalLoader` is updated
to reference the new path (`Rails.root.join("packs/fizzbuzz/evals")`).

| File | Domain | Pack Target |
|------|--------|-------------|
| `evals/fizzbuzz/prompts.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/fizzbuzz/samples.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/fizzbuzz/runs.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/fizzbuzz/executions.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/tdd/prompts.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/tdd/samples.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/tdd/runs.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/tdd/executions.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/runs.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/prompt_executions.yml` | fizzbuzz/evals | packs/fizzbuzz/evals/ |
| `evals/README.md` | docs | packs/fizzbuzz/evals/ |
