ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("evals"),
  %w[
    fizzbuzz/prompts fizzbuzz/samples fizzbuzz/runs fizzbuzz/executions
    workbook/prompts workbook/samples workbook/runs workbook/executions
  ]
)
