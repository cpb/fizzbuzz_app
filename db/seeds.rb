ActiveRecord::FixtureSet.create_fixtures(
  Rails.root.join("evals"),
  %w[fizzbuzz/prompts fizzbuzz/samples]
)
