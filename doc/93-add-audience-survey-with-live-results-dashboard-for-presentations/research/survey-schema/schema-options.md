# Schema Options and Trade-off Analysis

## App conventions observed

From reading `db/schema.rb` and the migration files:

- **Rails version:** 8.1 (`ActiveRecord::Schema[8.1]`)
- **Database:** SQLite3 (all environments, including production via Kamal Docker)
- **Primary keys:** default bigint autoincrement (`id`)
- **Timestamps:** `t.timestamps` pattern everywhere (`created_at`, `updated_at`)
- **String vs text:** Short, bounded values use `string`; long/unbounded use `text`
- **JSON columns:** Used for flexible structured data (`variables`, `params`, `tools`, `judge_message` in `ruby_llm_evals_*` tables)
- **Enum-like columns:** `eval_type` is a `string` column in `ruby_llm_evals_samples` and `ruby_llm_evals_prompt_executions` — no database-level CHECK constraint, validation lives in the model
- **No existing serialized arrays** — but `text` and `json` columns are both present and the `sqlite3` gem >= 2.1 supports JSON columns natively in SQLite 3.38+
- **Gems of note:** No `store_accessor`, no `pg_array` (PostgreSQL-only). No serialization helper gems. Standard Rails `serialize` macro is available.

---

## Approach A: Flat table (recommended)

One `survey_responses` table holds all fields as columns.

### Schema sketch

```
survey_responses
  id              integer PK
  location        text
  role            string        # enum: developer / engineering_manager / student / other
  writes_ruby     boolean
  paid_to_write_ruby  string    # enum: yes / no / sometimes
  years_of_experience string    # enum: none / lt_1 / 1_3 / 4_6 / 7_9 / 10_13 / 14_plus
  prior_experience    string    # enum: none / lt_2 / 2_5 / 5_plus
  team_ai_adoption    string    # enum: 5 values
  ai_tools            text      # JSON-serialized array of strings
  likert_overhyped            integer  # 1-5
  likert_frustrated           integer  # 1-5
  likert_limit_to_boilerplate integer  # 1-5
  likert_anxious              integer  # 1-5
  likert_made_peace           integer  # 1-5
  likert_more_capable         integer  # 1-5
  submitted_at    datetime
  created_at      datetime
  updated_at      datetime
```

### Pros

- **One query reads an entire response** — no joins
- **Aggregation is trivial** — `GROUP BY role`, `AVG(likert_overhyped)` work directly on the table
- **Live dashboard** can be a single SQL query with multiple aggregations
- **Matches app convention** — the `ruby_llm_evals_prompt_executions` table uses the same flat pattern for similarly heterogeneous data
- **SQLite-friendly** — SQLite performs poorly with many-way joins compared to Postgres; flat rows benefit from SQLite's row-scan strengths
- **Simple model** — one `SurveyResponse` ActiveRecord model, no associations to manage

### Cons

- `ai_tools` multi-select requires JSON parse to filter by individual tool (see multi-select section below)
- Schema grows wide (18 columns), but this is not a problem for SQLite or Rails

---

## Approach B: Normalized — `survey_responses` + `survey_response_ai_tools`

A join table holds one row per (response, tool) pair.

```
survey_responses   (all fields except ai_tools)
survey_response_ai_tools
  id                    integer PK
  survey_response_id    integer FK
  tool_name             string
```

### Pros

- Querying "how many responses selected GitHub Copilot" becomes a simple `COUNT` on the join table
- Tool names are stored once per selection (no JSON parse)

### Cons

- Every full read of a response requires a `LEFT OUTER JOIN` or separate query + Ruby aggregation
- Live dashboard aggregations require either a subquery or two queries
- More migrations and model files for what is a relatively simple multi-select on a fixed option list (9 choices)
- SQLite's join performance is adequate but adds complexity for negligible benefit at survey scale (hundreds to low thousands of responses expected)
- Overhead of a second model class (`SurveyResponseAiTool`) for no behavioral complexity

### Verdict

Normalized is over-engineered for this use case. The audience survey is write-once, read-many with fixed options. A serialized JSON array is simpler and sufficiently queryable.

---

## Multi-select storage: AI tools used

Three options evaluated:

### Option 1: Serialized JSON array (recommended)

```ruby
# model
serialize :ai_tools, coder: JSON

# storage: '["claude_code_cli","cursor","chatgpt"]'
```

- Works with SQLite's JSON functions: `json_each(ai_tools)` for per-tool counts
- Rails `serialize` macro handles encode/decode transparently
- Dashboard aggregation: iterate over all responses in Ruby (at survey scale this is fine), or use a raw SQL `json_each` query (see aggregation doc)
- Single column, no joins

### Option 2: Separate join table

See Approach B above. Rejected for this use case.

### Option 3: Bit flags (integer bitmask)

```ruby
AI_TOOLS = { claude_code_cli: 1, cursor: 2, copilot: 4, chatgpt: 8, ... }
```

- Compact storage but opaque; adding a new tool invalidates old bit positions
- No Rails built-in support; requires custom accessor
- Hard to read in raw SQL or in logs

Rejected: fragile and unnecessary complexity.

**Recommendation: Option 1 — serialized JSON array.**

---

## Likert storage options

Three options evaluated:

### Option 1: 6 integer columns (recommended)

```ruby
t.integer :likert_overhyped
t.integer :likert_frustrated
t.integer :likert_limit_to_boilerplate
t.integer :likert_anxious
t.integer :likert_made_peace
t.integer :likert_more_capable
```

- `AVG(likert_overhyped)`, `AVG(likert_frustrated)`, etc. are single-pass SQL
- Column names self-document the statement
- Rails validations: `validates :likert_overhyped, inclusion: { in: 1..5 }`
- Six statements is a fixed, known quantity — schema is stable

### Option 2: JSON column

```ruby
t.json :likert_scores
# { overhyped: 4, frustrated: 2, ... }
```

- Avoids 6 explicit columns but loses SQL-level aggregation (no `AVG` on a JSON field in SQLite without json_extract)
- Requires `json_extract(likert_scores, '$.overhyped')` in every aggregation query
- No Rails-level type coercion for individual items

Rejected: adds query complexity for no structural benefit when the number of statements is fixed.

### Option 3: Separate `likert_responses` table

```
likert_responses
  id                  integer PK
  survey_response_id  integer FK
  statement_key       string
  score               integer
```

- Maximum flexibility to add new statements without a migration
- But: aggregation requires GROUP BY + pivot; 6 rows per response instead of 1
- Overkill when the statement set is fixed and known at design time

Rejected: unnecessary normalization.

**Recommendation: Option 1 — 6 integer columns.**

---

## Enum pattern: Rails `enum` macro vs. plain string

The app's existing migrations use `string` columns for enum-like data (e.g., `eval_type`). No database-level CHECK constraints are applied. The Ruby model layer enforces validity.

For `SurveyResponse`, use the **Rails `enum` macro** backed by a string column. This is idiomatic Rails 8 and matches the app's convention of string storage without DB-level constraints:

```ruby
class SurveyResponse < ApplicationRecord
  serialize :ai_tools, coder: JSON

  enum :role, {
    developer: "developer",
    engineering_manager: "engineering_manager",
    student: "student",
    other: "other"
  }, validate: true

  enum :paid_to_write_ruby, {
    yes: "yes",
    no: "no",
    sometimes: "sometimes"
  }, validate: true

  enum :years_of_experience, {
    none: "none",
    lt_1: "lt_1",
    one_to_3: "1_3",
    four_to_6: "4_6",
    seven_to_9: "7_9",
    ten_to_13: "10_13",
    fourteen_plus: "14_plus"
  }, validate: true

  enum :prior_experience, {
    none: "none",
    lt_2: "lt_2",
    two_to_5: "2_5",
    five_plus: "5_plus"
  }, validate: true

  enum :team_ai_adoption, {
    regularly_integrated:          "regularly_integrated",
    actively_experimenting:        "actively_experimenting",
    tried_no_routine:              "tried_no_routine",
    aware_not_started:             "aware_not_started",
    evaluated_decided_not_to_use:  "evaluated_decided_not_to_use"
  }, validate: true

  validates :role, :paid_to_write_ruby, :years_of_experience,
            :prior_experience, :team_ai_adoption, :writes_ruby,
            :submitted_at, presence: true

  validates :likert_overhyped, :likert_frustrated,
            :likert_limit_to_boilerplate, :likert_anxious,
            :likert_made_peace, :likert_more_capable,
            numericality: { only_integer: true, in: 1..5 }, allow_nil: true
end
```

Using string-backed enums means the stored values are human-readable in the SQLite database and in logs, matching the app's `eval_type: "fizzbuzz"` style.
