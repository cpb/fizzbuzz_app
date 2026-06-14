# Aggregation Queries

All examples assume the flat `survey_responses` table as recommended in [schema-options.md](schema-options.md).

---

## 1. Count by role

### ActiveRecord

```ruby
SurveyResponse.group(:role).count
# => { "developer" => 42, "engineering_manager" => 8, "student" => 15, "other" => 5 }
```

### Raw SQL

```sql
SELECT role, COUNT(*) AS count
FROM survey_responses
GROUP BY role
ORDER BY count DESC;
```

### Dashboard use

Feed result hash directly into a bar chart. Percentage calculation:

```ruby
counts = SurveyResponse.group(:role).count
total  = counts.values.sum
percentages = counts.transform_values { |n| (n.to_f / total * 100).round(1) }
```

---

## 2. Ruby experience breakdown (percentage)

### ActiveRecord

```ruby
counts = SurveyResponse.group(:years_of_experience).count
total  = SurveyResponse.count
percentages = counts.transform_values { |n| (n.to_f / total * 100).round(1) }
```

To preserve ordering (enum order, not alphabetical):

```ruby
EXPERIENCE_ORDER = %w[none lt_1 1_3 4_6 7_9 10_13 14_plus]

ordered = EXPERIENCE_ORDER.each_with_object({}) do |key, h|
  h[key] = percentages.fetch(key, 0.0)
end
```

### Raw SQL

```sql
SELECT
  years_of_experience,
  COUNT(*)                                          AS count,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct
FROM survey_responses
GROUP BY years_of_experience;
```

---

## 3. Average Likert score per statement

### ActiveRecord

```ruby
LIKERT_COLUMNS = %i[
  likert_overhyped
  likert_frustrated
  likert_limit_to_boilerplate
  likert_anxious
  likert_made_peace
  likert_more_capable
]

averages = LIKERT_COLUMNS.each_with_object({}) do |col, h|
  h[col] = SurveyResponse.average(col)&.round(2)
end
# => { likert_overhyped: 3.12, likert_frustrated: 2.89, ... }
```

### Single SQL query (all 6 in one pass)

```sql
SELECT
  ROUND(AVG(likert_overhyped),            2) AS avg_overhyped,
  ROUND(AVG(likert_frustrated),           2) AS avg_frustrated,
  ROUND(AVG(likert_limit_to_boilerplate), 2) AS avg_limit_to_boilerplate,
  ROUND(AVG(likert_anxious),              2) AS avg_anxious,
  ROUND(AVG(likert_made_peace),           2) AS avg_made_peace,
  ROUND(AVG(likert_more_capable),         2) AS avg_more_capable
FROM survey_responses;
```

This is a single scan of the table — very efficient for live-updating dashboards using Turbo Streams or Action Cable.

### ActiveRecord equivalent (single query)

```ruby
result = SurveyResponse.pick(
  Arel.sql("ROUND(AVG(likert_overhyped), 2)"),
  Arel.sql("ROUND(AVG(likert_frustrated), 2)"),
  Arel.sql("ROUND(AVG(likert_limit_to_boilerplate), 2)"),
  Arel.sql("ROUND(AVG(likert_anxious), 2)"),
  Arel.sql("ROUND(AVG(likert_made_peace), 2)"),
  Arel.sql("ROUND(AVG(likert_more_capable), 2)")
)
# result => [3.12, 2.89, 3.44, 2.71, 3.95, 4.01]
```

---

## 4. AI tools frequency ranking

Because `ai_tools` is a JSON-serialized array, per-tool counts require either a Ruby-side aggregation or SQLite's `json_each` table-valued function.

### Ruby-side (simplest, fine at survey scale)

```ruby
tool_counts = Hash.new(0)
SurveyResponse.pluck(:ai_tools).each do |raw|
  tools = JSON.parse(raw)
  tools.each { |t| tool_counts[t] += 1 }
end
tool_counts.sort_by { |_, v| -v }.to_h
# => { "claude_code_cli" => 38, "chatgpt" => 29, "cursor" => 24, ... }
```

### SQLite JSON expansion (pure SQL)

```sql
SELECT
  value        AS tool,
  COUNT(*)     AS count
FROM survey_responses,
     json_each(survey_responses.ai_tools)
GROUP BY value
ORDER BY count DESC;
```

SQLite 3.38+ (included in the `sqlite3` gem >= 2.1 required by this app's Gemfile) supports `json_each` as a built-in table-valued function.

### ActiveRecord wrapper

```ruby
SurveyResponse.connection.select_all(<<~SQL).to_a
  SELECT value AS tool, COUNT(*) AS count
  FROM survey_responses, json_each(survey_responses.ai_tools)
  GROUP BY value
  ORDER BY count DESC
SQL
# => [{ "tool" => "claude_code_cli", "count" => 38 }, ...]
```

---

## 5. Combined dashboard query

For a single-page live results view, one query can aggregate everything except AI tools:

```sql
SELECT
  role,
  writes_ruby,
  paid_to_write_ruby,
  years_of_experience,
  prior_experience,
  team_ai_adoption,
  COUNT(*)                                          AS response_count,
  ROUND(AVG(likert_overhyped),            2)        AS avg_overhyped,
  ROUND(AVG(likert_frustrated),           2)        AS avg_frustrated,
  ROUND(AVG(likert_limit_to_boilerplate), 2)        AS avg_limit_to_boilerplate,
  ROUND(AVG(likert_anxious),              2)        AS avg_anxious,
  ROUND(AVG(likert_made_peace),           2)        AS avg_made_peace,
  ROUND(AVG(likert_more_capable),         2)        AS avg_more_capable
FROM survey_responses
GROUP BY
  role, writes_ruby, paid_to_write_ruby,
  years_of_experience, prior_experience, team_ai_adoption;
```

In practice, the dashboard will want separate aggregations per dimension; the above is shown to illustrate the flat schema's flexibility.

---

## Performance notes

- Expected row count: hundreds to low thousands per presentation session
- No indexes beyond `role` and `submitted_at` are needed at this scale
- SQLite in WAL mode handles concurrent reads from the dashboard and writes from new submissions without locking
- All aggregation queries above are single-table scans; no joins needed
