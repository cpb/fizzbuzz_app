# Eval Framework

The eval framework is a structured test harness for measuring LLM prompt quality. It has two
distinct data paths: **synthetic data** (YAML fixtures committed to the repository, run via
minitest) and the **production data path** (real customer data evaluated on the production
server through a web UI, never committed). Keeping these two paths separate is the core
rule — it's what makes evals safe to share and reproduce across the team while keeping
production data where it belongs.

---

## Table of Contents

- [What evals measure](#what-evals-measure) ← Product and Design start here
- [Synthetic data path](#synthetic-data-path) ← Engineering entry point
  - [Directory layout](#directory-layout)
  - [File reference](#file-reference)
  - [Eval types](#eval-types)
  - [Running evals](#running-evals)
- [Production data path](#production-data-path)
  - [The engine mount point](#the-engine-mount-point)
  - [Evaluating real data locally](#evaluating-real-data-locally)
  - [Guardrails](#guardrails)
- [Research gaps](#research-gaps)
  - [Associations to domain models](#associations-to-domain-models-for-samples-todo-research-pr)
  - [Multi-turn evals](#multi-turn-evals-todo-research-pr)
  - [Automatic synthetic data creation](#automatic-creation-of-valid-synthetic-data-todo-research-pr)
  - [Promoting synthetic data to production](#promoting-synthetic-data-to-production-todo-research-pr)

---

## What evals measure

An eval answers the question: *for this prompt, does the model produce the right output?*

Each eval ties a prompt template to a set of sample inputs and expected outputs. Running the
eval sends each sample through the model and checks whether the response matches — giving a
pass rate that makes prompt quality concrete and comparable across iterations.

The framework currently covers three eval suites:

| Suite | What it tests |
|---|---|
| `fizzbuzz` | Prompt variants for the FizzBuzz LLM feature; measures instruction clarity and output format compliance |
| `tdd` | Iterative TDD prompts for FizzBuzz; measures code correctness at each development stage |

Performance results and grid visualizations for past runs live in [`doc/evals/`](../doc/evals/README.md).

---

## Synthetic data path

Synthetic evals are the source of truth for prompt development. They are YAML fixtures
committed to the repository, seeded into the test database by Rails' fixture loader, and
executed against recorded HTTP cassettes. Because nothing here is real customer data —
every input is hand-authored or generated specifically for testing — the entire directory is
safe to commit, review, and share.

### Directory layout

```
evals/
├── fizzbuzz/
│   ├── prompts.yml           # prompt configurations
│   ├── samples.yml           # test cases
│   ├── runs.yml              # recorded batch execution metadata
│   └── executions.yml        # recorded per-sample results
├── tdd/
│   └── ...                   # same four files
├── runs.yml                  # empty fixture; clears Run records before each eval test
└── prompt_executions.yml     # empty fixture; clears PromptExecution records before each eval test
```

Each topic directory is self-contained. Add a new topic by creating a new directory with
`prompts.yml` and `samples.yml`.

### File reference

**`prompts.yml`** — defines the prompt configurations under test.

```yaml
_fixture:
  model_class: RubyLLM::Evals::Prompt

fizzbuzz_basic:
  name: "FizzBuzz Basic"
  slug: "fizzbuzz-basic"
  provider: "ollama"
  model: "llama3.2"
  message: "Is {{number}} a FizzBuzz number? Answer with FizzBuzz, Fizz, Buzz or the number if not."

fizzbuzz_eval:
  name: "FizzBuzz Eval"
  slug: "fizzbuzz-eval"
  provider: "ollama"
  model: "llama3.2"
  instructions: "Evaluate FizzBuzz for the given number. Return exactly one word: ..."
  message: "{{number}}"
```

| Field | Required | Description |
|---|---|---|
| `name` | yes | Human-readable display name |
| `slug` | yes | Unique identifier used to reference this prompt from samples |
| `provider` | yes | LLM provider (`ollama`, `anthropic`, etc.) |
| `model` | yes | Model identifier |
| `message` | yes | User message template; `{{variable}}` placeholders are filled from sample variables |
| `instructions` | no | System prompt / instructions prepended to every message |

---

**`samples.yml`** — defines the test cases for each prompt.

```yaml
_fixture:
  model_class: RubyLLM::Evals::Sample

fizzbuzz_basic_15:
  prompt: fizzbuzz_basic
  eval_type: regex
  expected_output: "fizz\\s*buzz"
  variables: { "number": "15" }

fizzbuzz_eval_15:
  prompt: fizzbuzz_eval
  eval_type: contains
  expected_output: "FizzBuzz"
  variables: { "number": "15" }
```

| Field | Description |
|---|---|
| `prompt` | YAML key of the prompt this sample belongs to |
| `eval_type` | How the response is checked (see [Eval types](#eval-types)) |
| `expected_output` | The value to check against (pattern, substring, or exact string) |
| `variables` | Key-value pairs that fill `{{placeholder}}` slots in the prompt's `message` |

---

**`runs.yml`** and **`executions.yml`** — recorded results from past eval runs. Written by
`EvalFixtureWriter` inside `with_eval_cassette` only when VCR records new HTTP interactions
(always with `RECORD_EVALS=true`; never during normal playback runs with all cassettes
present). Committed as a snapshot of model behavior. `seed_round_trip_test.rb` loads them
as fixtures and asserts that all records parse correctly and counts match — verifying YAML
structural integrity, not re-running the evals.

### Eval types

| Type | Pass condition |
|---|---|
| `regex` | Response matches the expected regular expression (case-insensitive) |
| `contains` | Response contains the expected substring |
| `exact` | Response exactly equals the expected string |
| `llm_judge` | A second LLM call judges whether the response meets the criterion |
| `human_judge` | A human reviewer marks pass/fail through the `/evals` UI |

### Running evals

```sh
# Run all eval tests (uses VCR cassettes — no real network calls)
bin/rails test test/evals/

# Run a specific eval suite
bin/rails test test/evals/fizzbuzz_basic_eval_test.rb

# Re-record cassettes (makes real LLM calls; overwrites existing cassettes; requires provider credentials)
RECORD_EVALS=true bin/rails test test/evals/fizzbuzz_basic_eval_test.rb
```

Eval tests include `EvalTestSetup` (`test/support/eval_test_setup.rb`), which:
- Points the fixture loader at `evals/` instead of `test/fixtures/`
- Serializes execution (`parallelize(workers: 1)`) to avoid database conflicts
- Provides `with_eval_cassette(name)` — runs the block inside a VCR cassette and writes
  `runs.yml`/`executions.yml` only when VCR records new HTTP interactions

---

## Production data path

The production data path is for evaluating prompts against real customer data **on the
production server**. Production data never leaves production — this is the core data privacy
constraint the path is designed to satisfy. The web UI runs where the data already lives;
no data is pulled down to a development machine.

### The engine mount point

`RubyLLM::Evals::Engine` is mounted at `/evals` (`config/routes.rb`):

```ruby
mount RubyLLM::Evals::Engine, at: "/evals"
```

This provides a full-featured UI at `/evals` on whichever host the app is running with:

- Prompt listing and management
- Run history with pass/fail metrics
- Per-run results with grid visualization (FizzBuzz) and detailed execution records
- Human-judge interface for `human_judge` eval type

### Evaluating production data on the production server

To evaluate a prompt against production data:

1. **Seed the prompt and samples** into the production database using `EvalLoader`:

   ```ruby
   # In a Rails console on the production server
   EvalLoader.seed_dir("fizzbuzz")  # loads evals/fizzbuzz/prompts.yml + samples.yml
   ```

2. **Navigate to `/evals`** on the production host and select the prompt you want to run.

3. **Start a run.** Results are written to the production database and stay there.

4. **Review results** in the UI. The grid visualization shows pass/fail distribution across
   all samples for the run.

### Guardrails

Three properties of the system enforce the data privacy boundary:

1. **Results stay in the production database.** Run results written via the engine UI are
   never written back to `runs.yml` or `executions.yml` in `evals/`. There is no export
   path from the UI to committed YAML.

2. **`EvalFixtureWriter` is test-only.** The class that writes results back to YAML
   (`test/support/eval_fixture_writer.rb`) is only available in the test environment and is
   only called from within `test/evals/` test files. There is no code path from a production
   run to a committed YAML file.

3. **VCR cassettes are for synthetic tests, not production runs.** Cassettes capture HTTP
   interactions during test execution. The production path makes live LLM calls and never
   touches the cassette layer.

The practical rule: anything in `evals/*.yml` is synthetic (commit freely); results from
running the engine UI against production data stay in the production database (never commit).

---

## Research gaps

The following sections describe anticipated capabilities that are not yet implemented. Each
is marked `[TODO: research-pr]` to indicate that an open investigation will fill in the
detail. Each gap will become a `/research-pr` issue when this README is merged.

### Associations to domain models for samples `[TODO: research-pr]`

Samples are currently self-contained YAML records with a `variables` hash. The expected
next step is that samples can be associated to domain model instances — a `WorkbookSession`,
a `ThinkingTrap`, or a `FizzBuzzer` run — so that production evals can be scoped to specific
records rather than hand-authored variable sets. This will likely surface as a
`sample_source` or `record_gid` field on `RubyLLM::Evals::Sample` that binds a sample to a
specific ActiveRecord object via GlobalID.

### Multi-turn evals `[TODO: research-pr]`

The eval framework currently treats each sample as a single prompt-response pair. Some
prompts are designed for multi-turn conversations where what matters is the quality of the
full exchange, not a single response. The expected capability is a first-class multi-turn
eval type that chains a sequence of messages across a conversation and evaluates the final
response — or each turn independently.

### Automatic creation of valid synthetic data `[TODO: research-pr]`

Hand-authoring YAML samples is the current bottleneck for expanding eval coverage. The
expected capability is tooling that generates well-formed sample fixtures from existing
domain model instances — converting a domain record into a `samples.yml` entry automatically. This reduces the barrier to adding new evals and
keeps synthetic data structurally consistent with production data shapes.

### Promoting synthetic data to production (upsert vs replace semantics) `[TODO: research-pr]`

When a synthetic prompt and sample set is ready for production evaluation, it needs to be
loaded into the live database. `EvalLoader.seed_dir` currently uses `find_or_create_by!`
(create-if-not-found semantics: returns the existing record unchanged if found, creates a
new one if not). The expected gap is a defined promotion workflow — including whether
updates to a synthetic fixture that already exists in production should upsert (update in
place) or replace (delete and re-create), and how to handle production runs that reference
the old record. Note: `EvalLoader.seed_dir` also has a bug where it calls
`attrs["model_class"].constantize` on every YAML entry rather than reading `model_class`
once from the `_fixture` header (tracked in issue #122).
