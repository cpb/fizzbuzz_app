ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("packs/fizzbuzz/evals"),
  %w[prompts samples runs executions]
)

ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("evals"),
  %w[tdd/prompts tdd/samples tdd/runs tdd/executions]
)

ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("db/seeds/fixtures"),
  %w[links gists]
)
