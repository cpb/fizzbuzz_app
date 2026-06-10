ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("evals"),
  %w[
    fizzbuzz/prompts fizzbuzz/samples fizzbuzz/runs fizzbuzz/executions
    tdd/prompts tdd/samples tdd/runs tdd/executions
  ]
)

ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("db/seeds/fixtures"),
  %w[links gists]
)
