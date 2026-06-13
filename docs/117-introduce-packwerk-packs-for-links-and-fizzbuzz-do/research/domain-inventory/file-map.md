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
| `app/models/application_record.rb` | infrastructure | root |
| `app/models/link.rb` | links | packs/links |
| `app/models/gist.rb` | links | packs/links |
| `app/models/gist_publisher.rb` | links | packs/links |
| `app/models/qr_code_generator.rb` | links | packs/links |
| `app/models/fizz_buzzer.rb` | fizzbuzz | packs/fizzbuzz |
| `app/models/llm_fizz_buzzer.rb` | fizzbuzz | packs/fizzbuzz |
| `app/models/survey_response.rb` | surveys | root (not packed this issue) |
| `app/controllers/application_controller.rb` | infrastructure | root |
| `app/controllers/fizz_buzz_controller.rb` | fizzbuzz | packs/fizzbuzz |
| `app/controllers/links_controller.rb` | links | packs/links |
| `app/controllers/surveys_controller.rb` | surveys | root (not packed this issue) |
| `app/controllers/replays_controller.rb` | workbook | out-of-scope |
| `app/controllers/workbook_session_replays_controller.rb` | workbook | out-of-scope |
| `app/controllers/workbook_sessions/replays_controller.rb` | workbook | out-of-scope |
| `app/controllers/concerns/.keep` | infrastructure | root |
| `app/jobs/application_job.rb` | infrastructure | root |
| `app/jobs/fizz_buzz_job.rb` | fizzbuzz | packs/fizzbuzz |
| `app/jobs/llm_fizz_buzz_job.rb` | fizzbuzz | packs/fizzbuzz |
| `app/jobs/publish_gist_job.rb` | links | packs/links |
| `app/mailers/application_mailer.rb` | infrastructure | root |
| `app/helpers/application_helper.rb` | infrastructure | root |
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
| `app/views/surveys/_results_panel.html.erb` | surveys | root (not packed this issue) |
| `app/views/surveys/results.html.erb` | surveys | root (not packed this issue) |
| `app/views/surveys/show.html.erb` | surveys | root (not packed this issue) |
| `app/views/pwa/manifest.json.erb` | infrastructure | root |
| `app/views/pwa/service-worker.js` | infrastructure | root |
| `app/views/replays/show.html.erb` | workbook | out-of-scope |
| `app/views/workbook_sessions/replays/_step.html.erb` | workbook | out-of-scope |
| `app/views/workbook_sessions/replays/advance.turbo_stream.erb` | workbook | out-of-scope |
| `app/views/workbook_sessions/replays/show.html.erb` | workbook | out-of-scope |
| `app/views/ruby_llm/evals/runs/_fizzbuzz_grid.html.erb` | fizzbuzz/evals | packs/fizzbuzz |
| `app/views/ruby_llm/evals/runs/show.html.erb` | fizzbuzz/evals | packs/fizzbuzz |
| `app/assets/stylesheets/application.css` | infrastructure | root |
| `app/assets/images/.keep` | infrastructure | root |
| `app/javascript/application.js` | infrastructure | root |
| `app/javascript/controllers/application.js` | infrastructure | root |
| `app/javascript/controllers/dismissible_controller.js` | infrastructure | root |
| `app/javascript/controllers/hello_controller.js` | infrastructure | root |
| `app/javascript/controllers/index.js` | infrastructure | root |
| `app/javascript/controllers/replay_controller.js` | workbook | out-of-scope |
| `app/javascript/controllers/word_by_word_controller.js` | workbook | out-of-scope |

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
| `test/controllers/surveys_controller_test.rb` | surveys | root (not packed this issue) |
| `test/jobs/fizz_buzz_job_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/jobs/llm_fizz_buzz_job_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/jobs/publish_gist_job_test.rb` | links | packs/links |
| `test/system/fizz_buzz_test.rb` | fizzbuzz | packs/fizzbuzz |
| `test/system/links_test.rb` | links | packs/links |
| `test/system/surveys_test.rb` | surveys | root (not packed this issue) |
| `test/evals/fizzbuzz_basic_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v2_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v3_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v4_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v5_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v6_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v7_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v7_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v8_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v9_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v10_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v11_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_basic_v12_full_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_clean_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/fizzbuzz_eval_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/yoda_fizzbuzz_eval_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/evals/eval_fixture_writer_test.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz |
| `test/evals/eval_test_setup_test.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz |
| `test/support/eval_fixture_writer.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz |
| `test/support/eval_test_setup.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz |
| `test/lib/eval_loader_test.rb` | fizzbuzz/evals infrastructure | packs/fizzbuzz |
| `test/helpers/ruby_llm/evals/runs_helper_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/configuration/evaluation_configuration_test.rb` | fizzbuzz/evals | packs/fizzbuzz |
| `test/fixtures/links.yml` | links | packs/links |
| `test/fixtures/ruby_llm/evals/prompts.yml` | fizzbuzz/evals | packs/fizzbuzz |
| `test/fixtures/ruby_llm/evals/samples.yml` | fizzbuzz/evals | packs/fizzbuzz |
| `test/fixtures/ruby_llm/evals/runs.yml` | fizzbuzz/evals | packs/fizzbuzz |
| `test/fixtures/ruby_llm/evals/prompt_executions.yml` | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/fizzbuzz_basic_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/fizzbuzz_basic_v*_*.yml` (×80+) | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/fizzbuzz_clean_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/fizzbuzz_eval_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/yoda_fizzbuzz_*.yml` (×15) | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/gist_publisher_*.yml` (×2) | links | packs/links |
| `test/cassettes/execute_sample_job_*.yml` (×3) | fizzbuzz/evals | packs/fizzbuzz |
| `test/cassettes/*_negative.yml` / `*_positive.yml` (×20) | surveys | root |
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
| `app/controllers/application_controller.rb` | Base class for all controllers |
| `app/models/application_record.rb` | Base class for all models |
| `app/jobs/application_job.rb` | Base class for all jobs |
| `app/mailers/application_mailer.rb` | Base class for all mailers |
| `app/helpers/application_helper.rb` | Shared helper |
| `app/views/layouts/application.html.erb` | Shared layout |
| `app/assets/stylesheets/application.css` | Shared stylesheet |
| `app/javascript/` (index, application, controllers/index) | Shared JS bundle |
| `test/test_helper.rb` | Shared test infrastructure |
| `test/application_system_test_case.rb` | Shared system test infrastructure |
| `lib/eval_loader.rb` | Shared library — used by seeds |

---

## evals/ Root Directory

| File | Domain | Notes |
|------|--------|-------|
| `evals/fizzbuzz/prompts.yml` | fizzbuzz/evals | Eval fixture data for fizzbuzz prompts |
| `evals/fizzbuzz/samples.yml` | fizzbuzz/evals | Eval fixture data for fizzbuzz samples |
| `evals/fizzbuzz/runs.yml` | fizzbuzz/evals | Historical run data |
| `evals/fizzbuzz/executions.yml` | fizzbuzz/evals | Historical execution data |
| `evals/tdd/prompts.yml` | fizzbuzz/evals | TDD eval data (fizzbuzz-related) |
| `evals/tdd/samples.yml` | fizzbuzz/evals | TDD eval data |
| `evals/tdd/runs.yml` | fizzbuzz/evals | TDD eval data |
| `evals/tdd/executions.yml` | fizzbuzz/evals | TDD eval data |
| `evals/runs.yml` | fizzbuzz/evals | Production eval run history |
| `evals/prompt_executions.yml` | fizzbuzz/evals | Production execution history |
| `evals/README.md` | docs | Eval documentation |

The `evals/` directory is referenced by `EvalLoader` (seeded at boot) and
`EvalTestSetup` (used by eval tests via `fixture_paths`). It is fizzbuzz-domain
data and should move into `packs/fizzbuzz/evals/` — but note that `EvalLoader`
and the `EvalTestSetup` paths will need updating.
